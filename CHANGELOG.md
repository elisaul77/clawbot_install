# 📦 Clawbot Community Package - Release Notes

## Versión 1.0.2 (Enero 2026)

### 🔒 SEGURIDAD CRÍTICA

1. **Gateway ya NO está expuesto a internet público**
   - **Problema**: Los puertos 80 y 443 estaban expuestos públicamente, permitiendo acceso sin VPN
   - **Solución**: Eliminados `ports` del servicio proxy, ahora solo usa `expose` (acceso interno)
   - **Impacto**: El Gateway ahora **SOLO** es accesible vía VPN en `https://172.22.0.9`
   - **Archivos modificados**:
     - `docker-compose.yml`: Cambio de `ports` a `expose` en servicio proxy
     - `README.md`: Actualizada sección de acceso con IP interna
     - `setup.sh`: Mensaje actualizado con advertencia de seguridad

⚠️ **IMPORTANTE**: Si ya tienes la instalación activa, ejecuta `docker-compose down && docker-compose up -d` para aplicar los cambios.

### 📝 Notas de Seguridad

- **Antes**: Gateway accesible desde cualquier lugar de internet (puerto 443 público)
- **Ahora**: Gateway SOLO accesible desde dispositivos conectados a la VPN
- **Acceso**: `https://172.22.0.9` (IP interna en red Docker backend_net)

---

## Versión 1.0.1 (Enero 2026)

### 🐛 Correcciones

