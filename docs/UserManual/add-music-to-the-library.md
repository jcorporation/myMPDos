---
title: Add music to the library
---

MPD is configured with `/media/mmcblk0p2/library` as the music_directory. You can add music to this library in several ways. After adding music you must update the mpd library.

## Copy files to the sd-card

You can copy files directly to this directory if you use a big sd-card. Run `rwdata.sh` before and after copying to toggle the read/write state of the sd-card. You can copy your music files with scp/sftp.

## Attach an usb-stick or drive

Simply attach an usb-stick or drive to the raspberry and myMPDos mounts the drive in the USB sub-directory of your library.

## Mounting a NAS

- You can mount a NFS share via the native MPD implementation. You can configure this in the myMPD gui.
- Alternatively you can configure a [linux mount](../AdvancedTopics/mount-a-cifs-or-nfs-share.md)
