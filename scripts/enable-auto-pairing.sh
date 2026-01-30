#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Habilitando Auto-Aprobación de Dispositivos ===${NC}"
echo ""

CONFIG_FILE="../data/clawbot_home/.clawdbot/clawdbot.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: No se encontró el archivo de configuración.${NC}"
    echo "Ejecuta primero: ./scripts/onboard.sh"
    exit 1
fi

echo -e "${YELLOW}Configurando modo de emparejamiento automático...${NC}"

# Usar jq si está disponible, sino usar sed
if command -v jq &> /dev/null; then
    # Método con jq (más seguro)
    jq '.gateway.pairing.mode = "auto"' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
else
    # Método con sed (backup)
    if grep -q '"pairing"' "$CONFIG_FILE"; then
        sed -i 's/"mode": "manual"/"mode": "auto"/g' "$CONFIG_FILE"
    else
        # Insertar la configuración de pairing después de "port"
        sed -i '/"port": [0-9]*,/a\    "pairing": {\n      "mode": "auto"\n    },' "$CONFIG_FILE"
    fi
fi

echo -e "${GREEN}✅ Auto-aprobación habilitada.${NC}"
echo ""
echo -e "${YELLOW}NOTA DE SEGURIDAD:${NC}"
echo "  - Los dispositivos ahora se aprobarán automáticamente"
echo "  - Solo accesible vía VPN, por lo que sigue siendo seguro"
echo "  - Para mayor seguridad, puedes cambiar a modo 'manual' después"
echo ""
echo -e "${YELLOW}Reiniciando gateway...${NC}"
cd ..
docker-compose restart gateway

echo ""
echo -e "${GREEN}✅ Completado. Los nuevos dispositivos se aprobarán automáticamente.${NC}"
