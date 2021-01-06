#!/bin/sh

#dump myMPD state
killall -HUP mympd

#dump alsa state
alsactl store

#save the state to /media/mmcblk0p2/jukebox.apkovl.tar.gz
lbu_commit
