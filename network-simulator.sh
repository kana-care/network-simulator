#!/bin/bash
# network_simulator.sh - Network Quality Simulation Script
# Usage: ./network_simulator.sh

# Startup level (0-5)
# 0 = disabled, 1-5 = quality levels
# Set to 0 to start with normal network conditions
STARTUP_LEVEL=3

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIG_DIR="./config"

# Network interface (change if needed)
INTERFACE="wlan0"

# Function to display header
show_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Network Quality Simulator${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

# Function to load level configuration
load_level_config() {
    local level=$1
    local config_file="$CONFIG_DIR/level_${level}.conf"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}✗ Configuration file not found: $config_file${NC}"
        return 1
    fi
    
    # Source the configuration file
    source "$config_file"
    echo -e "${GREEN}✓ Loaded level $level configuration from $config_file${NC}"
    return 0
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
    
    echo ""
    echo -e "${BLUE}Applied Network Quality Level $level on $INTERFACE:${NC}"
    echo -e "${YELLOW}┌─────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│ Network Parameters                      │${NC}"
    echo -e "${YELLOW}├─────────────────────────────────────────┤${NC}"
    printf "${YELLOW}│${NC} %-20s: %s\n" "Interface" "$INTERFACE"
    printf "${YELLOW}│${NC} %-20s: %s\n" "Base Delay" "${DELAY_BASE}ms"
    printf "${YELLOW}│${NC} %-20s: ±%s\n" "Jitter" "${DELAY_JITTER}ms"
    printf "${YELLOW}│${NC} %-20s: %s%%\n" "Delay Correlation" "$DELAY_CORRELATION"
    printf "${YELLOW}│${NC} %-20s: %s%% (corr: %s%%)\n" "Packet Loss" "$LOSS_PERCENTAGE" "$LOSS_CORRELATION"
    printf "${YELLOW}│${NC} %-20s: %s%%\n" "Corruption" "$CORRUPT_PERCENTAGE"
    printf "${YELLOW}│${NC} %-20s: %s%%\n" "Duplication" "$DUPLICATE_PERCENTAGE"
    printf "${YELLOW}│${NC} %-20s: every %s pkts, %s%% chance (corr: %s%%)\n" "Reordering" "$REORDER_GAP" "$REORDER_CHANCE" "$REORDER_CORRELATION"
    printf "${YELLOW}│${NC} %-20s: %s\n" "Bandwidth Limit" "$BANDWIDTH_LIMIT"
    echo -e "${YELLOW}└─────────────────────────────────────────┘${NC}"
}

# Function to apply network configuration
apply_config() {
    local level=$1
    
    # Load configuration for this level
    if ! load_level_config $level; then
        return 1
    fi
    
    # Clean up existing rules
    cleanup_tc
    
    if [ "$level" -eq 0 ]; then
        echo -e "${GREEN}✓ Network simulation disabled. Normal network conditions restored.${NC}"
        return 0
    fi

    # Apply netem qdisc with network impairments
    tc qdisc add dev $INTERFACE root handle 1: netem \
        delay ${DELAY_BASE}ms ${DELAY_JITTER}ms ${DELAY_CORRELATION}% distribution normal \
        loss ${LOSS_PERCENTAGE}% ${LOSS_CORRELATION}% \
        corrupt ${CORRUPT_PERCENTAGE}% \
        duplicate ${DUPLICATE_PERCENTAGE}% \
        reorder ${REORDER_CHANCE}% ${REORDER_CORRELATION}% gap ${REORDER_GAP}

    # Add bandwidth limitation if specified
    if [ "$BANDWIDTH_LIMIT" != "unlimited" ]; then
        # Calculate burst size
        local rate_num=$(echo $BANDWIDTH_LIMIT | sed 's/[^0-9]//g')
        local burst_size=$((rate_num * 1024 / 8))
        if [ $burst_size -lt 32768 ]; then
            burst_size=32768
        fi
        local burst="${burst_size}bit"
        
        # Calculate latency based on delay
        local tbf_latency=$((DELAY_BASE + DELAY_JITTER))
        if [ $tbf_latency -lt 100 ]; then
            tbf_latency=100
        fi

        tc qdisc add dev $INTERFACE parent 1:1 handle 10: tbf \
            rate $BANDWIDTH_LIMIT burst $burst latency ${tbf_latency}ms
    fi

    # Display applied parameters
    show_parameters $level

    echo ""
    echo -e "${GREEN}✓ Network quality level $level applied successfully!${NC}"
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

    show_header

    # If STARTUP_LEVEL is set and not 0, apply it automatically
    if [ -n "$STARTUP_LEVEL" ] && [ "$STARTUP_LEVEL" -ne 0 ]; then
        echo -e "${BLUE}Auto-applying startup level: $STARTUP_LEVEL${NC}"
        apply_config $STARTUP_LEVEL
        echo ""
    fi

    while true; do
        show_menu
        read -r choice

        case $choice in
            0|1|2|3|4|5)
                apply_config $choice
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
