#!/bin/sh
#
# SPDX-License-Identifier: GPL-2.0-or-later
# myMPD (c) 2020 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/mympd
#

BUILDDIR="/usr/build"
POWEROFF="0"
ARCH=$(uname -m)

#Build packages
B_BUILD="1"
B_MYMPD="1"
B_MYMPD_BRANCH="devel"
B_LIBMPDCLIENT="1"
B_MPD_STABLE="1"
B_MPD_MASTER="0"

get_pkgver()
{
  PKGVER=$(grep ^pkgver "$1/APKBUILD" | cut -d= -f2)
  echo "${PKGVER}"
}

get_pkgname()
{
  PKGNAME=$(grep ^pkgname "$1/APKBUILD" | cut -d= -f2)
  PKGVER=$(grep ^pkgver "$1/APKBUILD" | cut -d= -f2)
  PKGREL=$(grep ^pkgrel "$1/APKBUILD" | cut -d= -f2)
  echo "${PKGNAME}-${PKGVER}-r${PKGREL}.apk"
}

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

su build -c "install -d packages/package/$ARCH/"
if [ -f /media/vda1/mympdos-apks/APKINDEX.tar.gz ]
then
  echo "Restoring existing packages"
  su build -c "cp /media/vda1/mympdos-apks/* packages/package/$ARCH/"
else
  echo "No existing packages found"
fi

LIBMPDCLIENT_PACKAGE=$(get_pkgname /media/vda1/mympd/libmpdclient)
B_LIBMPDCLIENT_VER=$(get_pkgver /media/vda1/mympd/libmpdclient)
if [ "$B_LIBMPDCLIENT" = "1" ] && [ ! -f "packages/package/$ARCH/$LIBMPDCLIENT_PACKAGE" ]
then
  echo "Build libmpdclient"
  su build -c "cp -r /media/vda1/mympd/libmpdclient ."
  cd libmpdclient || exit 1
  su build -c "abuild checksum"
  su build -c "abuild -r"
  cd ..
  mv packages/build/"$ARCH"/*.apk "packages/package/$ARCH/"
fi

echo "/usr/build/packages/package/" >> /etc/apk/repositories
apk update

if [ "$B_MYMPD" = "1" ]
then
  echo "Build myMPD"
  su build -c "git clone -b $B_MYMPD_BRANCH --depth=1 https://github.com/jcorporation/myMPD.git"
  cd myMPD || exit 1
  MYMPD_PACKAGE=$(get_pkgname contrib/packaging/alpine)
  if [ ! -f "../packages/package/$ARCH/$MYMPD_PACKAGE" ]
  then
    su build -c "./build.sh pkgalpine"
  fi
  cd ..
fi

MPD_MASTER_PACKAGE=$(get_pkgname /media/vda1/mympd/mpd-master)
B_MPD_MASTER_VER=$(get_pkgver /media/vda1/mympd/mpd-master)
if [ "$B_MPD_MASTER" = "1" ] && [ ! -f "packages/package/$ARCH/$MPD_MASTER_PACKAGE" ]
then
  echo "Build MDP master"
  su build -c "cp -r /media/vda1/mympd/mpd-master ."
  cd mpd-master || exit 1
  su build -c "git clone -b master --depth=1 https://github.com/MusicPlayerDaemon/MPD.git"
  mv MPD "mympdos-mpd-master-${B_MPD_MASTER_VER}"
  tar -czf mympdos-mpd-master.tar.gz "mympdos-mpd-master-${B_MPD_MASTER_VER}"
  rm -fr "mympdos-mpd-master-${B_MPD_MASTER_VER}"
  su build -c "abuild checksum"
  su build -c "abuild -r"
  cd ..
fi

MPD_STABLE_PACKAGE=$(get_pkgname /media/vda1/mympd/mpd-stable)
B_MPD_STABLE_VER=$(get_pkgver /media/vda1/mympd/mpd-stable)
if [ "$B_MPD_STABLE" = "1" ] && [ ! -f "packages/package/$ARCH/$MPD_STABLE_PACKAGE" ]
then
  echo "Building MPD stable"
  su build -c "cp -r /media/vda1/mympd/mpd-stable ."
  cd mpd-stable || exit 1
  su build -c "wget http://www.musicpd.org/download/mpd/0.21/mpd-${B_MPD_STABLE_VER}.tar.xz"
  tar -xf "mpd-${B_MPD_STABLE_VER}.tar.xz"
  rm "mpd-${B_MPD_STABLE_VER}.tar.xz"
  mv "mpd-${B_MPD_STABLE_VER}" "mympdos-mpd-stable-${B_MPD_STABLE_VER}"
  tar -czf mympdos-mpd-stable.tar.gz "mympdos-mpd-stable-${B_MPD_STABLE_VER}"
  rm -fr "mympdos-mpd-stable-${B_MPD_STABLE_VER}"
  su build -c "abuild checksum"
  su build -c "abuild -r"
  cd ..
fi

[ "$POWEROFF" = "1" ] && poweroff
