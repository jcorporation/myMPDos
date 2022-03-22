#!/bin/sh

rm -f /etc/mympdos/templates/mympd.conf.tmpl
rm -f /etc/mympd.conf

export V_MAJOR=3
export V_MINOR=15
export V_POINT=1
export CHECKSUM=10ab2cd658d7b86def7bf6c05e748d107132a190935ceb0cc58d32f4a6215726
alpine-upgrade.sh
