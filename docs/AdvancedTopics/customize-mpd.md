---
title: Customize MPD
---

The MPD configuration is created by the script `/usr/bin/configmpd.sh`. This script is executed as soon as an audio device was changed (executed by mdev).

## Fully custom mpd.conf

If the scripts finds a `/etc/mympdos/custom/mpd.conf` then this file is used as mpd configuration file and no further customization appears.

## Using the default template

The script uses the template in `/etc/mympdos/templates/mympdos-mpd-(stable|master).conf.tmpl` and reads configuration values from `/etc/mympdos/mympdos.conf`.

It processes the template and adds detected soundcards to the mpd configuration.

You can use the `/etc/mympdos/custom/mpd.replace` file to customize any existing line of the template MPD configuration. The syntax is described in the file directly.

The default template includes the `/etc/mpd.custom.conf` in the MPD configuration. Use this file for additions.
