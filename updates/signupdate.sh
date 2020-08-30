#!/bin/sh

UPDATE_FILE=$1
KEY="../keys/mail@jcgames.de.rsa"
SIGN_FILE_SIG="$(basename "$UPDATE_FILE" .sh).sig"
SIGN_FILE="$(basename "$UPDATE_FILE" .sh).sha256"

openssl dgst -sha256 -sign "$KEY" -out "$SIGN_FILE_SIG" "$UPDATE_FILE"
openssl base64 -in "$SIGN_FILE_SIG" -out "$SIGN_FILE"
rm "$SIGN_FILE_SIG"
