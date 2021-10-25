#!/bin/bash

echo "Getting vault pass from gpg..." 1>&2
cd "$(dirname "$0")"
gpg2 --quiet --batch --use-agent --decrypt ./password.asc
