#!/bin/bash

SSID=""
PASSWORD=""

# Function to prompt for SSID
get_ssid() {
    while true; do
        echo -n "Enter WiFi Hotspot Name (SSID): "
        read -r SSID
        if [ -n "$SSID" ] && [ ${#SSID} -le 32 ]; then
            echo "SSID accepted: $SSID"
            return 0
        else
            echo "Invalid SSID. Please enter a non-empty SSID with up to 32 characters."
        fi
    done
}

# Function to prompt for password
get_password() {
    while true; do
        echo -n "Enter WiFi Hotspot Password (8-63 characters): "
        read -s PASSWORD
        echo
        if [ ${#PASSWORD} -ge 8 ] && [ ${#PASSWORD} -le 63 ]; then
            echo "Password accepted."
            return 0
        else
            echo "Invalid password. Please enter a password between 8 and 63 characters."
        fi
    done
}


if [[ $EUID -ne 0 ]]; then
	echo "script must be run as root"
	exit 1
fi

get_ssid
get_password

echo "setting up hotspot"

nmcli con add con-name hotspot ifname wlan0 type wifi ssid "$SSID"

echo "adding password"

nmcli con modify hotspot wifi-sec.key-mgmt wpa-psk
nmcli con modify hotspot wifi-sec.psk "$PASSWORD"

echo "setting hotspot in access point mode"

nmcli con modify hotspot 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared

echo "all set! edit the hotspot network settings via nmtui"

exit 0
