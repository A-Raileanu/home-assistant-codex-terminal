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
        echo "SUPERVISOR_TOKEN nu este setat" >&2
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
    echo "Opțiuni de siguranță:"
    echo "- readonly_mode: $(option readonly_mode false)"
    echo "- require_backup_before_edit: $(option require_backup_before_edit true)"
    echo "- enable_device_control: $(option enable_device_control false)"
    echo "- enable_file_tools: $(option enable_file_tools true)"
    echo "- enable_yaml_editing: $(option enable_yaml_editing true)"
    echo "- codex_full_permissions: $(option codex_full_permissions true)"
    echo "- context_detail_level: $(option context_detail_level standard)"
    echo "- include_addon_logs: $(option include_addon_logs false)"
    echo "- safe_edit_backup_retention_days: $(option safe_edit_backup_retention_days 30)"
    echo "- max_log_lines: $(option max_log_lines 80)"
    echo "- ha_context_refresh_minutes: $(option ha_context_refresh_minutes 30)"
}

show_context_json() {
    local context_dir="${CONTEXT_JSON_DIR:-/data/ha-context}"

    if [ ! -d "$context_dir" ]; then
        echo "Datele structurate nu există în ${context_dir}"
        echo "Rulează: ha-context --force"
        exit 1
    fi

    echo "Date structurate: ${context_dir}"
    find "$context_dir" -maxdepth 1 -type f -name "*.json" -print | sort
}

doctor() {
    local failed=0

    echo "Diagnostic Codex Terminal"
    echo ""

    for bin in codex curl jq python3 yq tmux ttyd uvx bwrap websocat; do
        if command -v "$bin" >/dev/null 2>&1; then
            echo "OK: $bin"
        else
            echo "EROARE: lipsește $bin"
            failed=1
        fi
    done

    echo ""
    if [ -n "$TOKEN" ]; then
        echo "OK: tokenul Supervisor este disponibil"
        if api_call GET "core/info" >/tmp/codex-ha-core-info.json 2>/dev/null; then
            echo "OK: API-ul Home Assistant Core răspunde"
            jq -r '"Versiune Core: " + (.data.version // "necunoscută")' /tmp/codex-ha-core-info.json 2>/dev/null || true
        else
            echo "EROARE: API-ul Home Assistant Core nu răspunde"
            failed=1
        fi
    else
        echo "EROARE: lipsește tokenul Supervisor"
        failed=1
    fi

    echo ""
    if [ -x /opt/scripts/validate-skills.sh ]; then
        /opt/scripts/validate-skills.sh || failed=1
    else
        echo "EROARE: lipsește scriptul validate-skills"
        failed=1
    fi

    echo ""
    if codex mcp list >/tmp/codex-ha-mcp.txt 2>/dev/null; then
        echo "OK: lista conexiunilor MCP este disponibilă"
        cat /tmp/codex-ha-mcp.txt
    else
        echo "AVERTISMENT: lista conexiunilor MCP nu a putut fi citită"
    fi

    if [ -x /opt/ha-mcp/bin/python ]; then
        local bundled_version
        bundled_version="$(/opt/ha-mcp/bin/python -c 'import importlib.metadata; print(importlib.metadata.version("ha-mcp"))' 2>/dev/null || true)"
        if [ -n "$bundled_version" ]; then
            echo "OK: ha-mcp ${bundled_version} este instalat în imagine"
        else
            echo "EROARE: mediul ha-mcp nu poate fi citit"
            failed=1
        fi
    else
        echo "EROARE: mediul ha-mcp instalat în imagine lipsește"
        failed=1
    fi

    echo ""
    show_safety

    if [ "$(option codex_full_permissions true)" = "true" ]; then
        echo "AVERTISMENT: codex_full_permissions este activ; Codex rulează fără confirmări și izolare"
    fi

    if [ "$(option enable_ha_mcp true)" != "true" ]; then
        echo "INFORMAȚIE: MCP Home Assistant nu este înregistrat deoarece enable_ha_mcp este dezactivat"
    elif [ "$(option mcp_mode ha-mcp)" = "disabled" ]; then
        echo "INFORMAȚIE: MCP Home Assistant nu este înregistrat deoarece mcp_mode este disabled"
    elif [ "$(option readonly_mode false)" = "true" ]; then
        echo "INFORMAȚIE: MCP Home Assistant nu este înregistrat cât timp readonly_mode este activ"
    elif [ "$(option enable_device_control false)" != "true" ]; then
        echo "INFORMAȚIE: MCP Home Assistant nu este înregistrat deoarece enable_device_control este false"
        echo "            Pentru a-l adăuga în Codex, setează enable_device_control: true și repornește add-on-ul"
    fi

    echo ""
    if [ "$failed" -eq 0 ]; then
        echo "Diagnosticul nu a găsit probleme"
    else
        echo "Diagnosticul a găsit probleme"
    fi
    exit "$failed"
}

show_logs() {
    local slug="${1:-}"
    local lines
    lines="$(option max_log_lines 80)"

    if [ -z "$slug" ]; then
        echo "Utilizare: codex-ha logs <slug_aplicație>" >&2
        exit 1
    fi

    api_call GET "addons/${slug}/logs" | tail -"${lines}"
}

usage() {
    cat <<'USAGE'
Utilizare: codex-ha <comandă>

Comenzi:
  doctor        Verifică Codex, API-ul HA, MCP, skill-urile și siguranța
  context       Actualizează datele Home Assistant; --force ignoră memoria temporară
  context-json  Listează fișierele JSON generate
  check-config  Verifică configurația Home Assistant
  mcp           Listează serverele MCP cunoscute de Codex
  safety        Arată opțiunile de siguranță
  plans         Listează planurile ha-safe-edit pregătite
  logs SLUG     Arată jurnalul aplicației cu acest SLUG
USAGE
}

command="${1:-doctor}"
shift || true

case "$command" in
    doctor) doctor "$@" ;;
    context) ha-context "$@" ;;
    context-json) show_context_json ;;
    check-config) check_config ;;
    mcp) codex mcp list ;;
    safety) show_safety ;;
    plans) ha-safe-edit list-plans ;;
    logs) show_logs "$@" ;;
    help|--help|-h) usage ;;
    *) echo "Comandă necunoscută: $command" >&2; usage; exit 1 ;;
esac
