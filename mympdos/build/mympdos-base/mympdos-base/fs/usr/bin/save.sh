#!/bin/sh

# SPDX-License-Identifier: GPL-3.0-or-later
# myMPDos (c) 2020-2023 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos

# Write myMPD state to disc
killall -HUP mympd
#myMPD needs some time to write the state files
sleep 1

# Save the alsa state
alsactl store

# Save the state to /media/mmcblk0p2/
lbu_commit
