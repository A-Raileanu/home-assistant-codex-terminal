#!/bin/bash

set -e

SUPERVISOR_URL="http://supervisor"
OUTPUT_FILE="${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
SKILL_DIR="${CODEX_HOME:-$HOME/.codex}/skills/home-assistant"
MAX_LOG_LINES="${MAX_LOG_LINES:-80}"
REFRESH_MINUTES="${HA_CONTEXT_REFRESH_MINUTES:-30}"
FULL_MODE=false
FORCE_REFRESH=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force)
            FORCE_REFRESH=true
            shift
            ;;
        --full)
            FULL_MODE=true
            shift
            ;;
        --refresh-minutes)
            REFRESH_MINUTES="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: ha-context [--force] [--full] [--refresh-minutes MINUTES] [--output FILE]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

api_call() {
    local endpoint="$1"
    curl -s -m 10 \
        -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
        -H "Content-Type: application/json" \
        "${SUPERVISOR_URL}/${endpoint}" 2>/dev/null || true
}

ha_api_call() {
    api_call "core/api/${1}"
}

check_prerequisites() {
    if [ -z "${SUPERVISOR_TOKEN:-}" ]; then
        echo "SUPERVISOR_TOKEN is not set; this must run inside a Home Assistant add-on." >&2
        exit 1
    fi

    for cmd in curl jq; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Required command not found: $cmd" >&2
            exit 1
        fi
    done
}

