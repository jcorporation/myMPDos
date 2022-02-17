#!/bin/sh

#dump myMPD state
killall -HUP mympd
#myMPD needs some time to write the state files
sleep 1

#dump alsa state
alsactl store

#save the state to /media/mmcblk0p2/jukebox.apkovl.tar.gz
lbu_commit
