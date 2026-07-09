#!/bin/bash

set -e

SUPERVISOR_URL="http://supervisor"
OUTPUT_FILE="${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
SKILL_DIR="${CODEX_HOME:-$HOME/.codex}/skills/home-assistant-instance"
CONTEXT_JSON_DIR="${CONTEXT_JSON_DIR:-/data/ha-context}"
MAX_LOG_LINES="${MAX_LOG_LINES:-80}"
REFRESH_MINUTES="${HA_CONTEXT_REFRESH_MINUTES:-30}"
OPTIONS_FILE="${OPTIONS_FILE:-/data/options.json}"
CONTEXT_DETAIL_LEVEL="${CONTEXT_DETAIL_LEVEL:-standard}"
INCLUDE_ADDON_LOGS="${INCLUDE_ADDON_LOGS:-false}"
FULL_MODE=false
FORCE_REFRESH=false

option() {
    local key="$1"
    local default="$2"
    if [ -f "$OPTIONS_FILE" ]; then
        jq -r --arg key "$key" --arg default "$default" '.[$key] // $default' "$OPTIONS_FILE" 2>/dev/null || echo "$default"
    else
        echo "$default"
    fi
}

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
            echo "Utilizare: ha-context [--force] [--full] [--refresh-minutes MINUTES] [--output FILE]"
            exit 0
            ;;
        *)
            echo "Opțiune necunoscută: $1" >&2
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
        echo "SUPERVISOR_TOKEN nu este setat; comanda trebuie rulată în aplicația Home Assistant." >&2
        exit 1
    fi

    for cmd in curl jq; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Lipsește comanda necesară: $cmd" >&2
            exit 1
        fi
    done
}

context_level() {
    local level
    level="$CONTEXT_DETAIL_LEVEL"
    if [ "$FULL_MODE" = true ]; then
        level="full"
    fi
    echo "$level"
}

is_summary_mode() {
    [ "$(context_level)" = "summary" ]
}

include_addon_logs() {
    local enabled="$INCLUDE_ADDON_LOGS"
    [ "$(context_level)" = "full" ] && return 0
    [ "$enabled" = "true" ]
}

redact_sensitive() {
    python3 -c 'import re,sys; d=sys.stdin.read(); p=[(r"(?i)(authorization:\s*bearer\s+)[^\s]+",r"\1[REDACTED]"),(r"(?i)(token(?:=|:)\s*)[A-Za-z0-9._\-]+",r"\1[REDACTED]"),(r"(?i)(api[_-]?key(?:=|:)\s*)[A-Za-z0-9._\-]+",r"\1[REDACTED]"),(r"(?i)(password(?:=|:)\s*)\S+",r"\1[REDACTED]"),(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}","[REDACTED_EMAIL]")];
for rx,rep in p:
    d=re.sub(rx,rep,d)
print(d,end="")'
}

write_json_payload() {
    local output="$1"
    local payload="$2"

    if [ -n "$payload" ] && echo "$payload" | jq -e '.' >/dev/null 2>&1; then
        echo "$payload" | jq . > "$output"
    else
        jq -n --arg error "unavailable" '{error:$error}' > "$output"
    fi
}

write_storage_json() {
    local source="$1"
    local output="$2"

    if [ -f "$source" ] && jq -e '.' "$source" >/dev/null 2>&1; then
        jq . "$source" > "$output"
    else
        jq -n --arg source "$source" --arg error "missing_or_invalid" '{source:$source,error:$error}' > "$output"
    fi
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

    [ -n "$ha_version" ] && echo "- Home Assistant: ${ha_version}" || echo "- Home Assistant: indisponibil"
    [ -n "$machine" ] && echo "- Sistem: ${machine}"
    [ -n "$ha_os" ] && echo "- OS: ${ha_os}"
    [ -n "$hostname" ] && echo "- Nume gazdă: ${hostname}"
    [ -n "$location_name" ] && echo "- Locație: ${location_name}"
    [ -n "$timezone" ] && echo "- Fus orar: ${timezone}"
}

