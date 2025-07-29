#!/bin/bash

SSID="my-wifi-name"
PASSWORD="supersecretpassword"

if [[ $EUID -ne 0 ]]; then
	echo "script must be run as root"
	exit 1
fi

echo "setting up hotspot"

nmcli con add con-name hotspot ifname wlan0 type wifi ssid "$SSID"

echo "adding password"

nmcli con modify hotspot wifi-sec.key-mgmt wpa-psk
nmcli con modify hotspot wifi-sec.psk "$PASSWORD"

echo "setting hotspot in access point mode"

nmcli con modify hotspot 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared

echo "all set! edit the hotspot network settings via nmtui"

exit 0
