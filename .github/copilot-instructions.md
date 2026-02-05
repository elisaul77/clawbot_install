# Clawbot Secure Gateway - Instrucciones para Agentes AI

> 📖 Documentación oficial: https://docs.openclaw.ai/

## Arquitectura del Sistema

```mermaid
architecture-beta
    group external(cloud)[Internet]
    group host_server(server)[Host Server]
    group docker_network(cloud)[Docker Network]
    
    service client(internet)[Cliente VPN] in external
    
    service port_vpn(server)[VPN 51820] in host_server
    service port_admin(server)[Admin 51821] in host_server
    
    service vpn(server)[clawbot vpn] in docker_network
    service proxy(server)[clawbot proxy] in docker_network
    service gateway(server)[clawbot gateway] in docker_network
    service certbot(disk)[certbot] in docker_network
    service autoapprove(server)[auto approve] in docker_network
    
    client:R --> L:port_vpn
    client:R --> L:port_admin
    port_vpn:R --> L:vpn
    port_admin:R --> L:vpn
    vpn:R --> L:proxy
    proxy:R --> L:gateway
    autoapprove:T --> B:gateway
    certbot:T --> B:proxy
```

### IPs del Docker Network (172.22.0.0/24)
| Servicio | IP | Puerto |
|----------|----|----|
| vpn | 172.22.0.6 | 51820/udp, 51821/tcp |
| proxy | 172.22.0.9 | 80, 443 |
| gateway | 172.22.0.14 | 18789 |

## Flujo de Instalación

```mermaid
flowchart LR
    subgraph STEP1["Paso 1: Onboarding"]
        O1["./scripts/onboard.sh"]
        O2["Seleccionar proveedor IA"]
        O3["Login GitHub Device"]
        O4["Generar token"]
    end
    
    subgraph STEP2["Paso 2: Setup Server"]
        S1["./setup.sh"]
        S2["Configurar dominio/IP"]
        S3["Generar hash VPN"]
        S4["Crear certificados SSL"]
    end
    
    subgraph STEP3["Paso 3: Deploy"]
        D1["docker-compose up -d"]
        D2["./scripts/post-install.sh"]
        D3["Conectar VPN cliente"]
    end
    
    STEP1 --> STEP2 --> STEP3
    
    style STEP1 fill:#2196f3,color:#fff
    style STEP2 fill:#ff9800,color:#000
    style STEP3 fill:#4caf50,color:#fff
```

## Estructura del Proyecto

```mermaid
flowchart TB
    subgraph ROOT["/clawbot_install"]
        direction TB
        COMPOSE["docker-compose.yml<br/>Define 5 servicios"]
        DOCKERFILE["Dockerfile<br/>Build gateway image"]
        SETUP["setup.sh<br/>Wizard configuración"]
        ENV[".env<br/>Variables entorno"]
    end
    
    subgraph CONFIG["config/"]
        direction TB
        NGINX["nginx.conf<br/>Reverse proxy SSL"]
        CLAWDBOT["clawdbot.json.example<br/>Template config"]
    end
    
    subgraph SCRIPTS["scripts/"]
        direction TB
        ONBOARD["onboard.sh<br/>Wizard inicial"]
        DIAGNOSE["diagnose.sh<br/>Troubleshooting"]
        AUTOAPPROVE["auto-approve-devices.sh<br/>Background service"]
        POSTINSTALL["post-install.sh<br/>trustedProxies config"]
    end
    
    subgraph DATA["data/"]
        direction TB
        WIREGUARD["wireguard/<br/>VPN keys"]
        CERTBOT["certbot/<br/>SSL certs"]
        CLAWBOT_HOME["clawbot_home/<br/>Gateway data"]
    end
    
    ROOT --> CONFIG
    ROOT --> SCRIPTS
    ROOT --> DATA
```

## Flujo de Conexión de Usuario

```mermaid
sequenceDiagram
    autonumber
    participant USER as Usuario
    participant WG as WireGuard Client
    participant VPN as clawbot_vpn
    participant PROXY as clawbot_proxy
    participant GW as clawbot_gateway
    
    USER->>WG: Activar VPN
    WG->>VPN: Handshake WireGuard
    VPN-->>WG: Tunnel establecido<br/>IP: 10.13.13.x
    
    USER->>PROXY: GET https://172.22.0.9?token=xxx
    Note over USER,PROXY: Aceptar cert autofirmado
    PROXY->>GW: Forward + WebSocket headers
    
    alt Dispositivo no emparejado
        GW-->>PROXY: Error 4008/1008
        PROXY-->>USER: Pairing required
        Note over GW: auto-approve aprueba<br/>cada 5 segundos
    else Dispositivo OK
        GW-->>PROXY: Success
        PROXY-->>USER: Gateway UI
    end
```

## Servicios Docker

