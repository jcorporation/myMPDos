#!/bin/sh

#export V_MAJOR=3
#export V_MINOR=14
#export V_POINT=1
#export CHECKSUM=376627f9f44142198a26123544c6505cf126b84199697fe436f6603de0b466a7
#alpine-upgrade.sh

echo "Trusting myMPD CA"
cp /var/lib/mympd/ssl/ca.pem /etc/ssl/certs/mympd.pem
update-ca-certificates
