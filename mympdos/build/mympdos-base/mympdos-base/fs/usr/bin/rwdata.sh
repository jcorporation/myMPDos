#!/bin/sh

# SPDX-License-Identifier: GPL-3.0-or-later
# myMPDos (c) 2020-2023 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos

# This script toggles the writeable state of the data partition

if grep -q -E '/dev/mmcblk0p2.*ro,' /etc/mtab
then
  mount -oremount,rw /media/mmcblk0p2/
  echo "Data media is now writeable"
else
  mount -oremount,ro /media/mmcblk0p2/
  echo "Data media is now readonly"
fi
