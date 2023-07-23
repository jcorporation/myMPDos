#!/bin/sh

# SPDX-License-Identifier: GPL-3.0-or-later
# myMPDos (c) 2020-2023 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos

# Stop MPD to save the current state to disc, befor wie call lbu_commit
service mpd stop
# Save the state
/usr/bin/save.sh
# Reboot
reboot
