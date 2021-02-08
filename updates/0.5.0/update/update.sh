#!/bin/sh
set -e
set -u

echo "Updating alpine boot image to 3.13.1"
echo " - Downloading"
BOOTDEV="/media/mmcblk0p1"
ARCHIVE="alpine-rpi-3.13.1-aarch64.tar.gz"
CHECKSUM="bccaaab7cb4a167ed05e18d72fdde71b101568c03d94fee60c193c019f4b0944"
if wget -q "http://dl-cdn.alpinelinux.org/alpine/v3.13/releases/aarch64/$ARCHIVE" -O "$ARCHIVE"
then
  echo " - Checking"
  if echo "$CHECKSUM  $ARCHIVE" | sha256sum -c -w
  then
    echo " - Mounting $BOOTDEV rw"
    mount -oremount,rw "$BOOTDEV"
    echo " - Removing old boot files"
    rm -rf "${BOOTDEV}/apks"
    echo " - Extracting"
    tar -xzf "$ARCHIVE" -C "$BOOTDEV"
    echo " - Mounting $BOOTDEV ro"
    if ! mount -oremount,ro "$BOOTDEV"
    then
      echo "Remounting ro failed, please reboot system after update"
    fi
    echo " - Cleaning up"
    rm "$ARCHIVE"
  else
    echo "Checksum error"
    exit 1
  fi
else
  echo "Error downloading alpine base image"
  exit 1
fi

echo "Updating repositories"
sed -i -e 's/v3\.12/v3.13/g' /etc/apk/repositories
apk update
apk upgrade
