---
title: After first start
---

After startup you should be able to connect with ssh and https to your myMPDos instance.

You need the ip-address of your Raspberry Pi:

- myMPDos displays the ip-address after startup on the hdmi display
- look at your routers dhcp leases

## SSH access

- User: root
- Password: set via the bootstrap file

## Webinterface

The myMPD webinterface is reachable by `https://<raspberry_ip>/`. In the about dialog is a link to the self generated myMPD certificate authority. Install this certificate as trusted ca certificate to avoid browser warnings.
