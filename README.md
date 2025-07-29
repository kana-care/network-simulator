# Wifi hotspot with network quality control

## Features
- Use a Raspberry Pi (or similar device) to create a WiFi hotspot
- The hotspot uses the network from the ethernet port input
- Network "simulator" to simulate bad network quality, such as:
  - Latency (high ping)
  - Variable latency
  - Dropped packages
  - Corrupt packages
  - Limited bandwidth
- Network quality levels go from 0 (off) to 5 (barely usable)
- Simulator starts when Pi is booted up
- No configuration required after initial setup

## Setup
1. (optional) run create-configs.sh if the configs are not present or corrupt
2. run install.sh
3. enter Wifi SSID and password
4. (optional) set the network quality level when the device boots in `startup.conf`

## Roadmap
- [x] Create hotspot
- [x] Simulate bad network quality on different levels
- [x] Start network quality on boot
- [x] Configuration of network quality settings can be done without having to edit bash script
- [x] Edited configuration is stored and can be loaded without having to restart script
- [x] Able to set network quality level on boot
- [ ] Frontend