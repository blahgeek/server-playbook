#!/bin/bash

mkdir -p "$STUNNEL_CERT_DIR"

while true; do
    cat "$STUNNEL_CERT_DIR/fullchain.pem"
    cat "$STUNNEL_CERT_DIR/key.pem" "$STUNNEL_CERT_DIR/fullchain.pem" > /tmp/stunnel.pem
    timeout 1d \
            stunnel3 -f -p /tmp/stunnel.pem -d "$STUNNEL_LOCAL_PORT" -r "$STUNNEL_REMOTE"
    # restart every day, to pick up newest cert
done
