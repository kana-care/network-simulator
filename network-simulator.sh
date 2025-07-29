#!/bin/bash
# network_simulator.sh - Network Quality Simulation Script
# Usage: ./network_simulator.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Network interface (change if needed)
INTERFACE="wlan0"

# Function to display header
show_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Network Quality Simulator${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

# Function to display menu
show_menu() {
    echo -e "${YELLOW}Select network quality level:${NC}"
    echo "0 - Disable network throttling (normal network)"
    echo "1 - Acceptable network quality"
    echo "2 - Reduced network quality"
    echo "3 - Bad network quality"
    echo "4 - Terrible network quality"
    echo "5 - Is this network even usable?"
    echo ""
    echo -n "Enter your choice (0-5): "
}

# Function to remove existing tc rules
cleanup_tc() {
    sudo tc qdisc del dev $INTERFACE root 2>/dev/null || true
    echo -e "${GREEN}✓ All tc rules removed from $INTERFACE${NC}"
}

# Function to display current parameters
show_parameters() {
    local level=$1
    local delay_base=$2
    local delay_jitter=$3
    local delay_corr=$4
    local loss_pct=$5
    local loss_corr=$6
    local corrupt_pct=$7
    local duplicate_pct=$8
    local reorder_gap=$9
    local reorder_chance=${10}
    local reorder_corr=${11}
    local bandwidth=${12}

    echo ""
    echo -e "${BLUE}Applied Network Quality Level $level:${NC}"
    echo -e "${YELLOW}┌─────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│ Network Parameters                      │${NC}"
    echo -e "${YELLOW}├─────────────────────────────────────────┤${NC}"
    printf "${YELLOW}│${NC} %-20s: %s\n" "Base Delay" "${delay_base}ms"
    printf "${YELLOW}│${NC} %-20s: ±%s\n" "Jitter" "${delay_jitter}ms"
    printf "${YELLOW}│${NC} %-20s: %s%%\n" "Delay Correlation" "$delay_corr"
    printf "${YELLOW}│${NC} %-20s: %s%% (corr: %s%%)\n" "Packet Loss" "$loss_pct" "$loss_corr"
    printf "${YELLOW}│${NC} %-20s: %s%%\n" "Corruption" "$corrupt_pct"
    printf "${YELLOW}│${NC} %-20s: %s%%\n" "Duplication" "$duplicate_pct"
    printf "${YELLOW}│${NC} %-20s: every %s pkts, %s%% chance (corr: %s%%)\n" "Reordering" "$reorder_gap" "$reorder_chance" "$reorder_corr"
    printf "${YELLOW}│${NC} %-20s: %s\n" "Bandwidth Limit" "$bandwidth"
    echo -e "${YELLOW}└─────────────────────────────────────────┘${NC}"
}

# Function to apply network configuration
apply_config() {
    local level=$1
    local delay_base=$2
    local delay_jitter=$3
    local delay_corr=$4
    local loss_pct=$5
    local loss_corr=$6
    local corrupt_pct=$7
    local duplicate_pct=$8
    local reorder_gap=$9
    local reorder_chance=${10}
    local reorder_corr=${11}
    local bandwidth=${12}

    # Clean up existing rules
    cleanup_tc

    # Apply netem qdisc with network impairments
    sudo tc qdisc add dev $INTERFACE root handle 1: netem \
        delay ${delay_base}ms ${delay_jitter}ms ${delay_corr}% distribution normal \
        loss ${loss_pct}% ${loss_corr}% \
        corrupt ${corrupt_pct}% \
        duplicate ${duplicate_pct}% \
        reorder ${reorder_chance}% ${reorder_corr}% gap ${reorder_gap}

    # Add bandwidth limitation if specified
    if [ "$bandwidth" != "unlimited" ]; then
        # Calculate burst size (typically 1/8 of rate or minimum 32kbit)
        local rate_num=$(echo $bandwidth | sed 's/[^0-9]//g')
        local burst_size=$((rate_num * 1024 / 8))
        if [ $burst_size -lt 32768 ]; then
            burst_size=32768
        fi
        local burst="${burst_size}bit"

        # Calculate latency based on delay
        local tbf_latency=$((delay_base + delay_jitter))
        if [ $tbf_latency -lt 100 ]; then
            tbf_latency=100
        fi

        sudo tc qdisc add dev $INTERFACE parent 1:1 handle 10: tbf \
            rate $bandwidth burst $burst latency ${tbf_latency}ms
    fi

    # Display applied parameters
    show_parameters $level $delay_base $delay_jitter $delay_corr $loss_pct $loss_corr \
                   $corrupt_pct $duplicate_pct $reorder_gap $reorder_chance $reorder_corr $bandwidth

    echo ""
    echo -e "${GREEN}✓ Network quality level $level applied successfully!${NC}"
}

# numbers represent
# 1:   level
# 2-4: ping	base, jitter, correlation
# 5-6: loss	percentage, correlation
# 7:   corrupt	percentage
# 8:   clone	percentage
# 9-11 reorder	gap, chance, correlation
# 12   bandwidth
# Function to configure Level 1 - Slightly reduced quality
config_level_1() {
    apply_config 1 50 20 15 0.1 10 0.01 0.1 10 0.5 25 "50mbit"
}

# Function to configure Level 2 - Quite bad quality
config_level_2() {
    apply_config 2 150 50 20 0.5 15 0.05 0.3 8 1 30 "20mbit"
}

# Function to configure Level 3 - Bad quality
config_level_3() {
    apply_config 3 300 100 25 1.5 20 0.1 0.5 6 2 35 "10mbit"
}

# Function to configure Level 4 - Terrible quality
config_level_4() {
    apply_config 4 500 200 30 3 25 0.2 1 5 3 40 "5mbit"
}

# Function to configure Level 5 - Almost not usable
config_level_5() {
    apply_config 5 800 400 35 5 30 0.5 2 4 5 50 "2mbit"
}

# Function to show current tc status
show_status() {
    echo ""
    echo -e "${BLUE}Current tc configuration on $INTERFACE:${NC}"
    tc qdisc show dev $INTERFACE
    echo ""
    echo -e "${BLUE}Detailed statistics:${NC}"
    tc -s qdisc show dev $INTERFACE
}

# Main script execution
main() {
    # Check if running as root for tc commands
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Error: This script requires sudo privileges to modify tc rules.${NC}"
        echo "Please run with: sudo $0"
        exit 1
    fi

    config_level_2

    show_header

    while true; do
        show_menu
        read -r choice

        case $choice in
            0)
                cleanup_tc
                echo ""
                echo -e "${GREEN}✓ Network simulation disabled. Normal network conditions restored.${NC}"
                ;;
            1)
                config_level_1
                ;;
            2)
                config_level_2
                ;;
            3)
                config_level_3
                ;;
            4)
                config_level_4
                ;;
            5)
                config_level_5
                ;;
            "status"|"s")
                show_status
                ;;
            "quit"|"q"|"exit")
                echo -e "${GREEN}Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter 0-5.${NC}"
                ;;
        esac

        echo ""
        echo -e "${BLUE}Additional commands: 'status' (show current config), and 'quit' (exit)${NC}"
        echo ""
    done
}

# Run the main function
main "$@"
