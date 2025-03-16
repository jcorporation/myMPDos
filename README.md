# myMPDos

myMPDos is a Raspberry Pi image (aarch64) based on Alpine Linux. It is running entirely in RAM and it does not write to the sd-card unless you want to save settings. Therefore, myMPDos is very robust and you can simply turn off the power without any risk of corruption of your sd-card.

myMPDos is a turnkey music playback solution and is designed around [MPD](https://www.musicpd.org/) and [myMPD](https://github.com/jcorporation/myMPD). After startup you can access the myMPD webinterface, copy music to the sd-card data partition, mount a music share or simply plugin an usb storage and you can start enjoying your music.

myMPDos has no configuration dialogs or web ui for initial and further configuration. But there are all common linux utilities installed and more can be installed from the alpine linux repositories.

The initial configuration is done through a simple bootstrap file, that has sane default values preconfigured. Setting up myMPDos takes only a few minutes. Experts can use the advanced bootstrap file to customize the installation further.

## Features

- Based on latest Alpine Linux
- Runs entirely in RAM
- Very small ressource usage
- Preconfigured MPD and myMPD
- Latest stable MPD and myMPD releases
- Bleeding edge versions of MPD, mpc and libmpdclient
- Automounts USB devices and adds its contents to the mpd database
- Configures MPD outputs automatically
- Use GPIO buttons to control MPD and myMPD with [myGPIOd](https://github.com/jcorporation/myGPIOd)
- Optional bluetooth support

## Usage

1. Download the latest [release image](https://github.com/jcorporation/myMPDos/releases)
2. Transfer it to the sd-card, e. g. with [balenaEtcher](https://www.balena.io/etcher/)
3. Copy `bootstrap-simple.txt` or `bootstrap-advanced.txt` to `bootstrap.txt`
4. Adapt `bootstrap.txt`
5. Boot your Raspberry Pi

## Processlist

```
init-+-getty
     |-mpd-+-{decoder:mad}
     |     |-{io}
     |     |-{output:U24XL US}
     |     |-{player}
     |     `-{rtio}
     |-mympd-+-{api}
     |       |-{scripts}
     |       `-{webserver}
     |-ntpd
     |-rngd
     |-sshd
     `-syslogd
```

## Documentation

For further information on installation and configuration, see the [myMPDos documentation](https://jcorporation.github.io/myMPDos/).

## Copyright

2020-2025 Juergen Mang <mail@jcgames.de>
