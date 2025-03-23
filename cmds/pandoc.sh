#!/usr/bin/env bash

set -e

if [[ -z "$1" ]]; then
    echo "Usage: pandoc.sh input.md"
    exit 1
fi

podman run --rm -v "$(pwd)":/data:Z  pandoc/core /data/"$1" --toc -s -o "$1".html
