#!/bin/sh

export V_MAJOR=3
export V_MINOR=19
export V_POINT=1
export CHECKSUM=e277d6f474e2f8e503257fb1d0b8c5a32874081629e291ab8a1cc6142d8a881c
alpine-upgrade.sh

echo "Trusting myMPD CA"
cp /var/lib/mympd/ssl/ca.pem /etc/ssl/certs/mympd.pem
update-ca-certificates
