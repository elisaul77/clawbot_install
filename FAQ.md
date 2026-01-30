# ❓ Preguntas Frecuentes (FAQ)

## General

### ¿Qué es Clawbot?
Clawbot es un Gateway de IA que te permite interactuar con múltiples modelos de lenguaje (LLMs) de forma segura y privada. Piensa en él como tu asistente de IA personal.

### ¿Por qué necesito una VPN?
La VPN (WireGuard) asegura que **solo tú y los dispositivos que autorices** puedan acceder al Gateway. Sin la VPN, cualquiera en internet podría intentar conectarse si conoce tu IP.

---

## Instalación

### ¿Necesito un dominio?
**NO.** Puedes usar tu IP pública directamente (ej: `https://203.0.113.10`). El instalador detecta automáticamente si usas IP o dominio y se ajusta.

**Con Dominio**:
- Ventaja: Puedes obtener certificados SSL "reales" de Let's Encrypt (candado verde).
- Costo: ~$10/año.

**Sin Dominio (Solo IP)**:
- Ventaja: Gratis, funciona igual.
- "Desventaja": Tu navegador mostrará "Conexión no segura" porque el certificado es autofirmado. Pero es seguro porque solo tú accedes por VPN.

### ¿Qué es el "onboarding" y por qué es obligatorio?
El **onboarding** (`./scripts/onboard.sh`) es el primer paso. Configura:
1. **Proveedor de IA**: GitHub Copilot, OpenAI, Anthropic, etc.
2. **Credenciales**: Login con tu cuenta de GitHub (para Copilot).
3. **Canales opcionales**: WhatsApp, Telegram, Discord.

Sin este paso, Clawbot no sabrá qué modelo usar ni cómo autenticarse. Es como instalar un coche sin ponerle motor.

### ¿Qué servidor necesito?
Cualquier VPS con:
- **2GB RAM** mínimo (4GB recomendado)
- **20GB disco**
- **Docker instalado**

**Recomendaciones**:
- DigitalOcean: Droplet $6/mes
- Hetzner: Cloud Server €4/mes
- Vultr: VPS $6/mes
- Linode: Nanode $5/mes

### ¿Funciona en mi casa (Raspberry Pi, NAS)?
Sí, siempre que:
1. Tengas Docker instalado.
2. Tu router permita abrir puertos (51820 para VPN).
3. Consideres que si tu IP cambia (IP dinámica), tendrás que actualizar la configuración.

---

## Seguridad

