#!/bin/bash

mkdir -p "$STUNNEL_CERT_DIR"

generate_pem() {
    cat "$STUNNEL_CERT_DIR/key.pem" "$STUNNEL_CERT_DIR/fullchain.pem" > /tmp/stunnel.pem
}

monitor_pem_file() {
    # use inotifywait to monitor changes in $STUNNEL_CERT_DIR
    # if any of them changes, send SIGHUP to stunnel3
    while true; do
        inotifywait -r "$STUNNEL_CERT_DIR"
        echo "Cert changed, reloading stunnel3..."
        sleep 1
        generate_pem
        pkill -HUP stunnel3
    done
}

monitor_pem_file &

while true; do
    generate_pem
    stunnel3 -f -p /tmp/stunnel.pem -d "$STUNNEL_LOCAL_PORT" -r "$STUNNEL_REMOTE"
    sleep 1
done
