#!/bin/sh

# SPDX-License-Identifier: GPL-3.0-or-later
# myMPDos (c) 2020-2024 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos

# Stop myMPD to save the current state to disc, before wie call lbu_commit
service mympd stop
# Stop MPD to save the current state to disc, before wie call lbu_commit
service mpd stop
# Save the state
/usr/bin/save.sh
# Reboot
reboot
