#!/bin/sh
set -e

CERT_DIR="/etc/nginx/certs"

echo "Checking SSL certificates..."

if [ ! -f "$CERT_DIR/localhost.pem" ] || [ ! -f "$CERT_DIR/localhost-key.pem" ]; then
  echo "Certificates not found. Generating..."

  openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout "$CERT_DIR/localhost-key.pem" \
    -out "$CERT_DIR/localhost.pem" \
    -subj "/CN=localhost"

  echo "Certificates generated"
else
  echo "Certificates already exist"
fi

echo "Starting nginx..."

exec "$@"