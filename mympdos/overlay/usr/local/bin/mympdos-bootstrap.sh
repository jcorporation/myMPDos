#!/bin/sh
#
# SPDX-License-Identifier: GPL-3.0-or-later
# myMPDos (c) 2020-2024 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos
#

export BOOTSTRAP="true"
if [ -e /dev/mmcblk0 ]
then
    SDCARD="mmcblk0"
    BOOTPART="p1"
    DATAPART="p2"
elif [ -e /dev/vda ]
then
    SDCARD="vda"
    BOOTPART="1"
    DATAPART="2"
else
    echo "Unsupported drive"
    exit 1
fi

BOOTDEV="/dev/${SDCARD}${BOOTPART}"
BOOTMEDIA="/media/${SDCARD}${BOOTPART}"
DATADEV="/dev/${SDCARD}${DATAPART}"
DATAMEDIA="/media/${SDCARD}${DATAPART}"
LBUMEDIA="${SDCARD}${DATAPART}"
REBOOT=1
NETWORK_CHECK=1

read -r VERSION < "$BOOTMEDIA/myMPDos.version" || { echo "$BOOTMEDIA/myMPDos.version not found"; exit 1; }

echo ""
echo "myMPDos $VERSION bootstrap script"
echo ""

#Bootstrap configuration
MYMPDOS_REPOSITORY="https://raw.githubusercontent.com/jcorporation/myMPDos/master/repository"
IP_TYPE="dhcp"
WLAN_ENABLE="false"
WLAN_KEYMGMT="WPA-PSK"
IP_HOSTNAME="myMPDos"
MPD_VERSION="1"
KEYBOARD_LAYOUT="us"
KEYBOARD_VARIANT="us"
BT_ENABLE="false"
BT_INTERNAL="false"
ADVANCED_SOFTWARE="true"
TIMEZONE="UTC"
ENABLE_RNGD="true"
DISABLE_HDMI="false"
UPSAMPLING="false"
RESAMPLER="libsamplerate"
LIBSAMPLERATE_TYPE="0"
ENABLE_AUTOMOUNT="true"
ENABLE_CONFIGMPD="true"
ENABLE_MIXER="true"
SOFTWARE_MIXER_FALLBACK="false"
if [ -f "$BOOTMEDIA/bootstrap.txt" ]
then
    . "$BOOTMEDIA/bootstrap.txt"
else
    echo "No bootstrap.txt found, using defaults"
    WLAN_ENABLE="false"
fi

[ -z "$WLAN_SSID" ] && WLAN_ENABLE="false"

#Setup sdcard
wait_for_device()
{
    printf "Waiting for %s" "$1"
    #first check device exists and is a block device
    I=0
    while [ ! -b "$1" ]
    do
        printf "."
        I=$((I+1))
        sleep 1
        if [ "$I" = "10" ]
        then
            echo " timeout"
            return 1
        fi
    done
    I=0
    #Check if device has a filesystem
    if [ "$2" = "FS" ]
    then
        while [ "$(blkid "$1")" = "" ]
        do
            printf "."
            I=$((I+1))
            sleep 1
            if [ "$I" = "10" ]
            then
                echo " timeout"
                return 1
            fi
        done
    fi
    echo " found with $2"
    return 0
}

if [ ! -b "$DATADEV" ]
then
    #Unmount sd-card to avoid a extra reboot
    /etc/init.d/modloop stop
    umount "$BOOTDEV"
    echo "Creating data partition on sd card"
    fdisk "/dev/$SDCARD" <<-EOF
	n
	p
	2


	w

	EOF
    #wait for devices to appear
    if ! wait_for_device "$BOOTDEV" FS
    then
        echo "Rebooting"
        reboot
        exit 0
    fi
    I=0
    while ! mount -t vfat "$BOOTDEV" "$BOOTMEDIA" > /dev/null 2>&1
    do
        I=$((I+1))
        if [ "$I" = 10 ]
        then
            echo "Can not mount $BOOTDEV"
            exit 1
        fi
        sleep 1
    done
    /etc/init.d/modloop start
fi

if ! wait_for_device "$DATADEV" NOFS
then
    echo "Rebooting"
    reboot
    exit 0
