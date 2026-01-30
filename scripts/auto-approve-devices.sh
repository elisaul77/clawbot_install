#!/bin/bash

# Auto-approve script for Clawbot devices
# Runs in background and automatically approves pending device pairing requests

# Token must be provided via environment variable from docker-compose
if [ -z "$CLAWDBOT_GATEWAY_TOKEN" ]; then
    echo "[$(date)] ERROR: CLAWDBOT_GATEWAY_TOKEN environment variable not set"
    exit 1
fi

CHECK_INTERVAL=5  # seconds

echo "[$(date)] Starting auto-approval service..."

while true; do
    # Get pending devices
    PENDING=$(docker exec clawbot_gateway sh -c "CLAWDBOT_GATEWAY_TOKEN=$CLAWDBOT_GATEWAY_TOKEN clawdbot devices list 2>/dev/null" | grep -A 10 "Pending" | grep -E "^│ [a-f0-9-]{36}" | awk '{print $2}')
    
    if [ -n "$PENDING" ]; then
        for REQUEST_ID in $PENDING; do
            echo "[$(date)] Auto-approving device request: $REQUEST_ID"
            docker exec clawbot_gateway sh -c "CLAWDBOT_GATEWAY_TOKEN=$CLAWDBOT_GATEWAY_TOKEN clawdbot devices approve $REQUEST_ID" 2>&1 | grep "Approved"
        done
    fi
    
    sleep $CHECK_INTERVAL
done
