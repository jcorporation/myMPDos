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
	install -d "tmp/$ARCH/image"
	
	cd "tmp/$ARCH" || exit 1
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

	$QEMU -m 1024 \
		-M "$MACHINE" \
		-sd "../../$IMAGE" \
		-kernel image/boot/vmlinuz-rpi \
		-initrd image/boot/initramfs-rpi \
		-append "console=ttyAMA0" \
		-dtb "image/$DTB" \
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
