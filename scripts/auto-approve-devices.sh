#!/bin/bash

# Auto-approve script for Clawbot devices
# Runs in background and automatically approves pending device pairing requests

GATEWAY_TOKEN="${CLAWDBOT_GATEWAY_TOKEN:-bde20abfdccc69caa4ac880b1f1c5a5d6cda2c1c87cc6159}"
CHECK_INTERVAL=5  # seconds

echo "[$(date)] Starting auto-approval service..."

while true; do
    # Get pending devices
    PENDING=$(docker exec clawbot_gateway sh -c "CLAWDBOT_GATEWAY_TOKEN=$GATEWAY_TOKEN clawdbot devices list 2>/dev/null" | grep -A 10 "Pending" | grep -E "^│ [a-f0-9-]{36}" | awk '{print $2}')
    
    if [ -n "$PENDING" ]; then
        for REQUEST_ID in $PENDING; do
            echo "[$(date)] Auto-approving device request: $REQUEST_ID"
            docker exec clawbot_gateway sh -c "CLAWDBOT_GATEWAY_TOKEN=$GATEWAY_TOKEN clawdbot devices approve $REQUEST_ID" 2>&1 | grep "Approved"
        done
    fi
    
    sleep $CHECK_INTERVAL
done
