#!/bin/bash

# Post-installation script
# Configures the gateway to trust the Nginx proxy

echo "⏳ Configurando gateway para confiar en el proxy..."

# Wait for gateway to be ready
sleep 10

# Check if gateway is running
if ! docker ps | grep -q clawbot_gateway; then
    echo "❌ Gateway no está corriendo. Inicia con: docker-compose up -d"
    exit 1
fi

# Check if jq is available in gateway container
if docker exec clawbot_gateway which jq > /dev/null 2>&1; then
    # Use jq to add trustedProxies
    docker exec clawbot_gateway sh -c '
        CONFIG_FILE="/home/clawbot/.clawdbot/clawdbot.json"
        if [ -f "$CONFIG_FILE" ]; then
            cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
            cat "$CONFIG_FILE" | jq ".gateway.trustedProxies = [\"172.22.0.9\", \"172.22.0.0/24\"]" > /tmp/clawdbot.json.tmp
            mv /tmp/clawdbot.json.tmp "$CONFIG_FILE"
            echo "✅ Configuración actualizada"
        fi
    '
else
    echo "⚠️  jq no disponible, aplicando configuración manual..."
    # Manual approach using sed
    docker exec clawbot_gateway sh -c '
        CONFIG_FILE="/home/clawbot/.clawdbot/clawdbot.json"
        if [ -f "$CONFIG_FILE" ]; then
            cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
            # Add trustedProxies after the gateway section
            sed -i "/\"gateway\": {/a\    \"trustedProxies\": [\"172.22.0.9\", \"172.22.0.0/24\"]," "$CONFIG_FILE"
            echo "✅ Configuración actualizada (método alternativo)"
        fi
    '
fi

# Restart gateway to apply changes
echo "♻️  Reiniciando gateway..."
docker restart clawbot_gateway

sleep 5

# Verify
if docker ps | grep -q "clawbot_gateway.*healthy"; then
    echo "✅ Gateway configurado correctamente y funcionando"
else
    echo "⚠️  Gateway reiniciado. Verifica el estado con: docker ps"
fi

echo ""
echo "🎉 Post-instalación completa. Ya puedes acceder al Gateway vía VPN."