section_entity_summary() {
    local states
    states="$(ha_api_call "states")"

    if [ -z "$states" ] || ! echo "$states" | jq -e '.' >/dev/null 2>&1; then
        echo "Stările entităților nu au putut fi citite."
        return
    fi

    local total
    total="$(echo "$states" | jq 'length')"

    echo "| Domeniu | Număr |"
    echo "|--------|-------|"
    echo "$states" | jq -r '
        [.[].entity_id | split(".")[0]] | group_by(.) |
        map({domain: .[0], count: length}) |
        sort_by(-.count) |
        .[] | "| \(.domain) | \(.count) |"
    ' 2>/dev/null
    echo ""
    echo "Total: ${total} entități"

    if [ "$(context_level)" = "full" ]; then
        echo ""
        echo "### Detalii despre entități"
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
        echo "Informațiile despre aplicații nu au putut fi citite."
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
        echo "Nu există erori recente."
        return
    fi

    echo '```text'
    echo "$error_log" | tail -20 | cut -c1-200 | redact_sensitive
    echo '```'
}

section_integrations() {
    local config_entries
    config_entries="$(ha_api_call "config/config_entries/entry")"

    if [ -z "$config_entries" ] || ! echo "$config_entries" | jq -e '.' >/dev/null 2>&1; then
        echo "Integrările nu au putut fi citite."
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
        echo "Automatizările, scripturile și scenele nu au putut fi citite."
        return
    fi

    if is_summary_mode; then
        echo "Modul rezumat este activ; lista automatizărilor, scripturilor și scenelor este omisă."
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
        echo "Stările entităților nu au putut fi citite."
        return
    fi

    if is_summary_mode; then
        echo "Modul rezumat este activ; detaliile entităților indisponibile sunt omise."
        return
    fi

    local count
    count="$(echo "$states" | jq '[.[] | select(.state == "unavailable" or .state == "unknown")] | length')"
    echo "Total indisponibile sau necunoscute: ${count}"

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
        echo "Reparațiile și problemele nu au putut fi citite."
        return
    fi

    echo "$repairs" | jq -r '
        .data |
        "- Nesuportate: \((.unsupported // []) | length)\n" +
        "- Cu probleme: \((.unhealthy // []) | length)\n" +
        "- Sugestii: \((.suggestions // []) | length)\n" +
        "- Probleme: \((.issues // []) | length)"
    ' 2>/dev/null
}

section_recorder() {
    local db_path="/config/home-assistant_v2.db"

    if [ -f "$db_path" ]; then
        local size
        size="$(du -h "$db_path" 2>/dev/null | awk '{print $1}')"
        echo "- Baza de date Recorder: ${db_path} (${size})"
    else
        echo "- Baza de date Recorder nu există în ${db_path}"
    fi
}

