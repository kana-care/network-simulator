#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "This script requires sudo privileges."
    exit 1
fi

echo "setting up wifi hotspot..."

./wifi-hotspot-setup.sh

echo "starting network traffic control on boot..."

./start-on-boot.sh

echo "all set!"
