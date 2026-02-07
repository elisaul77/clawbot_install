---
name: python-services-expert
description: Describe what this skill does and when to use it. Include keywords that help agents identify relevant tasks.
---

# 🐍 Skill: Experto en Desarrollo de Servicios Python

> Documentación oficial: https://docs.openclaw.ai/

## Arquitectura de Servicios Python en Clawbot

```mermaid
flowchart TB
    subgraph PY_PATTERNS["Patrones de Servicio Python"]
        direction TB
        CLI["CLI Scripts<br/>bash → python"]
        ASYNC["Async Processing<br/>loop + background"]
        DOCKER_INT["Docker Integration<br/>exec commands"]
    end
    
    subgraph ENTRY_POINTS["Entry Points del Proyecto"]
        direction LR
        ONBOARD["scripts/onboard.sh"]
        SETUP["setup.sh"]
        DIAG["scripts/diagnose.sh"]
        AUTO["scripts/auto-approve-devices.sh"]
    end
    
    ENTRY_POINTS --> PY_PATTERNS
    
    style PY_PATTERNS fill:#306998,color:#fff
    style ENTRY_POINTS fill:#ffd43b,color:#000
```

## Flujo de Desarrollo de Scripts

```mermaid
sequenceDiagram
    autonumber
    participant DEV as Developer
    participant SCRIPT as Bash Script
    participant DOCKER as Docker Container
    participant CLAWDBOT as clawdbot CLI
    
    DEV->>SCRIPT: Ejecutar ./script.sh
    SCRIPT->>SCRIPT: Validar dependencias
    SCRIPT->>DOCKER: docker exec clawbot_gateway
    DOCKER->>CLAWDBOT: clawdbot [command]
    CLAWDBOT-->>DOCKER: JSON/stdout response
    DOCKER-->>SCRIPT: Parse output
    SCRIPT-->>DEV: Formatted result
```

## Convenciones de Código

```mermaid
flowchart LR
    subgraph CONVENTIONS["Convenciones Obligatorias"]
        direction TB
        A["set -e en scripts"]
        B["Colores: GREEN, YELLOW, RED, NC"]
        C["Echo con -e para colores"]
        D["Validar docker antes de exec"]
    end
    
    subgraph ERROR_HANDLING["Manejo de Errores"]
        direction TB
        E["Verificar exit codes"]
        F["Logs descriptivos"]
        G["Timeout handling"]
    end
    
    CONVENTIONS --> ERROR_HANDLING
```

## Estructura de Script Típico

```mermaid
flowchart TD
    START([Inicio Script]) --> COLORS["Definir Colores<br/>GREEN, YELLOW, RED, NC"]
    COLORS --> TITLE["Mostrar Título<br/>echo -e con colores"]
    TITLE --> VALIDATE{"Validar<br/>Requisitos?"}
    
    VALIDATE -->|No Docker| ERROR["Error + Exit 1"]
    VALIDATE -->|OK| DIRS["Crear Directorios<br/>mkdir -p"]
    DIRS --> PERMS["Establecer Permisos<br/>chmod 777"]
    PERMS --> EXEC["Ejecutar Docker<br/>docker exec/run"]
    EXEC --> PARSE["Parsear Output<br/>grep, awk, sed"]
    PARSE --> OUTPUT["Mostrar Resultado<br/>con colores"]
    OUTPUT --> END([Fin])
    
    style START fill:#306998,color:#fff
    style END fill:#306998,color:#fff
    style ERROR fill:#ff6b6b,color:#fff
```

## Patrones de Integración Docker

```mermaid
flowchart LR
    subgraph DOCKER_PATTERNS["Patrones Docker"]
        direction TB
        RUN["docker run --rm -it<br/>Procesos interactivos"]
        EXEC["docker exec<br/>Comandos en contenedor activo"]
        BUILD["docker build -t<br/>Construir imagen local"]
    end
    
    subgraph VOLUMES["Volúmenes Típicos"]
        direction TB
        V1["/home/clawbot/.clawdbot<br/>Configuración"]
        V2["/home/clawbot/clawd<br/>Datos"]
        V3["/var/run/docker.sock<br/>Docker-in-Docker"]
    end
    
    DOCKER_PATTERNS --> VOLUMES
```

## Variables de Entorno Clave

```mermaid
flowchart TB
    subgraph ENV_VARS["Variables de Entorno"]
        direction LR
        TOKEN["CLAWDBOT_GATEWAY_TOKEN<br/>Auth token"]
        IP["VPN_PUBLIC_IP<br/>IP del servidor"]
        HASH["VPN_PASSWORD_HASH<br/>Hash bcrypt"]
        DOMAIN["DOMAIN_NAME<br/>Dominio o IP"]
    end
    
    subgraph FILES["Archivos de Config"]
        direction LR
        ENV[".env"]
        JSON["clawdbot.json"]
        NGINX["nginx.conf"]
    end
    
    ENV_VARS --> FILES
    
    style TOKEN fill:#ff9800,color:#000
    style ENV fill:#4caf50,color:#fff
```

## Ejemplo: Loop de Background

```mermaid
sequenceDiagram
    autonumber
    participant LOOP as While Loop
    participant DOCKER as docker exec
    participant GATEWAY as clawbot_gateway
    participant ACTION as Process Action
    
    loop Cada CHECK_INTERVAL segundos
        LOOP->>DOCKER: Lista dispositivos pendientes
        DOCKER->>GATEWAY: clawdbot devices list
        GATEWAY-->>DOCKER: JSON con pending
        DOCKER-->>LOOP: Parse REQUEST_IDs
        
        alt Hay dispositivos pendientes
            LOOP->>ACTION: Procesar cada REQUEST_ID
            ACTION->>DOCKER: clawdbot devices approve
            DOCKER->>GATEWAY: Aprobar dispositivo
        end
        
        LOOP->>LOOP: sleep $CHECK_INTERVAL
    end
```

## Debugging Tips

```mermaid
flowchart TD
    PROBLEM["Problema en Script"] --> CHECK1{"docker ps<br/>OK?"}
    CHECK1 -->|No| FIX1["docker-compose up -d"]
    CHECK1 -->|Sí| CHECK2{"Logs gateway<br/>tienen error?"}
    
    CHECK2 -->|Sí| ANALYZE["docker logs -f clawbot_gateway"]
    CHECK2 -->|No| CHECK3{"Permisos<br/>correctos?"}
    
    CHECK3 -->|No| FIX3["chmod -R 777 data/"]
    CHECK3 -->|Sí| CHECK4{"Token<br/>sincronizado?"}
    
    CHECK4 -->|No| FIX4["Revisar .env y clawdbot.json"]
    CHECK4 -->|Sí| DIAGNOSE["./scripts/diagnose.sh"]
    
    FIX1 --> RETRY["Reintentar"]
    FIX3 --> RETRY
    FIX4 --> RETRY
    ANALYZE --> RETRY
    DIAGNOSE --> RETRY
    
    style PROBLEM fill:#ff6b6b,color:#fff
    style RETRY fill:#4caf50,color:#fff
```
