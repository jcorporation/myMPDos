#!/bin/sh

IMAGE="myMPDos-0.1.0.img"
ARCH="aarch64"
ALPINE_MAJOR_VERSION="3.12"
ALPINE_VERSION="${ALPINE_MAJOR_VERSION}.0"
ALPINE_MIRROR="http://dl-cdn.alpinelinux.org/alpine"
BUILDUSER=$USER

install -d tmp
cd tmp || exit 1

echo "Download"
if [ ! -f alpine-netboot-${ALPINE_VERSION}-${ARCH}.tar.gz ]
then
  wget "${ALPINE_MIRROR}/v${ALPINE_MAJOR_VERSION}/releases/${ARCH}/alpine-netboot-${ALPINE_VERSION}-${ARCH}.tar.gz" \
	-O alpine-netboot-${ALPINE_VERSION}-${ARCH}.tar.gz
  tar -xzf /alpine-netboot-${ALPINE_VERSION}-${ARCH}.tar.gz
fi

[ -f alpine-rpi-${ALPINE_VERSION}-${ARCH}.tar.gz ] || \
	wget "${ALPINE_MIRROR}/v${ALPINE_MAJOR_VERSION}/releases/${ARCH}/alpine-rpi-${ALPINE_VERSION}-${ARCH}.tar.gz" \
		-O alpine-rpi-${ALPINE_VERSION}-${ARCH}.tar.gz

echo "Create build image"
dd if=/dev/zero of="$IMAGE" bs=1M count=2048
fdisk "$IMAGE" << EOL
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
LOOP=$(sudo losetup --partscan --show -f $IMAGE)
sudo mkfs.vfat "${LOOP}p1"
sudo mkfs.ext4 "${LOOP}p2"
install -d mnt
sudo mount -ouid=$BUILDUSER "${LOOP}p1" mnt
tar -xzf alpine-rpi-${ALPINE_VERSION}-${ARCH}.tar.gz -C mnt
cp boot/modloop-lts mnt/boot
install -d mnt/mympd
cp -r ../mympd/build/* mnt/mympd
rm -f init
gzip -dc boot/initramfs-lts | cpio -id init
patch init ../mympd/build/init.patch
echo ./init | cpio -H newc -o | gzip >> boot/initramfs-lts
sudo umount mnt

qemu-system-aarch64 \
  -M virt -m 1024M -cpu cortex-a57 \
  -kernel boot/vmlinuz-lts -initrd boot/initramfs-lts \
  -append "console=ttyAMA0 ip=dhcp" \
  -nographic \
  -drive file=${IMAGE},format=raw \
  -netdev user,id=mynet0,net=192.168.76.0/24,dhcpstart=192.168.76.9 \
  -nic user,id=mynet0

echo "Saving packages"
install -d ../mympd-os-apks
sudo mount -text4 "${LOOP}p2" mnt
cp mnt/build/packages/package/${ARCH}/* ../mympd-os-apks/
cp -r mnt/build/.abuild ../mympd-os-apks/
sudo umount mnt
sudo losetup -d "${LOOP}"

echo "Create image"
dd if=/dev/zero of="$IMAGE" bs=1M count=256
fdisk "$IMAGE" << EOL
n
p
1


t
b
a
w

EOL
LOOP=$(sudo losetup --partscan --show -f $IMAGE)
sudo mkfs.vfat "${LOOP}p1"
sudo mount -ouid=$BUILDUSER "${LOOP}p1" mnt
tar -xzf alpine-rpi-${ALPINE_VERSION}-${ARCH}.tar.gz -C mnt
cd ../mympd/overlay || exit 1
tar -czf ../../tmp/mnt/headless.apkovl.tar.gz *
cd ../../tmp || exit 1
echo "ssid WPA-PSK password" > mnt/wifi.txt
cp -r ../mympd-os-apks mnt/
sudo umount mnt
sudo losetup -d "${LOOP}"

echo "Cleanup"
#mv "$IMAGE" ..
#cd ..
#gzip "$IMAGE"
#rm -r tmp
