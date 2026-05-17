#!/bin/bash

set -e

missing=0

for bin in codex node npm ttyd tmux git rg jq curl uvx; do
    if command -v "$bin" >/dev/null 2>&1; then
        echo "OK: $bin"
    else
        echo "MISSING: $bin" >&2
        missing=1
    fi
done

if [ -z "${SUPERVISOR_TOKEN:-}" ]; then
    echo "WARNING: SUPERVISOR_TOKEN is not set; HA API and MCP features will not work." >&2
fi

if [ "$missing" -ne 0 ]; then
    exit 1
fi
