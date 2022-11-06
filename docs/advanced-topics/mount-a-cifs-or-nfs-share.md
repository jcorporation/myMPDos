---
layout: page
permalink: /advanced-topics/mount-a-cifs-or-nfs-share
title: Mount a CIFS or NFS share
---

1. Enable the netmount service: `rc-update add netmount default`
2. Add a mount point: `rwdata.sh; mkdir /media/mmcblk0p2/library/nas; rwdata.sh`
3. Install packages: 
  - for CIFS/SMB: `apk add cifs-utils`
  - for NFS: `apk add nfs-utils`
4. Add mount point to `/etc/fstab`:
  - for CIFS/SMB: `echo "//<nas>/<music> /media/mmcblk0p2/library/nas cifs guest,gid=audio,soft,_netdev 0 0" >> /etc/fstab`
  - for NFS: `echo "<nas>:/<music> /media/mmcblk0p2/library/nas nfs soft,_netdev 0 0" >> /etc/fstab`
5. Mount it: `mount -a`
6. Save changes for next reboot: `save.sh`

## Hint

If the share is not mounted at boot time, you can try to enable the `net-online` service: `rc-update add net-online boot` and edit `/etc/conf.d/net-online` configuration file.

## Placeholders

- `<nas>`: name or ip address of the cifs or nfs server
- `<music>`: the share for cifs or export for nfs
