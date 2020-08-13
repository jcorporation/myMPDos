#!/bin/bash
#
# SPDX-License-Identifier: GPL-2.0-or-later
# myMPD (c) 2018-2020 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/mympd
#
# This script starts the final image
# No networking becaus lack of usb support for raspberry in qemu
#

source config || { echo "config not found"; exit 1; }

install -d tmp
cd tmp || exit 1
[ -f "alpine-rpi-${ALPINE_VERSION}-${ARCH}.tar.gz" ] || \
        wget -q "${ALPINE_MIRROR}/v${ALPINE_MAJOR_VERSION}/releases/${ARCH}/alpine-rpi-${ALPINE_VERSION}-${ARCH}.tar.gz" \
                -O "alpine-rpi-${ALPINE_VERSION}-${ARCH}.tar.gz"
install -d image
tar -xzf "alpine-rpi-${ALPINE_VERSION}-${ARCH}.tar.gz" -C image

IMAGE=$(find ../images/ -name "myMPDos-*.img" | tail -1)

if [ "$IMAGE" = "" ]
then
  echo "No image found, build it with ./build.sh"  
  exit 1
fi

qemu-system-aarch64 -m 1024 \
	-M raspi3 \
	-sd "$IMAGE" \
	-kernel image/boot/vmlinuz-rpi \
	-initrd image/boot/initramfs-rpi \
	-append "console=ttyAMA0" \
	-dtb image/bcm2837-rpi-3-b.dtb \
	-nographic

exit 0
