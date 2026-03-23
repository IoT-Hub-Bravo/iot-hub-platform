# Shared Event Contracts

This document defines the baseline cross-service event contracts for the IoT Hub platform.
These contracts enable consistent communication between independently developed microservices.

---

# Event Envelope

All events MUST follow the standard envelope:

```json
{
  "event_id": "uuid",
  "event_type": "telemetry.received",
  "version": "v1",
  "timestamp": "ISO-8601",
  "source": "service-name",
  "correlation_id": "trace-id",
  "payload": {}
}
```

### Fields

| Field          | Description                      |
| -------------- | -------------------------------- |
| event_id       | Unique event identifier          |
| event_type     | Domain + action                  |
| version        | Schema version                   |
| timestamp      | Event creation time              |
| source         | Producing service                |
| correlation_id | Used for tracing across services |
| payload        | Event-specific data              |

---

# Versioning Rules

* Version format: `v1`, `v2`, etc.
* Breaking changes → new version
* Existing versions MUST NOT be modified
* Services SHOULD support backward compatibility when possible

---

# Topic Naming Convention

```
<domain>.<stage>
```

### Examples

```
telemetry.raw
telemetry.clean
telemetry.expired
rules.triggered
events.recorded
audit.events
```

---

# Event Contracts

## Telemetry

### telemetry.received.v1

**Topic:** `telemetry.raw`

```json
{
  "device_serial": "string",
  "ts": "ISO-8601",
  "metrics": {
    "<metric_name>": {
      "value": "int | float | string | bool",
      "unit": "string"
    }
  },
  "protocol": "mqtt | http"
}
```

**Notes:**

* `metrics` is a dynamic map keyed by metric name
* `value` is polymorphic and MUST be interpreted using `unit` and downstream config

---

### telemetry.processed.v1

**Topic:** `telemetry.clean`

```json
{
  "device_serial_id": "string",
  "device_metric_id": "number",
  "ts": "ISO-8601",
  "value_jsonb": {
    "t": "numeric | string | boolean",
    "v": "int | float | string | bool"
  }
}
```

**Notes:**

* Normalized structure optimized for storage and querying
* `device_metric_id` is resolved via device registry/config service
* `value_jsonb` is aligned with DB storage format

---

### telemetry.expired.v1

**Topic:** `telemetry.expired`

```json
{
  "device_serial_id": "string",
  "device_metric_id": "number",
  "ts": "ISO-8601",
  "value_jsonb": {
    "t": "numeric | string | boolean",
    "v": "int | float | string | bool"
  }
}
```

**Notes:**

* Emitted when telemetry is considered stale or out-of-retention window
* Same schema as processed for reuse in downstream consumers

---

## Rules

### rule.triggered.v1

**Topic:** `rules.triggered`

```json
{
  "event_uuid": "string",
  "rule_triggered_at": "ISO-8601",
  "rule_id": "number",
  "trigger_device_serial_id": "string",
  "trigger_context": {
    "metric_type": "string",
    "value": "number",
    "telemetry_timestamp": "ISO-8601"
  },
  "action": {
    "webhook": {
      "url": "string",
      "enabled": "boolean"
    },
    "notification": {
      "channel": "string",
      "enabled": "boolean",
      "message": "string (templated)"
    }
  }
}
```

**Notes:**

* `event_uuid` links rule execution across services
* `trigger_context` captures the exact condition that fired the rule
* `action` block represents resolved execution plan (not just config)

---

## Events Registry

### event.recorded.v1

**Topic:** `events.recorded`

```json
{ 
  "event_uuid": "string (uuid)", 
  "rule_id": "number", 
  "rule_triggered_at": "ISO-8601", 
  "created_at": "ISO-8601", 
  "acknowledged": "boolean", 
  "is_external": "boolean", 
  "trigger_device_serial_id": "string", 
  "trigger_context": 
  { 
    "any": "flexible JSON structure" 
  } 
}
```

**Notes:**

* Represents persisted business event derived from rule execution
* Used as source of truth for actions and history

---

## Audit

### audit.log.v1

**Topic:** `audit.events`

```json
{
  "service": "string",
  "action": "string",
  "entity_id": "string",
  "timestamp": "ISO-8601",
  "status": "SUCCESS | FAILED"
}
```

**Notes:**

* Emitted by all services
* MUST NOT affect business flow (fire-and-forget)
* Used for observability and compliance

---

# Publishing & Consuming Guidelines

## Publishing

* MUST use the standard envelope
* MUST validate payload against schema before sending
* MUST include `correlation_id` for traceability
* SHOULD include meaningful `event_type` aligned with naming conventions

## Consuming

* MUST validate event version
* SHOULD ignore unknown fields (forward compatibility)
* MUST handle idempotency (avoid duplicate processing)
* SHOULD log and route invalid events to dead-letter topics

---

# Design Principles

* Contracts are the **single source of truth**
* Events are **immutable**
* Services are **loosely coupled via events**
* Each domain owns its contracts
* Avoid reusing the same event across multiple stages
* Prefer **explicit events per stage** over overloading one schema

---

# Testing Strategy

## Service-Level Testing

* Mock external dependencies (Kafka, DB, other services)
* Validate schema compliance
* Validate producer/consumer logic

## Integration Testing

* Use real message broker (e.g., Kafka)
* Validate end-to-end event flow
* Validate contract compatibility between services

---

# Smoke Test Flow

1. Start platform (docker-compose or Kubernetes)
2. Publish `telemetry.received` event
3. Verify:

   * Telemetry is processed (`telemetry.clean`)
   * Expired telemetry (if applicable) is emitted
   * Rule is triggered (`rules.triggered`)
   * Event is recorded (`events.recorded`)
   * Audit log is created (`audit.events`)

---

# Acceptance Summary

* Shared contracts are defined and structured
* Standard event envelope is enforced
* Versioning rules are documented
* Topics and naming conventions are consistent
* End-to-end flow is testable

---
