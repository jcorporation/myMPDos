# myMPDos Changelog

https://github.com/jcorporation/myMPDos/

***

## myMPDos v1.7.3 (2025-08-28)

This release fixes a bootstrap issue introduced with myMPD v22.0.0.

### Changelog

- Fix file permissions for myMPD state folder #49
- Support all myMPD config variables

***

## myMPDos v1.7.2 (2025-07-17)

This release is build up on Alpine Linux 3.22.1.

### Changelog

- Alpine Linux 3.22.1

***

## myMPDos v1.7.1 (2025-06-29)

### Changelog

- Set default myMPD ports
- Disabled NFS support in MPD

***

## myMPDos v1.7.0 (2025-06-01)

This release is build up on Alpine Linux 3.22.0. The mympdos-mpd-master package tracks now the MPD master branch that will become MPD 0.25.

### Changelog

- Alpine Linux 3.22.0

***

## myMPDos v1.6.4 (2025-03-21)

This release updates the mympdos-mpd-stable package to MPD 0.24.1. The mympdos-mpd-master package will be stale until the development of MPD 0.25 begins. Migrate to the mympdos-mpd-stable package to keep your installation up-to-date.

***

## myMPDos v1.6.3 (2025-03-07)

This release is build up on Alpine Linux 3.21.3.

### Changelog

- Alpine Linux 3.21.3
- Updated MPD master
- Enabled wavpack for MPD builds

***

## myMPDos v1.6.2 (2025-01-09)

This release is build up on Alpine Linux 3.21.2.

### Changelog

- Alpine Linux 3.21.2

***

## myMPDos v1.6.1 (2024-12-11)

This is a small bugfix release.

### Changelog

- Fix chown semantics
- Add missing ca-certificates package

***

## myMPDos v1.6.0 (2024-12-05)

This release is build up on Alpine Linux 3.21.0.

### Changelog

- Alpine Linux 3.21.0
- MPD 0.23.16

***

## myMPD v1.5.4 (2024-11-01)

This is a small maintenance release.

### Changelog

- Set read permissions for all users for vcgencmd
- Migrate documentation to mkdocs
- Update libgpiod to v2.2

***

## myMPDos v1.5.3 (2024-09-11)

This release is build up on Alpine Linux 3.20.3.

### Changelog

- Alpine Linux 3.20.3

***

## myMPDos v1.5.2 (2024-07-27)

This release is build up on Alpine Linux 3.20.2.

### Changelog

- Alpine Linux 3.20.2
- Update mpc, libmpdclient, mpd-master
- Support ShowMovement Tag

***

## myMPDos v1.5.1 (2024-07-02)

This release is build up on Alpine Linux 3.20.1.

### Changelog

- Alpine Linux 3.20.1

***

## myMPDos v1.5.0 (2024-06-12)

This release is build up on Alpine Linux 3.20.0.

### Changelog

- Alpine Linux 3.20.0

***

## myMPDos v1.4.2 (2024-04-20)

This release fixes the bootstrap script.

### Changelog

- Increase boot partition size
- Improve bootstrap script
  - Do not default install mympdos-musicdb-scripts
  - Save bootstrap log to `/boot/bootstrap.log`
  - Save time for swclock
- Improve save*.sh scripts
  - Save time for swclock
  - Reliably save myMPD state
- Do not reset volume to 100% on startup

***

## myMPDos v1.4.1 (2024-01-28)

This release is build up on Alpine Linux 3.19.1.

### Changelog

- Alpine Linux 3.19.1
- Upd: add myMPD ca to system trust store

***

## myMPDos v1.4.0 (2023-12-19)

This release is build up on Alpine Linux 3.19.0.

### Notes

myGPIOd must be configured from scratch: https://github.com/jcorporation/myGPIOd

### Changelog

- Alpine Linux 3.19.0
- Save shutdowntime in apkovl
- New package: mympdos-libgpiod2 (libgpiod v2.1)
- myGPIOd v0.4.0 with many new features

***

## myMPDos v1.3.0 (2023-10-12)

This release is build up on Alpine Linux 3.18.4.

### Changelog

- Install myMPD scripts through bootstrap script #28
- Add myMPD config options to bootstrap file

## myMPDos v1.2.4 (2023-08-10)

This release is build up on Alpine Linux 3.18.3.

### Changelog

- Alpine Linux 3.18.3

***

## myMPDos v1.2.3 (2023-07-29)

This release enables IPv6.

***

## myMPDos v1.2.2 (2023-07-23)

This release adds bleeding edge versions of libmpdclient and mpc to the repositories.

Replace mympdos-mpd-stable with mympdos-mpd-master to enjoy the latest features.

### Changelog

