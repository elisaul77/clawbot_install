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

## Análisis de Logs por Servicio

```mermaid
flowchart LR
    subgraph GATEWAY_LOGS["Gateway Logs"]
        direction TB
        GL1["docker logs -f clawbot_gateway"]
        GL2["Buscar: error, pairing, token"]
        GL3["Healthcheck: :18789/health"]
    end
    
    subgraph PROXY_LOGS["Proxy Logs"]
        direction TB
        PL1["docker logs -f clawbot_proxy"]
        PL2["data/proxy_logs/"]
        PL3["Buscar: 502, 504, upstream"]
    end
    
    subgraph VPN_LOGS["VPN Logs"]
        direction TB
        VL1["docker logs -f clawbot_vpn"]
        VL2["docker exec clawbot_vpn wg show"]
        VL3["Buscar: handshake, peer"]
    end
    
    GATEWAY_LOGS --> ANALYZE["Correlacionar<br/>timestamps"]
    PROXY_LOGS --> ANALYZE
    VPN_LOGS --> ANALYZE
```

## Errores SSL/Certificados

```mermaid
flowchart TD
    SSL_ERR["Error: Certificado<br/>No Válido"] --> TYPE{"Usando<br/>IP o Dominio?"}
    
    TYPE -->|IP| SELF_SIGNED["Normal: Certificado<br/>autofirmado"]
    TYPE -->|Dominio| DOMAIN_CHECK{"Certificado<br/>expirado?"}
    
    SELF_SIGNED --> ACCEPT["Browser → Avanzado<br/>→ Aceptar riesgo"]
    
    DOMAIN_CHECK -->|Sí| RENEW["docker-compose run --rm<br/>certbot renew"]
    DOMAIN_CHECK -->|No| CERT_PATH["Verificar path:<br/>data/certbot/conf/live/"]
    
    RENEW --> RESTART["docker-compose<br/>restart proxy"]
    CERT_PATH --> GEN_CERT["Regenerar:<br/>setup.sh"]
    
    ACCEPT --> OK(["✅"])
    RESTART --> OK
    GEN_CERT --> OK
    
    style SSL_ERR fill:#ff9800,color:#000
    style OK fill:#4caf50,color:#fff
```

## Script diagnose.sh - Flujo

```mermaid
flowchart TD
    RUN["./scripts/diagnose.sh"] --> S1["1. Check Docker services<br/>docker ps"]
    S1 --> S2["2. VPN Status<br/>wg show"]
    S2 --> S3["3. Gateway logs<br/>grep error|warn|pairing"]
    S3 --> S4["4. Proxy logs<br/>grep error"]
    S4 --> S5["5. Network connectivity<br/>ping 172.22.0.9"]
    S5 --> S6["6. Port status<br/>nc -zv localhost [ports]"]
    S6 --> S7["7. Config validation<br/>.env, nginx.conf, clawdbot.json"]
    S7 --> RESULT["Mostrar resumen<br/>+ Common fixes"]
    
    style RUN fill:#2196f3,color:#fff
    style RESULT fill:#4caf50,color:#fff
```

## Matriz de Errores Comunes

```mermaid
flowchart TB
    subgraph ERRORS["Errores Comunes"]
        direction LR
        E1["502 Bad Gateway"]
        E2["Connection Refused"]
        E3["Token Invalid"]
        E4["Device Not Paired"]
        E5["SSL Handshake Failed"]
    end
    
    subgraph CAUSES["Causas"]
        direction LR
        C1["Gateway down"]
        C2["Network issue"]
        C3["Token mismatch"]
        C4["No approval"]
        C5["Cert missing"]
    end
    
    subgraph FIXES["Soluciones"]
        direction LR
        F1["restart gateway"]
        F2["check network"]
        F3["sync .env"]
        F4["approve device"]
        F5["regenerate cert"]
    end
    
    E1 --> C1 --> F1
    E2 --> C2 --> F2
    E3 --> C3 --> F3
    E4 --> C4 --> F4
    E5 --> C5 --> F5
```

## Verificación de Configuración

```mermaid
flowchart LR
    subgraph FILES["Archivos a Verificar"]
        direction TB
        F1[".env"]
        F2["config/nginx.conf"]
        F3["data/clawbot_home/<br/>.clawdbot/clawdbot.json"]
    end
    
    subgraph CHECKS[".env Checks"]
        direction TB
        C1["VPN_PUBLIC_IP=<tu IP>"]
        C2["VPN_PASSWORD_HASH=<hash>"]
        C3["CLAWDBOT_TOKEN=<64 hex>"]
        C4["DOMAIN_NAME=<IP o dominio>"]
    end
    
    subgraph NGINX_CHECKS["nginx.conf Checks"]
        direction TB
        N1["ssl_certificate path correcto"]
        N2["proxy_pass http://172.22.0.14:18789"]
        N3["WebSocket headers configurados"]
    end
    
    FILES --> CHECKS
    FILES --> NGINX_CHECKS
```

