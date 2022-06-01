#!/bin/sh

if [ -e /dev/mmcblk0 ]
then
	BOOTMEDIA="/media/mmcblk0p1"
	BOOTDEV="/dev/mmcblk0p1"
elif [ -e /dev/vda ]
then
	BOOTMEDIA="/media/vda1"
	BOOTDEV="/dev/vda1"
else
  echo "Unsupported drive"
  exit 1
fi

read -r VERSION < "${BOOTMEDIA}/myMPDos.version"
[ "$VERSION" = "" ] && exit 1

TMPDIR=$(mktemp -d)
cd $TMPDIR || exit 1

download() {
  [ "$CHANNEL" = "" ] && CHANNEL="master"
  URI="https://raw.githubusercontent.com/jcorporation/myMPDos/$CHANNEL/updates/${VERSION}"

  if wget -q "$URI/update.sha256" -O "$TMPDIR/update.sha256" 2>/dev/null && \
     wget -q "$URI/update.tar.gz" -O "$TMPDIR/update.tar.gz" 2>/dev/null
  then
    echo -n "  - Checking signature "
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
  cd update || return 1
  chmod +x update.sh
  if eval ./update.sh
  then
    read -r NEWVERSION < myMPDos.version
    echo "  - Setting version to $NEWVERSION"
    mount -oremount,rw "${BOOTDEV}"
    cp myMPDos.version "${BOOTMEDIA}/myMPDos.version"
    mount -oremount,ro "${BOOTDEV}"
    echo "Update finished"
    return 0
  else
    echo "Update failed"
    return 1
  fi
}

echo "Starting myMPDos update"
echo "  - Current version: $VERSION"
echo "  - Checking for update"
if download
then
  if do_update
  then
    echo "  - Saving changes"
    lbu_commit
  fi
else
  echo "  - No update found"
  echo ""
  echo "Updating apks"
  apk update
  apk upgrade
fi

cd /
rm -fr "$TMPDIR"

echo "Syncing apk cache"
apk cache -v sync

exit 0
