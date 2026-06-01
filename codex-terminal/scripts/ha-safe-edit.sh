#!/bin/bash

set -e

SUPERVISOR_URL="${SUPERVISOR_URL:-http://supervisor}"
TOKEN="${SUPERVISOR_TOKEN:-${HOMEASSISTANT_TOKEN:-}}"
OPTIONS_FILE="${OPTIONS_FILE:-/data/options.json}"
BACKUP_ROOT="${BACKUP_ROOT:-/data/safe-edit-backups}"
PLAN_ROOT="${PLAN_ROOT:-/data/safe-edit-plans}"

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
    local readonly_mode yaml_editing
    local file_tools
    readonly_mode="$(option readonly_mode false)"
    yaml_editing="$(option enable_yaml_editing true)"
    file_tools="$(option enable_file_tools true)"

    if [ "$readonly_mode" = "true" ]; then
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

file_sha256() {
    sha256sum "$1" | awk '{print $1}'
}

plan_id_for_file() {
    local file="$1"
    local base
    base="$(printf '%s' "$(basename "$file")" | tr -c 'A-Za-z0-9._-' '_')"
    printf "%s-%s" "$(date '+%Y%m%d-%H%M%S')" "$base"
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

safe_plan() {
    local file="$1"
    shift || true

    if [ -z "$file" ] || [ "${1:-}" != "--" ]; then
        echo "Usage: ha-safe-edit plan <file> -- <command...>" >&2
        exit 1
    fi
    shift

    if [ "$#" -eq 0 ]; then
        echo "No edit command supplied" >&2
        exit 1
    fi

    assert_enabled

    if [ ! -f "$file" ]; then
        echo "File does not exist: $file" >&2
        exit 1
    fi

    local plan_id plan_dir original staged diff_file metadata backup original_hash command_display
    plan_id="$(plan_id_for_file "$file")"
    plan_dir="${PLAN_ROOT}/${plan_id}"
    original="${plan_dir}/original"
    staged="${plan_dir}/staged"
    diff_file="${plan_dir}/diff.patch"
    metadata="${plan_dir}/metadata.json"
    command_display="$(printf '%q ' "$@")"

    mkdir -p "$plan_dir"
    cp -a "$file" "$original"
    original_hash="$(file_sha256 "$original")"
    backup="$(backup_file "$file")"

    restore_original() {
        cp -a "$original" "$file"
    }
    trap restore_original EXIT

    "$@"

    yaml_check_file "$file"
    ha_check_config

    cp -a "$file" "$staged"
    restore_original
    trap - EXIT

    diff -u "$original" "$staged" > "$diff_file" || true

    jq -n \
        --arg id "$plan_id" \
        --arg file "$file" \
        --arg backup "$backup" \
        --arg original_hash "$original_hash" \
        --arg staged_hash "$(file_sha256 "$staged")" \
        --arg created_at "$(date -Iseconds)" \
        --arg command "$command_display" \
        '{id:$id,file:$file,backup:$backup,original_hash:$original_hash,staged_hash:$staged_hash,created_at:$created_at,command:$command}' \
        > "$metadata"

    echo "Plan: $plan_id"
    echo "File: $file"
    echo "Backup: $backup"
    echo "Diff: $diff_file"
    echo ""
    cat "$diff_file"
    echo ""
    echo "Apply with: ha-safe-edit apply $plan_id"
}

safe_apply_plan() {
    local plan_id="$1"
    local plan_dir metadata file staged original_hash current_hash backup

    if [ -z "$plan_id" ]; then
        echo "Usage: ha-safe-edit apply <plan_id>" >&2
        exit 1
    fi

    assert_enabled

    plan_dir="${PLAN_ROOT}/${plan_id}"
    metadata="${plan_dir}/metadata.json"
    staged="${plan_dir}/staged"

    if [ ! -f "$metadata" ] || [ ! -f "$staged" ]; then
        echo "Plan not found or incomplete: $plan_id" >&2
        exit 1
    fi

    file="$(jq -r '.file' "$metadata")"
    original_hash="$(jq -r '.original_hash' "$metadata")"

    if [ ! -f "$file" ]; then
        echo "Target file no longer exists: $file" >&2
        exit 1
    fi

    current_hash="$(file_sha256 "$file")"
    if [ "$current_hash" != "$original_hash" ]; then
        echo "Refusing to apply: target changed since plan was created" >&2
        echo "Expected: $original_hash" >&2
        echo "Current:  $current_hash" >&2
        exit 1
    fi

    backup="$(backup_file "$file")"
    cp -a "$staged" "$file"

    yaml_check_file "$file"
    ha_check_config

    jq --arg applied_at "$(date -Iseconds)" --arg apply_backup "$backup" \
        '. + {applied_at:$applied_at, apply_backup:$apply_backup}' \
        "$metadata" > "${metadata}.tmp"
    mv "${metadata}.tmp" "$metadata"

    echo "Applied plan: $plan_id"
    echo "File: $file"
    echo "Backup: $backup"
}

list_plans() {
    if [ ! -d "$PLAN_ROOT" ]; then
        echo "No plans found."
        return 0
    fi

    find "$PLAN_ROOT" -mindepth 2 -maxdepth 2 -name metadata.json -print | sort | while IFS= read -r metadata; do
        jq -r '"\(.id)\t\(.created_at)\t\(.file)\t" + (if .applied_at then "applied " + .applied_at else "pending" end)' "$metadata"
    done
}

show_plan() {
    local plan_id="$1"
    local plan_dir="${PLAN_ROOT}/${plan_id}"

    if [ -z "$plan_id" ] || [ ! -f "${plan_dir}/metadata.json" ]; then
        echo "Usage: ha-safe-edit show-plan <plan_id>" >&2
        exit 1
    fi

    jq . "${plan_dir}/metadata.json"
    echo ""
    cat "${plan_dir}/diff.patch"
}

usage() {
    cat <<'USAGE'
Usage:
  ha-safe-edit <file> -- <command...>
  ha-safe-edit plan <file> -- <command...>
  ha-safe-edit apply <plan_id>
  ha-safe-edit list-plans
  ha-safe-edit show-plan <plan_id>
  ha-safe-edit backup <file>
  ha-safe-edit check [file]

Examples:
  ha-safe-edit /config/automations.yaml -- sh -c 'yq -i ". += []" /config/automations.yaml'
  ha-safe-edit plan /config/automations.yaml -- sh -c 'yq -i ". += []" /config/automations.yaml'
  ha-safe-edit apply 20260528-121314-automations.yaml
  ha-safe-edit backup /config/configuration.yaml
  ha-safe-edit check /config/configuration.yaml
USAGE
}

command="${1:-}"

case "$command" in
    plan)
        shift
        safe_plan "$@"
        ;;
    apply)
        shift
        safe_apply_plan "${1:-}"
        ;;
    list-plans)
        list_plans
        ;;
    show-plan)
        shift
        show_plan "${1:-}"
        ;;
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
