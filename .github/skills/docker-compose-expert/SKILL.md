---
name: docker-compose-expert
description: Describe what this skill does and when to use it. Include keywords that help agents identify relevant tasks.
---

# 🐳 Skill: Experto en Docker Compose

> Documentación oficial: https://docs.openclaw.ai/

## Arquitectura de Servicios Docker

```mermaid
architecture-beta
    group clawbot_network(cloud)[Clawbot Network - 172.22.0.0/24]
    
    service vpn(server)[VPN WireGuard<br/>172.22.0.6] in clawbot_network
    service proxy(server)[Nginx Proxy<br/>172.22.0.9] in clawbot_network
    service gateway(server)[Clawbot Gateway<br/>172.22.0.14] in clawbot_network
    service certbot(disk)[Certbot] in clawbot_network
    service autoapprove(server)[Auto-Approve] in clawbot_network
    
    vpn:R --> L:proxy
    proxy:R --> L:gateway
    autoapprove:T --> B:gateway
    certbot:T --> B:proxy
```

## Flujo de Red y Puertos

```mermaid
flowchart LR
    subgraph INTERNET["Internet"]
        CLIENT["Cliente VPN"]
    end
    
    subgraph HOST["Host Server"]
        PORT_VPN["51820/udp<br/>VPN Traffic"]
        PORT_ADMIN["51821/tcp<br/>VPN Admin UI"]
    end
    
    subgraph DOCKER_NET["Docker Network<br/>172.22.0.0/24"]
        VPN["clawbot_vpn<br/>172.22.0.6"]
        PROXY["clawbot_proxy<br/>172.22.0.9<br/>:80, :443"]
        GATEWAY["clawbot_gateway<br/>172.22.0.14<br/>:18789"]
    end
    
    CLIENT -->|WireGuard| PORT_VPN
    CLIENT -->|HTTP| PORT_ADMIN
    PORT_VPN --> VPN
    PORT_ADMIN --> VPN
    VPN -->|VPN Tunnel| PROXY
    PROXY -->|reverse proxy| GATEWAY
    
    style INTERNET fill:#e3f2fd
    style HOST fill:#fff3e0
    style DOCKER_NET fill:#e8f5e9
```

## Estructura del docker-compose.yml

```mermaid
flowchart TB
    subgraph SERVICES["Servicios Definidos"]
        direction TB
        VPN["vpn<br/>ghcr.io/wg-easy/wg-easy"]
        PROXY["proxy<br/>nginx:latest"]
        GW["gateway<br/>clawbot-custom:latest"]
        CERT["certbot<br/>certbot/certbot"]
        AUTO["auto-approve<br/>docker:latest"]
    end
    
    subgraph NETWORKS["Red Personalizada"]
        NET["backend_net<br/>bridge driver<br/>172.22.0.0/24"]
    end
    
    subgraph VOLUMES["Volúmenes Persistentes"]
        V1["./data/wireguard"]
        V2["./data/certbot/conf"]
        V3["./data/clawbot_home"]
        V4["./config/nginx.conf"]
    end
    
    SERVICES --> NETWORKS
    SERVICES --> VOLUMES
    
    style VPN fill:#1976d2,color:#fff
    style PROXY fill:#388e3c,color:#fff
    style GW fill:#7b1fa2,color:#fff
```

## Dependencias entre Servicios

```mermaid
flowchart TD
    VPN["vpn"] 
    PROXY["proxy"]
    GATEWAY["gateway"]
    CERTBOT["certbot"]
    AUTOAPPROVE["auto-approve"]
    
    PROXY -->|depends_on| GATEWAY
    AUTOAPPROVE -->|depends_on| GATEWAY
    
    CERTBOT -.->|volumes shared| PROXY
    VPN -.->|network access| PROXY
    
    style VPN fill:#2196f3,color:#fff
    style GATEWAY fill:#9c27b0,color:#fff
    style PROXY fill:#4caf50,color:#fff
```

## Variables de Entorno Críticas

```mermaid
flowchart LR
    subgraph ENV_FILE[".env"]
        direction TB
        A["VPN_PUBLIC_IP"]
        B["VPN_PASSWORD_HASH"]
        C["CLAWDBOT_TOKEN"]
        D["DOMAIN_NAME"]
    end
    
    subgraph VPN_SERVICE["Servicio VPN"]
        direction TB
        E["WG_HOST=${VPN_PUBLIC_IP}"]
        F["PASSWORD_HASH=${VPN_PASSWORD_HASH}"]
        G["WG_PORT=51820"]
        H["WG_DEFAULT_ADDRESS=10.13.13.x"]
    end
    
    subgraph GW_SERVICE["Servicio Gateway"]
        direction TB
        I["CLAWDBOT_GATEWAY_TOKEN=${CLAWDBOT_TOKEN}"]
        J["NODE_ENV=production"]
    end
    
    ENV_FILE --> VPN_SERVICE
    ENV_FILE --> GW_SERVICE
```

## Ciclo de Vida de Contenedores

```mermaid
sequenceDiagram
    autonumber
    participant USER as Usuario
    participant COMPOSE as docker-compose
    participant VPN as vpn container
    participant PROXY as proxy container
    participant GW as gateway container
    
    USER->>COMPOSE: docker-compose up -d
    
    par Inicio paralelo
        COMPOSE->>VPN: Crear y arrancar
        VPN-->>COMPOSE: Running
    and
        COMPOSE->>GW: Build + arrancar
        GW-->>COMPOSE: Running
    end
    
    Note over COMPOSE,GW: Gateway debe estar listo primero
    
    COMPOSE->>PROXY: depends_on: gateway OK
    PROXY-->>COMPOSE: Running
    
    COMPOSE-->>USER: All services started
```