context_is_fresh() {
    local file="$1"
    local refresh_minutes="$2"

    if [ "$FORCE_REFRESH" = true ]; then
        return 1
    fi

    if [ ! -f "$file" ]; then
        return 1
    fi

    if ! [[ "$refresh_minutes" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    if [ "$refresh_minutes" -le 0 ]; then
        return 1
    fi

    python3 - "$file" "$refresh_minutes" <<'PY'
import pathlib
import sys
import time

path = pathlib.Path(sys.argv[1])
refresh_seconds = int(sys.argv[2]) * 60
age = time.time() - path.stat().st_mtime
sys.exit(0 if age < refresh_seconds else 1)
PY
}

section_system_info() {
    local core_info host_info ha_config
    core_info="$(api_call "core/info")"
    host_info="$(api_call "host/info")"
    ha_config="$(ha_api_call "config")"

    local ha_version machine ha_os hostname timezone location_name
    ha_version="$(echo "$core_info" | jq -r '.data.version // empty' 2>/dev/null)"
    machine="$(echo "$core_info" | jq -r '.data.machine // empty' 2>/dev/null)"
    ha_os="$(echo "$host_info" | jq -r '.data.operating_system // empty' 2>/dev/null)"
    hostname="$(echo "$host_info" | jq -r '.data.hostname // empty' 2>/dev/null)"
    timezone="$(echo "$ha_config" | jq -r '.time_zone // empty' 2>/dev/null)"
    location_name="$(echo "$ha_config" | jq -r '.location_name // empty' 2>/dev/null)"

    [ -n "$ha_version" ] && echo "- Home Assistant: ${ha_version}" || echo "- Home Assistant: unavailable"
    [ -n "$machine" ] && echo "- Machine: ${machine}"
    [ -n "$ha_os" ] && echo "- OS: ${ha_os}"
    [ -n "$hostname" ] && echo "- Hostname: ${hostname}"
    [ -n "$location_name" ] && echo "- Location: ${location_name}"
    [ -n "$timezone" ] && echo "- Timezone: ${timezone}"
}

section_entity_summary() {
    local states
    states="$(ha_api_call "states")"

    if [ -z "$states" ] || ! echo "$states" | jq -e '.' >/dev/null 2>&1; then
        echo "Unable to retrieve entity states."
        return
    fi

    local total
    total="$(echo "$states" | jq 'length')"

    echo "| Domain | Count |"
    echo "|--------|-------|"
    echo "$states" | jq -r '
        [.[].entity_id | split(".")[0]] | group_by(.) |
        map({domain: .[0], count: length}) |
        sort_by(-.count) |
        .[] | "| \(.domain) | \(.count) |"
    ' 2>/dev/null
    echo ""
    echo "Total: ${total} entities"

    if [ "$FULL_MODE" = true ]; then
        echo ""
        echo "### Entity Details"
        echo "$states" | jq -r '
            group_by(.entity_id | split(".")[0])[] |
            "#### " + (.[0].entity_id | split(".")[0]) + "\n" +
            (.[0:25] | map("- `" + .entity_id + "`") | join("\n")) + "\n"
        ' 2>/dev/null
    fi
}

section_addons() {
    local addons_data
    addons_data="$(api_call "addons")"

    if [ -z "$addons_data" ] || ! echo "$addons_data" | jq -e '.data.addons' >/dev/null 2>&1; then
        echo "Unable to retrieve add-on information."
        return
    fi

    echo "$addons_data" | jq -r '
        .data.addons[] |
        select(.installed == true) |
        "- \(.name) v\(.version) (\(.state))"
    ' 2>/dev/null | sort
}

section_recent_errors() {
    local error_log
    error_log="$(ha_api_call "error_log")"

    if [ -z "$error_log" ] || [ "$error_log" = "\"\"" ]; then
        echo "No recent errors."
        return
    fi

    echo '```text'
    echo "$error_log" | tail -20 | cut -c1-200
    echo '```'
}

section_integrations() {
    local config_entries
    config_entries="$(ha_api_call "config/config_entries/entry")"

    if [ -z "$config_entries" ] || ! echo "$config_entries" | jq -e '.' >/dev/null 2>&1; then
        echo "Unable to retrieve integration entries."
        return
    fi

    echo "$config_entries" | jq -r '
        if type == "array" then .
        elif .data and (.data | type == "array") then .data
        else [] end |
        map(select(.disabled_by == null)) |
        group_by(.domain // "unknown") |
        map({domain: .[0].domain, count: length}) |
        sort_by(.domain) |
        .[] | "- \(.domain): \(.count)"
    ' 2>/dev/null
}

section_automation_inventory() {
    local states
    states="$(ha_api_call "states")"

    if [ -z "$states" ] || ! echo "$states" | jq -e '.' >/dev/null 2>&1; then
        echo "Unable to retrieve automation/script/scene inventory."
        return
    fi

    echo "$states" | jq -r '
        map(select(.entity_id | test("^(automation|script|scene)\\."))) |
        group_by(.entity_id | split(".")[0])[] |
        "### " + (.[0].entity_id | split(".")[0]) + " (" + (length | tostring) + ")\n" +
        (.[0:30] | map("- `" + .entity_id + "`: " + (.attributes.friendly_name // .entity_id) + " [" + .state + "]") | join("\n")) + "\n"
    ' 2>/dev/null
}

section_unavailable_entities() {
    local states
    states="$(ha_api_call "states")"

    if [ -z "$states" ] || ! echo "$states" | jq -e '.' >/dev/null 2>&1; then
        echo "Unable to retrieve entity states."
        return
    fi

    local count
    count="$(echo "$states" | jq '[.[] | select(.state == "unavailable" or .state == "unknown")] | length')"
    echo "Total unavailable/unknown: ${count}"

    echo "$states" | jq -r '
        [.[] | select(.state == "unavailable" or .state == "unknown")] |
        group_by(.entity_id | split(".")[0]) |
        .[] |
        "### " + (.[0].entity_id | split(".")[0]) + "\n" +
        (.[0:25] | map("- `" + .entity_id + "`: " + .state) | join("\n")) + "\n"
    ' 2>/dev/null
}

section_repairs() {
    local repairs
    repairs="$(api_call "resolution/info")"

    if [ -z "$repairs" ] || ! echo "$repairs" | jq -e '.data' >/dev/null 2>&1; then
        echo "Unable to retrieve repairs/issues."
        return
    fi

    echo "$repairs" | jq -r '
        .data |
        "- Unsupported: \((.unsupported // []) | length)\n" +
        "- Unhealthy: \((.unhealthy // []) | length)\n" +
        "- Suggestions: \((.suggestions // []) | length)\n" +
        "- Issues: \((.issues // []) | length)"
    ' 2>/dev/null
}

section_recorder() {
    local db_path="/config/home-assistant_v2.db"

    if [ -f "$db_path" ]; then
        local size
        size="$(du -h "$db_path" 2>/dev/null | awk '{print $1}')"
        echo "- Recorder database: ${db_path} (${size})"
    else
        echo "- Recorder database not found at ${db_path}"
    fi
}

section_addon_logs() {
    local addons_data
    addons_data="$(api_call "addons")"

    if [ -z "$addons_data" ] || ! echo "$addons_data" | jq -e '.data.addons' >/dev/null 2>&1; then
        echo "Unable to retrieve add-on logs."
        return
    fi

    echo "$addons_data" | jq -r '.data.addons[] | select(.installed == true) | .slug' 2>/dev/null | head -10 | while IFS= read -r slug; do
        [ -n "$slug" ] || continue
        echo "### ${slug}"
        echo '```text'
        api_call "addons/${slug}/logs" | tail -"${MAX_LOG_LINES}" | cut -c1-220
        echo '```'
        echo ""
    done
}

write_skill() {
    mkdir -p "$SKILL_DIR"
    cat > "$SKILL_DIR/SKILL.md" <<'SKILL'
---
name: home-assistant
description: "Use when working on this Home Assistant machine: configuration YAML, automations, scripts, dashboards, add-ons, Supervisor/Core APIs, logs, entities, and troubleshooting."
---

# Home Assistant

You are running inside a Home Assistant add-on container.

## Local Paths

- `/config` is the mapped Home Assistant configuration directory.
- `$CODEX_HOME/AGENTS.md` contains generated context for this installation.
- `/data` persists across add-on restarts and updates.
- `ha-context` refreshes live context.
- `codex-ha doctor` checks auth, API access, MCP, skills, and safety options.
- `ha-safe-edit` backs up files and validates YAML/config checks around edits.

## Safety

- Treat this as a live home automation system.
- Prefer reading and validating before editing.
- Use `ha-safe-edit` before changing YAML or other `/config` files.
- Always store backups under `/data/safe-edit-backups` (or a subfolder inside it).
- Do not write backup files next to source files in `/config` (no inline `.bak` files).
- Keep backup paths in your final response.
- Treat device control as opt-in. Avoid service calls unless the user explicitly requested them.
- Explain device-control side effects before issuing service calls.
- Never edit `.storage/` directly unless the user explicitly accepts the risk and no API path exists.

## APIs

- Supervisor API base: `http://supervisor`
- Core API base: `http://supervisor/core/api`
- Use `Authorization: Bearer $SUPERVISOR_TOKEN`.
- The `home-assistant` MCP server may be available through Codex.

## Useful Commands

```bash
ha-context
codex-ha doctor
ha-safe-edit check
codex mcp list
curl -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/core/info
curl -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/core/api/states
```

## Included Skills

- `home-assistant-best-practices`
- `ha-automation-author`
- `ha-dashboard-author`
- `ha-template-debugger`
- `ha-safe-refactor`
- `ha-add-on-developer`
- `ha-troubleshooter`
SKILL
}

generate_agents_md() {
    local timestamp tmp_file
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    mkdir -p "$(dirname "$OUTPUT_FILE")"
    tmp_file="$(mktemp "${OUTPUT_FILE}.XXXXXX")"

    {
        echo "# Home Assistant Context"
        echo ""
        echo "Auto-generated by the Codex Terminal add-on. Run \`ha-context\` to refresh."
        echo "Last updated: ${timestamp}"
        echo ""
        echo "## System"
        echo ""
        section_system_info
        echo ""
        echo "## Entities"
        echo ""
        section_entity_summary
        echo ""
        echo "## Installed Add-ons"
        echo ""
        section_addons
        echo ""
        echo "## Integrations"
        echo ""
        section_integrations
        echo ""
        echo "## Automations, Scripts, And Scenes"
        echo ""
        section_automation_inventory
        echo ""
        echo "## Unavailable Or Unknown Entities"
        echo ""
        section_unavailable_entities
        echo ""
        echo "## Repairs And System Health"
        echo ""
        section_repairs
        echo ""
        echo "## Recorder"
        echo ""
        section_recorder
        echo ""
        echo "## Recent Errors"
        echo ""
        section_recent_errors
        echo ""
        echo "## Add-on Log Samples"
        echo ""
        section_addon_logs
        echo ""
        echo "## API Access"
        echo ""
        echo '```bash'
        echo 'curl -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/core/info'
        echo 'curl -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/core/api/states'
        echo 'curl -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" -H "Content-Type: application/json" -d '"'"'{"entity_id":"light.example"}'"'"' http://supervisor/core/api/services/light/turn_on'
        echo '```'
    } > "$tmp_file"

    chmod 644 "$tmp_file"
    mv "$tmp_file" "$OUTPUT_FILE"
}

main() {
    check_prerequisites
    write_skill

    if context_is_fresh "$OUTPUT_FILE" "$REFRESH_MINUTES"; then
        echo "Home Assistant context is fresh; skipping refresh (${OUTPUT_FILE}, refresh window ${REFRESH_MINUTES} minutes)" >&2
        echo "Run 'ha-context --force' to refresh immediately." >&2
        exit 0
    fi

    generate_agents_md
    echo "Home Assistant context written to ${OUTPUT_FILE}" >&2
    echo "Home Assistant skill written to ${SKILL_DIR}/SKILL.md" >&2
}

main "$@"