### ¿Es seguro usar un certificado autofirmado?
**Sí**, porque:
1. Solo tú accedes por VPN (nadie más puede interceptar).
2. El certificado autofirmado encripta el tráfico igual que uno "real".
3. La advertencia del navegador es solo porque no fue emitido por una autoridad reconocida (Let's Encrypt, DigiCert, etc).

**Ejemplo**: Es como usar una llave que funciona perfectamente, pero que hiciste tú mismo en vez de comprarla en una ferretería "oficial".

### ¿Qué es "trustedProxies" y por qué es importante?
Cuando Nginx (el proxy) reenvía las peticiones a Clawbot, la IP que ve Clawbot es la de Nginx (`172.22.0.9`), no la tuya. Sin `trustedProxies`, Clawbot pensaría:
> "Esta conexión viene de una IP desconocida (Nginx). ¡Alerta! Bloqueo."

Con `trustedProxies` configurado, Clawbot sabe:
> "Ah, esta conexión viene de Nginx, que es de confianza. Dejo pasar."

Este paquete ya incluye esa configuración. **No la elimines.**

### ¿Debo cambiar el puerto de la VPN (51820)?
No es necesario, pero puedes hacerlo en `docker-compose.yml` si tienes conflictos. Ejemplo:
```yaml
ports:
  - '12345:51820/udp'  # Cambiar 51820 por el puerto que prefieras
```

---

## Uso

### ¿Cómo agrego más usuarios a la VPN?
1. Ve a `http://TU_IP:51821` (panel de WireGuard).
2. Haz clic en "Add Client".
3. Dale un nombre (ej: "Móvil de María").
4. Comparte el `.conf` o QR con esa persona.

### ¿Puedo conectarme desde mi móvil?
Sí:
1. Instala la app "WireGuard" desde tu tienda de apps.
2. En el panel web de la VPN, crea un cliente.
3. Escanea el QR desde la app.
4. Activa la conexión.

### ¿Cómo desconecto la VPN temporalmente?
En la app/cliente de WireGuard, simplemente desliza el botón para desactivar. No necesitas borrar la configuración.

---

## Problemas Comunes

### "Connection Failed" al abrir el Gateway
**Causas**:
1. La VPN no está activa. → Actívala en WireGuard.
2. El servicio Clawbot no está corriendo. → Ejecuta: `docker logs clawbot_gateway`
3. Nginx no está enrutando bien. → Verifica: `docker logs clawbot_proxy`

**Solución rápida**:
```bash
docker-compose restart
```

### Error 4008 o 1008 (Pairing Required)
Este es el sistema de emparejamiento de Clawbot. **Primera vez únicamente**:
1. Abre terminal en tu servidor.
2. Ejecuta:
   ```bash
   docker logs clawbot_gateway | grep "pairing requested"
   ```
3. Copia el ID que aparece.
4. Aprueba:
   ```bash
   docker exec clawbot_gateway clawdbot devices approve <ID>
   ```
5. Recarga la página.

**Nota**: Una vez emparejado, no volverás a ver este error.

### "Su conexión no es privada" (Certificado SSL)
**Si usaste una IP** (sin dominio): Esto es esperado. Haz clic en:
- Chrome/Edge: "Avanzado" → "Ir a [IP] (no seguro)".
- Firefox: "Avanzado" → "Aceptar el riesgo".

**Si tienes dominio** y quieres SSL real:
```bash
docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d tudominio.com
docker-compose restart proxy
```

### No puedo acceder al panel de la VPN (puerto 51821)
**Causas**:
1. El firewall del servidor bloquea el puerto.
   ```bash
   # Ubuntu/Debian
   sudo ufw allow 51821/tcp
   sudo ufw allow 51820/udp
   ```
2. El servicio no está corriendo.
   ```bash
   docker ps | grep vpn
   ```

---

## Mantenimiento

### ¿Cómo actualizo Clawbot?
```bash
cd /root/apps/clawbot_install
docker-compose pull gateway
docker-compose up -d
```

### ¿Cómo hago backup?
Los datos importantes están en `data/`. Respalda:
```bash
tar -czf backup-$(date +%Y%m%d).tar.gz data/
```

### ¿Cómo veo los logs en tiempo real?
```bash
docker-compose logs -f
```

O para un servicio específico:
```bash
docker logs -f clawbot_gateway
```

---

## Solución de Problemas

### Error 1008/4008: "Emparejamiento Requerido"
**Síntoma**: Al abrir el Gateway aparece un error con código 1008 o 4008, o mensaje de "pairing required"

**Causa**: Clawbot requiere aprobación manual de dispositivos nuevos por seguridad.

**Solución**:
1. En tu servidor, lista dispositivos pendientes:
   ```bash
   docker exec clawbot_gateway clawdbot devices list
   ```
2. Copia el **Request ID** (primera columna de la tabla "Pending")
3. Aprueba el dispositivo:
   ```bash
   docker exec clawbot_gateway clawdbot devices approve <REQUEST_ID>
   ```
4. Recarga tu navegador

**Ejemplo completo**:
```bash
# Ver dispositivos pendientes
$ docker exec clawbot_gateway clawdbot devices list

Pending (1)
┌──────────────────────────────────────┬────────────────────────────────────┐
│ Request                              │ Device                             │
├──────────────────────────────────────┼────────────────────────────────────┤
│ 4b03c3ac-f9b5-4ff0-ae73-446545331100 │ ee5c6b12670888...                  │
└──────────────────────────────────────┴────────────────────────────────────┘

# Aprobar
$ docker exec clawbot_gateway clawdbot devices approve 4b03c3ac-f9b5-4ff0-ae73-446545331100
Approved ee5c6b12670888...
```

**Nota**: Este proceso es necesario solo la primera vez por dispositivo.

### Error: "EACCES: permission denied" durante onboarding
**Síntoma**: El onboarding falla con mensajes como `EACCES: permission denied, mkdir '/home/clawbot/.clawdbot/credentials'`

**Causa**: Los directorios de datos tienen permisos restrictivos.

**Solución**: El instalador ahora configura automáticamente los permisos correctos. Si usas una versión antigua (<1.0.1), ejecuta:
```bash
cd clawbot_install
chmod -R 777 data/clawbot_home/
```

**Prevención**: Siempre usa la versión más reciente del instalador desde el repositorio.

### ¿Puedo cambiar la IP del servidor después de instalar?
Sí, edita `.env`:
```bash
nano .env
# Cambia VPN_PUBLIC_IP=nueva_ip
docker-compose restart vpn
```

Los clientes VPN existentes deberán descargar nuevas configuraciones.

### Mi certificado SSL expiró
Si usas Let's Encrypt, renovar es automático (Certbot). Si falla:
```bash
docker-compose run --rm certbot renew
docker-compose restart proxy
```

---

## Conceptos Técnicos (Para Curiosos)

### ¿Qué es Docker Compose?
Una herramienta que te permite definir múltiples contenedores (servicios) en un solo archivo (`docker-compose.yml`) y gestionarlos juntos.

### ¿Qué hace Nginx aquí?
Nginx actúa como **Reverse Proxy**:
- Recibe las peticiones HTTPS de tu navegador.
- Las desencripta (SSL termination).
- Las reenvía a Clawbot (que corre en HTTP internamente).
- Maneja la negociación de WebSockets.

### ¿Por qué WireGuard y no OpenVPN?
WireGuard es más:
- **Rápido**: Menos overhead.
- **Moderno**: Criptografía actualizada.
- **Simple**: Menos de 4000 líneas de código (OpenVPN tiene +100,000).

---

## Soporte

### ¿Dónde reporto bugs?
Abre un Issue en el repositorio de GitHub (enlace en README.md).

### ¿Puedo modificar la configuración?
Sí, todos los archivos son editables:
- `config/clawdbot.json`: Configuración del Gateway.
- `config/nginx.conf`: Rutas y SSL.
- `docker-compose.yml`: Servicios y redes.

**Importante**: Si modificas `trustedProxies`, asegúrate de saber qué haces. Eliminarlos romperá el emparejamiento.

---

**¿No encuentras tu pregunta?** Abre un Issue o deja un comentario en el video de YouTube.
