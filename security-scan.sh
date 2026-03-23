#!/bin/bash
# Security Log Analyzer - DevOps Week 3 Project
# Author: happycuzitsme
# Date: March 2026

LOG_FILE="/var/log/auth.log"
REPORT_FILE="$HOME/security-report-$(date +%Y%m%d).txt"
ALERT_EMAIL="your@email.com"  # Optional

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    SECURITY LOG ANALYZER              ${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Scanning logs from: $LOG_FILE"
echo "Report will be saved to: $REPORT_FILE"
echo ""

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo -e "${RED}Error: Log file not found!${NC}"
    echo "Trying journalctl instead..."
    
    # Use journalctl for systems without auth.log (like WSL)
    journalctl --since "24 hours ago" > /tmp/journallog.txt
    LOG_FILE="/tmp/journallog.txt"
fi

# Initialize report
echo "Security Report - $(date)" > $REPORT_FILE
echo "================================" >> $REPORT_FILE

# 1. Failed SSH logins
echo -e "${YELLOW}[*] Checking failed login attempts...${NC}"
FAILED=$(grep -i "Failed password" $LOG_FILE | wc -l)
echo "Failed SSH attempts (last 24h): $FAILED" >> $REPORT_FILE

if [ $FAILED -gt 10 ]; then
    echo -e "${RED}WARNING: High number of failed logins!${NC}"
    echo "WARNING: Possible brute force attack!" >> $REPORT_FILE
    
    # Show top attacking IPs
    echo "" >> $REPORT_FILE
    echo "Top attacking IPs:" >> $REPORT_FILE
    grep -i "Failed password" $LOG_FILE | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr | head -5 >> $REPORT_FILE
fi

# 2. Successful logins
echo -e "${YELLOW}[*] Checking successful logins...${NC}"
SUCCESS=$(grep -i "Accepted password" $LOG_FILE | wc -l)
echo "Successful logins: $SUCCESS" >> $REPORT_FILE

if [ $SUCCESS -gt 0 ]; then
    echo "" >> $REPORT_FILE
    echo "Login details:" >> $REPORT_FILE
    grep -i "Accepted password" $LOG_FILE | tail -5 >> $REPORT_FILE
fi

# 3. Service restarts
echo -e "${YELLOW}[*] Checking service restarts...${NC}"
RESTARTS=$(grep -i "Started\|Stopped" $LOG_FILE | grep -i "nginx\|ssh\|systemd" | wc -l)
echo "Service restarts detected: $RESTARTS" >> $REPORT_FILE

# 4. Sudo usage
echo -e "${YELLOW}[*] Checking sudo commands...${NC}"
SUDO=$(grep -i "sudo:" $LOG_FILE | grep -i "COMMAND" | wc -l)
echo "Sudo commands executed: $SUDO" >> $REPORT_FILE

if [ $SUDO -gt 0 ]; then
    echo "" >> $REPORT_FILE
    echo "Recent sudo commands:" >> $REPORT_FILE
    grep -i "sudo:" $LOG_FILE | grep -i "COMMAND" | tail -5 >> $REPORT_FILE
fi

# 5. Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SCAN COMPLETE${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Failed attempts: $FAILED"
echo "Successful logins: $SUCCESS"
echo "Service restarts: $RESTARTS"
echo "Sudo commands: $SUDO"
echo ""
echo "Full report saved to: $REPORT_FILE"

# Optional: Email alert if critical
if [ $FAILED -gt 50 ]; then
    echo -e "${RED}CRITICAL: High attack volume detected!${NC}"
    # Uncomment if you have mailutils installed
    # mail -s "ALERT: High failed logins on $(hostname)" $ALERT_EMAIL < $REPORT_FILE
fi

# Cleanup
if [ -f "/tmp/journallog.txt" ]; then
    rm /tmp/journallog.txt
fi