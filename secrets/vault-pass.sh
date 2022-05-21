#!/bin/bash

GPG=gpg2
if ! which $GPG > /dev/null 2>&1; then
    GPG=gpg
fi

echo "Getting vault pass from gpg..." 1>&2
cd "$(dirname "$0")"
$GPG --quiet --batch --use-agent --decrypt ./password.asc
