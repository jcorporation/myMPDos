---
title: Filesystem Layout
---

| MOUNTPOINT | DESCRIPTION |
| ---------- | ----------- |
| / | tmpfs |
| /etc/mympdos/ | myMPDos configuration files |
| /boot | Link to /media/mmcblk0p1 |
| /data | Link to /media/mmcblk0p2 |
| /media/mmcblk0p1 | Boot partition (FAT32) on sd-card |
| /media/mmcblk0p2 | Data partition (ext4) on sd-card |
| /media/mmcblk0p2/library | Music library |
| /mnt | Path for automounter |
