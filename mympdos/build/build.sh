#!/bin/sh
#
# SPDX-License-Identifier: GPL-3.0-or-later
# myMPDos (c) 2020-2023 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos
#

BUILDDIR="/usr/build"
POWEROFF="1"
ARCH=$(uname -m)

#Build packages
B_BUILD="1"
B_MYMPD="1"
B_MYMPD_BRANCH="master"
#B_MYMPD_BRANCH="devel"
B_MYGPIOD_BRANCH="master"
#B_MYGPIOD_BRANCH="devel"
B_LIBMPDCLIENT="1"
B_MPC="1"
B_MPD_STABLE="1"
B_MPD_MASTER="1"
B_LIBGPIOD2="1"
B_MYGPIOD="1"
B_MUSICDB_SCRIPTS="1"

get_pkgver() {
  PKGVER=$(grep ^pkgver "$1/APKBUILD" | cut -d= -f2)
  echo "${PKGVER}"
}

get_pkgname() {
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
echo "/media/vda1/apks" > /etc/apk/repositories
setup-apkrepos -1
sed -r -e's/^#\s?(.*\d\/community)/\1/' -i /etc/apk/repositories
while apk update 2>&1 | grep WARNING
do
  echo "Error...trying new random repository"
  echo "/media/vda1/apks" > /etc/apk/repositorie
  setup-apkrepos -r
  sed -r -e's/^#\s?(.*\d\/community)/\1/' -i /etc/apk/repositories
done
apk upgrade

echo "Moving /usr to /dev/vda2"
mount /dev/vda2 /mnt -text4
cp -a /usr/* /mnt
umount /mnt
mount /dev/vda2 /usr -text4

echo "Setup apkcache"
install -d /usr/build/distfiles -g abuild -m775
setup-apkcache /usr/build/distfiles

echo "Installing build packages"
apk add git alpine-sdk perl build-base xz

echo "Adding build user"
adduser -D build -h "$BUILDDIR"
addgroup build abuild
cd "$BUILDDIR" || exit 1

echo "Setting up package signing key"
if [ -f /media/vda1/mympdos/abuild.tgz ]
then
  echo "Restoring .abuild"
  cp /media/vda1/mympdos/abuild.tgz .
  tar -xzf abuild.tgz
else
  if su build -c "abuild-keygen -n -a"
  then
    tar -czf abuild.tgz .abuild
  fi
fi
cp .abuild/*.rsa.pub /etc/apk/keys/

su build -c "install -d packages/package/$ARCH/"
ln -s /usr/build/packages/package/ /usr/build/packages/build

if [ -f /media/vda1/mympdos-apks/APKINDEX.tar.gz ]
then
  echo "Restoring existing packages"
  su build -c "cp /media/vda1/mympdos-apks/* packages/package/$ARCH/"
else
  echo "No existing packages found"
fi

LIBMPDCLIENT_PACKAGE=$(get_pkgname /media/vda1/mympdos/mympdos-libmpdclient)
B_LIBMPDCLIENT_VER=$(get_pkgver /media/vda1/mympdos/mympdos-libmpdclient)
if [ "$B_LIBMPDCLIENT" = "1" ] && [ ! -f "packages/package/$ARCH/$LIBMPDCLIENT_PACKAGE" ]
then
  echo "Build libmpdclient"
  su build -c "rm -rf libmpdclient"
  su build -c "cp -r /media/vda1/mympdos/mympdos-libmpdclient ."
  cd mympdos-libmpdclient || exit 1
  su build -c "git clone -b libmympdclient --depth=1 https://github.com/jcorporation/libmympdclient.git"
  mv libmympdclient "mympdos-libmpdclient-${B_LIBMPDCLIENT_VER}"
  tar -czf mympdos-libmpdclient.tar.gz "mympdos-libmpdclient-${B_LIBMPDCLIENT_VER}"
  rm -fr "mympdos-libmpdclient-${B_LIBMPDCLIENT_VER}"
  su build -c "abuild checksum"
  su build -c "abuild -r"
  cd ..
fi

#install freshly build libmpdclient
echo "/usr/build/packages/package/" >> /etc/apk/repositories
apk update
apk add mympdos-libmpdclient mympdos-libmpdclient-dev

MPC_PACKAGE=$(get_pkgname /media/vda1/mympdos/mympdos-mpc)
B_MPC_VER=$(get_pkgver /media/vda1/mympdos/mympdos-mpc)
if [ "$B_MPC" = "1" ] && [ ! -f "packages/package/$ARCH/$MPC_PACKAGE" ]
then
  echo "Building mpc"
  su build -c "rm -rf mympdos-mpc"
  su build -c "cp -r /media/vda1/mympdos/mympdos-mpc ."
  cd mympdos-mpc || exit 1
  su build -c "git clone -b master --depth=1 https://github.com/jcorporation/mpc.git"
  mv "mpc" "mympdos-mpc-${B_MPC_VER}"
  tar -czf mympdos-mpc.tar.gz "mympdos-mpc-${B_MPC_VER}"
  rm -fr "mympdos-mpc-${B_MPC_VER}"
  su build -c "abuild checksum"
  su build -c "abuild -r"
  cd ..
fi

LIBGPIOD2_PACKAGE=$(get_pkgname /media/vda1/mympdos/mympdos-libgpiod2)
B_LIBGPIOD2_VER=$(get_pkgver /media/vda1/mympdos/mympdos-libgpiod2)
if [ "$B_LIBGPIOD2" = "1" ] && [ ! -f "packages/package/$ARCH/$LIBGPIOD2_PACKAGE" ]
then
  echo "Building libgpiod v2"
  su build -c "rm -rf mympdos-libgpiod2"
  su build -c "cp -r /media/vda1/mympdos/mympdos-libgpiod2 ."
  cd mympdos-libgpiod2 || exit 1
  su build -c "git clone -b v2.1.x --depth=1 https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git"
  mv "libgpiod" "mympdos-libgpiod2-${B_LIBGPIOD2_VER}"
  tar -czf mympdos-libgpiod2.tar.gz "mympdos-libgpiod2-${B_LIBGPIOD2_VER}"
  rm -fr "mympdos-libgpiod2-${B_LIBGPIOD2_VER}"
  su build -c "abuild checksum"
  su build -c "abuild -r"
  cd ..
fi

apk update
apk add mympdos-libgpiod2 mympdos-libgpiod2-dev curl-dev

if [ "$B_MYGPIOD" = "1" ]
then
  echo "Build myGPIOd"
  su build -c "rm -rf myGPIOd"
  su build -c "git clone -b "$B_MYGPIOD_BRANCH" --depth=1 https://github.com/jcorporation/myGPIOd.git"
  cd myGPIOd || exit 1
  MYGPIOD_PACKAGE=$(get_pkgname contrib/packaging/alpine)
  if [ ! -f "../packages/package/$ARCH/$MYGPIOD_PACKAGE" ]
  then
    sed -i 's/libmpdclient/mympdos-libmpdclient/g' contrib/packaging/alpine/APKBUILD
    su build -c "./build.sh pkgalpine"
  else
    echo "myGPIOd is already up-to-date"
  fi
  cd ..
fi

apk update
apk add mygpiod mygpiod-dev

if [ "$B_MYMPD" = "1" ]
then
  echo "Build myMPD"
  su build -c "rm -rf myMPD"
  su build -c "git clone -b $B_MYMPD_BRANCH --depth=1 https://github.com/jcorporation/myMPD.git"
  cd myMPD || exit 1
  MYMPD_PACKAGE=$(get_pkgname contrib/packaging/alpine)
  if [ ! -f "../packages/package/$ARCH/$MYMPD_PACKAGE" ]
  then
    ./build.sh installdeps
    if [ "$B_MYMPD_BRANCH" != "master" ]
    then
      su build -c "./build.sh cleanupdist"
      su build -c "./build.sh createdist"
    fi
    su build -c "./build.sh pkgalpine"
  else
    echo "myMPD is already up-to-date"
  fi
  cd ..
fi

MYMPDOS_BASE_PACKAGE=$(get_pkgname /media/vda1/mympdos/mympdos-base)
B_MYMPDOS_BASE_VER=$(get_pkgver /media/vda1/mympdos/mympdos-base)
if [ "$B_BUILD" = "1" ] && [ ! -f "packages/package/$ARCH/$MYMPDOS_BASE_PACKAGE" ]
then
  addgroup -S mympd
  adduser -S -D -H -h /var/lib/mympd -s /sbin/nologin -G mympd -g myMPD mympd
  su build -c "rm -rf mympdos-base"
  su build -c "cp -r /media/vda1/mympdos/mympdos-base ."
  cd mympdos-base || exit 1
  mv mympdos-base "mympdos-base-$B_MYMPDOS_BASE_VER"
  tar -czf "mympdos-base-$B_MYMPDOS_BASE_VER.tar.gz" "mympdos-base-$B_MYMPDOS_BASE_VER"
  su build -c "abuild checksum"
  su build -c "abuild -r"
  cd ..
fi

MPD_STABLE_PACKAGE=$(get_pkgname /media/vda1/mympdos/mympdos-mpd-stable)
B_MPD_STABLE_VER=$(get_pkgver /media/vda1/mympdos/mympdos-mpd-stable)
if [ "$B_MPD_STABLE" = "1" ] && [ ! -f "packages/package/$ARCH/$MPD_STABLE_PACKAGE" ]
then
  echo "Building MPD stable"
  su build -c "rm -rf mympdos-mpd-stable"
  su build -c "cp -r /media/vda1/mympdos/mympdos-mpd-stable ."
  cd mympdos-mpd-stable || exit 1
  su build -c "wget http://www.musicpd.org/download/mpd/0.24/mpd-${B_MPD_STABLE_VER}.tar.xz"
  tar -xf "mpd-${B_MPD_STABLE_VER}.tar.xz"
  rm "mpd-${B_MPD_STABLE_VER}.tar.xz"
  mv "mpd-${B_MPD_STABLE_VER}" "mympdos-mpd-stable-${B_MPD_STABLE_VER}"
  tar -czf mympdos-mpd-stable.tar.gz "mympdos-mpd-stable-${B_MPD_STABLE_VER}"
  rm -fr "mympdos-mpd-stable-${B_MPD_STABLE_VER}"
  su build -c "abuild checksum"
  su build -c "abuild -r"
  cd ..
fi

MPD_MASTER_PACKAGE=$(get_pkgname /media/vda1/mympdos/mympdos-mpd-master)
B_MPD_MASTER_VER=$(get_pkgver /media/vda1/mympdos/mympdos-mpd-master)
if [ "$B_MPD_MASTER" = "1" ] && [ ! -f "packages/package/$ARCH/$MPD_MASTER_PACKAGE" ]
then
  echo "Build MDP master"
  su build -c "rm -rf mympdos-mpd-master"
  su build -c "cp -r /media/vda1/mympdos/mympdos-mpd-master ."
  cd mympdos-mpd-master || exit 1
  su build -c "git clone -b master --depth=1 https://github.com/MusicPlayerDaemon/MPD.git"
  mv MPD "mympdos-mpd-master-${B_MPD_MASTER_VER}"
  tar -czf mympdos-mpd-master.tar.gz "mympdos-mpd-master-${B_MPD_MASTER_VER}"
  rm -fr "mympdos-mpd-master-${B_MPD_MASTER_VER}"
  su build -c "abuild checksum"
  su build -c "abuild -r"
  cd ..
fi

MUSICDB_SCRIPTS_PACKAGE=$(get_pkgname /media/vda1/mympdos/mympdos-musicdb-scripts)
B_MUSICDB_SCRIPTS_VER=$(get_pkgver /media/vda1/mympdos/mympdos-musicdb-scripts)
if [ "$B_MUSICDB_SCRIPTS" = "1" ] && [ ! -f "packages/package/$ARCH/$MUSICDB_SCRIPTS_PACKAGE" ]
then
  echo "Build musicdb-scripts"
  su build -c "rm -rf mympdos-musicdb-scripts"
  su build -c "cp -r /media/vda1/mympdos/mympdos-musicdb-scripts ."
  cd mympdos-musicdb-scripts || exit 1
  su build -c "git clone -b master --depth=1 https://github.com/jcorporation/musicdb-scripts.git"
  mv musicdb-scripts "mympdos-musicdb-scripts-${B_MUSICDB_SCRIPTS_VER}"
  tar -czf "mympdos-musicdb-scripts-${B_MUSICDB_SCRIPTS_VER}.tar.gz" "mympdos-musicdb-scripts-${B_MUSICDB_SCRIPTS_VER}"
  rm -fr "mympdos-musicdb-scripts-${B_MUSICDB_SCRIPTS_VER}"
  su build -c "abuild checksum"
  su build -c "abuild -r"
  cd ..
fi

echo "Creating repository index"
rm -f packages/package/aarch64/APKINDEX.tar.gz
apk index --rewrite-arch aarch64 --no-warnings -d "myMPDos" -o packages/package/aarch64/APKINDEX.tar.gz packages/package/aarch64/*.apk
abuild-sign -k /usr/build/$(echo .abuild/*.rsa) packages/package/aarch64/APKINDEX.tar.gz

[ "$POWEROFF" = "1" ] && poweroff
