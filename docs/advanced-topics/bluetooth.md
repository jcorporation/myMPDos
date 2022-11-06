---
layout: page
permalink: /advanced-topics/bluetooth
title: Bluetooth
---

Using bluetooth speakers with myMPDos.

The best is to attach a bluetooth dongle to the raspberry but you can also try to use the [internal bluetooth]({{site.baserurl}}/advanced-topics/bluetooth-internal) chip.

## Install packages

```
apk add bluez bluez-alsa
```
## Reboot

Enable the services at startup, save and reboot again.
```
rc-update add bluetooth
rc-update add bluealsa
savereboot.sh
```

## Connect the bluetooth speakers

1. Discover the speaker
```
bluetoothctl power on
bluetoothctl agent on
bluetoothctl default-agent
bluetoothctl scan on
```
2. The speaker should appear
3. Connect the speaker
```
bluetoothctl pair <address>
bluetoothctl trust <address>
bluetoothctl connect <address>
```
4. Save the bluetooth state
```
lbu include /var/lib/bluetooth
lbu commit
```

## Configure MPD

Add following to `/etc/mpd.custom.conf`

```
audio_output {
       type            "alsa"
       name            "BT-Speaker"
       device          "bluealsa:DEV=<address>,PROFILE=a2dp"
       mixer_type      "software"
       format          "44100:16:2"
}
```

Restart MPD: `service mpd restart`

***

Reference: <a href="https://wiki.alpinelinux.org/wiki/Raspberry_Pi_3_-_Setting_Up_Bluetooth">https://wiki.alpinelinux.org/wiki/Raspberry_Pi_3_-_Setting_Up_Bluetooth</a>
