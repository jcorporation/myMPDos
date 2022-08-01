---
layout: page
permalink: /advanced-topics/power-on-and-off-with-gpio
title: Power on and off with GPIO
---

myMPDos can be configured to shutdown the Raspberry Pi safely with a press of a button.

## Configuration

- Connect a button to pin 5 (GPIO 3 SCL) and pin 6 (Ground)
- Add the package mygpiod: `apk add mygpiod`
- Add a line in `/etc/mygpiod.conf`: `3,falling,doas /usr/bin/saveshutdown.sh 2>&1`
- Configure doas: `echo "permit nopass mygpiod cmd /usr/bin/saveshutdown.sh" >> /etc/doas.d/mygpiod.conf`
- Enable and start the mygpiod service: `rc-update add mygpiod`, `service mygpiod start`

## How it works

### Power on

The WAKE_ON_GPIO powers on the the Raspberry Pi if you shortend pin 5 (GPIO 3 SCL) to ground. 

Reference: https://www.raspberrypi.org/documentation/hardware/raspberrypi/bcm2711_bootloader_config.md

### Power off

The myGPIOd daemon listens on pin 5 (GPIO 3 SCL) and calls `/usr/bin/saveshutdown.sh`.
