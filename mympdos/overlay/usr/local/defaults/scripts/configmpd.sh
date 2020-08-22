#!/bin/sh
#
# SPDX-License-Identifier: GPL-2.0-or-later
# myMPD (c) 2020 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos
#

[ -f /tmp/configmpd.lock ] && exit 0

if [ "$MDEV" != "" ] && [ "$(echo "$MDEV" | grep controlC)" = "" ]
then
  #run from mdev only for controlC* devices
  exit 0
fi

source /etc/mympdos/mympdos.conf

echo "Configuring sound devices"
touch /tmp/configmpd.lock
cp /etc/mympdos/mpd.conf.tmpl /etc/mpd.conf.new

if [ "$RESAMPLER" = "libsamplerate" ]
then
  cat >> /etc/mpd.conf.new << EOF
resampler {
  plugin "libsamplerate"
  type "$LIBSAMPLERATE_TYPE"
}
EOF
elif [ "$RESAMPLER" = "soxr" ]
then
  cat >> /etc/mpd.conf.new << EOF
resampler {
  plugin "soxr"
  quality "$SOXR_QUALITY"
  threads "$SOXR_THREADS"
}
EOF
fi

LAST_CARD_ID=""
LAST_DEVICE_ID=""
for CARD in /proc/asound/card[0-9]/pcm?p
do 
  while read KEY VALUE
  do
    VALUE=$(echo "$VALUE" | sed 's/"//g')
    case "$KEY" in
      name) DEVICE_NAME="$VALUE";;
      card) CARD_ID="$VALUE";;
      subdevice) DEVICE_ID="$VALUE";;
    esac
  done << EOF
$(sed -r -e 's/: / "/' -e 's/$/"/' "$CARD/info")
EOF
  if [ "$LAST_CARD_ID" = "$CARD_ID" ] && [ "$LAST_DEVICE_ID" = "$DEVICE_ID" ]
  then
    echo "Skipping duplicate entry"
    continue
  fi
  LAST_CARD_ID="$CARD_ID"
  LAST_DEVICE_ID="$DEVICE_ID"
  CARD_NAME=$(cat /proc/asound/card$CARD_ID/id)
  echo "  Soundcard $CARD_NAME - $DEVICE_NAME"
  cat >> /etc/mpd.conf.new << EOF
audio_output {
  name          "$CARD_NAME $DEVICE_NAME"
  device        "hw:$CARD_ID,$DEVICE_ID"
  type          "alsa"
  auto_resample "no"
  auto_format   "no"
EOF
  read MIXER_CONTROL MIXER_ID << EOF
$(amixer -c "$CARD_ID" | grep -m1 "Simple mixer control" -A1 | grep pvolume -B1 | tr -d '\n' | sed -r "s/.*'([^']+)',(\d+).*/\1 \2/")
EOF
  if [ "$MIXER_CONTROL" != "" ] && [ "$MIXER_ID" != "" ]
  then
    echo "    Mixer: $MIXER_CONTROL"
    echo "  mixer_type    \"hardware\"" >> /etc/mpd.conf.new
    echo "  mixer_device  \"hw:$CARD_ID,$MIXER_ID\"" >> /etc/mpd.conf.new
    echo "  mixer_control \"$MIXER_CONTROL\"" >> /etc/mpd.conf.new
  else
    echo "    Mixer: none"
    echo "  mixer_type    \"none\"" >> /etc/mpd.conf.new
  fi
  echo "}" >> /etc/mpd.conf.new
done

if ! cmp /etc/mpd.conf /etc/mpd.conf.new > /dev/null 2>&1
then
  echo "Updating MPD configuration"
  [ -f /etc/mpd.conf ] && cp /etc/mpd.conf /etc/mpd.conf.bak
  mv /etc/mpd.conf.new /etc/mpd.conf
  [ "$BOOTSTRAP" = "true" ] || service mpd restart
else
  rm /etc/mpd.conf.new
fi

echo "Unmuting soundcards"
for CARD in $(grep "^\s\d" /proc/asound/cards | sed -r 's/^\s(\d+)\s.*/\1/')
do
  for F in $(amixer -c "$CARD" | grep -B1 pvolume | grep "mixer control" | sed -r "s/.+'([^']+)'.*/\1/")
  do
	  echo "$CARD:$F"
	  amixer -c "$CARD" set "$F" 100% unmute > /dev/null
  done
done

rm /tmp/configmpd.lock
