#!/bin/sh

KEY="../../keys/.abuild/mail@jcgames.de.rsa"
ACTION="$1"
FROM="$2"
TO="$3"

skel() {
  mkdir -p "$FROM"/update
  cat > "$FROM/update/update.sh" << EOL
#!/bin/sh

#export V_MAJOR=3
#export V_MINOR=14
#export V_POINT=1
#export CHECKSUM=376627f9f44142198a26123544c6505cf126b84199697fe436f6603de0b466a7
#alpine-upgrade.sh
EOL
  echo "$TO" > "$FROM/update/myMPDos.version"
}

package() {
  cd "$FROM" || exit 1
  find ./ -name \*~ -delete
  tar -czf "update.tar.gz" update
  openssl dgst -sha256 -sign "$KEY" -out "update.sig" "update.tar.gz"
  openssl base64 -in "update.sig" -out "update.sha256"
  rm "update.sig"
  exit 0
}

usage() {
  echo "Usage: (skel|package) <from version> <to version>"
}

if [ "$2" = "" ] || [ "$3" = "" ]
then
  usage
  exit 1
fi

case "$1" in
  skel)
    skel
  ;;
  package)
    package
  ;;
  *)
    usage
    exit 1
  ;;
esac
