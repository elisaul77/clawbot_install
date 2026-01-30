# Guion de Video: Implementación Segura de Clawbot con VPN y Nginx

**Título**: "Tu Propia IA Privada: Instálala en 5 Minutos (Sin Dominio, Solo IP)"

**Duración**: ~10 minutos

---

## Introducción (0:00 - 1:00)
- **Visual**: Logo de Clawbot, diagrama de arquitectura (Usuario <-> VPN <-> Nginx <-> Clawbot).
- **Audio**: 
  > "¿Quieres tu propio agente de IA, pero sin exponerte a internet? Hoy te enseño cómo montar Clawbot de forma 100% segura usando una VPN. Y lo mejor: **NO necesitas comprar un dominio**. Con solo tu IP pública, en 5 minutos lo tendrás funcionando. Usaremos Docker para levantar 3 servicios clave:
  > 1. **WireGuard**: Tu VPN personal. Solo tú entras.
  > 2. **Nginx**: Maneja el HTTPS y los WebSockets.
  > 3. **Clawbot**: Tu agente de IA privado."

---

## Requisitos y Contexto (1:00 - 2:30)
- **Visual**: Captura de un VPS (DigitalOcean, Hetzner, etc). Destacar: "Desde $5/mes".
- **Audio**: 
  > "Lo único que necesitas es un servidor Linux con Docker. Puede ser un VPS barato de $5 al mes. **No necesitas dominio**. Si tienes uno, genial, pero si no, usarás tu IP directamente. El instalador detecta automáticamente qué estás usando."

---

## Descarga e Instalación (2:30 - 5:30)
- **Visual**: Terminal. Comandos en pantalla.
- **Acción Parte 1 - Construcción y Onboarding (2:30 - 4:00)**: 
    1. `cd /root/apps/clawbot_install/scripts`
    2. `./onboard.sh`
- **Audio**: 
  > "Primero, configuramos Clawbot. Ejecutamos `onboard.sh`. 
  > Lo primero que hará es **construir tu propia imagen Docker** desde cero. Esto es clave: no descargamos una imagen a ciegas, creamos nuestra propia versión segura usando el código fuente oficial. Tarda unos segundos.
  > 
  > Luego se abre el asistente interactivo..."
  
- **Visual**: QR de WhatsApp en pantalla (opcional).
- **Audio**: 
  > "También pregunta si quieres WhatsApp. Esto es opcional. Si dices que sí, escaneas el QR con tu teléfono y el bot responde por WhatsApp. Yo lo omito para este demo."

- **Acción Parte 2 - Setup del Servidor (4:00 - 5:30)**:
    1. `cd ..`
    2. `./setup.sh`
- **Audio**: 
  > "Ahora configuramos el servidor. Ejecutamos `setup.sh`. Te hará 3 preguntas:
  > 1. **Dominio o IP**: Escribo mi IP porque no tengo dominio (ej: `203.0.113.10`).
  > 2. **IP del servidor**: La misma.
  > 3. **Contraseña para la VPN**: Una segura.
  > 
  > Miren cómo detecta que uso IP y avisa: 'Usarás certificado autofirmado'. Genera el hash de la VPN, sincroniza el token del onboarding... Todo automático."

---

## Despliegue (5:30 - 6:30)
- **Visual**: Comando `docker-compose up -d`. Logs en tiempo real (verde = éxito).
- **Audio**: 
  > "Un solo comando levanta toda la infraestructura. Miren cómo Docker descarga las imágenes: WireGuard, Nginx, Clawbot. En menos de un minuto, está todo corriendo."

---

## Configuración de la VPN (6:30 - 8:00)
- **Visual**: Navegador abriendo `http://IP:51821`. Panel de WireGuard. Crear cliente. QR visible.
- **Audio**: 
  > "Primero, aseguramos el perímetro. Abrimos el puerto 51821 (solo para gestión de VPN, no el Gateway). Entramos con usuario 'admin' y la contraseña que pusimos. Creamos un cliente, le ponemos nombre: 'Mi Laptop'. Descargamos el archivo de configuración o escaneamos el QR con el móvil. Instalamos WireGuard en nuestro equipo (es gratis, en todas las plataformas). Importamos el archivo y... ¡activamos la VPN!"
- **Visual**: Mostrar cómo cambia la IP (ejecutar `curl ifconfig.me` antes y después, o simplemente destacar el ícono de WireGuard activo).
- **Audio**: 
  > "Ahora estoy dentro de la red del servidor. Mi IP local es `10.13.13.2`. Nadie más puede entrar."

---

## El "Secreto" del SSL sin Dominio (8:00 - 9:30)
- **Visual**: Navegador abriendo `https://TU_IP`. Aparece "Tu conexión no es privada".
- **Audio**: 
  > "Aquí viene lo interesante. Como usamos una IP en vez de dominio, el navegador no reconoce el certificado SSL. Pero **esto no es un error**. El instalador generó un certificado autofirmado que funciona perfectamente. Solo que Chrome no lo conoce. Hacemos clic en 'Avanzado', 'Aceptar riesgo', y..."
- **Visual**: Se carga el dashboard de Clawbot.
- **Audio**: 
  > "¡Boom! Ahí está. Conexión segura, candadito (aunque sea naranja). Lo importante es que nadie en internet puede ver esto porque están bloqueados por la VPN."

---

## El Truco de los Proxies Confiables (9:30 - 10:30)
- **Visual**: Mostrar archivo `config/clawdbot.json`. Destacar la línea `"trustedProxies": ["172.22.0.9", ...]`.
- **Audio**: 
  > "Y ahora el truco que me costó horas descubrir. Clawbot tiene una capa extra de seguridad llamada 'Emparejamiento de Dispositivos'. Si el bot ve que la conexión viene de Nginx (que está en la IP interna `172.22.0.9`), puede pensar que es un ataque y bloquear la conexión con errores 4008 o 1008.
  > 
  > Por eso, en la configuración ya incluí `trustedProxies`. Esto le dice al bot: 'Hey, el tráfico de Nginx es de confianza'. Sin esto, tendrían que aprobar manualmente cada dispositivo. Ahora, la primera vez que entres, es posible que te pida aprobación, pero con un solo comando en el servidor (`docker exec clawbot_gateway clawdbot devices approve ...`), quedas emparejado para siempre."

---

## Demo Final y Cierre (10:30 - 11:30)
- **Visual**: Usando Clawbot. Hacer una pregunta al agente. Respuesta en tiempo real.
- **Audio**: 
  > "Y así de simple. Tu propio agente de IA, corriendo 24/7, accesible solo por ti a través de VPN. Todo esto sin necesidad de dominio. Si más adelante quieres agregar uno, solo cambias una línea en `.env` y reinicias.
  > 
  > El paquete completo está en la descripción del video. ¡Suscríbete para más tutoriales de IA y seguridad! Nos vemos en el próximo."
  
- **Visual**: Pantalla final con:
  - Link al repo GitHub
  - Botón de suscripción
  - Thumbnails de videos relacionados

---

## 📝 Notas para la Edición

- **Momento clave**: Minuto 7:00 (cuando se explica el certificado autofirmado). Poner texto en pantalla: "SIN DOMINIO = CERTIFICADO AUTOFIRMADO. SEGURO, SOLO QUE EL NAVEGADOR NO LO RECONOCE".
- **Call-to-Action**: Minuto 9:50. Botón animado "DESCARGAR INSTALADOR".
- **Música**: Algo tech/cyberpunk para intro y outro. Sin música en las secciones de comando.
