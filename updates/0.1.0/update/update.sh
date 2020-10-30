#!/bin/sh
echo "Updating alpine base image to 3.12.1"
echo " - Downloading"
ARCHIVE="alpine-rpi-3.12.1-aarch64.tar.gz"
CHECKSUM="125fcbc1e21d092dd68df6e457fa5e0b76964d00ffd7706e93c9eb9578f4f729"
if wget -q "http://dl-cdn.alpinelinux.org/alpine/v3.12/releases/aarch64/$ARCHIVE" -O "$ARCHIVE"
then
  echo " - Checking"
  if echo "$CHECKSUM  $ARCHIVE" | sha256sum -c -w
  then
    echo " - Extracting"
    mount -oremount,rw /media/mmcblk0p1
    tar -xzf "$ARCHIVE" -C /media/mmcblk0p1
    mount -oremount,ro /media/mmcblk0p1
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

exit 0
