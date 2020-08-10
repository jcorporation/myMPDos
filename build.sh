#!/bin/sh

VERSION="0.1.0"
IMAGE="myMPDos-${VERSION}-$(date +%Y%m%d).img"
ARCH="aarch64"
ALPINE_MAJOR_VERSION="3.12"
ALPINE_VERSION="${ALPINE_MAJOR_VERSION}.0"
ALPINE_MIRROR="http://dl-cdn.alpinelinux.org/alpine"
BUILDUSER=$USER
IMAGESIZE=256
IMAGESIZEBUILD=2048
CLEANUP=0

install -d tmp
cd tmp || exit 1

echo "Download"
if [ ! -f alpine-netboot-${ALPINE_VERSION}-${ARCH}.tar.gz ]
then
  wget -q "${ALPINE_MIRROR}/v${ALPINE_MAJOR_VERSION}/releases/${ARCH}/alpine-netboot-${ALPINE_VERSION}-${ARCH}.tar.gz" \
	-O "alpine-netboot-${ALPINE_VERSION}-${ARCH}.tar.gz"
  tar -xzf "alpine-netboot-${ALPINE_VERSION}-${ARCH}.tar.gz"
fi

[ -f alpine-rpi-${ALPINE_VERSION}-${ARCH}.tar.gz ] || \
	wget -q "${ALPINE_MIRROR}/v${ALPINE_MAJOR_VERSION}/releases/${ARCH}/alpine-rpi-${ALPINE_VERSION}-${ARCH}.tar.gz" \
		-O "alpine-rpi-${ALPINE_VERSION}-${ARCH}.tar.gz"

echo "Create build image"
dd if=/dev/zero of="$IMAGE" bs=1M count="$IMAGESIZEBUILD"
fdisk "$IMAGE" > /dev/null << EOL
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

EOL
LOOP=$(sudo losetup --partscan --show -f "$IMAGE")
[ "$LOOP" = "" ] && exit 1
sudo mkfs.vfat "${LOOP}p1"
sudo mkfs.ext4 "${LOOP}p2"
install -d mnt
sudo mount -ouid="$BUILDUSER" "${LOOP}p1" mnt || exit 1
tar -xzf alpine-rpi-${ALPINE_VERSION}-${ARCH}.tar.gz -C mnt
cp boot/modloop-lts mnt/boot
install -d mnt/mympd
cp -r ../mympd/build/* mnt/mympd
[ -f ../mympd-os-apks/abuild.tgz ] && cp ../mympd-os-apks/abuild.tgz mnt/mympd/
date +%s > mnt/date
sudo umount mnt || exit 1

rm -f init
gzip -dc boot/initramfs-lts | cpio -id init
patch init ../mympd/build/init.patch
echo ./init | cpio -H newc -o | gzip >> boot/initramfs-lts

echo "Starting build image"
qemu-system-aarch64 \
  -M virt -m 1024M -cpu cortex-a57 \
  -kernel boot/vmlinuz-lts -initrd boot/initramfs-lts \
  -append "console=ttyAMA0 ip=dhcp" \
  -nographic \
  -drive "file=${IMAGE},format=raw" \
  -netdev user,id=mynet0,net=192.168.76.0/24,dhcpstart=192.168.76.9 \
  -nic user,id=mynet0

echo "Saving packages"
install -d ../mympd-os-apks
sudo mount -text4 "${LOOP}p2" mnt || exit 1
[ -f mnt/build/abuild.tgz ] && cp mnt/build/abuild.tgz ../mympd-os-apks/
cp mnt/build/packages/package/${ARCH}/* ../mympd-os-apks/
sudo umount mnt || exit 1
sudo losetup -d "${LOOP}"

echo "Create image"
dd if=/dev/zero of="$IMAGE" bs=1M count="$IMAGESIZE"
fdisk "$IMAGE" > /dev/null << EOL
n
p
1


t
b
a
w

EOL
LOOP=$(sudo losetup --partscan --show -f "$IMAGE")
[ "$LOOP" = "" ] && exit 1
sudo mkfs.vfat "${LOOP}p1"
sudo mount -ouid="$BUILDUSER" "${LOOP}p1" mnt || exit 1
tar -xzf "alpine-rpi-${ALPINE_VERSION}-${ARCH}.tar.gz" -C mnt
cd ../mympd/overlay || exit 1
tar -czf ../../tmp/mnt/headless.apkovl.tar.gz .
cd ../../tmp || exit 1
echo "ssid WPA-PSK password" > mnt/wifi.txt
cp -r ../mympd-os-apks mnt/
sudo umount mnt || exit 1
sudo losetup -d "${LOOP}"

[ "$CLEANUP" = "0" ] && exit 0
echo "Cleanup"
mv "$IMAGE" ..
cd ..
gzip "$IMAGE"
rm -r tmp
exit 0