section_rename_memory() {
    local entity_registry="/config/.storage/core.entity_registry"
    local device_registry="/config/.storage/core.device_registry"
    local states

    if [ ! -f "$entity_registry" ] || [ ! -f "$device_registry" ]; then
        echo "Fișierele registrelor nu sunt disponibile încă."
        return
    fi

    states="$(ha_api_call "states")"

    echo "Sursa memoriei: \`/data/ha-context/rename_memory.json\`."
    echo "Fișierul este generat din registrele Home Assistant la fiecare actualizare; nu păstra un inventar separat."
    echo ""

    jq -n \
        --slurpfile devices "$device_registry" \
        --slurpfile entities "$entity_registry" \
        --argjson states "$(echo "$states" | jq '. // []' 2>/dev/null || echo '[]')" '
        ($devices[0].data.devices // []) as $devices_list |
        ($entities[0].data.entities // []) as $entities_list |
        ($states | if type == "array" then . else [] end) as $states_list |
        ($states_list | map({key:.entity_id,value:.}) | from_entries) as $state_map |
        {
          devices_total: ($devices_list | length),
          devices_named_by_user: ([$devices_list[]? | select((.name_by_user // "") != "")] | length),
          devices_with_canonical_name: ([$devices_list[]? | select(((.name_by_user // .name // "") | test("^\\[[^\\]]+\\] ")))] | length),
          entities_total: ($entities_list | length),
          entities_with_registry_name_override: ([$entities_list[]? | select((.name // "") != "")] | length),
          entities_with_canonical_friendly_name: ([
            $entities_list[]? as $entity |
            (($state_map[$entity.entity_id].attributes.friendly_name // $entity.name // "") | select(test("^\\[[^\\]]+\\] ")))
          ] | length),
          disabled_entities: ([$entities_list[]? | select(.disabled_by != null)] | length)
        } |
        "- Dispozitive: \(.devices_total) total, \(.devices_named_by_user) denumite de utilizator, \(.devices_with_canonical_name) deja corecte\n" +
        "- Entități: \(.entities_total) total, \(.entities_with_registry_name_override) cu nume suprascris, \(.entities_with_canonical_friendly_name) cu nume corect, \(.disabled_entities) dezactivate"
    ' 2>/dev/null || echo "Memoria de redenumire nu a putut fi rezumată."

    echo ""
    echo "Înainte să propui o redenumire, verifică elementele relevante din \`rename_memory.json\` și sari peste dispozitivele sau entitățile deja corecte, dacă utilizatorul nu cere explicit altceva."
}

section_addon_logs() {
    if ! include_addon_logs; then
        echo "Citirea jurnalelor aplicațiilor este dezactivată."
        return
    fi

    local addons_data
    addons_data="$(api_call "addons")"

    if [ -z "$addons_data" ] || ! echo "$addons_data" | jq -e '.data.addons' >/dev/null 2>&1; then
        echo "Jurnalele aplicațiilor nu au putut fi citite."
        return
    fi

    echo "$addons_data" | jq -r '.data.addons[] | select(.installed == true) | .slug' 2>/dev/null | head -10 | while IFS= read -r slug; do
        [ -n "$slug" ] || continue
        echo "### ${slug}"
        echo '```text'
        api_call "addons/${slug}/logs" | tail -"${MAX_LOG_LINES}" | cut -c1-220 | redact_sensitive
        echo '```'
        echo ""
    done
}

write_skill() {
    local readonly_mode enable_device_control require_backup codex_full_permissions
    local skill_template
    readonly_mode="$(option readonly_mode false)"
    enable_device_control="$(option enable_device_control false)"
    require_backup="$(option require_backup_before_edit true)"
    codex_full_permissions="$(option codex_full_permissions true)"

    mkdir -p "$SKILL_DIR"
    skill_template="$(cat <<'SKILL'
---
name: home-assistant-instance
description: "Configurarea și regulile de siguranță pentru această instalare Home Assistant: căi, mod doar pentru citire, controlul dispozitivelor și copii de siguranță."
---

# Instanța Home Assistant

Rulezi în containerul aplicației Home Assistant.

## Căi locale

- `/config` este directorul de configurare Home Assistant.
- `$CODEX_HOME/AGENTS.md` conține datele generate pentru această instalare.
- `/data/ha-context/*.json` conține date structurate pentru analiză.
- `/data/ha-context/rename_memory.json` conține memoria de redenumire creată din registrele Home Assistant.
- `/data` se păstrează după restarturi și actualizări.
- `ha-context` actualizează datele instalației.
- `codex-ha doctor` verifică autentificarea, API-ul, MCP, skill-urile și siguranța.
- `ha-safe-edit plan` pregătește modificările și diferențele; `ha-safe-edit apply` aplică planul aprobat.

## Siguranță

- Tratează instalația ca pe un sistem de automatizare activ.
- Citește și verifică înainte să editezi.
- Înainte de redenumiri, citește `/data/ha-context/rename_memory.json` și sari peste elementele deja corecte, dacă utilizatorul nu cere explicit altceva.
- Folosește `ha-safe-edit plan <fișier> -- <comandă...>` înainte să schimbi YAML sau alte fișiere din `/config`.
- Aplică numai după aprobarea utilizatorului, cu `ha-safe-edit apply <plan_id>`.
- Păstrează copiile de siguranță în `/data/safe-edit-backups` sau într-un subdirector.
- Nu scrie copii de siguranță lângă fișierele sursă din `/config` și nu crea fișiere `.bak` acolo.
- Include căile copiilor de siguranță în răspunsul final.
- `readonly_mode`: __READONLY_MODE__
- `enable_device_control`: __ENABLE_DEVICE_CONTROL__
- `require_backup_before_edit`: __REQUIRE_BACKUP__
- `codex_full_permissions`: __CODEX_FULL_PERMISSIONS__
- Controlează dispozitive numai la cererea explicită a utilizatorului.
- Explică efectele înainte să apelezi servicii care controlează dispozitive.
- Nu edita direct `.storage/` decât dacă utilizatorul acceptă explicit riscul și nu există o cale prin API.

## API-uri

- Baza API Supervisor: `http://supervisor`
- Baza API Core: `http://supervisor/core/api`
- WebSocket Core: `ws://supervisor/core/api/websocket`; autentificarea este primul mesaj JSON.
- Pentru HTTP, folosește `Authorization: Bearer $SUPERVISOR_TOKEN`.
- Serverul MCP `home-assistant` poate fi disponibil în Codex.

## Comenzi utile

```bash
ha-context
codex-ha doctor
ha-safe-edit check
ha-safe-edit plan /config/automations.yaml -- sh -c 'comandă de editare'
ha-safe-edit apply <plan_id>
codex mcp list
curl -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/core/info
curl -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/core/api/states
websocat ws://supervisor/core/api/websocket   # trimite întâi mesajul de autentificare
```

## Skill-uri asociate

Vezi skill-ul `home-assistant` (`$CODEX_HOME/skills/home-assistant/SKILL.md`) pentru entități, dispozitive și camere, automatizări, scripturi, elemente ajutătoare și scene, panouri, șabloane, notificări, controlul dispozitivelor, refactorizare și exemple.
SKILL
)"
    skill_template="${skill_template//__READONLY_MODE__/${readonly_mode}}"
    skill_template="${skill_template//__ENABLE_DEVICE_CONTROL__/${enable_device_control}}"
    skill_template="${skill_template//__REQUIRE_BACKUP__/${require_backup}}"
    skill_template="${skill_template//__CODEX_FULL_PERMISSIONS__/${codex_full_permissions}}"
    printf "%s\n" "$skill_template" > "$SKILL_DIR/SKILL.md"
}

generate_agents_md() {
    local timestamp tmp_file
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    mkdir -p "$(dirname "$OUTPUT_FILE")"
    tmp_file="$(mktemp "${OUTPUT_FILE}.XXXXXX")"

    {
        echo "# Date Home Assistant"
        echo ""
        echo "Generat automat de Codex Terminal. Rulează \`ha-context\` pentru actualizare."
        echo "Ultima actualizare: ${timestamp}"
        echo ""
        echo "## Sistem"
        echo ""
        section_system_info
        echo ""
        echo "## Entități"
        echo ""
        section_entity_summary
        echo ""
        echo "## Aplicații instalate"
        echo ""
        section_addons
        echo ""
        echo "## Integrări"
        echo ""
        section_integrations
        echo ""
        echo "## Automatizări, scripturi și scene"
        echo ""
        section_automation_inventory
        echo ""
        echo "## Entități indisponibile sau necunoscute"
        echo ""
        section_unavailable_entities
        echo ""
        echo "## Reparații și stare sistem"
        echo ""
        section_repairs
        echo ""
        echo "## Recorder"
        echo ""
        section_recorder
        echo ""
        echo "## Memorie pentru redenumirea dispozitivelor și entităților"
        echo ""
        section_rename_memory
        echo ""
        echo "## Erori recente"
        echo ""
        section_recent_errors
        echo ""
        echo "## Fragmente din jurnalele aplicațiilor"
        echo ""
        section_addon_logs
        echo ""
        echo "## Acces API"
        echo ""
        echo '```bash'
        echo 'curl -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/core/info'
        echo 'curl -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/core/api/states'
        echo 'curl -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" -H "Content-Type: application/json" -d '"'"'{"entity_id":"light.example"}'"'"' http://supervisor/core/api/services/light/turn_on'
        echo '```'
    } > "$tmp_file"

    chmod 600 "$tmp_file"
    mv "$tmp_file" "$OUTPUT_FILE"
}

generate_context_json() {
    local timestamp tmp_dir states addons repairs core_info host_info ha_config config_entries
    timestamp="$(date -Iseconds)"
    mkdir -p "$(dirname "$CONTEXT_JSON_DIR")"
    tmp_dir="$(mktemp -d "$(dirname "$CONTEXT_JSON_DIR")/ha-context.XXXXXX")"

    states="$(ha_api_call "states")"
    addons="$(api_call "addons")"
    repairs="$(api_call "resolution/info")"
    core_info="$(api_call "core/info")"
    host_info="$(api_call "host/info")"
    ha_config="$(ha_api_call "config")"
    config_entries="$(ha_api_call "config/config_entries/entry")"

    jq -n \
        --arg generated_at "$timestamp" \
        --arg agents_md "$OUTPUT_FILE" \
        --arg context_detail_level "$(context_level)" \
        --arg include_addon_logs "$INCLUDE_ADDON_LOGS" \
        '{generated_at:$generated_at,agents_md:$agents_md,context_detail_level:$context_detail_level,include_addon_logs:($include_addon_logs == "true"),files:{system:"system.json",entities:"entities.json",entity_summary:"entity_summary.json",entity_registry:"entity_registry.json",device_registry:"device_registry.json",area_registry:"area_registry.json",label_registry:"label_registry.json",rename_memory:"rename_memory.json",addons:"addons.json",integrations:"integrations.json",automations_scripts_scenes:"automations_scripts_scenes.json",unavailable_entities:"unavailable_entities.json",repairs:"repairs.json"}}' \
        > "${tmp_dir}/manifest.json"

    jq -n \
        --arg generated_at "$timestamp" \
        --argjson core "$(echo "$core_info" | jq '. // {}' 2>/dev/null || echo '{}')" \
        --argjson host "$(echo "$host_info" | jq '. // {}' 2>/dev/null || echo '{}')" \
        --argjson config "$(echo "$ha_config" | jq '. // {}' 2>/dev/null || echo '{}')" \
        '{generated_at:$generated_at,core:$core,host:$host,config:{location_name:$config.location_name,time_zone:$config.time_zone,unit_system:$config.unit_system,version:$config.version,components:$config.components}}' \
        > "${tmp_dir}/system.json"

    write_json_payload "${tmp_dir}/entities.json" "$states"
    write_json_payload "${tmp_dir}/addons.json" "$addons"
    write_json_payload "${tmp_dir}/repairs.json" "$repairs"

    write_storage_json "/config/.storage/core.entity_registry" "${tmp_dir}/entity_registry.json"
    write_storage_json "/config/.storage/core.device_registry" "${tmp_dir}/device_registry.json"
    write_storage_json "/config/.storage/core.area_registry" "${tmp_dir}/area_registry.json"
    write_storage_json "/config/.storage/core.label_registry" "${tmp_dir}/label_registry.json"

    jq -n \
        --arg generated_at "$timestamp" \
        --slurpfile devices "${tmp_dir}/device_registry.json" \
        --slurpfile entities "${tmp_dir}/entity_registry.json" \
        --slurpfile areas "${tmp_dir}/area_registry.json" \
        --slurpfile labels "${tmp_dir}/label_registry.json" \
        --slurpfile states "${tmp_dir}/entities.json" '
        def registry_array($doc; $key):
          if ($doc[0].data[$key]? | type) == "array" then $doc[0].data[$key] else [] end;
        def state_array($doc):
          if ($doc[0] | type) == "array" then $doc[0] else [] end;
        def canonical_name:
          test("^\\[[^\\]]+\\] ");

        (registry_array($devices; "devices")) as $devices_list |
        (registry_array($entities; "entities")) as $entities_list |
        (registry_array($areas; "areas")) as $areas_list |
        (registry_array($labels; "labels")) as $labels_list |
        (state_array($states)) as $states_list |
        ($states_list | map({key:.entity_id,value:.}) | from_entries) as $state_map |
        ($areas_list | map({key:.id,value:.name}) | from_entries) as $area_names |
        ($labels_list | map(select((.label_id // .id) != null) | {key:(.label_id // .id),value:{name:.name,icon:.icon,description:.description}}) | from_entries) as $label_map |
        def label_details($ids):
          [($ids // [])[] as $id | {id:$id} + ($label_map[$id] // {})];
        def area_name($id):
          if $id == null then null else ($area_names[$id] // $id) end;

        {
          generated_at: $generated_at,
          source: "derived_from_home_assistant_registries",
          guidance: {
            purpose: "Memorie pentru denumirea dispozitivelor și entităților Home Assistant. Înlocuiește inventarul manual și este refăcută din registrele curente.",
            before_rename: "Citește dispozitivele și entitățile potrivite și sari peste elementele deja corecte, dacă utilizatorul nu cere explicit o nouă redenumire.",
            canonical_device_name: "[Cameră] Producător Model [#N]",
            canonical_entity_friendly_name: "[Cameră] Nume dispozitiv - Funcție sau [Cameră] Nume dispozitiv pentru entitatea principală",
            canonical_entity_id: "<domain>.<area_slug>_<function>[_<detail>]"
          },
          summary: {
            devices_total: ($devices_list | length),
            devices_named_by_user: ([$devices_list[]? | select((.name_by_user // "") != "")] | length),
            devices_with_canonical_name: ([$devices_list[]? | select(((.name_by_user // .name // "") | canonical_name))] | length),
            entities_total: ($entities_list | length),
            entities_with_registry_name_override: ([$entities_list[]? | select((.name // "") != "")] | length),
            entities_with_canonical_friendly_name: ([
              $entities_list[]? as $entity |
              (($state_map[$entity.entity_id].attributes.friendly_name // $entity.name // "") | select(canonical_name))
            ] | length),
            disabled_entities: ([$entities_list[]? | select(.disabled_by != null)] | length)
          },
          devices: [
            $devices_list[]? |
            {
              device_id: .id,
              name: (.name_by_user // .name // .model // .id),
              registry_name: .name,
              name_by_user: .name_by_user,
              area_id: .area_id,
              area_name: area_name(.area_id),
              manufacturer: .manufacturer,
              model: .model,
              model_id: .model_id,
              sw_version: .sw_version,
              hw_version: .hw_version,
              identifiers: (.identifiers // []),
              connections: (.connections // []),
              labels: (.labels // []),
              label_details: label_details(.labels),
              config_entries: (.config_entries // []),
              via_device_id: .via_device_id,
              is_canonical_name: ((.name_by_user // .name // "") | canonical_name),
              skip_rename_by_default: ((.name_by_user // .name // "") | canonical_name)
            }
          ] | sort_by(.name // ""),
          entities: [
            $entities_list[]? as $entity |
            ($state_map[$entity.entity_id] // {}) as $state |
            ($state.attributes.friendly_name // $entity.name // $entity.original_name // "") as $friendly |
            {
              entity_id: $entity.entity_id,
              unique_id: $entity.unique_id,
              domain: ($entity.entity_id | split(".")[0]),
              platform: $entity.platform,
              device_id: $entity.device_id,
              area_id: $entity.area_id,
              area_name: area_name($entity.area_id),
              labels: ($entity.labels // []),
              label_details: label_details($entity.labels),
              registry_name: $entity.name,
              original_name: $entity.original_name,
              friendly_name: $friendly,
              has_entity_name: $entity.has_entity_name,
              disabled_by: $entity.disabled_by,
              hidden_by: $entity.hidden_by,
              entity_category: $entity.entity_category,
              device_class: ($state.attributes.device_class // $entity.device_class),
              unit_of_measurement: $state.attributes.unit_of_measurement,
              is_canonical_friendly_name: ($friendly | canonical_name),
              has_registry_name_override: (($entity.name // "") != ""),
              skip_rename_by_default: (($friendly | canonical_name) or ($entity.disabled_by != null))
            }
          ] | sort_by(.entity_id // "")
        }
    ' > "${tmp_dir}/rename_memory.json"

    if [ -n "$states" ] && echo "$states" | jq -e 'type == "array"' >/dev/null 2>&1; then
        echo "$states" | jq '
            {
                total: length,
                domains: ([.[].entity_id | split(".")[0]] | group_by(.) | map({domain: .[0], count: length}) | sort_by(.domain)),
                unavailable_or_unknown_count: ([.[] | select(.state == "unavailable" or .state == "unknown")] | length)
            }
        ' > "${tmp_dir}/entity_summary.json"

        echo "$states" | jq '
            [.[] | select(.entity_id | test("^(automation|script|scene)\\."))
                | {entity_id, state, friendly_name: .attributes.friendly_name, last_changed, last_updated}]
        ' > "${tmp_dir}/automations_scripts_scenes.json"

        echo "$states" | jq '
            [.[] | select(.state == "unavailable" or .state == "unknown")
                | {entity_id, state, friendly_name: .attributes.friendly_name, last_changed, last_updated}]
        ' > "${tmp_dir}/unavailable_entities.json"
    else
        jq -n '{total:0,domains:[],unavailable_or_unknown_count:0,error:"states_unavailable"}' > "${tmp_dir}/entity_summary.json"
        jq -n '[]' > "${tmp_dir}/automations_scripts_scenes.json"
        jq -n '[]' > "${tmp_dir}/unavailable_entities.json"
    fi

    if [ -n "$config_entries" ] && echo "$config_entries" | jq -e '.' >/dev/null 2>&1; then
        echo "$config_entries" | jq '
            if type == "array" then .
            elif .data and (.data | type == "array") then .data
            else [] end
            | map({entry_id, domain, title, disabled_by, source, state})
            | sort_by(.domain // "", .title // "")
        ' > "${tmp_dir}/integrations.json"
    else
        jq -n '[]' > "${tmp_dir}/integrations.json"
    fi

    chmod -R go-rwx "$tmp_dir"
    rm -rf "${CONTEXT_JSON_DIR}.old"
    if [ -d "$CONTEXT_JSON_DIR" ]; then
        mv "$CONTEXT_JSON_DIR" "${CONTEXT_JSON_DIR}.old"
    fi
    mv "$tmp_dir" "$CONTEXT_JSON_DIR"
    rm -rf "${CONTEXT_JSON_DIR}.old"
}

main() {
    check_prerequisites
    CONTEXT_DETAIL_LEVEL="$(option context_detail_level "$CONTEXT_DETAIL_LEVEL")"
    INCLUDE_ADDON_LOGS="$(option include_addon_logs "$INCLUDE_ADDON_LOGS")"

    case "$CONTEXT_DETAIL_LEVEL" in
        summary|standard|full) ;;
        *) CONTEXT_DETAIL_LEVEL="standard" ;;
    esac

    write_skill

    if context_is_fresh "$OUTPUT_FILE" "$REFRESH_MINUTES" && [ -d "$CONTEXT_JSON_DIR" ]; then
        echo "Datele Home Assistant sunt recente; actualizarea este omisă (${OUTPUT_FILE}, interval ${REFRESH_MINUTES} minute)" >&2
        echo "Rulează 'ha-context --force' pentru actualizare imediată." >&2
        exit 0
    fi

    generate_agents_md
    generate_context_json
    echo "Datele Home Assistant au fost scrise în ${OUTPUT_FILE}" >&2
    echo "Datele Home Assistant structurate au fost scrise în ${CONTEXT_JSON_DIR}" >&2
    echo "Skill-ul instanței Home Assistant a fost scris în ${SKILL_DIR}/SKILL.md" >&2
}

main "$@"
