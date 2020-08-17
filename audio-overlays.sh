#!/bin/bash

echo "Downloading overlays readme"
install -d tmp
wget -q https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/overlays/README \
  -O - | \
  grep -B1 "audio card" tmp/overlays.md | \
  cut -d":" -f2 | \
  sed -r 's/^\s+//' | tee tmp/audio-overlays.txt
