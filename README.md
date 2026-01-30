# Clawbot Secure Gateway (Community Edition)

Este paquete proporciona una implementación segura y lista para producción del Clawbot AI Gateway usando Docker, Nginx y WireGuard.

## 🎯 ¿Qué lograrás?

Tendrás tu propio agente de IA privado, accesible solo a través de una VPN segura (WireGuard). Nadie más en internet podrá acceder a tu sistema, incluso si conocen tu IP pública.

## 🏗️ Arquitectura

- **WireGuard (wg-easy)**: Red Privada Virtual (VPN). Solo los dispositivos autorizados por ti pueden conectarse.
- **Nginx**: Proxy reverso que maneja SSL (HTTPS) y enrutamiento.
- **Clawbot Gateway**: El núcleo del agente de IA.

## ✅ Requisitos

- Servidor Linux (Ubuntu/Debian recomendado) - puede ser un VPS de $5/mes
- Docker & Docker Compose instalados
- **IP Pública** (todos los servidores la tienen)
- **Dominio (OPCIONAL)**: Si no tienes dominio, puedes usar tu IP directamente

## 🚀 Instalación (10 minutos)

### Opción A: CON Dominio
Si tienes un dominio (ej: `ai.midominio.com`), apúntalo a la IP de tu servidor antes de comenzar.

### Opción B: SIN Dominio (Solo IP)
No hay problema. El instalador funcionará igual, solo usarás la IP directamente (ej: `https://203.0.113.10`).

⚠️ **Nota sobre SSL**: Si usas solo IP, el certificado será autofirmado. Tu navegador mostrará "Conexión no segura", pero es normal. Solo haz clic en "Avanzado" → "Aceptar riesgo".

### Pasos:

1. **Descarga/Clona** esta carpeta a tu servidor:
   ```bash
   cd /root/apps
   # Si tienes git: git clone https://tu-repo/clawbot_install
   ```

2. **PASO 1: Configuración Inicial de Clawbot (Onboarding)**:
   ```bash
   cd clawbot_install/scripts
   ./onboard.sh
   ```
   
   Este asistente interactivo te preguntará:
   - **Proveedor de IA**: Elige "GitHub Copilot" (necesitas suscripción) u otro.
   - **Login**: Te dará un código para ingresar en `https://github.com/login/device`.
   - **WhatsApp (Opcional)**: Si quieres usar el bot por WhatsApp, escanea el QR.
   
   **⚠️ IMPORTANTE**: El asistente generará automáticamente un **token de autenticación** único durante esta configuración inicial. Este token quedará guardado en `data/clawbot_home/.clawdbot/clawdbot.json` y será sincronizado automáticamente con el servidor en el siguiente paso.
   
   ⏱️ **Duración**: 3-5 minutos (incluye login en GitHub).

3. **PASO 2: Configuración del Servidor (VPN + Nginx)**:
   ```bash
   cd ..
   ./setup.sh
   ```
   
   El script te preguntará:
   - **Dominio o IP**: Escribe tu dominio (si tienes) o tu IP pública.
   - **IP del servidor**: La misma IP pública (para configurar la VPN).
   - **Contraseña VPN**: Elige una segura.
   
   El script automáticamente:
   - Detecta el token generado en el Paso 1 y lo sincroniza con la configuración del servidor.
   - Genera el hash de la contraseña VPN.
   - Crea certificados SSL.

4. **PASO 3: Iniciar los Servicios**:
   ```bash
   docker-compose up -d
   ```

## 📱 Guía Post-Instalación

### 1. Conectar a la VPN (IMPORTANTE)
1. Abre tu navegador y ve a: `http://TU_IP_PUBLICA:51821`
   - Ejemplo: `http://203.0.113.10:51821`
2. **Login**:
   - Usuario: `admin` (no lo cambies)
   - Contraseña: La que escribiste en el instalador.
3. **Crear un Cliente**:
   - Haz clic en "Add Client" (o "Agregar Cliente").
   - Ponle un nombre (ej: "Mi Laptop").
   - Descarga el archivo `.conf` o escanea el QR con tu móvil.
