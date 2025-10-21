#!/bin/sh

echo "Fixing myMPD permissions"
chown -R mympd:mympd /var/lib/mympd
chown -R mympd:mympd /var/cache/mympd
