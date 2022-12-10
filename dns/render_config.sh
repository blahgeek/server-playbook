#!/bin/bash -ex

cd "$(dirname "$0")"

jsonnet --multi config --string ./config.jsonnet