4. **Instalar WireGuard**:
   - **Windows/Mac/Linux**: Descarga desde [wireguard.com/install](https://www.wireguard.com/install/)
   - **Android/iOS**: Busca "WireGuard" en tu tienda de apps.
5. **Importar la configuración**:
   - Abre WireGuard → "Add Tunnel" → Selecciona el archivo `.conf` (o escanea el QR).
6. **¡Activa la VPN!** (desliza el botón).

🎉 **Ahora estás dentro de la red privada.** Tu IP local será algo como `10.13.13.2`.

### 2. Acceder al Gateway de IA

⚠️ **IMPORTANTE: Solo accesible vía VPN** - El Gateway NO está expuesto a internet público por seguridad.

**Desde tu dispositivo con VPN conectada:**

**Si usaste un DOMINIO**:
- Abre: `https://172.22.0.9` (IP interna del proxy en la red Docker)

**Si usaste una IP**:
- Abre: `https://172.22.0.9` (IP interna del proxy en la red Docker)
- Tu navegador dirá "Su conexión no es privada" o "Riesgo de seguridad". ¡Esto es normal!
- **Cómo proceder**:
  - Chrome/Edge: Haz clic en "Avanzado" → "Ir a 172.22.0.9 (no seguro)".
  - Firefox: "Avanzado" → "Aceptar el riesgo y continuar".
  
💡 **¿Por qué pasa esto?**: Los certificados SSL "reales" (de Let's Encrypt) requieren un dominio. Como usaste una IP, el instalador creó un certificado "autofirmado" que funciona igual, pero el navegador no lo reconoce. Solo tú puedes acceder (por la VPN), así que es seguro.

### 3. Emparejar tu Dispositivo (Resolver Errores 4008/1008)

La primera vez que abras el Gateway, verás un error de "Emparejamiento Requerido" o código `1008/4008`. Esto es una **capa extra de seguridad** de Clawbot.

**Proceso de Aprobación:**

1. **Lista los dispositivos pendientes** en tu servidor:
   ```bash
   docker exec clawbot_gateway clawdbot devices list
   ```

2. Verás una salida como esta:
   ```
   Pending (1)
   ┌──────────────────────────────────────┬────────────────────────────────────┐
   │ Request                              │ Device                             │
   ├──────────────────────────────────────┼────────────────────────────────────┤
   │ 4b03c3ac-f9b5-4ff0-ae73-446545331100 │ ee5c6b12670888...                  │
   └──────────────────────────────────────┴────────────────────────────────────┘
   ```

3. **Aprueba el dispositivo** usando el **Request ID** (primera columna):
   ```bash
   docker exec clawbot_gateway clawdbot devices approve <REQUEST_ID>
   ```
   
   Ejemplo:
   ```bash
   docker exec clawbot_gateway clawdbot devices approve 4b03c3ac-f9b5-4ff0-ae73-446545331100
   ```

4. **Recarga la página** en tu navegador. ¡Listo!

**¿Por qué sucede esto?** Clawbot tiene 2 niveles de seguridad:
- **Nivel 1**: Token de autenticación (configurado con `trustedProxies`)
- **Nivel 2**: Emparejamiento de dispositivos (previene acceso no autorizado incluso con el token)

**💡 Auto-Aprobación Automática**:
Este paquete incluye un servicio que aprueba automáticamente los dispositivos nuevos. Los dispositivos se aprobarán en segundo plano cada 5 segundos. Si prefieres la aprobación manual por mayor seguridad:
```bash
docker-compose stop auto-approve
```

## 📁 Estructura de Archivos

- `docker-compose.yml`: Define los servicios (VPN, Nginx, Clawbot, Auto-Approve).
- `config/nginx.conf`: Reglas del servidor web (generado desde `.example`).
- `data/`: Almacenamiento persistente (backups, logs, configuración del onboarding).
- `.env`: Variables de entorno (IP, contraseñas, token sincronizado). ¡No lo compartas!

## 🔧 Solución de Problemas

### "Connection Failed" o Error WebSocket
- **Verifica** que la VPN esté activa (mira el ícono de WireGuard).
- **Comprueba** los logs: `docker logs clawbot_gateway`
- **Reinicia** los servicios: `docker-compose restart`

### "Certificado No Válido" (usando IP)
- Esto es esperado. Haz clic en "Avanzado" y acepta el riesgo. Solo tú puedes acceder por la VPN.

### Obtener SSL Real (solo si tienes dominio)
```bash
docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d tudominio.com
docker-compose restart proxy
```

## ❓ Preguntas Frecuentes (FAQ)

**P: ¿Necesito pagar por un dominio?**
R: No. Puedes usar tu IP directamente. El único "inconveniente" es que el navegador te advertirá sobre el certificado autofirmado (pero es seguro porque solo tú accedes por VPN).

**P: ¿Qué pasa con el token de autenticación?**
R: El token se genera **automáticamente** durante el onboarding (Paso 1). El script `setup.sh` lo detecta y lo sincroniza con el servidor. No necesitas copiarlo ni guardarlo manualmente.

**P: ¿Qué VPS recomiendas?**
R: Cualquier VPS con 2GB RAM y Docker. Ejemplos: DigitalOcean ($6/mes), Hetzner (€4/mes), Vultr ($6/mes).

**P: ¿Puedo usar esto en mi casa con IP dinámica?**
R: Sí, pero cada vez que tu IP cambie, deberás actualizar `.env` y reiniciar los servicios. Considera usar un servicio DynDNS o No-IP.

**P: ¿Es seguro compartir el puerto 51821 (VPN Admin)?**
R: Sí, pero cambia la contraseña regularmente. Ese puerto es solo para gestionar la VPN, no expone el Gateway.

## 📚 Recursos Adicionales

- [Documentación de Clawbot](https://github.com/clawbot/gateway)
- [WireGuard Official Site](https://www.wireguard.com/)
- [Video Tutorial en YouTube](#) ← ¡Suscríbete!

## 🤝 Contribuir

Si encuentras errores o mejoras, ¡abre un Issue o Pull Request! Este proyecto es para la comunidad.

---

**Creado con ❤️ para la comunidad de IA open-source.**
