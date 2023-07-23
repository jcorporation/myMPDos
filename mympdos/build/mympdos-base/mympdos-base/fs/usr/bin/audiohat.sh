#!/bin/sh

# SPDX-License-Identifier: GPL-3.0-or-later
# myMPDos (c) 2020-2023 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos

BOOTMEDIA="/media/mmcblk0p1"
USERCFG="$BOOTMEDIA/usercfg.txt"
TMP_USERCFG="/tmp/usercfg.txt"
OVERLAY_FILE="/tmp/overlays.txt"

echo "Downloading audio hats description"
cd /tmp
wget -q https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/overlays/README \
  -O - | grep -B1 -E "(audio card|soundcard|sound card)" | grep "^Name" | awk '{print $2}' > "$OVERLAY_FILE"

if [ ! -s "$OVERLAY_FILE" ]
then
  echo "Overlays file is empty."
  exit 1
fi

I=0
for O in $(cat /tmp/overlays.txt)
do
  I=$((I+1))
  echo "  $I) $O"
done
read -p "Select overlay: " -r NR
OVERLAY=$(sed -n "${NR}p" < "$OVERLAY_FILE")

OLDOVERLAY=""
for O in $(grep dtoverlay "$USERCFG" | sed -r 's/^.+=(.+)$/\1/')
do
  if grep -q -E "^${O}$" "$OVERLAY_FILE"
  then
    OLDOVERLAY="$O"
    break
  fi
done

if [ "$OLDOVERLAY" != "" ]
then
  grep -v -E "dtoverlay\s*=\s*$OLDOVERLAY" "$USERCFG" > "$TMP_USERCFG"
else
  cp "$USERCFG" "$TMP_USERCFG"
fi

echo "dtoverlay=$OVERLAY" >> "$TMP_USERCFG"
mount -oremount,rw "$BOOTMEDIA"
mv "$TMP_USERCFG" "$USERCFG"
mount -oremount,ro "$BOOTMEDIA"

echo ""
[ "$OLDOVERLAY" != "" ] && echo "Disabled overlay: $OLDOVERLAY"
echo "Enabled overlay: $OVERLAY"
echo "Details: https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/overlays/README"
echo ""

rm -f "$OVERLAY_FILE"
