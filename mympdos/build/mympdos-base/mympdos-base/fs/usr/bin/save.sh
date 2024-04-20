#!/bin/sh

# SPDX-License-Identifier: GPL-3.0-or-later
# myMPDos (c) 2020-2024 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos

MTIME_OLD=$(stat -c%Y /var/lib/mympd/state/trigger_list)
MTIME_NEW=$MTIME_OLD

# Write myMPD state to disc
killall -HUP mympd

# Save the alsa state
alsactl store

# Update swclock time
touch /var/lib/misc/openrc-shutdowntime

# Give myMPD some time to write the state files
I=0
while [ "$MTIME_OLD" -eq "$MTIME_NEW" ]
do
    I=$((I+1))
    sleep "$I"
    MTIME_NEW=$(stat -c%Y /var/lib/mympd/state/trigger_list)
    [ "$I" -eq 10 ] && break
done

# Save the state to /media/mmcblk0p2/
lbu_commit
