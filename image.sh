#!/bin/bash
#
# SPDX-License-Identifier: GPL-2.0-or-later
# myMPDos (c) 2020-2021 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos
#

source config || { echo "config not found"; exit 1; }
IMAGE=$(ls -t images/myMPDos-"$ARCH"-*.img | head -1)

if [ "$IMAGE" = "" ]
then
	echo "No image found, build it with ./build.sh"
	exit 1
fi

mountimage() {
	install -d tmp/mnt
	LOOP=$(sudo losetup --partscan --show -f "$IMAGE")
	sudo mount -ouid="$BUILDUSER" "${LOOP}p1" tmp/mnt || exit 1
	return 0
}

umountimage() {
	./build.sh umountbuild
}

burnimage() {
	SDCARD=$1
	[ "$SDCARD" = "" ] && exit 1
	if mount | grep -q "$SDCARD"
	then
		echo "$SDCARD seems to be mounted"
		exit 1
	fi
	echo "Transfering $IMAGE to $SDCARD"
	sudo dd if="$IMAGE" of="$SDCARD"
}

startimage() {
	mountimage
	rm tmp/mnt/boot/modloop-*
	cp "tmp/$ARCH/netboot/boot/modloop-lts" tmp/mnt/boot/
	umountimage
	$QEMU \
    	-M virt -m "$BUILDRAM" -cpu "$CPU" -smp "$BUILDCPUS" \
    	-kernel "tmp/$ARCH/netboot/boot/$KERNEL" \
    	-initrd "tmp/$ARCH/netboot/boot/$INITRAMFS" \
    	-append "console=ttyAMA0 ip=dhcp" \
    	-nographic \
    	-drive "file=${IMAGE},format=raw" \
    	-netdev user,id=mynet0,net=192.168.76.0/24,dhcpstart=192.168.76.9 \
    	-nic user,id=mynet0
}

case "$1" in
	start)
		startimage
	;;
	mount)
		mountimage
	;;
	umount)
		umountimage
	;;
	burn)
		if [ "$2" = "" ]
		then
			echo "Usage: $0 burnimage <sdcard device>"
			exit 1
		fi
		burnimage "$2"
	;;
	*)
		echo "Usage: $0 (start|mount|umount|burn)"
		exit 1
	;;
esac
exit 0
