#!/bin/sh

apk update

if apk list -I | grep -q mympdos-mpd-master
then
    apk del mympdos-mpd-master
    apk add mympdos-mpd-stable
fi

apk upgrade
savereboot.sh
