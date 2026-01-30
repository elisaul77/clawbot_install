#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Clawbot Secure Installation Wizard ===${NC}"

# 1. Check Requirements
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed.${NC}"
    exit 1
fi

# 2. Setup Directories
echo "Creating data directories..."
mkdir -p data/wireguard
mkdir -p data/certbot/conf
mkdir -p data/certbot/www
mkdir -p data/proxy_logs
mkdir -p data/clawbot_home

# Set proper permissions to avoid Docker permission issues
echo "Setting directory permissions..."
chmod -R 777 data/

# 3. Env Configuration
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file from template...${NC}"
    cp .env.example .env
fi

# 4. Interactive Configuration
echo -e "${YELLOW}¿Tienes un dominio? (Ejemplo: ai.midominio.com)${NC}"
echo "Si NO tienes dominio, puedes usar tu IP directamente."
read -p "Dominio o IP Pública: " DOMAIN_NAME
read -p "IP Pública del Servidor (para VPN): " VPN_IP
read -p "Contraseña para VPN (Admin): " VPN_PASS

# Detect if it's an IP or domain
if [[ $DOMAIN_NAME =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${YELLOW}Detectado: Usando IP ($DOMAIN_NAME). SSL será autofirmado.${NC}"
    USE_IP=true
else
    echo -e "${GREEN}Detectado: Dominio ($DOMAIN_NAME).${NC}"
    USE_IP=false
fi

# Update .env
sed -i "s/DOMAIN_NAME=.*/DOMAIN_NAME=$DOMAIN_NAME/" .env
sed -i "s/VPN_PUBLIC_IP=.*/VPN_PUBLIC_IP=$VPN_IP/" .env

# Update Nginx Config
sed -i "s/\${DOMAIN_NAME}/$DOMAIN_NAME/g" config/nginx.conf

# 5. Security Token Generation
echo -e "${YELLOW}Generando Token de Seguridad...${NC}"

# Check if onboarding was done (token exists in data)
ONBOARD_CONFIG="data/clawbot_home/.clawdbot/config.json"
if [ -f "$ONBOARD_CONFIG" ]; then
    echo -e "${GREEN}Detectado: Configuración de onboarding existente.${NC}"
    # Extract token from onboarding config
    EXISTING_TOKEN=$(grep -oP '"token"\s*:\s*"\K[^"]+' "$ONBOARD_CONFIG" | head -1)
    if [ -n "$EXISTING_TOKEN" ]; then
        echo -e "${YELLOW}Reutilizando token del onboarding...${NC}"
        RAW_TOKEN=$EXISTING_TOKEN
    else
        echo -e "${YELLOW}No se encontró token en onboarding. Generando uno nuevo...${NC}"
        RAW_TOKEN=$(openssl rand -hex 32)
    fi
else
    echo -e "${RED}ADVERTENCIA: No se detectó onboarding previo (./scripts/onboard.sh).${NC}"
    echo -e "${YELLOW}Generando token nuevo. Deberás actualizarlo manualmente después.${NC}"
    RAW_TOKEN=$(openssl rand -hex 32)
fi

sed -i "s/CLAWDBOT_TOKEN=.*/CLAWDBOT_TOKEN=$RAW_TOKEN/" .env

# Update clawdbot.json
sed -i "s/REPLACE_WITH_YOUR_TOKEN_HASH/$RAW_TOKEN/" config/clawdbot.json

# 6. VPN Password Hashing
echo "Generating VPN Password Hash..."
# Note: This requires the wg-easy image to be pulled. We'll do a quick run.
docker pull ghcr.io/wg-easy/wg-easy > /dev/null
VPN_HASH=$(docker run --rm ghcr.io/wg-easy/wg-easy wgpw "$VPN_PASS")
# Escape special chars for sed - need to escape $ and other special characters
VPN_HASH_ESCAPED=$(printf '%s\n' "$VPN_HASH" | sed -e 's/[\/&]/\\&/g' -e 's/\$/\\$/g')
sed -i "s|VPN_PASSWORD_HASH=.*|VPN_PASSWORD_HASH=${VPN_HASH_ESCAPED}|" .env

# 7. Self-Signed Certs (to prevent Nginx crash on first run)
CERT_PATH="./data/certbot/conf/live/$DOMAIN_NAME"
if [ ! -f "$CERT_PATH/fullchain.pem" ]; then
    echo -e "${YELLOW}Generating self-signed SSL certificates for boot...${NC}"
    mkdir -p "$CERT_PATH"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_PATH/privkey.pem" \
        -out "$CERT_PATH/fullchain.pem" \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN_NAME"
fi

echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}  ✅ Configuración del Servidor Completa!${NC}"
echo -e "${GREEN}===========================================${NC}"
echo ""
echo -e "${YELLOW}PRÓXIMO PASO:${NC} Iniciar los servicios"
echo -e "  docker-compose up -d"
echo ""
echo -e "${YELLOW}Luego, conectar a la VPN:${NC}"
echo -e "  Abre en tu navegador: ${GREEN}http://$VPN_IP:51821${NC}"
echo -e "  Usuario: admin"
echo -e "  Contraseña: (la que acabas de escribir)"
echo ""
echo -e "${YELLOW}PASO 3:${NC} Descargar configuración VPN"
echo -e "  - Crea un cliente (ej: 'Mi Laptop')"
echo -e "  - Descarga el archivo .conf o escanea el QR"
echo -e "  - Instala WireGuard en tu PC/móvil"
echo ""
echo -e "${YELLOW}PASO 4:${NC} Acceder al Gateway"
echo -e "  ${RED}⚠️  SOLO ACCESIBLE VÍA VPN${NC}"
echo -e "  URL: ${GREEN}https://172.22.0.9${NC} (IP interna del proxy)"
echo -e "  ${RED}NOTA:${NC} Tu navegador mostrará 'Conexión no segura'"
echo -e "  porque el certificado es autofirmado. Haz clic en 'Avanzado' y 'Aceptar riesgo'."
echo -e "  ${YELLOW}El Gateway NO está expuesto a internet por seguridad.${NC}"
echo ""
echo -e "${RED}🔒 GUARDA ESTE TOKEN:${NC} $RAW_TOKEN"
echo -e "${YELLOW}Lo necesitarás para aprobar dispositivos.${NC}"
echo ""
