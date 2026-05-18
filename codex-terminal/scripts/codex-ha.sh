#!/bin/bash

set -e

SUPERVISOR_URL="${SUPERVISOR_URL:-http://supervisor}"
TOKEN="${SUPERVISOR_TOKEN:-${HOMEASSISTANT_TOKEN:-}}"
OPTIONS_FILE="/data/options.json"

option() {
    local key="$1"
    local default="$2"
    if [ -f "$OPTIONS_FILE" ]; then
        jq -r --arg key "$key" --arg default "$default" '.[$key] // $default' "$OPTIONS_FILE" 2>/dev/null || echo "$default"
    else
        echo "$default"
    fi
}

api_call() {
    local method="$1"
    local endpoint="$2"
    local body="${3:-}"

    if [ -z "$TOKEN" ]; then
        echo "SUPERVISOR_TOKEN is not set" >&2
        return 1
    fi

    if [ -n "$body" ]; then
        curl -sS -X "$method" \
            -H "Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$body" \
            "${SUPERVISOR_URL}/${endpoint}"
    else
        curl -sS -X "$method" \
            -H "Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json" \
            "${SUPERVISOR_URL}/${endpoint}"
    fi
}

check_config() {
    api_call POST "core/api/config/core/check_config" "{}" | jq .
}

show_safety() {
    echo "Safety options:"
    echo "- readonly_mode: $(option readonly_mode false)"
    echo "- require_backup_before_edit: $(option require_backup_before_edit true)"
    echo "- enable_device_control: $(option enable_device_control false)"
    echo "- enable_file_tools: $(option enable_file_tools true)"
    echo "- enable_yaml_editing: $(option enable_yaml_editing true)"
    echo "- max_log_lines: $(option max_log_lines 80)"
    echo "- ha_context_refresh_minutes: $(option ha_context_refresh_minutes 30)"
}

doctor() {
    local failed=0

    echo "Codex Terminal doctor"
    echo ""

    for bin in codex curl jq python3 yq tmux ttyd uvx bwrap; do
        if command -v "$bin" >/dev/null 2>&1; then
            echo "OK: $bin"
        else
            echo "FAIL: missing $bin"
            failed=1
        fi
    done

    echo ""
    if [ -n "$TOKEN" ]; then
        echo "OK: Supervisor token is present"
        if api_call GET "core/info" >/tmp/codex-ha-core-info.json 2>/dev/null; then
            echo "OK: Home Assistant Core API reachable"
            jq -r '"Core version: " + (.data.version // "unknown")' /tmp/codex-ha-core-info.json 2>/dev/null || true
        else
            echo "FAIL: Home Assistant Core API not reachable"
            failed=1
        fi
    else
        echo "FAIL: Supervisor token is missing"
        failed=1
    fi

    echo ""
    if command -v validate-skills >/dev/null 2>&1; then
        validate-skills || failed=1
    else
        echo "FAIL: validate-skills command missing"
        failed=1
    fi

    echo ""
    if codex mcp list >/tmp/codex-ha-mcp.txt 2>/dev/null; then
        echo "OK: Codex MCP list works"
        cat /tmp/codex-ha-mcp.txt
    else
        echo "WARN: Codex MCP list failed"
    fi

    echo ""
    show_safety

    echo ""
    if [ "$failed" -eq 0 ]; then
        echo "Doctor passed"
    else
        echo "Doctor found issues"
    fi
    exit "$failed"
}

show_logs() {
    local slug="${1:-}"
    local lines
    lines="$(option max_log_lines 80)"

    if [ -z "$slug" ]; then
        echo "Usage: codex-ha logs <addon_slug>" >&2
        exit 1
    fi

    api_call GET "addons/${slug}/logs" | tail -"${lines}"
}

usage() {
    cat <<'USAGE'
Usage: codex-ha <command>

Commands:
  doctor        Check Codex, HA API, MCP, skills, and safety options
  context       Regenerate Home Assistant context when cache is stale
  context-force Regenerate Home Assistant context immediately
  check-config  Run Home Assistant configuration check
  mcp           List Codex MCP servers
  safety        Print safety options
  logs SLUG     Print add-on logs for SLUG
USAGE
}

command="${1:-doctor}"
shift || true

case "$command" in
    doctor) doctor "$@" ;;
    context) ha-context "$@" ;;
    context-force) ha-context --force "$@" ;;
    check-config) check_config ;;
    mcp) codex mcp list ;;
    safety) show_safety ;;
    logs) show_logs "$@" ;;
    help|--help|-h) usage ;;
    *) echo "Unknown command: $command" >&2; usage; exit 1 ;;
esac