## Patrones de Volúmenes

```mermaid
flowchart TB
    subgraph HOST_DIRS["Directorios del Host"]
        H1["./data/wireguard/"]
        H2["./data/certbot/"]
        H3["./data/clawbot_home/"]
        H4["./config/nginx.conf"]
        H5["./data/proxy_logs/"]
    end
    
    subgraph CONTAINER_PATHS["Paths en Contenedores"]
        C1["/etc/wireguard"]
        C2["/etc/letsencrypt"]
        C3["/home/clawbot/.clawdbot"]
        C4["/etc/nginx/conf.d/default.conf:ro"]
        C5["/var/log/nginx"]
    end
    
    H1 --> C1
    H2 --> C2
    H3 --> C3
    H4 --> C4
    H5 --> C5
    
    style HOST_DIRS fill:#e3f2fd
    style CONTAINER_PATHS fill:#fce4ec
```

## Comandos Esenciales

```mermaid
flowchart LR
    subgraph START["Iniciar"]
        A1["docker-compose up -d"]
        A2["docker-compose up --build -d"]
    end
    
    subgraph MANAGE["Gestionar"]
        B1["docker-compose ps"]
        B2["docker-compose logs -f [service]"]
        B3["docker-compose restart [service]"]
    end
    
    subgraph STOP["Detener"]
        C1["docker-compose stop"]
        C2["docker-compose down"]
        C3["docker-compose down -v"]
    end
    
    START --> MANAGE --> STOP
    
    style START fill:#4caf50,color:#fff
    style MANAGE fill:#2196f3,color:#fff
    style STOP fill:#f44336,color:#fff
```

## Configuración de Red

```mermaid
flowchart TB
    subgraph NETWORK_CONFIG["Configuración de Red"]
        direction TB
        NET_DEF["networks:<br/>  backend_net:<br/>    driver: bridge"]
        IPAM["ipam:<br/>  config:<br/>    - subnet: 172.22.0.0/24"]
    end
    
    subgraph IP_ASSIGNMENTS["IPs Asignadas"]
        direction LR
        IP1["vpn: 172.22.0.6"]
        IP2["proxy: 172.22.0.9"]
        IP3["gateway: 172.22.0.14"]
    end
    
    subgraph VPN_ROUTING["Rutas VPN"]
        direction TB
        ALLOWED["WG_ALLOWED_IPS:<br/>10.13.13.0/24<br/>172.22.0.0/24"]
    end
    
    NETWORK_CONFIG --> IP_ASSIGNMENTS
    IP_ASSIGNMENTS --> VPN_ROUTING
```

## Build del Dockerfile

```mermaid
flowchart TD
    BASE["FROM node:22-bookworm"] --> DEPS["apt-get install<br/>git, curl, python3"]
    DEPS --> BUN["Install Bun<br/>curl bun.sh"]
    BUN --> PNPM["corepack enable<br/>pnpm ready"]
    PNPM --> CLAWDBOT["npm install -g<br/>clawdbot@latest"]
    CLAWDBOT --> USER["Create user clawbot<br/>UID 1000"]
    USER --> DIRS["mkdir /home/clawbot<br/>.clawdbot, clawd, logs"]
    DIRS --> HEALTH["HEALTHCHECK<br/>curl :18789/health"]
    HEALTH --> CMD["CMD clawdbot gateway<br/>--bind lan"]
    
    style BASE fill:#43a047,color:#fff
    style CMD fill:#1565c0,color:#fff
```

## Troubleshooting Docker

```mermaid
flowchart TD
    ERROR["Error Docker"] --> CHECK1{"Container<br/>running?"}
    CHECK1 -->|No| CMD1["docker-compose up -d"]
    CHECK1 -->|Sí| CHECK2{"Logs<br/>con error?"}
    
    CHECK2 -->|Sí| CMD2["docker logs -f [container]"]
    CHECK2 -->|No| CHECK3{"Network<br/>issue?"}
    
    CHECK3 -->|Sí| CMD3["docker network inspect<br/>backend_net"]
    CHECK3 -->|No| CHECK4{"Volume<br/>perms?"}
    
    CHECK4 -->|Sí| CMD4["chmod -R 777 data/"]
    CHECK4 -->|No| CMD5["docker-compose down<br/>docker-compose up -d --build"]
    
    CMD1 --> RETRY["Reintentar"]
    CMD2 --> RETRY
    CMD3 --> RETRY
    CMD4 --> RETRY
    CMD5 --> RETRY

    style ERROR fill:#f44336,color:#fff
    style RETRY fill:#4caf50,color:#fff
```

## Capacidades Especiales del VPN

```mermaid
flowchart LR
    subgraph CAP_ADD["Capabilities Requeridas"]
        direction TB
        NET["NET_ADMIN<br/>Network management"]
        SYS["SYS_MODULE<br/>Kernel modules"]
    end
    
    subgraph SYSCTLS["Sysctls"]
        direction TB
        FWD["ip_forward=1<br/>Enable routing"]
        MARK["src_valid_mark=1<br/>WireGuard marks"]
    end
    
    CAP_ADD --> SYSCTLS
    
    style CAP_ADD fill:#ff9800,color:#000
    style SYSCTLS fill:#9c27b0,color:#fff
```
