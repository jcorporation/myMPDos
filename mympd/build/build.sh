#!/bin/sh
BUILDDIR="/usr/build"
BRANCH="devel"

while ! ntpd -q -n -p pool.ntp.org
do
  echo "Retry"
done

setup-alpine -e -f /media/vda1/mympd/setup-alpine.answers

sed -r -e's/^#(.*\d\/community)/\1/' -i /etc/apk/repositories
apk update
apk upgrade
apk add e2fsprogs

mount -oremount,rw /media/vda1
install -d /media/vda2
mount /dev/vda2 /media/vda2
cp -a /usr/* /media/vda2
umount /media/vda2
mount /dev/vda2 /usr -text4

apk add git sudo alpine-sdk perl

adduser -D build -h "$BUILDDIR"
addgroup build abuild
echo "build    ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
su build -c "abuild-keygen -n -a -i"

install -d /var/cache/distfiles
chgrp abuild /var/cache/distfiles
chmod g+w /var/cache/distfiles

cd "$BUILDDIR" || exit 1

su build -c "git clone -b $BRANCH --depth=1 https://github.com/jcorporation/myMPD.git"
cd myMPD || exit 1
#su build -c "./build.sh pkgalpine"
cd ..

#su build -c "cp -r /media/vda1/mympd/mpd-master ."
#cd mpd-master || exit 1
#su build -c "abuild checksum"
#su build -c "abuild -r"
#cd ..

#su build -c "cp -r /media/vda1/mympd/mpd-stable ."
#cd mpd-stable || exit 1
#su build -c "abuild checksum"
#su build -c "abuild -r"
#cd ..

#poweroff
