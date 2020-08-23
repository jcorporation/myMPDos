# myMPDos

myMPDos is a Raspberry Pi image (aarch64) based on Alpine Linux. It is running entirely in RAM and it does not write to the sd-card unless you want to save settings. Therefore, myMPDos is very robust and you can simply turn off the power without any risk of corruption of your sd-card.

myMPDos is a turnkey music playback solution and is designed arround [MPD](https://www.musicpd.org/) and [myMPD](https://github.com/jcorporation/myMPD). After startup you can access the myMPD webinterface, copy music to the sd-card data partition, mount a music storage or simply plugin an usb storage and you can start enjoying your music.

The initial configuration is done through a simple bootstrap file, that has sane default values preconfigured. Setting up myMPDos takes only a few minutes. Experts can use the advanced bootstrap file to customize the installation further.

WARNING: myMPDOS is currently in an early development stage. If it evolves I will add prebuild images.

## Features
- Based on latest Alpine Linux
- Runs entirely in RAM
- Very small ressource usage
- Preconfigured MPD and myMPD
- HTTPS Streaming
- Automounts USB devices and adds its content to mpd database
- Configures MPD outputs automatically

## Building the image

The `build.sh` script creates a qemu image, starts it and compiles myMPD and MPD. The resulting packages are integrated in a custom overlay for the default Alpine Linux Raspberry image.

1. Create the image with `./build.sh build`
2. Optionally run `./build.sh cleanup` to cleanup things

## Usage

1. Transfer the image to a sdcard
2. Copy `bootstrap-simple.txt` or `bootstrap-advanced.txt` to `bootstrap.txt`
3. Adapt `bootstrap.txt`
4. Boot your Raspberry Pi

## Test

Qemu does not support a raspberry pi compatible network interface. Do not burn the image after test to the sd-card. After first start of an image all bootstrap files are removed.

- Run `./image.sh start`

## Build depedencies

- Qemu (qemu-system-aarch64)
- DHCP server in your network
- Working internet connection
- Standard linux tools

## Copyright
2020 Juergen Mang <mail@jcgames.de>
