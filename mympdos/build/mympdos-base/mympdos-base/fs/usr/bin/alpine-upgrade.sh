#!/bin/sh
#
#export V_MAJOR=3
#export V_MINOR=14
#export V_POINT=0
#export CHECKSUM=0cc1dbad694c93b686bd76a0a5db3aaae2e1357e1b687a99b1bd37df9bae8692

echo "Updating alpine boot image to ${V_MAJOR}.${V_MINOR}.${V_POINT}"
echo " - Downloading"
BOOTDEV="/media/mmcblk0p1"
ARCHIVE="alpine-rpi-${V_MAJOR}.${V_MINOR}.${V_POINT}-aarch64.tar.gz"
BACKUP_FILE="/tmp/old_boot.tgz"

if ! wget -q "http://dl-cdn.alpinelinux.org/alpine/v${V_MAJOR}.${V_MINOR}/releases/aarch64/$ARCHIVE" -O "$ARCHIVE"
then
  echo "Error downloading alpine base image"
  exit 1
fi

echo " - Checking"
if ! echo "$CHECKSUM  $ARCHIVE" | sha256sum -c -w
then
    echo "Checksum error"
    exit 1
fi

echo " - Mounting $BOOTDEV rw"
if ! mount -oremount,rw "$BOOTDEV"
then
    echo "Error remounting"
    exit 1
fi

echo " - Backup old boot files"
if ! tar -czf "$BACKUP_FILE" "$BOOTDEV"
then
    echo "Backup failed"
    exit 1
fi

echo " - Removing old boot files"
rm -rf "${BOOTDEV}/apks"
rm -rf "${BOOTDEV}/overlays"
rm -rf "${BOOTDEV}/boot"
rm -f "${BOOTDEV}"/*.dtb
rm -f "${BOOTDEV}"/*.bin
rm -f "${BOOTDEV}"/*.dat
rm -f "${BOOTDEV}"/*.elf

echo " - Extracting new boot files"
if ! tar -xzf "$ARCHIVE" -C "$BOOTDEV"
then
    echo "Error extracting archiv, restoring old /boot"
    rm -fr "${BOOTDEV}"/*
    if ! tar -xzf "$BACKUP_FILE" -C /
    then
        echo "Restore of backup failed!"
    fi
    exit 1
fi

echo " - Cleaning up"
rm "$ARCHIVE"
rm "$BACKUP_FILE"
sync

echo " - Mounting $BOOTDEV ro"
if ! mount -oremount,ro "$BOOTDEV"
then
    echo "Remounting ro failed, please reboot system after update"
fi

echo "Updating repositories"
cp /etc/apk/repositories /etc/apk/repositories.bak
sed -i -r "s/v\d+.\d+/v${V_MAJOR}.${V_MINOR}/g" /etc/apk/repositories
apk update
apk upgrade --available
