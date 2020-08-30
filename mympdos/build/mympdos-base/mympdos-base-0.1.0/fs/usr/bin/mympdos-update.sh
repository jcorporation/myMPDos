#!/bin/sh

read -r VERSION < "/media/mmcblk0p1/myMPDos.version"
[ "$VERSION" = "" ] && exit 1

TMPDIR=$(mktemp -d)
cd $TMPDIR || exit 1

download() {
  URI="https://raw.githubusercontent.com/jcorporation/myMPDos/master/updates/${VERSION}"

  if wget -q "$URI/update.sha256" -O "$TMPDIR/update.sha256" 2>/dev/null && \
     wget -q "$URI" -O "$TMPDIR/update.tar.gz" 2>/dev/null
  then
    openssl base64 -d -in "$TMPDIR/update.sha256" -out "$TMPDIR/update.sig"
    if openssl dgst -sha256 -verify /etc/apk/keys/mail@jcgames.de.rsa.pub \
               -signature "$TMPDIR/update.sig" "$TMPDIR/update.tar.gz"
    then
      return 0
    else
      echo "  - Signature check failed"
    fi
  fi
  return 1
}

do_update() {
  echo "  - Unpacking update"
  tar -xzf update.tar.gz
  echo "  - Executing update script"
  cd update || exit 1
  eval update.sh

  read -r NEWVERSION < myMPDos.version
  echo "  - Setting version to $NEWVERSION"
  mount -oremount,rw /media/mmcblk0p1
  mv myMPDos.version /media/mmcblk0p1/myMPDos.version
  mount -oremount,ro /media/mmcblk0p1
  echo "Update finished"
}

echo "Updating apks"
apk update
apk upgrade

echo "Starting myMPDos update"
echo "  - Current version: $VERSION"
echo "  - Checking for update"
if download
then
  do_update
else
  echo "  - No update found"
fi

cd /
rm -fr "$TMPDIR"

echo "  - Saving changes"
lbu_commit
exit 0
