#!/bin/bash
#
# SPDX-License-Identifier: GPL-2.0-or-later
# myMPD (c) 2018-2020 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/mympd
#

source config || { echo "config not found"; exit 1; }
IMAGE=$(find images/ -name "myMPDos-*.img" | tail -1)

if [ "$IMAGE" = "" ]
then
	echo "No image found, build it with ./build.sh"
	exit 1
fi

mountimage() {
	install -d tmp/mnt
	LOOP=$(sudo losetup --partscan --show -f "$IMAGE")
	sudo mount -ouid="$BUILDUSER" "${LOOP}p1" mnt || exit 1
	return 0
}

umountimage() {
	sudo umount tmp/mnt || exit 1
	LOOP=$(losetup | grep "myMPDos" | awk '{print $1}')
	sudo losetup -d "$LOOP"
}

burnimage() {
	SDCARD=$1
	[ "$SDCARD" = "" ] && exit 1
	if mount | grep -q "$SDCARD"
	then
		echo "$SDCARD seems to be mounted"
		exit 1
	fi
	sudo dd if="$IMAGE" of="$SDCARD"
}

startimage() {
	install -d tmp/image
	
	cd tmp || exit 1
	if [ ! -f "$ARCHIVE" ]
	then
		echo "Getting $ARCHIVE"
		wget -q "${ALPINE_MIRROR}/v${ALPINE_MAJOR_VERSION}/releases/${ARCH}/$ARCHIVE" \
			-O "alpine-rpi-${ALPINE_VERSION}-${ARCH}.tar.gz"
	fi
	if ! tar -xzf "$ARCHIVE" -C image
	then
		echo "Error unpacking $ARCHIVE"
		exit 1
	fi

	qemu-system-aarch64 -m 1024 \
		-M raspi3 \
		-sd "../$IMAGE" \
		-kernel image/boot/vmlinuz-rpi \
		-initrd image/boot/initramfs-rpi \
		-append "console=ttyAMA0" \
		-dtb image/bcm2837-rpi-3-b.dtb \
		-nographic
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
