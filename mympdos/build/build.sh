#!/bin/sh

# SPDX-License-Identifier: GPL-3.0-or-later
# myMPDos (c) 2020-2026 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos


BUILDDIR="/build"
ARCH=$(uname -m)

#Build packages
B_BUILD="1"
B_MYMPD="1"
B_MYMPD_BRANCH="master"
B_LIBMPDCLIENT="1"
B_MPC="1"
B_MPD_STABLE="1"
B_MPD_MASTER="1"
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

echo "Setup myMPDos build"

echo "Adding build user"
adduser -D build -u 1000 -h "$BUILDDIR"
adduser build abuild
adduser build wheel

export HOME="$BUILDDIR"

# default distfiles location
install -d -g abuild -m 775 /var/cache/distfiles

cd "$BUILDDIR" || exit 1

echo "Setting up package signing key"
if [ -f "$BUILDDIR/abuild.tgz" ]
then
  echo "Restoring .abuild"
  tar -xzf abuild.tgz
else
  if abuild-keygen -n -a
  then
    tar -czf abuild.tgz .abuild
  fi
fi
cp -v .abuild/*.rsa.pub /etc/apk/keys/

echo "Adding local myMPDos repository"
echo "$BUILDDIR/packages/package" >> /etc/apk/repositories

# Enable apk cache
ln -s /var/cache/apk /etc/apk/cache

echo "Updating apks"
apk update
apk upgrade

echo "Installing build packages"
apk add \
  alsa-lib-dev \
  alpine-sdk \
  build-base \
  check-dev \
  cmake \
  curl-dev \
  doas \
  expat-dev \
  faad2-dev \
  ffmpeg-dev \
  flac-dev \
  fmt-dev \
  git \
  glib-dev \
  gzip \
  icu-dev \
  jq \
  lame-dev \
  libgpiod-dev \
  libid3tag-dev \
  libmad-dev \
  linux-headers \
  lua5.4 \
  lua5.4-dev \
  meson \
  mpg123-dev \
  newt \
  libmicrohttpd-dev \
  libogg-dev \
  libsamplerate-dev \
  liburing-dev \
  libvorbis-dev \
  meson \
  nlohmann-json \
  opus-dev \
  pcre2-dev \
  perl \
  raspberrypi-utils-vcgencmd \
  samurai \
  soxr-dev \
  sqlite-dev \
  utf8proc-dev \
  wavpack-dev \
  xz

# Doas config
cat > /etc/doas.d/doas.conf <<EOL
permit nopass :wheel
permit nopass :root
EOL
chmod 600 /etc/doas.d/doas.conf

install -o build -d "packages/package/$ARCH/"
if [ ! -h "$BUILDDIR/packages/build" ]
then
  ln -s "$BUILDDIR/packages/package/" "$BUILDDIR/packages/build"
fi

echo "Starting myMPDos build"

LIBMPDCLIENT_PACKAGE=$(get_pkgname /mympdos/mympdos-libmpdclient)
B_LIBMPDCLIENT_VER=$(get_pkgver /mympdos/mympdos-libmpdclient)
if [ "$B_LIBMPDCLIENT" = "1" ] && [ ! -f "packages/package/$ARCH/$LIBMPDCLIENT_PACKAGE" ]
then
  echo "Build libmpdclient"
  rm -rf libmpdclient
  cp -r /mympdos/mympdos-libmpdclient .
  chown -R build mympdos-libmpdclient
  cd mympdos-libmpdclient || exit 1
  su build -c "git clone -b master --depth=1 https://github.com/MusicPlayerDaemon/libmpdclient.git"
  mv libmpdclient "mympdos-libmpdclient-${B_LIBMPDCLIENT_VER}"
  tar -czf mympdos-libmpdclient.tar.gz "mympdos-libmpdclient-${B_LIBMPDCLIENT_VER}"
  rm -fr "mympdos-libmpdclient-${B_LIBMPDCLIENT_VER}"
  abuild -F checksum
  if ! abuild -F
  then
    # Retry
    abuild -F
  fi
fi

cd "$BUILDDIR" || exit 1

#install freshly build libmpdclient
apk update
if ! apk add mympdos-libmpdclient mympdos-libmpdclient-dev
then
  echo "Failed"
  exit 1
fi

MPC_PACKAGE=$(get_pkgname /mympdos/mympdos-mpc)
B_MPC_VER=$(get_pkgver /mympdos/mympdos-mpc)
if [ "$B_MPC" = "1" ] && [ ! -f "packages/package/$ARCH/$MPC_PACKAGE" ]
then
  echo "Building mpc"
  rm -rf mympdos-mpc
  cp -r /mympdos/mympdos-mpc .
  chown -R build mympdos-mpc
  cd mympdos-mpc || exit 1
  git clone -b master --depth=1 https://github.com/jcorporation/mpc.git
  mv "mpc" "mympdos-mpc-${B_MPC_VER}"
  tar -czf mympdos-mpc.tar.gz "mympdos-mpc-${B_MPC_VER}"
  rm -fr "mympdos-mpc-${B_MPC_VER}"
  abuild -F checksum
  if ! abuild -F
  then
    # Retry
    abuild -F
  fi
fi

cd "$BUILDDIR" || exit 1

MYGPIOD_PACKAGE=$(get_pkgname /mympdos/mygpiod)
B_MYGPIOD_VER=$(get_pkgver /mympdos/mygpiod)
if [ "$B_MYGPIOD" = "1" ] && [ ! -f "packages/package/$ARCH/$MYGPIOD_PACKAGE" ]
then
  echo "Build mygpiod"
  rm -rf mygpiod
  cp -r /mympdos/mygpiod .
  chown -R build mygpiod
  cd mygpiod || exit 1
  su build -c "git clone -b master --depth=1 https://github.com/jcorporation/myGPIOd.git"
  mv myGPIOd "mygpiod-${B_MYGPIOD_VER}"
  tar -czf mygpiod.tar.gz "mygpiod-${B_MYGPIOD_VER}"
  rm -fr "mygpiod-${B_MYGPIOD_VER}"
  abuild -F checksum
  if ! abuild -F
  then
    # Retry
    abuild -F
  fi
fi

cd "$BUILDDIR" || exit 1

MYMPD_PACKAGE=$(get_pkgname /mympdos/mympd)
B_MYMPD_VER=$(get_pkgver /mympdos/mympd)
if [ "$B_MYMPD" = "1" ] && [ ! -f "packages/package/$ARCH/$MYMPD_PACKAGE" ]
then
  echo "Build mympd"
  rm -rf mympd
  cp -r /mympdos/mympd .
  chown -R build mympd
  cd mympd || exit 1
  su build -c "git clone -b "$B_MYMPD_BRANCH" --depth=1 https://github.com/jcorporation/myMPD.git"
  mv myMPD "mympd-${B_MYMPD_VER}"
  tar -czf mympd.tar.gz "mympd-${B_MYMPD_VER}"
  rm -fr "mympd-${B_MYMPD_VER}"
  git config --global --add safe.directory "/${BUILDDIR}/mympd/src/mympd-${B_MYMPD_VER}"
  abuild -F checksum
  if ! abuild -F
  then
    # Retry
    abuild -F
  fi
fi

cd "$BUILDDIR" || exit 1

MYMPDOS_BASE_PACKAGE=$(get_pkgname /mympdos/mympdos-base)
B_MYMPDOS_BASE_VER=$(get_pkgver /mympdos/mympdos-base)
if [ "$B_BUILD" = "1" ] && [ ! -f "packages/package/$ARCH/$MYMPDOS_BASE_PACKAGE" ]
then
  rm -rf mympdos-base
  cp -r /mympdos/mympdos-base .
  chown -R build mympdos-base
  cd mympdos-base || exit 1
  mv mympdos-base "mympdos-base-$B_MYMPDOS_BASE_VER"
  tar -czf "mympdos-base-$B_MYMPDOS_BASE_VER.tar.gz" "mympdos-base-$B_MYMPDOS_BASE_VER"
  abuild -F checksum
  if ! abuild -F
  then
    # Retry
    abuild -F
  fi
fi

cd "$BUILDDIR" || exit 1

MPD_STABLE_PACKAGE=$(get_pkgname /mympdos/mympdos-mpd-stable)
B_MPD_STABLE_VER=$(get_pkgver /mympdos/mympdos-mpd-stable)
if [ "$B_MPD_STABLE" = "1" ] && [ ! -f "packages/package/$ARCH/$MPD_STABLE_PACKAGE" ]
then
  echo "Building MPD stable"
  rm -rf mympdos-mpd-stable
  cp -r /mympdos/mympdos-mpd-stable .
  chown -R build mympdos-mpd-stable
  cd mympdos-mpd-stable || exit 1
  su build -c "wget http://www.musicpd.org/download/mpd/0.24/mpd-${B_MPD_STABLE_VER}.tar.xz"
  tar -xf "mpd-${B_MPD_STABLE_VER}.tar.xz"
  rm "mpd-${B_MPD_STABLE_VER}.tar.xz"
  mv "mpd-${B_MPD_STABLE_VER}" "mympdos-mpd-stable-${B_MPD_STABLE_VER}"
  tar -czf mympdos-mpd-stable.tar.gz "mympdos-mpd-stable-${B_MPD_STABLE_VER}"
  rm -fr "mympdos-mpd-stable-${B_MPD_STABLE_VER}"
  abuild -F checksum
  if ! abuild -F
  then
    # Retry
    abuild -F
  fi
fi

cd "$BUILDDIR" || exit 1

MPD_MASTER_PACKAGE=$(get_pkgname /mympdos/mympdos-mpd-master)
B_MPD_MASTER_VER=$(get_pkgver /mympdos/mympdos-mpd-master)
if [ "$B_MPD_MASTER" = "1" ] && [ ! -f "packages/package/$ARCH/$MPD_MASTER_PACKAGE" ]
then
  echo "Build MDP master"
  rm -rf mympdos-mpd-master
  cp -r /mympdos/mympdos-mpd-master .
  chown -R build mympdos-mpd-master
  cd mympdos-mpd-master || exit 1
  su build -c "git clone -b master --depth=1 https://github.com/MusicPlayerDaemon/MPD.git"
  mv MPD "mympdos-mpd-master-${B_MPD_MASTER_VER}"
  tar -czf mympdos-mpd-master.tar.gz "mympdos-mpd-master-${B_MPD_MASTER_VER}"
  rm -fr "mympdos-mpd-master-${B_MPD_MASTER_VER}"
  abuild -F checksum
  if ! abuild -F
  then
    # Retry
    abuild -F
  fi
fi

cd "$BUILDDIR" || exit 1

MUSICDB_SCRIPTS_PACKAGE=$(get_pkgname /mympdos/mympdos-musicdb-scripts)
B_MUSICDB_SCRIPTS_VER=$(get_pkgver /mympdos/mympdos-musicdb-scripts)
if [ "$B_MUSICDB_SCRIPTS" = "1" ] && [ ! -f "packages/package/$ARCH/$MUSICDB_SCRIPTS_PACKAGE" ]
then
  echo "Build musicdb-scripts"
  rm -rf mympdos-musicdb-scripts
  cp -r /mympdos/mympdos-musicdb-scripts .
  chown -R build mympdos-musicdb-scripts
  cd mympdos-musicdb-scripts || exit 1
  su build -c "git clone -b master --depth=1 https://github.com/jcorporation/musicdb-scripts.git"
  mv musicdb-scripts "mympdos-musicdb-scripts-${B_MUSICDB_SCRIPTS_VER}"
  tar -czf "mympdos-musicdb-scripts-${B_MUSICDB_SCRIPTS_VER}.tar.gz" "mympdos-musicdb-scripts-${B_MUSICDB_SCRIPTS_VER}"
  rm -fr "mympdos-musicdb-scripts-${B_MUSICDB_SCRIPTS_VER}"
  abuild -F checksum
  if ! abuild -F
  then
    # Retry
    abuild -F
  fi
fi

chown -R build:build "/build/"
