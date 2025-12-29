#!/bin/sh

export V_MAJOR=3
export V_MINOR=23
export V_POINT=3
export CHECKSUM=ff36ced256e6aafe8d921dd2227f69980b6d39937b238f65696e27f53ee9301f
alpine-upgrade.sh

# Replace custom libgpiod2 with official Alpine Linux package
apk remove mympdos-libgpiod2
apk add libgpiod mygpiod