```mermaid
flowchart TB
    subgraph SERVICES["docker-compose.yml"]
        direction LR
        
        subgraph VPN_SVC["vpn"]
            VPN_IMG["ghcr.io/wg-easy/wg-easy"]
            VPN_PORTS["51820/udp, 51821/tcp"]
            VPN_IP["172.22.0.6"]
        end
        
        subgraph PROXY_SVC["proxy"]
            PROXY_IMG["nginx:latest"]
            PROXY_EXPOSE[":80, :443 internal"]
            PROXY_IP["172.22.0.9"]
        end
        
        subgraph GW_SVC["gateway"]
            GW_IMG["clawbot-custom:latest"]
            GW_PORT[":18789 internal"]
            GW_IP["172.22.0.14"]
        end
    end
    
    VPN_SVC -.->|network| PROXY_SVC
    PROXY_SVC -->|proxy_pass| GW_SVC
    
    style VPN_SVC fill:#1976d2,color:#fff
    style PROXY_SVC fill:#388e3c,color:#fff
    style GW_SVC fill:#7b1fa2,color:#fff
```

## Variables de Entorno Críticas

```mermaid
flowchart LR
    subgraph ENV_FILE[".env"]
        direction TB
        A["DOMAIN_NAME"]
        B["VPN_PUBLIC_IP"]
        C["VPN_PASSWORD_HASH"]
        D["CLAWDBOT_TOKEN"]
    end
    
    subgraph USAGE["Uso en Servicios"]
        direction TB
        U1["VPN: WG_HOST, PASSWORD_HASH"]
        U2["Gateway: CLAWDBOT_GATEWAY_TOKEN"]
        U3["Nginx: ssl_certificate path"]
    end
    
    ENV_FILE --> USAGE
    
    style D fill:#ff5722,color:#fff
```

## Comandos Esenciales

```mermaid
flowchart TB
    subgraph INSTALL["Instalación"]
        I1["./scripts/onboard.sh"]
        I2["./setup.sh"]
        I3["docker-compose up -d"]
        I4["./scripts/post-install.sh"]
    end
    
    subgraph MANAGE["Gestión"]
        M1["docker-compose ps"]
        M2["docker logs -f [service]"]
        M3["docker-compose restart"]
    end
    
    subgraph DEBUG["Depuración"]
        D1["./scripts/diagnose.sh"]
        D2["docker exec clawbot_gateway<br/>clawdbot devices list"]
        D3["docker exec clawbot_gateway<br/>clawdbot devices approve ID"]
    end
    
    INSTALL --> MANAGE --> DEBUG
```

## Niveles de Seguridad

```mermaid
flowchart TD
    subgraph SECURITY["Capas de Seguridad"]
        direction TB
        
        L1["Nivel 1: VPN WireGuard<br/>Solo clientes autorizados"]
        L2["Nivel 2: Token Auth<br/>CLAWDBOT_TOKEN en URL"]
        L3["Nivel 3: Device Pairing<br/>Aprobación por dispositivo"]
        L4["Nivel 4: TrustedProxies<br/>Solo acepta de 172.22.0.9"]
    end
    
    L1 --> L2 --> L3 --> L4
    
    style L1 fill:#1565c0,color:#fff
    style L2 fill:#2e7d32,color:#fff
    style L3 fill:#ef6c00,color:#fff
    style L4 fill:#6a1b9a,color:#fff
```

## Troubleshooting Rápido

```mermaid
flowchart TD
    ERR["Error"] --> TYPE{"Tipo?"}
    
    TYPE -->|Conexión| C1["Verificar VPN activa"]
    TYPE -->|4008/1008| C2["Esperar auto-approve<br/>o aprobar manual"]
    TYPE -->|502 Gateway| C3["docker-compose restart gateway"]
    TYPE -->|SSL| C4["Aceptar cert en browser"]
    
    C1 --> DIAG["./scripts/diagnose.sh"]
    C2 --> DIAG
    C3 --> DIAG
    C4 --> DIAG
    
    style ERR fill:#f44336,color:#fff
    style DIAG fill:#4caf50,color:#fff
```

---

## 🎯 Skills Especializadas

Para tareas específicas, consulta las skills detalladas:

| Skill | Archivo | Uso |
|-------|---------|-----|
| 🐍 Python Services | [python-services-expert.md](.github/skills/python-services-expert.md) | Desarrollo de scripts bash/python |
| 🐳 Docker Compose | [docker-compose-expert.md](.github/skills/docker-compose-expert.md) | Configuración de contenedores |
| 🔧 Debugger | [application-debugger.md](.github/skills/application-debugger.md) | Depuración de errores |

---

## Archivos Clave

| Archivo | Propósito |
|---------|-----------|
| `docker-compose.yml` | Define los 5 servicios |
| `Dockerfile` | Build de imagen gateway |
| `setup.sh` | Wizard de configuración |
| `.env` | Variables de entorno |
| `config/nginx.conf` | Configuración reverse proxy |
| `scripts/diagnose.sh` | Script de diagnóstico |