- Replace libmpdclient with [libmympdclient](https://github.com/jcorporation/libmympdclient)
- Add [mympdos-mpc](https://github.com/jcorporation/mpc)

***

## myMPDos v1.2.1 (2023-06-14)

This release is build up on Alpine Linux 3.18.2.

### Changelog

- Alpine Linux 3.18.2

***

## myMPDos v1.2.0 (2023-06-04)

This release is build up on Alpine Linux 3.18.0.

### Changelog

- Alpine Linux 3.18.0

***

## myMPDos v1.1.3 (2023-03-30)

This release is build up on Alpine Linux 3.17.3.

### Changelog

- Alpine Linux 3.17.3

***

## myMPDos v1.1.2 (2023-02-17)

This release is build up on Alpine Linux 3.17.2.

### Changelog

- Alpine Linux 3.17.2
- myMPD 10.2.3

***

## myMPDos v1.1.1 (2023-01-19)

This release is build up on Alpine Linux 3.17.1.

### Changelog

- Alpine Linux 3.17.1
- myMPD 10.2.0
- MPD 0.23.12

***

## myMPDos v1.1.0 (2022-11-28)

This release is build up on Alpine Linux 3.17.0.

### Changelog

- Alpine Linux 3.17.0
- myMPD 10.1.3

***

## myMPDos v1.0.2 (2022-11-13)

This release is build up on Alpine Linux 3.16.3.

***

## myMPDos v1.0.1 (2022-08-14)

This release is build up on Alpine Linux 3.16.2.

***

## myMPDos v1.0.0 (2022-08-01)

This release is build up on Alpine Linux 3.16.1.

### Changelog

- myMPD 9.4.1
- MPD 0.23.8

***

## myMPDos v0.9.9 (2022-06-25)

This release is build up on Alpine Linux 3.16.0.

### Changelog

- Feat: install mympdos-musicdb-scripts as advanced package (https://github.com/jcorporation/musicdb-scripts)

***

## myMPDos v0.9.8 (2022-04-06)

This release is based on Alpine Linux 3.15.4.

***

## myMPDos v0.9.7 (2022-04-01)

This release is based on Alpine Linux 3.15.3.

***

## myMPDos v0.9.6 (2022-03-24)

This release is based on Alpine Linux 3.15.2.

***

## myMPDos v0.9.5

This release updates the base to Alpine Linux 3.15.1.

### Changelog

- default usercfg.txt file to support RPI Zero and 2B
- based on Alpine Linux 3.15.1

***

## myMPDos v0.9.4 (2021-12-02)

This release updates the base alpine linux image to 3.15.

### Changelog

- MPD 0.23.5 is now the default MPD version
- sudo is replaced by doas

***

## myMPDos v0.9.3 (2021-11-14)

This release upgrades the alpine base image to 3.14.3.

***

## myMPDos v0.9.2 (2021-10-08)

This release updates the base alpine image to 3.14.2.

***

## myMPDos v0.9.1 (2021-08-16)

This release updates the base alpine image to 3.14.1 and myMPD to 8.0.4.

***

## myMPDos v0.9.0 (2021-07-30)

This release adds some features.

### Changelog

- Feat: enabling/disabling internal raspberry pi bluetooth support
- Upd: myMPD v8.0.2
- Upd: remove obsolet myMPDos apks from boot partition
- Upd: enhance alpine upgrade process
- Upd: enhanced bootstrap process
- Upd: remove disfunctional support for armel und armhf
- Fix: bootstrap process starts myMPD with old commandline option
- Fix: permissions of /var/lib/mympd/scripts

***

## myMPDos v0.8.0 (2021-07-08)

This release updates the base image to Alpine Linux 3.14.0 and updates MPD to the latest versions.

***

## myMPDos v0.7.0 (2021-02-20)

This release updates the base image to Alpine Linux 3.13.2.

***

## myMPDos v0.6.0 (2021-02-08)

This release is based on Alpine Linux 3.13.1.

***

## myMPDos v0.4.0 (2020-12-19)

This release is based on Alpine Linux 3.12.3.

### Changelog

- Upd: myMPD 6.9.0

***

### myMPDos v0.3.0 (2020-11-17)

This is the third release of myMPDos.

### Changelog

- Feat: new package for myGPIOd 0.1.0
- Upd: myMPD 6.7.0
- Upd: MPD 0.22.3

***

## myMPDos v0.2.0 (2020-10-30)

This is the second release of myMPDos.

### Changelog

- Based on Alpine Linux 3.12.1
- myMPD 6.6.2
- MPD 0.22.2
- MPD from git master branch (0.23.0)
- libmpdclient from git master branch

***

## myMPDos v0.1.0 (2020-08-31)

This is the first release of myMPDos, the codename is "The updater works, I can ship!"

### Changelog

- Based on Alpine Linux 3.12
- myMPD 6.6.1
- MPD 0.21.25
- MPD from git master branch (0.22.0)
- libmpdclient from git master branch
