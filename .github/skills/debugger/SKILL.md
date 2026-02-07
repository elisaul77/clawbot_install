---
name: application-debugger
description: Describe what this skill does and when to use it. Include keywords that help agents identify relevant tasks.
---

# 🔧 Skill: Experto en Depuración de Aplicaciones

> Documentación oficial: https://docs.openclaw.ai/

## Flujo de Diagnóstico Principal

```mermaid
flowchart TD
    START(["🔴 Error Detectado"]) --> TRIAGE{"Tipo de<br/>Error?"}
    
    TRIAGE -->|WebSocket/Conexión| WS_PATH["Path WebSocket"]
    TRIAGE -->|SSL/Certificado| SSL_PATH["Path SSL"]
    TRIAGE -->|VPN| VPN_PATH["Path VPN"]
    TRIAGE -->|Autenticación| AUTH_PATH["Path Auth"]
    TRIAGE -->|Docker| DOCKER_PATH["Path Docker"]
    
    WS_PATH --> DIAG["./scripts/diagnose.sh"]
    SSL_PATH --> DIAG
    VPN_PATH --> DIAG
    AUTH_PATH --> DIAG
    DOCKER_PATH --> DIAG
    
    DIAG --> RESOLVE(["✅ Resolver"])
    
    style START fill:#f44336,color:#fff
    style RESOLVE fill:#4caf50,color:#fff
```

## Árbol de Decisiones - Errores de Conexión

```mermaid
flowchart TD
    ERR["Connection Failed<br/>Error WebSocket"] --> VPN_CHECK{"VPN<br/>Activa?"}
    
    VPN_CHECK -->|No| VPN_FIX["Activar WireGuard<br/>en cliente"]
    VPN_CHECK -->|Sí| PING_CHECK{"Ping<br/>172.22.0.9?"}
    
    PING_CHECK -->|No| NET_FIX["docker network inspect<br/>backend_net"]
    PING_CHECK -->|Sí| GW_CHECK{"Gateway<br/>running?"}
    
    GW_CHECK -->|No| GW_FIX["docker-compose<br/>restart gateway"]
    GW_CHECK -->|Sí| PROXY_CHECK{"Proxy<br/>running?"}
    
    PROXY_CHECK -->|No| PROXY_FIX["docker-compose<br/>restart proxy"]
    PROXY_CHECK -->|Sí| LOGS_CHECK["docker logs -f<br/>clawbot_gateway"]
    
    VPN_FIX --> RETRY["Reintentar conexión"]
    NET_FIX --> RETRY
    GW_FIX --> RETRY
    PROXY_FIX --> RETRY
    LOGS_CHECK --> ANALYZE["Analizar logs"]
    
    style ERR fill:#ff5722,color:#fff
    style RETRY fill:#2196f3,color:#fff
```

## Diagnóstico de Error 4008/1008 (Emparejamiento)

```mermaid
sequenceDiagram
    autonumber
    participant BROWSER as Browser
    participant PROXY as Nginx Proxy
    participant GATEWAY as Clawbot Gateway
    participant ADMIN as Admin CLI
    
    BROWSER->>PROXY: GET /?token=xxx
    PROXY->>GATEWAY: Forward request
    GATEWAY-->>PROXY: Error 4008/1008<br/>Device not paired
    PROXY-->>BROWSER: Show error
    
    Note over ADMIN,GATEWAY: Solución Manual
    
    ADMIN->>GATEWAY: docker exec clawbot_gateway<br/>clawdbot devices list
    GATEWAY-->>ADMIN: Lista pending requests
    ADMIN->>GATEWAY: clawdbot devices approve<br/><REQUEST_ID>
    GATEWAY-->>ADMIN: Device approved
    
    BROWSER->>PROXY: Refresh page
    PROXY->>GATEWAY: Forward request
    GATEWAY-->>PROXY: Success
    PROXY-->>BROWSER: Gateway UI
```
