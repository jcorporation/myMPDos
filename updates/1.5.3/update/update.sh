#!/bin/sh

# Set read permissions for all users for vcgencmd
cat >> /etc/mdev.conf << EOL

#vcgencmd
vcio            root:root 0664

EOL
