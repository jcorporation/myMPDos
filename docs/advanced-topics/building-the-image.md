---
layout: page
permalink: /advanced-topics/building-the-image
title: Building the image
---

The `build.sh` script creates a qemu image, starts it and compiles all custom myMPDos packages. The result is custom alpine linux image that bootstraps its configuration and uses this repository as additional apk source.

1. Create the image with `./build.sh build`
2. The image is created in the `tmp/images` directory
3. Optionally run `./build.sh cleanup` to cleanup things

# Test

Move the image from `tmp/images` to `images`.
Do not burn the image after test to the sd-card. After first start of an image all bootstrap files are removed.

- Run `./image.sh start`

# Build depedencies

- Qemu (qemu-system-aarch64)
- DHCP server in your network
- Working internet connection
- Standard linux tools