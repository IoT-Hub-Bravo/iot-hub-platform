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

---

# Environment Configuration

```env
KAFKA_BOOTSTRAP_SERVERS=kafka:9092
KAFKA_GROUP_ID=my-service-group
```

---

# Publishing Events

Example:

```python
producer.send(
    topic="telemetry.raw",
    value={
        "event_id": "...",
        "event_type": "telemetry.received",
        "version": "v1",
        "timestamp": "...",
        "source": "my-service",
        "correlation_id": "...",
        "payload": {...}
    }
)
```

---

# Consuming Events

```python
consumer.subscribe(["telemetry.raw"])

for message in consumer:
    event = message.value

    if event["event_type"] == "telemetry.received":
        handle_event(event)
```

---

# Adding Service to Platform

1. Add to docker-compose:

```yaml
my-service:
  build: ./services/my-service
  depends_on:
    - kafka
  networks:
    - backend
```

2. Ensure service joins `backend` network

---

# Topic Responsibilities

| Service        | Consumes        | Produces        |
| -------------- | --------------- | --------------- |
| telemetry      | telemetry.raw   | telemetry.clean |
| rule-engine    | telemetry.clean | rules.triggered |
| events-service | rules.triggered | events.recorded |

---

# Best Practices

* Use `correlation_id` for tracing
* Ensure idempotent consumers
* Do not modify existing event schemas
* Use retry + DLQ for failures

---