elif [ "$(blkid "$DATADEV")" = "" ]
then
    echo "Formating data partition on sd card"
    apk add e2fsprogs
    mkfs.ext4 "$DATADEV"
fi

echo "Mounting data partition on sd card"
install -d "$DATAMEDIA"
if ! grep -q "$DATADEV" /etc/fstab
then
    echo "$DATADEV	$DATAMEDIA	ext4	noatime,ro,defaults 0 0" >> /etc/fstab
fi

if ! mount "$DATADEV"
then
    echo "Can not mount $DATADEV"
    exit 1
fi

echo ""
echo "Filesystem usage"
df -h
echo ""
echo "Mounts"
mount
echo ""

#setup networking
find_wlan_device()
{
    for DEV in /sys/class/net/*
    do
        if [ -e "${DEV}"/wireless ] || [ -e "${DEV}"/phy80211 ]
        then
            echo "${DEV##*/}"
        fi
    done
}

write_interfaces_dhcp()
{
    cat <<-EOF > /etc/network/interfaces
	auto lo
	iface lo inet loopback

	auto ${IFACE}
	iface ${IFACE} inet dhcp
		hostname myMPDos
	EOF
}

write_interfaces_static()
{
    cat <<-EOF > /etc/network/interfaces
	auto lo
	iface lo inet loopback

	auto ${IFACE}
	iface ${IFACE} inet static
		address $IP_ADDRESS
		netmask $IP_NETMASK
		gateway $IP_GATEWAY
		hostname $IP_HOSTNAME
	EOF
}

if [ "$WLAN_ENABLE" = "true" ]
then
    echo "Configuring wlan"
  IFACE=$(find_wlan_device)
    if [ "$IFACE" != "" ]
    then
        apk add wpa_supplicant
        cat <<-EOF > /etc/wpa_supplicant/wpa_supplicant.conf
		network={
			ssid="$WLAN_SSID"
			key_mgmt=$WLAN_KEYMGMT
			psk="$WLAN_PSK"
		}
		EOF
        rc-service wpa_supplicant start
        rc-update add wpa_supplicant boot
    else
        echo "No wlan device found, falling back to eth0"
        IFACE="eth0"
    fi
else
  echo "Configuring eth0"
  IFACE="eth0"
fi

if [ "$IP_TYPE" = "dhcp" ]
then
    write_interfaces_dhcp
else
    write_interfaces_static
fi

if [ "$IP_DNS_CONFIGURE" = "true" ]
then
    cp /dev/null /etc/resolv.conf
    [ "$IP_DNS_SEARCH" != "" ] && echo "search $IP_DNS_SEARCH" >> /etc/resolv.conf
    [ "$IP_DNS_DOMAIN" != "" ] && echo "domain $IP_DNS_DOMAIN" >> /etc/resolv.conf
    [ "${IP_DNS_SERVER1}${IP_DNS_SERVER2}" = "" ] && IP_DNS_SERVER1="$IP_GATEWAY"
    [ "$IP_DNS_SERVER1" != "" ] && echo "nameserver $IP_DNS_SERVER1" >> /etc/resolv.conf
    [ "$IP_DNS_SERVER2" != "" ] && echo "nameserver $IP_DNS_SERVER2" >> /etc/resolv.conf
fi

rc-service networking start
hostname "$IP_HOSTNAME"
echo "$IP_HOSTNAME" > /etc/hostname

