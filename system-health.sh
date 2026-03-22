#!/bin/bash
# System Resource Monitor - DevOps Week 2 Project
# Author: Your Name
# Date: February 2026

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Clear screen for fresh output
clear

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    SYSTEM HEALTH DASHBOARD            ${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo "Uptime: $(uptime -p)"
echo -e "Load Average: $(uptime | awk -F'load average:' '{print $2}')\n"

# Memory Usage
echo -e "${YELLOW}--- MEMORY USAGE ---${NC}"
free -h | grep -E "^(Mem|Swap)"
echo ""

# Disk Usage
echo -e "${YELLOW}--- DISK USAGE ---${NC}"
df -h | grep -E "^/dev/" | while read line; do
    usage=$(echo $line | awk '{print $5}' | sed 's/%//')
    if [ $usage -gt 80 ]; then
        echo -e "${RED}WARNING: $line${NC}"
    else
        echo "$line"
    fi
done
echo ""

# Top Processes
echo -e "${YELLOW}--- TOP 5 CPU PROCESSES ---${NC}"
ps aux --sort=-%cpu | head -6 | tail -5
echo ""

echo -e "${YELLOW}--- TOP 5 MEMORY PROCESSES ---${NC}"
ps aux --sort=-%mem | head -6 | tail -5
echo ""

# Service Status Check
echo -e "${YELLOW}--- CRITICAL SERVICES ---${NC}"
services=("ssh" "nginx" "systemd-journald")
for service in "${services[@]}"; do
    if systemctl is-active --quiet $service; then
        echo -e "${GREEN}✓ $service is running${NC}"
    else
        echo -e "${RED}✗ $service is NOT running${NC}"
    fi
done
echo ""

echo -e "${BLUE}========================================${NC}"