1. **Fix de Permisos de Directorios** ([Issue #1])
   - **Problema**: Los scripts creaban directorios con permisos de root, causando errores `EACCES` cuando el contenedor Docker intentaba escribir.
   - **Solución**: Agregado `chmod -R 777 data/` en ambos scripts (`onboard.sh` y `setup.sh`) inmediatamente después de crear los directorios.
   - **Archivos modificados**:
     - `scripts/onboard.sh`: Agregado comando `chmod` con mensaje informativo
     - `setup.sh`: Agregado comando `chmod` después de crear directorios de datos

2. **Corrección de Volúmenes en docker-compose.yml**
   - **Problema**: Los volúmenes del servicio `gateway` apuntaban a rutas incorrectas (`/home/node/` en lugar de `/home/clawbot/`)
   - **Solución**: Actualizado para usar las rutas correctas que coinciden con el Dockerfile:
     - `./data/clawbot_home/.clawdbot:/home/clawbot/.clawdbot`
     - `./data/clawbot_home/clawd:/home/clawbot/clawd`

### 📝 Notas Técnicas

- **Permisos 777**: Aunque permisivos, son necesarios para garantizar compatibilidad entre diferentes configuraciones de Docker (Docker Desktop, rootless, etc.). Los datos están protegidos por la VPN de todas formas.
- **Testing**: Probado en Ubuntu 22.04 con Docker 24.x ejecutándose como root.

---

## Versión 1.0.0 (Enero 2026)

### 🎯 Qué incluye este paquete

Este es un kit de instalación completo para desplegar Clawbot (AI Gateway) con seguridad de nivel empresarial usando Docker, WireGuard (VPN) y Nginx.

**Componentes**:
- ✅ Instalador automatizado (`setup.sh`)
- ✅ Docker Compose pre-configurado
- ✅ Configuración de Nginx optimizada para WebSockets
- ✅ Configuración de Clawbot con `trustedProxies` pre-cargada
- ✅ Soporte para IP pública (sin necesidad de dominio)
- ✅ Soporte para dominios personalizados
- ✅ Generación automática de tokens seguros
- ✅ Script de diagnóstico (`scripts/diagnose.sh`)

### 🚀 Instalación Rápida

```bash
git clone https://tu-repo/clawbot_install
cd clawbot_install
./setup.sh
docker-compose up -d
```

### 🔒 Características de Seguridad

1. **VPN Obligatoria**: Acceso solo por WireGuard. Puertos del Gateway NO expuestos a internet.
2. **Tokens Únicos**: Generados automáticamente con `openssl rand -hex 32`.
3. **Trusted Proxies**: Pre-configurado para evitar errores de emparejamiento (4008/1008).
4. **SSL/TLS**: Certificados autofirmados incluidos. Soporte para Let's Encrypt.

### 📖 Documentación

- [README.md](README.md): Guía de instalación paso a paso
- [FAQ.md](FAQ.md): Preguntas frecuentes (problemas comunes, conceptos técnicos)
- [YOUTUBE_SCRIPT.md](YOUTUBE_SCRIPT.md): Guion para video tutorial

### 🛠️ Herramientas Incluidas

- `scripts/diagnose.sh`: Diagnóstico automático de problemas
  ```bash
  ./scripts/diagnose.sh
  ```

### 🔧 Configuración Avanzada

#### Cambiar Puertos de la VPN
Edita `docker-compose.yml`:
```yaml
services:
  vpn:
    ports:
      - '12345:51820/udp'  # Puerto personalizado
```

#### Usar Dominio Después de Instalar con IP
1. Apunta tu dominio a la IP del servidor (DNS A record).
2. Edita `.env`:
   ```bash
   DOMAIN_NAME=ai.tudominio.com
   ```
3. Actualiza `config/nginx.conf`:
   ```bash
   sed -i 's/TU_IP_VIEJA/ai.tudominio.com/g' config/nginx.conf
   ```
4. Obtén certificado SSL real:
   ```bash
   docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d ai.tudominio.com
   docker-compose restart proxy
   ```

### ⚠️ Limitaciones Conocidas

1. **Primera Conexión**: Puede requerir aprobación manual de dispositivo (`docker exec clawbot_gateway clawdbot devices approve <ID>`).
2. **IP Dinámica**: Si tu servidor tiene IP dinámica, necesitarás actualizar `.env` cada vez que cambie.
3. **Certificados Autofirmados**: Si usas solo IP (sin dominio), el navegador mostrará advertencia de seguridad. Es normal y seguro.

### 🐛 Problemas Conocidos y Soluciones

| Problema | Solución |
|----------|----------|
| Error 4008/1008 | Ejecuta `docker exec clawbot_gateway clawdbot devices approve <ID>` |
| "Connection not private" | Normal si usas IP. Haz clic en "Avanzado" → "Aceptar riesgo" |
| VPN no conecta | Verifica firewall: `sudo ufw allow 51820/udp` |
| Gateway no responde | Revisa logs: `docker logs clawbot_gateway` |

### 📊 Requisitos del Sistema

**Mínimos**:
- CPU: 1 core
- RAM: 2GB
- Disco: 20GB
- OS: Linux (Ubuntu 20.04+, Debian 11+)

**Recomendados**:
- CPU: 2 cores
- RAM: 4GB
- Disco: 40GB
- OS: Ubuntu 22.04 LTS

### 🌍 Compatibilidad

**Tested en**:
- ✅ Ubuntu 22.04 LTS
- ✅ Debian 11
- ✅ Hetzner Cloud
- ✅ DigitalOcean
- ⚠️ Raspberry Pi 4 (funciona, pero lento con modelos grandes)

### 📈 Roadmap Futuro

- [ ] Soporte para Docker Swarm (cluster multi-servidor)
- [ ] Integración con Prometheus/Grafana (métricas)
- [ ] Auto-renovación de certificados Let's Encrypt
- [ ] Interfaz Web para gestión (alternativa al CLI)
- [ ] Soporte para múltiples gateways (load balancing)

### 🤝 Contribuciones

Este proyecto es de código abierto. Se aceptan Pull Requests para:
- Mejoras en el instalador
- Nuevas opciones de configuración
- Corrección de bugs
- Traducción a otros idiomas

### 📜 Licencia

[Incluir licencia aquí - MIT recomendada para proyectos comunitarios]

### 👏 Créditos

- **Clawbot**: [Repositorio original](https://github.com/clawbot/gateway)
- **WireGuard-Easy**: [wg-easy](https://github.com/wg-easy/wg-easy)
- **Nginx**: [nginx.org](https://nginx.org)

---

**Creado por [TU_NOMBRE] para la comunidad de IA open-source.**

¿Preguntas? Abre un Issue en GitHub o comenta en el [video de YouTube](#).
