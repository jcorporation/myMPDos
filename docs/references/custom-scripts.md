---
layout: page
permalink: /references/custom-scripts
title: Custom scripts
---

This scripts are installed by the mympdos-base package in the directory `/usr/bin`.

| SCRIPT | DESCRIPTION |
| ------ | ----------- |
| alpine-upgrade.sh | Upgrades alpine linux - used by mympdos-update.sh |
| audiohat.sh | Interactive script to configures an audio hat overlay |
| automount.sh | Automount script, executed by mdev |
| configmpd.sh | MPD configuration script, executed by mdev |
| mympdos-update.sh | myMPDos update script - for package updates and distribution upgrades |
| rwdata.sh | Toggle read/write state of `/media/mmcblk0p2` |
| save.sh | Saves all changes (uses `lbu commit`) |
| savereboot.sh | Save settings and reboot |
| saveshutdown.sh | Save settings and poweroff |
| status.sh | Shows status informations from your raspberry |
{: .table .table-sm }

# Running a custom script from myMPD client

To run a script from the myMPD client, the script must be configured to be able to run through `doas`.
A script located at `~/my-script.sh` will typically have an absolute path of `/root/my-script.sh`.
First, configure the script for use with `doas`:

```
# Append line to /etc/doas.d/mympd.conf
permit nopass mympd cmd /root/my-script.sh
```

Next, check compilation of `doas`:

```
doas -C /etc/doas.d/mympd.conf
```

Finally, add the script in the myMPD client, calling it with `doas`:

```
result = mympd.os_capture("doas /root/my-script.sh")
return result
```
