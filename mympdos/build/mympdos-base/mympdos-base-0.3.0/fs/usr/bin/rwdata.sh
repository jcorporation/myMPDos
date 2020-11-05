#!/bin/sh

if grep -q -E '/dev/mmcblk0p2.*ro,' /etc/mtab
then
  mount -oremount,rw /media/mmcblk0p2/
  echo "Data media is now writeable"
else
  mount -oremount,ro /media/mmcblk0p2/
  echo "Data media is now readonly"
fi
