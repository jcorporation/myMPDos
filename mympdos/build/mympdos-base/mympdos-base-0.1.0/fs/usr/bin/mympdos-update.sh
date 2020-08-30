#!/bin/sh

read -r VERSION < "/boot/myMPDos.version"

check_signature() {
  if wget -q "https://jcgames.de/stuff/mympdos/update/update-${VERSION}.sha256" \
      -O "/tmp/update.sha256" 2>/dev/null
  then
    openssl base64 -d -in /tmp/update.sha256 -out /tmp/update.sig
    openssl dgst -sha256 -verify /etc/apk/keys/mail@jcgames.de.rsa.pub \
      -signature /tmp/update.sig /tmp/update.sh
  fi
  return 1
}

echo "Starting myMPDos update"
echo "  - Current version: $VERSION"
echo "  - Checking for update"
if wget -q "https://jcgames.de/stuff/mympdos/updates/update-${VERSION}.sh" \
      -O "/tmp/update.sh" 2>/dev/null
then
  echo "  - Update found"
  echo "  - Checking signature"
  if check_signature
  then
    echo "  - Executing update script"
    chmod +x /tmp/update.sh
    /tmp/update.sh
    echo "  - Update finished"
    echo "  - Cleanup"
    rm -f /tmp/update.sha256
    rm -f /tmp/update.sig
    rm -f /tmp/update.sh
  fi
else
  echo "  - No update found"
fi