if [ "$IP_TYPE" = "dhcp" ] && [ "$IP_COPY_DHCP_TO_STATIC" = "true" ]
then
    echo "Setting static ip address from dhcp"
    IP_ADDRESS=$(ifconfig "$IFACE" | grep -m 1 "inet addr" | sed -r 's/.*inet addr:(\S+)\s.*/\1/')
    IP_NETMASK=$(ifconfig "$IFACE" | grep -m 1 "inet addr" | sed -r 's/.*Mask:(\S+)/\1/')
    IP_GATEWAY=$(route -n | grep -m 1 "^0.0.0.0" | sed -r 's/0\.0\.0\.0\s+(\S+)\s.*/\1/')
    if [ "$IP_ADDRESS" != "" ] && [ "$IP_NETMASK" != "" ] && [ "$IP_GATEWAY" != "" ]
    then
        write_interfaces_static
        rc-service networking restart
    fi
    #check
    NIP_ADDRESS=$(ifconfig "$IFACE" | grep -m 1 "inet addr" | sed -r 's/.*inet addr:(\S+)\s.*/\1/')
    NIP_NETMASK=$(ifconfig "$IFACE" | grep -m 1 "inet addr" | sed -r 's/.*Mask:(\S+)/\1/')
    NIP_GATEWAY=$(route -n | grep -m 1 "^0.0.0.0" | sed -r 's/0\.0\.0\.0\s+(\S+)\s.*/\1/')
    if [ "$IP_ADDRESS" != "$NIP_ADDRESS" ] || [ "$IP_NETMASK" != "$NIP_NETMASK" ] || [ "$IP_GATEWAY" != "$NIP_GATEWAY" ]
    then
        echo "Setting static ip address failed, reverting to dhcp"
        cat /etc/network/interfaces
        write_interfaces_dhcp
        rc-service networking restart
    fi
fi

if [ "$NETWORK_CHECK" -eq 1 ]
then
    printf "Checking network connectivity"
    I=0
    while ! wget dl-cdn.alpinelinux.org > /dev/null 2>&1
    do
        printf "."
        I=$((I+1))
        if [ "$I" = "15" ]
        then
            echo "ERROR"
            exit 1
        fi
        sleep 2
    done
    echo "OK"
fi

printf "Setup NTP"
I=0
while ! ntpd -n -q -p pool.ntp.org > /dev/null 2>&1
do
    printf "."
    I=$((I+1))
    [ "$I" = "5" ] && break;
done
echo ""
setup-ntp -c busybox
[ "$TIMEZONE" != "" ] && setup-timezone -z "$TIMEZONE"

echo "Setup OpenSSH"
setup-sshd -c openssh
echo "Enabling ssh root login"
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
service sshd restart

echo "Setting keymap to ${KEYBOARD_LAYOUT} ${KEYBOARD_VARIANT}"
apk add kbd-bkeymaps
if [ -f "/usr/share/bkeymaps/${KEYBOARD_LAYOUT}/${KEYBOARD_VARIANT}.bmap.gz" ]
then
    setup-keymap "$KEYBOARD_LAYOUT" "$KEYBOARD_VARIANT"
else
    echo "Invalid keyboard layout or variant configured."
    exit 1
fi
apk del kbd-bkeymaps

echo "Setting up apk cache"
setup-apkcache "$DATAMEDIA/apkcache"

echo "Adding repositories and upgrade"
echo "${BOOTMEDIA}/apks" > /etc/apk/repositories
setup-apkrepos -c -1
while apk update 2>&1 | grep WARNING
do
    echo "Error...trying new random repository"
    echo "${BOOTMEDIA}/apks" > /etc/apk/repositories
    setup-apkrepos -c -r
done

echo "$MYMPDOS_REPOSITORY" >> /etc/apk/repositories

echo "Adding myMPDos archiv signing public key"
cp "$BOOTMEDIA"/mympdos-apk-keys/*.rsa.pub /etc/apk/keys/

echo "Upgrading all packages"
apk update
apk upgrade

PKGLIST_ADV="usbutils raspberrypi busybox-extras net-tools mpg123 mympdos-libgpiod2 mygpiod"
PKGLIST="mympdos-base mympd mympdos-libmpdclient mympdos-mpc doas alsa-utils"
[ "$BT_ENABLE" = "true" ] && PKGLIST="$PKGLIST bluez bluez-alsa"
[ "$ENABLE_RNGD" = "true" ] && PKGLIST="$PKGLIST rng-tools"
[ "$ADVANCED_SOFTWARE" = "true" ] && PKGLIST="$PKGLIST $PKGLIST_ADV"
case "$MPD_VERSION" in
    1)
        PKGLIST="$PKGLIST mympdos-mpd-stable";;
    2)
        PKGLIST="$PKGLIST mympdos-mpd-master";;
    *)
        echo "Invalid MPD package configured";;
esac
echo "Installing packages: $PKGLIST"
apk add $PKGLIST

if [ "$EXTRA_SOFTWARE" != "" ]
then
    echo "Installing extra packages: $PKGLIST"
    apk add $EXTRA_SOFTWARE
fi

echo "Creating user and groups"
adduser mympd audio
addgroup -S mpd

echo "Creating files in data partition"
mount -oremount,rw "$DATAMEDIA"
install -d "$DATAMEDIA/library" -o mpd -g audio -m 775
ln -s /mnt "$DATAMEDIA/library/USB"
mount -oremount,ro "$DATAMEDIA"

echo "Installing myMPD scripts"
install -d /var/lib/mympd/scripts
cp -v /usr/local/defaults/mympd-scripts/*.lua /var/lib/mympd/scripts
chown -R mympd.mympd /var/lib/mympd/scripts

echo "Setting defaults"
install -d /var/lib/mpd/cache -o mpd -g mpd
cp /usr/local/defaults/etc/doas.conf /etc/doas.d/mympd.conf

if [ "$ENABLE_CONFIGMPD" = "true" ]
then
    echo "Enable automatic reconfiguration of MPD"
    sed -i -r 's/^SUBSYSTEM=sound.*/SUBSYSTEM=sound;\.\*    root:audio 0660 \*\/usr\/bin\/configmpd.sh/' /etc/mdev.conf 
