#!/bin/bash

set -e

SUPERVISOR_URL="${SUPERVISOR_URL:-http://supervisor}"
TOKEN="${SUPERVISOR_TOKEN:-${HOMEASSISTANT_TOKEN:-}}"
OPTIONS_FILE="/data/options.json"
BACKUP_ROOT="/data/safe-edit-backups"

option() {
    local key="$1"
    local default="$2"
    if [ -f "$OPTIONS_FILE" ]; then
        jq -r --arg key "$key" --arg default "$default" '.[$key] // $default' "$OPTIONS_FILE" 2>/dev/null || echo "$default"
    else
        echo "$default"
    fi
}

assert_enabled() {
    local readonly yaml_editing
    local file_tools
    readonly="$(option readonly_mode false)"
    yaml_editing="$(option enable_yaml_editing true)"
    file_tools="$(option enable_file_tools true)"

    if [ "$readonly" = "true" ]; then
        echo "readonly_mode is enabled; refusing to edit" >&2
        exit 1
    fi

    if [ "$yaml_editing" != "true" ]; then
        echo "enable_yaml_editing is false; refusing to edit" >&2
        exit 1
    fi

    if [ "$file_tools" != "true" ]; then
        echo "enable_file_tools is false; refusing file operation" >&2
        exit 1
    fi
}

backup_file() {
    local file="$1"
    local timestamp dest

    if [ ! -f "$file" ]; then
        echo "File does not exist: $file" >&2
        exit 1
    fi

    timestamp="$(date '+%Y%m%d-%H%M%S')"
    dest="${BACKUP_ROOT}${file}.${timestamp}.bak"
    mkdir -p "$(dirname "$dest")"
    cp -a "$file" "$dest"
    prune_old_backups
    echo "$dest"
}

prune_old_backups() {
    local retention_days
    retention_days="$(option safe_edit_backup_retention_days 30)"

    if ! [[ "$retention_days" =~ ^[0-9]+$ ]] || [ "$retention_days" -le 0 ]; then
        return 0
    fi

    find "$BACKUP_ROOT" -type f -name "*.bak" -mtime +"$retention_days" -delete 2>/dev/null || true
}

yaml_check_file() {
    local file="$1"

    case "$file" in
        *.yaml|*.yml)
            python3 - "$file" <<'PY'
import pathlib
import sys
import yaml

path = pathlib.Path(sys.argv[1])
with path.open("r", encoding="utf-8") as handle:
    yaml.safe_load(handle)
print(f"YAML OK: {path}")
PY
            ;;
    esac
}

ha_check_config() {
    if [ -z "$TOKEN" ]; then
        echo "WARN: SUPERVISOR_TOKEN not set; skipping Home Assistant config check" >&2
        return 0
    fi

    curl -sS -X POST \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{}" \
        "${SUPERVISOR_URL}/core/api/config/core/check_config" | jq .
}

safe_edit() {
    local file="$1"
    shift || true

    if [ -z "$file" ]; then
        echo "Usage: ha-safe-edit <file> -- <command...>" >&2
        exit 1
    fi

    if [ "${1:-}" != "--" ]; then
        echo "Usage: ha-safe-edit <file> -- <command...>" >&2
        exit 1
    fi
    shift

    if [ "$#" -eq 0 ]; then
        echo "No edit command supplied" >&2
        exit 1
    fi

    assert_enabled
    local backup
    backup="$(backup_file "$file")"
    echo "Backup: $backup"

    "$@"

    yaml_check_file "$file"
    ha_check_config
}

usage() {
    cat <<'USAGE'
Usage:
  ha-safe-edit <file> -- <command...>
  ha-safe-edit backup <file>
  ha-safe-edit check [file]

Examples:
  ha-safe-edit /config/automations.yaml -- sh -c 'yq -i ". += []" /config/automations.yaml'
  ha-safe-edit backup /config/configuration.yaml
  ha-safe-edit check /config/configuration.yaml
USAGE
}

command="${1:-}"

case "$command" in
    backup)
        shift
        assert_enabled
        backup_file "${1:-}"
        ;;
    check)
        shift || true
        [ -z "${1:-}" ] || yaml_check_file "$1"
        ha_check_config
        ;;
    help|--help|-h|"")
        usage
        ;;
    *)
        safe_edit "$@"
        ;;
esac