## Comandos de Debug Rápido

```mermaid
flowchart TB
    subgraph QUICK_DEBUG["Comandos Rápidos"]
        direction TB
        
        subgraph STATUS["Estado"]
            A["docker ps | grep clawbot"]
            B["docker-compose ps"]
        end
        
        subgraph LOGS["Logs"]
            C["docker logs --tail 50 clawbot_gateway"]
            D["docker logs --tail 50 clawbot_proxy"]
        end
        
        subgraph NETWORK["Red"]
            E["docker exec clawbot_gateway<br/>ping -c 2 172.22.0.9"]
            F["docker network inspect backend_net"]
        end
        
        subgraph RESTART["Reinicio"]
            G["docker-compose restart"]
            H["docker-compose down && docker-compose up -d"]
        end
    end
    
    STATUS --> LOGS --> NETWORK --> RESTART
```

## Debugging Token Issues

```mermaid
sequenceDiagram
    autonumber
    participant ENV as .env
    participant JSON as clawdbot.json
    participant GATEWAY as Gateway
    participant PROXY as Proxy
    
    Note over ENV,JSON: Verificar sincronización
    
    ENV->>ENV: cat .env | grep CLAWDBOT_TOKEN
    JSON->>JSON: cat data/clawbot_home/.clawdbot/clawdbot.json<br/>| grep token
    
    alt Tokens no coinciden
        ENV->>JSON: Copiar token de .env a JSON<br/>o viceversa
        JSON->>GATEWAY: docker-compose restart gateway
    else Tokens coinciden
        GATEWAY->>PROXY: Verificar trustedProxies<br/>en clawdbot.json
        Note over PROXY: Debe incluir 172.22.0.9
    end
    
    GATEWAY-->>PROXY: Conexión OK
```

## Checklist de Depuración

```mermaid
flowchart TD
    CHECK["Checklist Pre-Debug"] --> C1{"Docker<br/>instalado?"}
    C1 -->|No| I1["Instalar Docker"]
    C1 -->|Sí| C2{"docker-compose<br/>up?"}
    
    C2 -->|No| I2["docker-compose up -d"]
    C2 -->|Sí| C3{"Todos containers<br/>healthy?"}
    
    C3 -->|No| I3["docker-compose ps<br/>Revisar estados"]
    C3 -->|Sí| C4{".env<br/>completo?"}
    
    C4 -->|No| I4["./setup.sh"]
    C4 -->|Sí| C5{"VPN cliente<br/>conectada?"}
    
    C5 -->|No| I5["Conectar WireGuard"]
    C5 -->|Sí| C6{"Token en URL?"}
    
    C6 -->|No| I6["Agregar ?token=xxx"]
    C6 -->|Sí| DONE(["✅ Ready to debug<br/>specific issue"])
    
    I1 --> C1
    I2 --> C2
    I3 --> C3
    I4 --> C4
    I5 --> C5
    I6 --> C6
    
    style CHECK fill:#673ab7,color:#fff
    style DONE fill:#4caf50,color:#fff
```

## Auto-Approve Debug

```mermaid
flowchart TD
    AUTO_ERR["Auto-approve<br/>no funciona"] --> CHECK1{"Container<br/>running?"}
    
    CHECK1 -->|No| FIX1["docker-compose up -d auto-approve"]
    CHECK1 -->|Sí| CHECK2{"CLAWDBOT_GATEWAY_TOKEN<br/>en env?"}
    
    CHECK2 -->|No| FIX2["Verificar docker-compose.yml<br/>environment section"]
    CHECK2 -->|Sí| CHECK3{"Docker socket<br/>mounted?"}
    
    CHECK3 -->|No| FIX3["Verificar volume:<br/>/var/run/docker.sock"]
    CHECK3 -->|Sí| LOGS["docker logs -f<br/>clawbot_auto_approve"]
    
    FIX1 --> RETRY["Reintentar"]
    FIX2 --> RETRY
    FIX3 --> RETRY
    LOGS --> ANALYZE["Analizar output"]
    
    style AUTO_ERR fill:#ff5722,color:#fff
    style RETRY fill:#2196f3,color:#fff
```
