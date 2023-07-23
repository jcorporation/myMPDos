#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later
# myMPDos (c) 2020-2023 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos
#

#save script path and change to it
STARTPATH=$(dirname "$(realpath "$0")")
cd "$STARTPATH" || exit 1

source config || { echo "config not found"; exit 1; }
IMAGE=$(ls -t "$STARTPATH"/images/myMPDos-"$ARCH"-*.img 2>/dev/null | head -1)

if [ "$IMAGE" = "" ]
then
    echo "No image found, build it with ./build.sh"
    exit 1
else
    echo "Image: $IMAGE"
fi

mountimage() {
    install -d "$STARTPATH/tmp/mnt"
    LOOP=$(sudo losetup --partscan --show -f "$IMAGE")
    echo "Mounting image on $STARTPATH/tmp/mnt"
    sudo mount -ouid="$BUILDUSER" "${LOOP}p1" "$STARTPATH/tmp/mnt" || exit 1
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
    rm "$STARTPATH"/tmp/mnt/boot/modloop-*
    cp "$STARTPATH/tmp/$ARCH/netboot/boot/modloop-lts" tmp/mnt/boot/
    umountimage
    $QEMU \
        -M virt -m "$BUILDRAM" -cpu "$CPU" -smp "$BUILDCPUS" \
        -kernel "$STARTPATH/tmp/$ARCH/netboot/boot/$KERNEL" \
        -initrd "$STARTPATH/tmp/$ARCH/netboot/boot/$INITRAMFS" \
        -append "console=ttyAMA0 ip=dhcp" \
        -nographic \
        -drive "file=$STARTPATH/${IMAGE},format=raw" \
        -nic user,id=mynet0,net=192.168.76.0/24,dhcpstart=192.168.76.9
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
            echo "Usage: $0 burn <sdcard device>"
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
