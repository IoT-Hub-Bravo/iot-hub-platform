# Service Integration Guide

This document describes how independent service repositories integrate with the IoT Hub platform.

---

# Overview

All services communicate via Kafka using shared event contracts defined in `CONTRACTS.md`.

Each service acts as:

* **Producer** (publishes events)
* **Consumer** (subscribes to events)

---

# Requirements

Each service MUST:

* Connect to Kafka (`kafka:9092`)
* Use the shared event envelope
* Follow topic naming conventions
* Validate payloads against contracts
* Use Kafka headers for metadata (`correlation_id`, `protocol`)

---

# Environment Configuration

```env
KAFKA_BOOTSTRAP_SERVERS=kafka:9092
KAFKA_GROUP_ID=my-service-group
SERVICE_HOST=0.0.0.0
SERVICE_PORT=8000
```
# Publishing Events

**Example:**
```py
producer.send(
    topic="telemetry.raw",
    value={
        "event_id": "...",
        "event_type": "telemetry.received",
        "version": "v1",
        "timestamp": "...",
        "source": "my-service",
        "payload": {...}
    },
    headers=[
        ("correlation_id", b"..."),
        ("protocol", b"mqtt")
    ]
)
```

# Consuming Events
```py
consumer.subscribe(["telemetry.raw"])

for message in consumer:
    event = message.value
    headers = dict(message.headers)

    correlation_id = headers.get("correlation_id")

    if event["event_type"] == "telemetry.received":
        handle_event(event, correlation_id)
```

# Adding Service to Platform

## Add to docker-compose

```yaml
my-service:
  build: ./services/my-service
  depends_on:
    - kafka
  networks:
    - backend
```

## Docker Naming Conventions

All services MUST follow naming convention:

`<domain>-<service>`

**Examples:**

- telemetry-service
- rule-engine
- alerts-service

## Container Naming
- Avoid hardcoding `container_name`
- Let Docker Compose manage container names
## Port Strategy
### Internal Ports (inside container)

| Type     | Port |
| -------- | ---- |
| HTTP API | 8000 |

### External Ports (host machine)
Use domain-based ranges to avoid collisions:

| Domain    | Range     |
| --------- | --------- |
| Core      | 1000–1999 |
| Telemetry | 2000–2999 |
| Rules     | 3000–3999 |
| Alerts    | 4000–4999 |

**Example:**
```yaml
telemetry-service:
ports:
    - "2100:8000"

rule-engine:
ports:
    - "3100:8000"

alerts-service:
ports:
    - "4100:8000"
```
## Service Communication

Services MUST communicate via Docker network DNS:

`http://<service-name>:<port>`

**Example:**
```
http://telemetry-service:8000
http://rule-engine:8000
```

> [!CAUTION]
> ❌ DO NOT use localhost between services

## Network Configuration

All services MUST join the shared network:
```yaml
networks:
backend:
    driver: bridge
```
---

## Topic Responsibilities
| Service           | Consumes        | Produces        |
| ----------------- | --------------- | --------------- |
| telemetry-service | telemetry.raw   | telemetry.clean |
| rule-engine       | telemetry.clean | rules.triggered |
| alerts-service    | rules.triggered | alerts.created  |

## Best Practices
- Use correlation_id for tracing (via Kafka headers)
- Ensure idempotent consumers
- Do not modify existing event schemas
- Use retry + DLQ for failures
- Do not use localhost for service-to-service communication
- Keep ports consistent across services

---

## Summary

Following this guide ensures:

- Consistent service integration
- No port or naming collisions
- Reliable event-driven communication
- Scalable and maintainable platform architecture