#!/bin/bash
# Script de prueba para validar permisos de directorios

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Test de Permisos de Directorios ===${NC}"
echo ""

# Test 1: Verificar que los directorios existen
echo "Test 1: Verificando existencia de directorios..."
if [ -d "../data/clawbot_home/.clawdbot" ] && [ -d "../data/clawbot_home/clawd" ]; then
    echo -e "${GREEN}✓ Directorios existen${NC}"
else
    echo -e "${RED}✗ Directorios no encontrados${NC}"
    exit 1
fi

# Test 2: Verificar permisos de escritura
echo "Test 2: Verificando permisos de escritura..."
TEST_FILE="../data/clawbot_home/.clawdbot/test_write.tmp"
if touch "$TEST_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ Escritura permitida en .clawdbot${NC}"
    rm "$TEST_FILE"
else
    echo -e "${RED}✗ Sin permisos de escritura${NC}"
    exit 1
fi

TEST_FILE="../data/clawbot_home/clawd/test_write.tmp"
if touch "$TEST_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ Escritura permitida en clawd${NC}"
    rm "$TEST_FILE"
else
    echo -e "${RED}✗ Sin permisos de escritura${NC}"
    exit 1
fi

# Test 3: Simular escritura como usuario del contenedor
echo "Test 3: Simulando escritura desde contenedor Docker..."
docker run --rm \
    -v "$(pwd)/../data/clawbot_home/.clawdbot:/test/.clawdbot" \
    -v "$(pwd)/../data/clawbot_home/clawd:/test/clawd" \
    alpine:latest \
    sh -c "touch /test/.clawdbot/container_test.tmp && touch /test/clawd/container_test.tmp && rm /test/.clawdbot/container_test.tmp && rm /test/clawd/container_test.tmp"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Contenedor puede escribir en ambos directorios${NC}"
else
    echo -e "${RED}✗ Contenedor no puede escribir${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Todos los tests pasaron exitosamente ===${NC}"
echo ""
echo -e "${YELLOW}Los directorios están configurados correctamente para Docker.${NC}"
