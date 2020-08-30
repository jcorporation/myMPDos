#!/bin/sh

KEY="../../keys/.abuild/mail@jcgames.de.rsa"
ACTION="$1"
FROM="$2"
TO="$3"

skel() {
  mkdir -p "$FROM"/update
  echo "#!/bin/sh" > "$FROM/update/update.sh"
  echo "$TO" > "$FROM/update/myMPDos.version"
}

package() {
  cd "$FROM" || exit 1
  tar -czf "update.tar.gz" update
  openssl dgst -sha256 -sign "$KEY" -out "update.sig" "update.tar.gz"
  openssl base64 -in "update.sig" -out "update.sha256"
  rm "update.sig"
  exit 0
}

case "$1" in
  skel)
    skel
  ;;
  package)
    package
  ;;
  *)
    echo "Usage: (skel|package) <from version> <to version>"
    exit 1
  ;;
esac
