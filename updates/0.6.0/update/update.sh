#!/bin/sh
set -e
set -u

VERSION="3.13.2"
ARCHIVE="alpine-rpi-${VERSION}-aarch64.tar.gz"
CHECKSUM="3dc14236dec90078c5b989db305be7cf0aff0995c8cdb006dcccf13b0ac92f97"
BOOTDEV="/media/mmcblk0p1"

echo "Updating alpine boot image to ${VERSION}"
echo " - Downloading"
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
