#!/bin/bash

# Quick troubleshooting script for Clawbot installation
# Usage: ./diagnose.sh

echo "=== Clawbot Diagnostics ==="
echo ""

# Check if services are running
echo "1. Checking Docker services..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "clawbot|NAME"
echo ""

# Check VPN connectivity
echo "2. VPN Status..."
if docker exec clawbot_vpn wg show 2>/dev/null; then
    echo "✅ VPN is running"
else
    echo "❌ VPN is not running or not configured"
fi
echo ""

# Check Gateway logs for errors
echo "3. Gateway recent logs (last 20 lines)..."
docker logs --tail 20 clawbot_gateway 2>&1 | grep -E "error|Error|ERROR|warn|Warn|WARN|pairing"
echo ""

# Check Nginx logs for errors
echo "4. Proxy recent logs (last 10 lines)..."
docker logs --tail 10 clawbot_proxy 2>&1 | grep -E "error|Error|ERROR"
echo ""

# Check network connectivity
echo "5. Network connectivity..."
docker exec clawbot_gateway ping -c 2 172.22.0.9 >/dev/null 2>&1 && echo "✅ Gateway can reach Proxy" || echo "❌ Gateway cannot reach Proxy"
echo ""

# Check if ports are open
echo "6. Port status..."
nc -zv localhost 443 2>&1 | grep -q succeeded && echo "✅ Port 443 (HTTPS) is open" || echo "❌ Port 443 is closed"
nc -zv localhost 51820 2>&1 | grep -q succeeded && echo "✅ Port 51820 (VPN) is open" || echo "❌ Port 51820 is closed"
nc -zv localhost 51821 2>&1 | grep -q succeeded && echo "✅ Port 51821 (VPN Admin) is open" || echo "❌ Port 51821 is closed"
echo ""

# Check configuration files
echo "7. Configuration validation..."
[ -f .env ] && echo "✅ .env exists" || echo "❌ .env missing"
[ -f config/clawdbot.json ] && echo "✅ clawdbot.json exists" || echo "❌ clawdbot.json missing"
[ -f config/nginx.conf ] && echo "✅ nginx.conf exists" || echo "❌ nginx.conf missing"
echo ""

echo "=== Diagnostics Complete ==="
echo ""
echo "Common fixes:"
echo "  - Service not running: docker-compose up -d"
echo "  - See full logs: docker logs -f clawbot_gateway"
echo "  - Restart all: docker-compose restart"
