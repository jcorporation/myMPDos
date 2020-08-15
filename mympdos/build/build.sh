#!/bin/sh
#
# SPDX-License-Identifier: GPL-2.0-or-later
# myMPD (c) 2020 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/mympd
#

BUILDDIR="/usr/build"
MYMPD_BRANCH="devel"
POWEROFF="1"

#Build packages
B_BUILD="0"
B_MYMPD="0"
B_MPD_STABLE="0"
B_MPD_MASTER="0"

echo ""
echo "Starting myMPDos build"

echo "Setting the local clock"
date -s@"$(cat /media/vda1/date)"

if [ "$POWEROFF" = "0" ]
then
  echo "Setting keymap"
  setup-keymap de de-nodeadkeys
fi

echo "Setup repositories and upgrade"
setup-apkrepos -1
sed -r -e's/^#(.*\d\/community)/\1/' -i /etc/apk/repositories
apk update
apk upgrade

echo "Moving /usr to /dev/vda2"
mount /dev/vda2 /mnt -text4
cp -a /usr/* /mnt
umount /mnt
mount /dev/vda2 /usr -text4

echo "Setup apkcache"
install -d /usr/build/distfiles -g abuild -m775
setup-apkcache /usr/build/distfiles

if [ "$B_BUILD" = "1" ]
then
  echo "Installing build packages"
  apk add git alpine-sdk perl sudo build-base
else
  apk add abuild sudo
fi

echo "Adding build user"
adduser -D build -h "$BUILDDIR"
addgroup build abuild
echo "build    ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
cd "$BUILDDIR" || exit 1

echo "Setting up package signing key"
if [ -f /media/vda1/mympd/abuild.tgz ]
then
  echo "Restoring .abuild"
  tar -xzf /media/vda1/mympd/abuild.tgz 
else
  if su build -c "abuild-keygen -n -a"
  then
    tar -czf abuild.tgz .abuild
  fi
fi
cp .abuild/*.rsa.pub /etc/apk/keys/

su build -c "install -d packages/package/aarch64/"
if [ -f /media/vda1/mympdos-apks/APKINDEX.tar.gz ]
then
  echo "Restoring existing packages"
  su build -c "cp /media/vda1/mympdos-apks/* packages/package/aarch64/"
else
  echo "No existing packages found"
fi

if [ "$B_MYMPD" = "1" ]
then
  echo "Building myMPD"
  su build -c "git clone -b $MYMPD_BRANCH --depth=1 https://github.com/jcorporation/myMPD.git"
  cd myMPD || exit 1
  su build -c "./build.sh pkgalpine"
  cd ..
fi
if [ "$B_MPD_MASTER" = "1" ]
then
  echo "Build MDP master"
  MPDVER="0.22.0"
  su build -c "cp -r /media/vda1/mympd/mpd-master ."
  cd mpd-master || exit 1
  sed -e "s/__MPDVER__/${MPDVER}/g" -i APKBUILD
  su build -c "git clone -b master --depth=1 https://github.com/MusicPlayerDaemon/MPD.git"
  mv MPD "mympdos-mpd-master-${MPDVER}"
  tar -czf mympdos-mpd-master.tar.gz "mympdos-mpd-master-${MPDVER}"
  rm -fr "mympdos-mpd-master-${MPDVER}"
  su build -c "abuild checksum"
  su build -c "abuild -r"
  cd ..
fi
if [ "$B_MPD_STABLE" = "1" ]
then
  echo "Building MPD stable"
  MPDVER="0.21.25"
  su build -c "cp -r /media/vda1/mympd/mpd-stable ."
  cd mpd-stable || exit 1
  sed -e "s/__MPDVER__/${MPDVER}/g" -i APKBUILD
  su build -c "wget http://www.musicpd.org/download/mpd/0.21/mpd-${MPDVER}.tar.xz"
  tar -xzf "mpd-${MPDVER}.tar.xz"
  rm "mpd-${MPDVER}.tar.xz"
  mv "mpd-${MPDVER}" "mympdos-mpd-stable-${MPDVER}"
  tar -czf mympdos-mpd-stable.tar.gz "mympdos-mpd-stable-${MPDVER}"
  rm -fr "mympdos-mpd-stable-${MPDVER}"
  su build -c "abuild checksum"
  su build -c "abuild -r"
  cd ..
fi

[ "$POWEROFF" = "1" ] && poweroff
