---
layout: page
permalink: /advanced-topics/building-the-image
title: Building the image
---

The `build.sh` script creates a qemu image, starts it and compiles all custom myMPDos packages. The result is custom Alpine Linux image that bootstraps its configuration and uses this repository as additional apk source.

1. Create the image with `./build.sh build`
2. The image is created in the `images` directory
3. Optionally run `./build.sh cleanup` to cleanup things

## Inspect

You can inspect the created image:

- Run `./image.sh mount` to mount the image
- Image is mounted to `tmp/mnt`
- Run `./image.sh umount` to unmount the image

## Test

Do not burn the image after test to the sd-card. After first start of an image all bootstrap files are removed.

- Run `./image.sh start` to start the image with qemu

## Build dependencies

- Qemu (qemu-system-aarch64)
- Working internet connection
- Standard linux tools
