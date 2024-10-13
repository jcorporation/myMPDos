---
title: Bluetooth
---

Using bluetooth speakers with myMPDos.

The best is to attach a bluetooth dongle to the raspberry but you can also try to use the [internal bluetooth](bluetooth-internal.md) chip.

## Install packages

Install packages, enable it and restart.

```sh
apk add bluez bluez-alsa
rc-update add bluetooth
rc-update add bluealsa
savereboot.sh
```

## Connect the bluetooth speakers

```sh
# Discover the speaker

bluetoothctl power on
bluetoothctl agent on
bluetoothctl default-agent
bluetoothctl scan on

# The speaker should appear
# Connect the speaker

bluetoothctl pair <address>
bluetoothctl trust <address>
bluetoothctl connect <address>

# Save the bluetooth state

lbu include /var/lib/bluetooth
lbu commit
```

## Configure MPD

Append the following to `/etc/mpd.custom.conf`

```text
audio_output {
       type            "alsa"
       name            "BT-Speaker"
       device          "bluealsa:DEV=<address>,PROFILE=a2dp"
       mixer_type      "software"
       format          "44100:16:2"
}
```

Restart MPD

```sh
service mpd restart
```

***

Reference: [https://wiki.alpinelinux.org/wiki/Raspberry_Pi_3_-_Setting_Up_Bluetooth](https://wiki.alpinelinux.org/wiki/Raspberry_Pi_3_-_Setting_Up_Bluetooth)
