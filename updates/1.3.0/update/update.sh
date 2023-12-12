#!/bin/sh

if apkinfo mygpiod
then
    HAVE_LIBGPIOD=1
    apk del libgpiod mygpiod
else
    HAVE_LIBGPIOD=0
fi

export V_MAJOR=3
export V_MINOR=19
export V_POINT=0
export CHECKSUM=5621e7e597c3242605cd403a0a9109ec562892a6c8a185852b6b02ff88f5503c
alpine-upgrade.sh

# Save shutdowntime in apkovl
lbu_include /var/lib/misc/openrc-shutdowntime

if apkinfo libgpiod
then
    apk update
    apk add mympdos-libgpiod2 mygpiod
fi
