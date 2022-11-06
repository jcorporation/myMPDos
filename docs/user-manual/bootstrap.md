---
layout: page
permalink: /user-manual/bootstrap
title: Bootstrap
---

## First steps

1. Download the latest image from the releases page: https://github.com/jcorporation/myMPDos/releases
2. Transfer it to the sd-card. You can use e. g. [balenaEtcher](https://www.balena.io/etcher/) for this task

## Customize the bootstrap file

Copy the [bootstrap-simple.txt](https://github.com/jcorporation/myMPDos/blob/master/mympdos/bootstrap-simple.txt) or [bootstrap-advanced.txt](https://github.com/jcorporation/myMPDos/blob/master/mympdos/bootstrap-advanced.txt) to bootstrap.txt and change the options to your needs.

```
#
#Simple bootstrap configuration file for myMPDos
#
ROOT_PASSWORD="your_secure_password"
TIMEZONE="UTC"

#If WLAN is not set to true eth0 is configured
WLAN_ENABLE="true"
WLAN_SSID="ssid of your wlan"
WLAN_PSK="psk of the ssid"

AUDIOHAT="allo-digione"
```

## First start 

At the first start myMPD executes the bootstrap script to configure your instance according to `bootstrap.txt`. 

- It adds a data partition to the sd-card
- It needs internet connectivity to set the time and update the packages.

## References

| FILE | DESCRIPTION |
| ---- | ----------- |
| usercfg.txt | Custom raspberry configuration, edit this and not config.txt. The bootstrap script creates a default usercfg.txt if you don't create it. |
| bootstrap.txt | Bootstrap file for myMPDos, examples are in folder [mympdos](https://github.com/jcorporation/myMPDos/tree/master/mympdos) |
| mpd.conf | Custom mpd.conf, the bootstrap script copies it to /etc/mpd.conf |
| mpd.custom.conf | Custom mpd configuration that is included in the default mpd.conf |
| mpd.replace | Can add, change and remove lines from default [mpd.conf](https://github.com/jcorporation/myMPDos/blob/master/mympdos/build/mympdos-base/mympdos-base-0.1.0/fs/etc/mympdos/templates/mympdos-mpd-stable.conf.tmpl): [example](https://github.com/jcorporation/myMPDos/blob/master/mympdos/mpd.replace) |
{: .table .table-sm }