fi
if [ "$ENABLE_AUTOMOUNT" = "true" ]
then
    echo "Enable automount"
    sed -i -r 's/^sd\[a-z\]\.\*.*/sd\[a-z\]\.\*    root:disk 0660 \*\/usr\/bin\/automount.sh/' /etc/mdev.conf
fi

# Set read permissions for all users for vcgencmd
cat >> /etc/mdev.conf << EOL

#vcgencmd
vcio            root:root 0664

EOL

echo "#myMPDos configuration file" > /etc/mympdos/mympdos.conf
echo "DISABLE_HDMI=\"$DISABLE_HDMI\"" >> /etc/mympdos/mympdos.conf
echo "RESAMPLER=\"$RESAMPLER\"" >> /etc/mympdos/mympdos.conf
echo "ENABLE_MIXER=\"$ENABLE_MIXER\"" >> /etc/mympdos/mympdos.conf
echo "SOFTWARE_MIXER_FALLBACK=\"$SOFTWARE_MIXER_FALLBACK\"" >> /etc/mympdos/mympdos.conf
if [ "$UPSAMPLING" = "true" ]
then
    echo "UPSAMPLING=\"true\"" >> /etc/mympdos/mympdos.conf
    echo "AUDIO_OUTPUT_FORMAT=\"$AUDIO_OUTPUT_FORMAT\"" >> /etc/mympdos/mympdos.conf
    echo "SAMPLERATE_CONVERTER=\"$SAMPLERATE_CONVERTER\"" >> /etc/mympdos/mympdos.conf
elif [ "$RESAMPLER" = "libsamplerate" ]
then
    echo "LIBSAMPLERATE_TYPE=\"$LIBSAMPLERATE_TYPE\"" >> /etc/mympdos/mympdos.conf
elif [ "$RESAMPLER" = "soxr" ]
then
    echo "SOXR_QUALITY=\"$SOXR_QUALITY\"" >> /etc/mympdos/mympdos.conf
    echo "SOXR_THREADS=\"$SOXR_THREADS\"" >> /etc/mympdos/mympdos.conf
fi

echo "Configuring MPD"
install -d /etc/mympdos/custom
[ -f "$BOOTMEDIA/mpd.replace" ] && cp "$BOOTMEDIA/mpd.replace" /etc/mympdos/custom/
[ -f "$BOOTMEDIA/mpd.conf" ] && cp "$BOOTMEDIA/mpd.conf" /etc/mympdos/custom/
[ -f "$BOOTMEDIA/mpd.custom.conf" ] && cp "$BOOTMEDIA/mpd.custom.conf" /etc/
/usr/bin/configmpd.sh

echo "Enabling boot services"
[ "$ENABLE_RNGD" = "true" ] && rc-update add rngd boot
rc-update add networking boot
rc-update add seedrng boot
rc-update add alsa boot
[ "$ENABLE_CRON" = "true" ] && rc-update add crond boot
if [ "$BT_ENABLE" = "true" ]
then
    rc-update add bluetooth boot
    rc-update add bluealsa boot
