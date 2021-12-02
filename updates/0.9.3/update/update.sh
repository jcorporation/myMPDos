#!/bin/sh
export V_MAJOR=3
export V_MINOR=15
export V_POINT=0
export CHECKSUM=5b1b42973294325fca4581eeda62d30d7a4741c7946234956b32ab98cda7b4fe

#remove old lua scripts with sudo
rm -f /var/lib/mympd/scripts/Shutdown.lua
rm -f /var/lib/mympd/scripts/Reboot.lua
rm -f /var/lib/mympd/scripts/RW-Library.lua

#upgrade
alpine-upgrade.sh

#replace sudo with doas
apk del sudo
apk add doas

#add doas config
cat > /etc/doas.d/mympd.conf << EOL
permit nopass mympd cmd /usr/bin/savereboot.sh
permit nopass mympd cmd /usr/bin/saveshutdown.sh
permit nopass mympd cmd /usr/bin/rwdata.sh

EOL

#remove sudo config
rm -f /etc/sudoers
rm -f /etc/sudoers.apk-new
