#!/bin/sh

EVENT_POWER='*code 116 (KEY_POWER), value 1*'

evtest /dev/input/event0 | while read line
do
  case $line in
    ($EVENT_POWER) /usr/bin/saveshutdown.sh
  esac
done

