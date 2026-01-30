#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Clawbot Onboarding (Paso 1) ===${NC}"
echo ""
echo -e "${YELLOW}Este script ejecutará el asistente interactivo de Clawbot.${NC}"
echo "Te preguntará:"
echo "  1. Qué proveedor de IA usar (GitHub Copilot recomendado)"
echo "  2. Te dará un código para login en GitHub"
echo "  3. Opcionalmente, configurar WhatsApp"
echo ""
read -p "Presiona ENTER para continuar..."

# Build Docker image locally
echo -e "${YELLOW}Construyendo tu propia imagen de Clawbot (esto asegura que tienes la última versión segura)...${NC}"
cd .. # Go to root of install package to find Dockerfile
docker build -t clawbot-custom:latest .
cd scripts # Go back to scripts

# Create directories if they don't exist with proper permissions
echo -e "${YELLOW}Preparando directorios de datos...${NC}"
mkdir -p ../data/clawbot_home/.clawdbot
mkdir -p ../data/clawbot_home/clawd

# Set permissions to allow Docker container to write
# Using 777 to ensure compatibility across different Docker setups
chmod -R 777 ../data/clawbot_home/

echo -e "${GREEN}Iniciando asistente interactivo...${NC}"
echo ""

# Run onboarding
docker run --rm -it \
  -v "$(pwd)/../data/clawbot_home/.clawdbot:/home/clawbot/.clawdbot" \
  -v "$(pwd)/../data/clawbot_home/clawd:/home/clawbot/clawd" \
  clawbot-custom:latest \
  clawdbot onboard

echo ""
echo -e "${GREEN}✅ Onboarding completado!${NC}"
echo ""
echo -e "${YELLOW}IMPORTANTE:${NC}"
echo "  1. El asistente generó una configuración en: data/clawbot_home/.clawdbot/"
echo "  2. Ahora debes ejecutar: ./setup.sh (para configurar VPN y Nginx)"
echo "  3. Finalmente: docker-compose up -d"
echo ""
echo -e "${RED}NOTA:${NC} El token que viste en el onboarding debe coincidir con el de config/clawdbot.json"
