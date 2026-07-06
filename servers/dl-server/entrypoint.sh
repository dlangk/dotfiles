#!/bin/sh
# Nginx entrypoint — generates self-signed cert fallback if Let's Encrypt certs
# are not yet available, then starts nginx.

CERT_DIR="/etc/letsencrypt/live/langkilde.se"
SELF_SIGNED_DIR="/etc/letsencrypt/self-signed"
FULLCHAIN="${CERT_DIR}/fullchain.pem"
PRIVKEY="${CERT_DIR}/privkey.pem"
FALLBACK_FULLCHAIN="${SELF_SIGNED_DIR}/fullchain.pem"
FALLBACK_PRIVKEY="${SELF_SIGNED_DIR}/privkey.pem"

if [ ! -f "$FULLCHAIN" ] || [ ! -f "$PRIVKEY" ]; then
  echo "Generating a self-signed certificate as a fallback..."
  mkdir -p "$SELF_SIGNED_DIR"
  openssl req -x509 -nodes -days 1 -newkey rsa:2048 \
    -keyout "$FALLBACK_PRIVKEY" \
    -out "$FALLBACK_FULLCHAIN" \
    -subj "/CN=localhost"
fi

while [ ! -f "$FULLCHAIN" ] || [ ! -f "$PRIVKEY" ]; do
  echo "Waiting for Certbot to generate certificates..."
  sleep 5
done

echo "Starting Nginx..."
exec nginx -g "daemon off;"
