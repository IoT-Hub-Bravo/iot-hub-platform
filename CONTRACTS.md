# Shared Event Contracts

This document defines the baseline cross-service event contracts for the IoT Hub platform.

---

# Event Structure

Events are split into:

- **Kafka Headers** → event metadata (envelope)
- **Message Body (Payload)** → business data only

---

# Kafka Headers (Event Envelope)

All events MUST include the following headers:

| Header         | Description                      |
|----------------|----------------------------------|
| event_id       | Unique event identifier          |
| event_type     | Domain + action                  |
| version        | Schema version                   |
| timestamp      | Event creation time              |
| source         | Producing service                |
| correlation_id | Trace identifier                 |
| protocol       | Transport (mqtt, http, etc.)     |

---

## Example
```
event_id=uuid
event_type=telemetry.received
version=v1
timestamp=ISO-8601
source=telemetry-service
correlation_id=abc-123
protocol=mqtt
```
---

# Message Body (Payload)

- MUST contain **only business data**
- MUST NOT include envelope fields

---

# Versioning Rules

- Version format: `v1`, `v2`, etc.
- Breaking changes → new version
- Existing versions MUST NOT be modified

---

# Topic Naming Convention

```
<domain>.<stage>
```

### Examples

```
device.created
telemetry.raw
telemetry.clean
telemetry.expired
rules.triggered
alerts.created
audit.events
```

---

# Event Contracts

## Device

### device.created.v1

**Topic:** `device.regitry`

```json
{
  "device_serial_id": "string",
  "metrics":[
    {
      "name": "string", 
      "unit": "string", 
      "type": "numeric | string | boolean"
    }
  ],
  "created_at": "ISO-8601",
}

## Telemetry

### telemetry.received.v1

**Topic:** `telemetry.raw`

```json
{
  "device_serial_id": "string",
  "ts": "ISO-8601",
  "metrics": [
    {
      "name" :"metric_name",
      "value": "int | float | string | bool",
      "unit": "string" 
    }
  ]
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
  "type": "numeric | string | boolean",
  "value": "int | float | string | bool"
}
```

---

### telemetry.expired.v1

**Topic:** `telemetry.expired`
```json
{
  "device_serial_id": "string",
  "device_metric_id": "number",
  "ts": "ISO-8601",
  "type": "numeric | string | boolean",
  "value": "int | float | string | bool"
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

## Alerts 

### alert.created.v1

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

- Represents a business-level alert generated from rule execution
- Replaces generic event registry approach
- Used for monitoring, alerting, and user-facing systems
---

## Audit

### audit.log.v1

**Topic:** `audit.events`

```json
{
  "actor_type": "user | system | external",
  "actor_id": "string | null",
  "entity_type": "string",
  "entity_id": "string",
  "event_type": "string",
  "severity": "info | warning | error",
  "occurred_at": "ISO-8601",
  "details": {
    "any": "flexible JSON structure"
  },
  "audit_event_id": "uuid"
}
```

**Notes:**

* Emitted by all services
* MUST NOT affect business flow (fire-and-forget)
* Used for observability and compliance

---

# Publishing & Consuming Guidelines

## Publishing
- **MUST** use the standard event envelope
- **MUST** validate payload against schema before sending
- **MUST** include correlation_id in Kafka headers
- **SHOULD** include protocol in Kafka headers
- **SHOULD** include meaningful event_type
## Consuming
- **MUST** validate event version
- **SHOULD** ignore unknown fields (forward compatibility)
- **MUST** handle idempotency
- **SHOULD** read metadata from Kafka headers
- **SHOULD** route invalid events to dead-letter topics

---

# Design Principles
- Contracts are the single source of truth
- Events are immutable
- Services are loosely coupled via events
- Each domain owns its contracts
- Prefer explicit events per stage

---

# Testing Strategy
## Service-Level Testing
- Mock Kafka, DB, external services
- Validate schema compliance
- Validate producer/consumer logic

## Integration Testing
- Use real Kafka
- Validate end-to-end event flow
- Validate contract compatibility

---

# Smoke Test Flow
1. Start platform (docker-compose or Kubernetes)
2. Publish telemetry.received event
3. Verify:
  - Telemetry is processed (telemetry.clean)
  - Expired telemetry is emitted (telemetry.expired)
  - Rule is triggered (rules.triggered)
  - Alert is created (alerts.created)
  - Audit log is created (audit.events)

---

# Acceptance Summary
- Shared contracts are defined and structured
- Event envelope is consistent and validated
- Kafka headers are used for metadata
- Versioning rules are enforced
- Topics and naming are consistent
- End-to-end flow is testable