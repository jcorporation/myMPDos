#!/bin/sh
#Remove obsolet local apk repository
mount -oremount,rw /dev/mmcblk0p1
rm -rf /media/mmcblk0p1/mympdos-apks
sed -i -r '/mympdos-apks/d' /etc/apk/repositories
sync
mount -oremount,ro /dev/mmcblk0p1
