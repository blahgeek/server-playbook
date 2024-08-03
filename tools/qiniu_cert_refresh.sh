#!/bin/bash -ex

export CF_Token="$CLOUDFLARE_API_TOKEN"
# blahgeek.com zone
export CF_Zone_ID="60e2d0bdfcb99d08771679ced29925d8"

cd "$(dirname "$0")"

ACMESH="../third_party/acme.sh/acme.sh"

install_domain() {
    DOMAIN="$1"
    "$ACMESH" --issue --dns dns_cf -d "$DOMAIN"
    "$ACMESH" --deploy -d "$DOMAIN" --deploy-hook qiniu
}

install_domain qnsource.hpurl.blahgeek.com