fi
if [ "$BT_INTERNAL" = "true" ]
then
    sed -i 's/^#ttyAMA0/ttyAMA0/' /etc/mdev.conf
fi

echo "Enabling default services"
rc-update add mpd default
rc-update add mympd default

if [ "$ROOT_PASSWORD" != "" ]
then
  echo "Setting root password"
  printf "%s\n%s\n" "$ROOT_PASSWORD" "$ROOT_PASSWORD" | passwd
fi

mount -o remount,rw "$BOOTMEDIA"

echo "Setting usercfg.txt"
echo "" >> "$BOOTMEDIA/usercfg.txt"
[ "$WLAN_ENABLE" = "false" ] && echo "dtoverlay=disable-wifi" >> "$BOOTMEDIA/usercfg.txt"
[ "$BT_INTERNAL" = "false" ] && echo "dtoverlay=disable-bt" >> "$BOOTMEDIA/usercfg.txt"
[ "$AUDIOHAT" != "" ] && echo "dtoverlay=$AUDIOHAT" >> "$BOOTMEDIA/usercfg.txt"

echo "Removing installation files"
rm "$BOOTMEDIA/mympdos-bootstrap.apkovl.tar.gz"
rm -f "$BOOTMEDIA/bootstrap.txt"
rm -f "$BOOTMEDIA/bootstrap-simple.txt"
rm -f "$BOOTMEDIA/bootstrap-advanced.txt"
rm -f "$BOOTMEDIA/mpd.replace"
rm -f "$BOOTMEDIA/mpd.conf"
rm -f "$BOOTMEDIA/mpd.custom.conf"

mount -o remount,ro "$BOOTMEDIA"

if [ "$WLAN_ENABLE" = "false" ]
then
    echo "Removing wlan packages"
    apk del wpa_supplicant wpa_supplicant-openrc dbus-libs
fi

echo "Removing obsolet users and groups"
for DU in lp mail postmaster ftp at squid xfs games cyrus vpopmail smmsp guest news operator
do
    deluser "$DU" > /dev/null 2>&1
done
for DG in mail tape
do
    delgroup "$DG" > /dev/null 2>&1
done

echo "Cleaning up"
sed -i -r 's/tty(2|3|4|5|6)/#tty\1/' /etc/inittab
rm /etc/local.d/mympdos-bootstrap.start
for DIR in /usr/local/defaults /etc/logrotate.d /etc/openldap /etc/pkcs11 /etc/acpi /etc/sasl2 \
    /etc/dbus-1 /etc/opt /media/cdrom /media/floppy /media/usb
do
    rm -rf "$DIR"
done

echo "Create myMPD configuration"
export MYMPD_ACL
export MYMPD_ALBUM_GROUP_TAG
export MYMPD_ALBUM_MODE
export MYMPD_COVERCACHE_KEEP_DAYS
export MYMPD_HTTP
export MYMPD_HTTP_HOST
export MYMPD_HTTP_PORT
export MYMPD_LOGLEVEL
export MYMPD_LUALIBS
export MYMPD_URI
export MYMPD_SAVE_CACHES
export MYMPD_SCRIPTACL
export MYMPD_STICKERS
export MYMPD_SSL
export MYMPD_SSL_PORT
export MYMPD_SSL_SAN
export MYMPD_CUSTOM_CERT
export MYMPD_SSL_CERT
export MYMPD_SSL_KEY
mympd -c

echo "Trusting myMPD CA"
cp /var/lib/mympd/ssl/ca.pem /etc/ssl/certs/mympd.pem
update-ca-certificates

echo "Setting swclock"
install -d /var/lib/misc/
touch /var/lib/misc/openrc-shutdowntime

echo "Saving configuration"
echo "LBU_MEDIA=$LBUMEDIA" > /etc/lbu/lbu.conf
LBU_INCLUDES="/var/lib/mympd /var/lib/mpd /var/lib/alsa /var/lib/misc/openrc-shutdowntime"
for INCLUDE in $LBU_INCLUDES
do
    lbu_include "$INCLUDE"
done
if [ "$BT_ENABLE" = "true" ]
then
    lbu include /var/lib/bluetooth
fi
alsactl store
lbu_commit -v
