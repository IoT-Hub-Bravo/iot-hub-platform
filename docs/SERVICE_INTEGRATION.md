# Service Integration Guide

This document describes how independent service repositories integrate with the IoT Hub platform.

---

## Overview

All services communicate via Kafka using shared event contracts defined in `CONTRACTS.md`.

Each service acts as:

* **Producer** (publishes events)
* **Consumer** (subscribes to events)

---

## Requirements

Each service MUST:

* Connect to Kafka (`kafka:9092`)
* Use the shared event envelope (via Kafka headers)
* Follow topic naming conventions
* Validate payloads against contracts
* Use Kafka headers for metadata

---

## Environment Configuration

```env
KAFKA_BOOTSTRAP_SERVERS=kafka:9092
KAFKA_GROUP_ID=my-service-group
SERVICE_HOST=0.0.0.0
SERVICE_PORT=8000
```

---

## Publishing Events

**Example:**

```py
producer.send(
    topic="telemetry.raw",
    key=b"device-123",
    value={
        "payload": {...}
    },
    headers=[
        ("event_id", b"..."),
        ("event_type", b"telemetry.received"),
        ("version", b"v1"),
        ("timestamp", b"..."),
        ("source", b"my-service"),
        ("correlation_id", b"..."),
        ("protocol", b"mqtt")
    ]
)
```

---

## Consuming Events

```py
consumer.subscribe(["telemetry.raw"])

for message in consumer:
    event = message.value
    headers = {k: v.decode() for k, v in message.headers}

    event_type = headers.get("event_type")
    correlation_id = headers.get("correlation_id")

    if event_type == "telemetry.received":
        handle_event(event["payload"], correlation_id)
```

---

## Kafka Headers (Event Envelope)

All events **MUST include the following headers**:

| Header         | Description                    |
| -------------- | ------------------------------ |
| event_id       | Unique event identifier (UUID) |
| event_type     | Domain + action                |
| version        | Schema version                 |
| timestamp      | Event creation time (ISO-8601) |
| source         | Producing service              |
| correlation_id | Trace identifier               |
| protocol       | Transport (mqtt, http, etc.)   |

---

## Failure Handling

Consumers MUST:

* Retry processing (with backoff)
* Ensure idempotency
* On failure, publish event to a DLQ topic

**Example:**

```
telemetry.raw → telemetry.raw.dlq
```

---

## Adding Service to Platform

### Add to docker-compose

```yaml
my-service:
  build: ./services/my-service
  depends_on:
    - kafka
  networks:
    - backend
```

---

## Docker Naming Conventions

All services MUST follow naming convention:

```
<domain>-<service>
```

**Examples:**

* telemetry-service
* rule-engine
* alerts-service

---

## Container Naming

* Avoid hardcoding `container_name`
* Let Docker Compose manage container names

---

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

---

## Service Communication

Services MUST communicate via Docker network DNS:

```
http://<service-name>:<port>
```

**Examples:**

```
http://telemetry-service:8000
http://rule-engine:8000
```

> ❌ DO NOT use localhost between services

---

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

---

## Event Flow

```
telemetry-service → telemetry.raw
→ rule-engine → telemetry.clean
→ alerts-service → alerts.created
```

---

## Best Practices

* Use `correlation_id` for tracing
* Ensure idempotent consumers
* Do not modify existing event schemas
* Use retry + DLQ for failures
* Keep ports consistent across services

---

## Summary

Following this guide ensures:

* Consistent service integration
* No port or naming collisions
* Reliable event-driven communication
* Scalable and maintainable platform architecture
