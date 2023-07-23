#!/bin/sh

# SPDX-License-Identifier: GPL-3.0-or-later
# myMPDos (c) 2020-2023 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos

# Automount script for mdev

MOUNTDIR="/mnt"

[ "$(echo $MDEV | sed 's/sd.//')" = "" ] && exit
[ "$MDEV" = "" ] && exit 1
[ "$ACTION" = "" ] && [ -b "/dev/$MDEV" ] && ACTION="add"
[ "$ACTION" = "" ] && [ -d "$MOUNTDIR/$MDEV" ] && ACTION="remove"

if [ "$ACTION" = "add" ]
then
  mkdir "$MOUNTDIR/$MDEV"
  mount -oro,noatime /dev/${MDEV} ${MOUNTDIR}/${MDEV}
  [ -f /run/mpd/pid ] && mpc update
elif [ "$ACTION" = "remove" ]
then
  umount ${MOUNTDIR}/${MDEV}
  rmdir ${MOUNTDIR}/${MDEV}
  [ -f /run/mpd/pid ] && mpc update
fi
