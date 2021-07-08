#!/bin/sh
echo "Updating alpine boot image to 3.14"
echo " - Downloading"
BOOTDEV="/media/mmcblk0p1"
ARCHIVE="alpine-rpi-3.14.0-aarch64.tar.gz"
CHECKSUM="0cc1dbad694c93b686bd76a0a5db3aaae2e1357e1b687a99b1bd37df9bae8692"
if wget -q "http://dl-cdn.alpinelinux.org/alpine/v3.14/releases/aarch64/$ARCHIVE" -O "$ARCHIVE"
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
sed -i -e 's/v3\.13/v3.14/g' /etc/apk/repositories
apk update
apk upgrade
