---
title: General
---

## Read only sd-card

myMPDos runs in memory only, also the myMPD settings and MPD database are kept in RAM. This has the advantage that you can simply poweroff your device without the hassle of filesystem corruption, but with the disadvantage that you must manually save the changes to the sd-card.

There are some helper scripts:

- `save.sh`: saves the the current state of myMPD, MPD and the base system
- `saveshutdown.sh`: run save.sh and power offs your device
- `savereboot.sh`: run save.sh and reboots your device
