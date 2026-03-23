#!/bin/bash

echo "🚀 Running smoke test..."

echo "Sending test telemetry event to Kafka..."

docker exec -i kafka \
/opt/kafka/bin/kafka-console-producer.sh \
--bootstrap-server kafka:9092 \
--topic telemetry.raw <<EOF
{"event_id":"test-1","event_type":"telemetry.received","version":"v1","timestamp":"2026-01-01T00:00:00Z","source":"smoke-test","correlation_id":"test-123","payload":{"device_serial":"TEST-DEVICE","metrics":{"temp":{"value":25,"unit":"C"}}}}
EOF

echo "✅ Event sent!"

echo "👉 Now check:"
echo "- kafka-ui (topics)"
echo "- rule-engine logs"
echo "- events service logs"