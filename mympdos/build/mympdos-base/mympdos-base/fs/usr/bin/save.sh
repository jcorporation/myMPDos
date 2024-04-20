#!/bin/sh

# SPDX-License-Identifier: GPL-3.0-or-later
# myMPDos (c) 2020-2024 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos

# Write myMPD state to disc if running
if [ -f /var/run/myMPD.pid ]
then
    echo "Saving myMPD state"
    MTIME_OLD=$(stat -c%Y /var/lib/mympd/state/trigger_list)
    MTIME_NEW=$MTIME_OLD
    killall -HUP mympd
    # Give myMPD some time to write the state files
    I=0
    while [ "$MTIME_OLD" -eq "$MTIME_NEW" ]
    do
        I=$((I+1))
        sleep 1
        MTIME_NEW=$(stat -c%Y /var/lib/mympd/state/trigger_list)
        [ "$I" -eq 10 ] && break
    done
fi

echo "Saving alsa state"
alsactl store

echo "Saving swclock"
touch /var/lib/misc/openrc-shutdowntime

# Save the state to /media/mmcblk0p2/
echo "Commiting changes"
lbu_commit
