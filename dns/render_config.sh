#!/bin/bash -ex

cd "$(dirname "$0")"

jsonnet --string ./octodns.yaml.jsonnet -o octodns.yaml
jsonnet --multi config --string ./config.jsonnet
