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

install -d /media/vda2
mount /dev/vda2 /media/vda2 -text4
cp -a /usr/* /media/vda2
umount /media/vda2
mount /dev/vda2 /usr -text4

apk add git sudo alpine-sdk perl build-base

adduser -D build -h "$BUILDDIR"
addgroup build abuild
echo "build    ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
if [ -d /media/vda1/mympd/.abuild ]
then
 cp -r /media/vda1/mympd/.abuild /usr/build/
 chown -R build.abuild /usr/build/.abuild
 chmod 700 /usr/build/.abuild
 chmod 600 /usr/build/.abuild/*.rsa
 chmod 644 /usr/build/.abuild/*.rsa.pub
 chmod 644 /usr/build/.abuild/abuild.conf
 cp /usr/build/.abuild/*.rsa.pub /etc/apk/keys/
else
  su build -c "abuild-keygen -n -a -i"
fi

install -d /var/cache/distfiles -g abuild -m775

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
