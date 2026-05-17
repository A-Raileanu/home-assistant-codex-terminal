#!/bin/bash

CYAN='\033[0;36m'
GREEN='\033[0;32m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'

MOTD_VERSION_FILE="/data/.codex-terminal-motd-version"
ADDON_VERSION_FILE="/opt/scripts/addon-version"

current_version() {
    cat "$ADDON_VERSION_FILE" 2>/dev/null || echo "unknown"
}

last_seen_version() {
    cat "$MOTD_VERSION_FILE" 2>/dev/null || echo "none"
}

save_version() {
    echo "$1" > "$MOTD_VERSION_FILE" 2>/dev/null || true
}

main() {
    local version last_seen
    version="$(current_version)"
    last_seen="$(last_seen_version)"

    echo ""
    echo -e "  ${CYAN}Codex Terminal${NC} ${DIM}v${version}${NC}"
    echo -e "  ${DIM}Home Assistant Add-on - OpenAI Codex CLI in your sidebar${NC}"
    echo ""

    if [ "$version" != "$last_seen" ] && [ "$version" != "unknown" ]; then
        echo -e "  ${GREEN}What's new:${NC}"
        echo "  - Codex CLI with persistent auth under /data"
        echo "  - Home Assistant context generation"
        echo "  - Optional Home Assistant MCP integration"
        echo ""
        save_version "$version"
    fi

    echo "  Useful commands:"
    echo "    codex --cd /config"
    echo "    codex login"
    echo "    codex mcp list"
    echo "    ha-context"
    echo ""
    printf "  Press Enter to continue..."
    read -r
}

main "$@"
