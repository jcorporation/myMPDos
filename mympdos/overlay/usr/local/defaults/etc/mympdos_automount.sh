#!/bin/sh
#
# SPDX-License-Identifier: GPL-2.0-or-later
# myMPD (c) 2020 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos
#
#env >> /tmp/automount.log

MOUNTDIR="/mnt"

[ "$(echo $MDEV | sed 's/sd.//')" = "" ] && exit
[ "$MDEV" = "" ] && exit 1
[ "$ACTION" = "" ] && [ -b "/dev/$MDEV" ] && ACTION="add"
[ "$ACTION" = "" ] && [ -d "$MOUNTDIR/$MDEV" ] && ACTION="remove"

if [ "$ACTION" = "add" ]
then
  mkdir "$MOUNTDIR/$MDEV"
  mount -oro,noatime /dev/${MDEV} ${MOUNTDIR}/${MDEV}
elif [ "$ACTION" = "remove" ]
then
  umount ${MOUNTDIR}/${MDEV}
  rmdir ${MOUNTDIR}/${MDEV}
fi
