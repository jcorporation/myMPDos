#!/bin/bash
#
# SPDX-License-Identifier: GPL-2.0-or-later
# myMPD (c) 2020 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/mympd
#

source config || { echo "config not found"; exit 1; }

[ "$1" == "private" ] && PRIVATE=1

echo "Checking dependencies"
for DEP in wget tar gzip cpio dd losetup fdisk mkfs.vfat mkfs.ext4 sudo install sed patch
do
  if ! command -v "$DEP" > /dev/null
  then
    echo "Tool $DEP not found"
    exit 1
  fi
done

umount_retry() {
  if ! sudo umount "$1"
  then
    echo "Retrying in 2s"
    sleep 2
    sudo umount "$1" || return 1
  fi
  return 0
}

install -d tmp
cd tmp || exit 1

echo "Download"
NETBOOT_ARCHIVE="alpine-netboot-${ALPINE_VERSION}-${ARCH}.tar.gz"
if [ ! -f "$NETBOOT_ARCHIVE" ]
then
  echo "Getting $NETBOOT_ARCHIVE"
  wget -q "${ALPINE_MIRROR}/v${ALPINE_MAJOR_VERSION}/releases/${ARCH}/$NETBOOT_ARCHIVE" \
    -O "$NETBOOT_ARCHIVE"
fi
if [ ! -d boot ]
then
  if ! tar -xzf "$NETBOOT_ARCHIVE"
  then
    echo "Can not extract $NETBOOT_ARCHIVE"
    exit 1
  fi
fi

ARCHIVE="alpine-rpi-${ALPINE_VERSION}-${ARCH}.tar.gz"
if [ ! -f "$ARCHIVE" ]
then
  echo "Getting $ARCHIVE"
  wget -q "${ALPINE_MIRROR}/v${ALPINE_MAJOR_VERSION}/releases/${ARCH}/$ARCHIVE" \
    -O "$ARCHIVE"
  if ! tar -tzf "$ARCHIVE" > /dev/null
  then
    echo "Can not extract $ARCHIVE"
    exit 1
  fi
fi

echo "Create build image"
dd if=/dev/zero of="$BUILDIMAGE" bs=1M count="$IMAGESIZEBUILD"
fdisk "$BUILDIMAGE" > /dev/null << EOF
n
p
1

+248M
t
b
a
n
p
2


w

EOF
LOOP=$(sudo losetup --partscan --show -f "$BUILDIMAGE")
[ "$LOOP" = "" ] && exit 1
sudo mkfs.vfat "${LOOP}p1"
sudo mkfs.ext4 "${LOOP}p2"
install -d mnt
sudo mount -ouid="$BUILDUSER" "${LOOP}p1" mnt || exit 1
tar -xzf "$ARCHIVE" -C mnt
cp boot/modloop-lts mnt/boot

echo "Copy build scripts"
install -d mnt/mympd
cp -r ../mympdos/build/* mnt/mympd

echo "Copy existing packages"
install -d mnt/mympdos-apks
if [ -f ../mympdos-apks/APKINDEX.tar.gz ]
then
  cp ../mympdos-apks/*.apk mnt/mympdos-apks/
  cp ../mympdos-apks/APKINDEX.tar.gz mnt/mympdos-apks/
else
  echo "No existing packages found"
fi
if [ -f ../mympdos-apks/abuild.tgz ]
then
  cp ../mympdos-apks/abuild.tgz mnt/mympd/
else
  echo "No saved abuild.tgz found"
fi
date +%s > mnt/date
umount_retry mnt || exit 1

echo "Patching initramfs"
rm -f init
gzip -dc boot/initramfs-lts | cpio -id init
patch init ../mympdos/build/init.patch
echo ./init | cpio -H newc -o | gzip >> boot/initramfs-lts

echo "Starting build image"
qemu-system-aarch64 \
  -M virt -m 1024M -cpu cortex-a57 \
  -kernel boot/vmlinuz-lts -initrd boot/initramfs-lts \
  -append "console=ttyAMA0 ip=dhcp" \
  -nographic \
  -drive "file=${BUILDIMAGE},format=raw" \
  -netdev user,id=mynet0,net=192.168.76.0/24,dhcpstart=192.168.76.9 \
  -nic user,id=mynet0

echo "Saving packages"
install -d ../mympdos-apks
sudo mount -text4 "${LOOP}p2" mnt || exit 1
if [ -f mnt/build/abuild.tgz ]
then
  cp mnt/build/abuild.tgz ../mympdos-apks/
else
  echo "No abuild.tgt found"
fi
if [ -f "mnt/build/packages/package/${ARCH}/APKINDEX.tar.gz" ]
then
  cp mnt/build/packages/package/"${ARCH}"/* ../mympdos-apks/
else
  echo "No APKINDEX.tar.gz found"
fi
umount_retry mnt || exit 1
sudo losetup -d "${LOOP}"

echo "Create image"
dd if=/dev/zero of="$IMAGE" bs=1M count="$IMAGESIZE"
fdisk "$IMAGE" > /dev/null << EOF
n
p
1


t
b
a
w

EOF
LOOP=$(sudo losetup --partscan --show -f "$IMAGE")
[ "$LOOP" = "" ] && exit 1
sudo mkfs.vfat "${LOOP}p1"
sudo mount -ouid="$BUILDUSER" "${LOOP}p1" mnt || exit 1
tar -xzf "$ARCHIVE" -C mnt
cd ../mympdos/overlay || exit 1
tar -czf ../../tmp/mnt/mympdos-bootstrap.apkovl.tar.gz .
cd ../../tmp || exit 1
if [ "$PRIVATE" = "1" ]
then
  echo "Copy private bootstrap.txt"
  cp ../mympdos/bootstrap.txt mnt/
else
  echo "Copy sample bootstrap.txt files"
  cp ../mympdos/bootstrap-*.txt mnt/
fi
echo "$VERSION" > mnt/myMPDos.version
echo "Copy saved packages to image"
install -d mnt/mympdos-apks
if [ -f ../mympdos-apks/APKINDEX.tar.gz ]
then
  cp ../mympdos-apks/*.apk mnt/mympdos-apks/
  cp ../mympdos-apks/APKINDEX.tar.gz mnt/mympdos-apks/
  tar --wildcards -xzf ../mympdos-apks/abuild.tgz -C mnt/mympdos-apks ".abuild/*.rsa.pub"
else
  echo "No myMPDos apks found"
fi

echo ""
echo "Image $IMAGE created successfully"
if [ "$PRIVATE" = "1" ]
then
  echo ""
  echo "Productive bootstrap.txt copied to image."
  echo "Dont redistribute this image!"
  echo ""
else
  echo ""
  echo "Next step is to create a bootstrap.txt."
  echo "There are samples in the image."
  echo ""
fi
umount_retry mnt || exit 1
sudo losetup -d "${LOOP}"
install -d ../images
mv "$IMAGE" ../images
exit 0
