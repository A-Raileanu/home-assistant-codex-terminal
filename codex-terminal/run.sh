#!/usr/bin/with-contenv bashio

set -e
set -o pipefail
STARTUP_STATUS_FILE="/data/startup-status.log"

init_environment() {
    local data_home="/data/home"
    local config_dir="/data/.config"
    local cache_dir="/data/.cache"
    local state_dir="/data/.local/state"
    local data_dir="/data/.local/share"
    local codex_home="/data/.codex"

    bashio::log.info "Pregătesc mediul Codex în /data..."

    mkdir -p \
        "$data_home" \
        "$config_dir" \
        "$cache_dir" \
        "$state_dir" \
        "$data_dir" \
        "$codex_home" \
        "$codex_home/skills" \
        "$codex_home/plugins"

    chmod 700 "$codex_home"
    chmod 755 "$data_home" "$config_dir" "$cache_dir" "$state_dir" "$data_dir"

    export HOME="$data_home"
    export CODEX_HOME="$codex_home"
    export XDG_CONFIG_HOME="$config_dir"
    export XDG_CACHE_HOME="$cache_dir"
    export XDG_STATE_HOME="$state_dir"
    export XDG_DATA_HOME="$data_dir"
    export HOME_ASSISTANT_URL="http://supervisor/core"
    export HOMEASSISTANT_URL="http://supervisor/core"
    export HOMEASSISTANT_TOKEN="${SUPERVISOR_TOKEN:-}"
    export CODEX_HA_READONLY_MODE="$(bashio::config "readonly_mode" "false")"
    export CODEX_HA_REQUIRE_BACKUP="$(bashio::config "require_backup_before_edit" "true")"
    export CODEX_HA_ENABLE_DEVICE_CONTROL="$(bashio::config "enable_device_control" "false")"
    export CODEX_HA_ENABLE_FILE_TOOLS="$(bashio::config "enable_file_tools" "true")"
    export CODEX_HA_ENABLE_YAML_EDITING="$(bashio::config "enable_yaml_editing" "true")"
    export CODEX_HA_FULL_PERMISSIONS="$(bashio::config "codex_full_permissions" "true")"
    export MAX_LOG_LINES="$(bashio::config "max_log_lines" "80")"
    export HA_CONTEXT_REFRESH_MINUTES="$(bashio::config "ha_context_refresh_minutes" "30")"
    export CONTEXT_DETAIL_LEVEL="$(bashio::config "context_detail_level" "standard")"
    export INCLUDE_ADDON_LOGS="$(bashio::config "include_addon_logs" "false")"
    export HA_MCP_VERSION="$(bashio::config "ha_mcp_version" "7.12.0")"
    export CODEX_HA_MCP_MODE="$(bashio::config "mcp_mode" "ha-mcp")"
    export SAFE_EDIT_BACKUP_RETENTION_DAYS="$(bashio::config "safe_edit_backup_retention_days" "30")"

    migrate_legacy_codex_files "$codex_home"
    install_tmux_config

    bashio::log.info "Mediul este pregătit:"
    bashio::log.info "  HOME=${HOME}"
    bashio::log.info "  CODEX_HOME=${CODEX_HOME}"
    bashio::log.info "  XDG_CONFIG_HOME=${XDG_CONFIG_HOME}"
}

migrate_legacy_codex_files() {
    local target_dir="$1"
    local legacy_locations=(
        "/root/.codex"
        "/config/codex-config"
    )

    for legacy_path in "${legacy_locations[@]}"; do
        if [ -d "$legacy_path" ] && [ "$(ls -A "$legacy_path" 2>/dev/null)" ]; then
            bashio::log.info "Mut fișierele Codex din ${legacy_path}"
            cp -a "$legacy_path"/. "$target_dir"/ 2>/dev/null || bashio::log.warning "Fișierele din ${legacy_path} nu au putut fi mutate"
        fi
    done

    rm -rf /root/.codex
    ln -sfn "$target_dir" /root/.codex
}

install_tmux_config() {
    if [ -f /opt/scripts/tmux.conf ]; then
        cp /opt/scripts/tmux.conf "$HOME/.tmux.conf"
        chmod 644 "$HOME/.tmux.conf"
    fi
}

configure_codex_cli_defaults() {
    local config_file="${CODEX_HOME}/config.toml"

    mkdir -p "$CODEX_HOME"

    if [ ! -f "$config_file" ]; then
        cat > "$config_file" <<'TOML'
suppress_unstable_features_warning = true
hide_agent_reasoning = true
show_raw_agent_reasoning = false
model_verbosity = "low"

[tui]
raw_output_mode = false
TOML
        chmod 600 "$config_file"
        bashio::log.info "Am creat configurația Codex cu mesaje reduse"
        return 0
    fi

    python3 - "$config_file" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8", errors="replace")
lines = text.splitlines()

# Eliminatează limita veche introdusă de versiunile anterioare.
lines = [
    line for line in lines
    if not re.match(r"^\s*tool_output_token_limit\s*=", line)
]

settings = {
    "suppress_unstable_features_warning": "true",
    "hide_agent_reasoning": "true",
    "show_raw_agent_reasoning": "false",
    "model_verbosity": '"low"',
}

for key, value in settings.items():
    pattern = re.compile(rf"^\s*{re.escape(key)}\s*=.*$")
    for index, line in enumerate(lines):
        if pattern.match(line):
            lines[index] = f"{key} = {value}"
            break
    else:
        lines.insert(0, f"{key} = {value}")

tui_start = next(
    (index for index, line in enumerate(lines) if re.match(r"^\[tui\]\s*$", line)),
    None,
)
if tui_start is None:
    lines.extend(["", "[tui]", "raw_output_mode = false"])
else:
    tui_end = next(
        (index for index in range(tui_start + 1, len(lines)) if re.match(r"^\[.+\]\s*$", lines[index])),
        len(lines),
    )
    raw_line = next(
        (index for index in range(tui_start + 1, tui_end) if re.match(r"^\s*raw_output_mode\s*=", lines[index])),
        None,
    )
    if raw_line is None:
        lines.insert(tui_start + 1, "raw_output_mode = false")
    else:
        lines[raw_line] = "raw_output_mode = false"

path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
    chmod 600 "$config_file"
}

remove_codex_mcp_server() {
    local server_name="$1"
    local config_file="${CODEX_HOME}/config.toml"

    if command -v codex >/dev/null 2>&1 \
        && [ -f "$config_file" ] \
        && grep -Fq "[mcp_servers.${server_name}]" "$config_file"; then
        codex mcp remove "$server_name" >/dev/null 2>&1 || true
    fi
}

cleanup_unavailable_mcp_servers() {
    local enable_ha_mcp mcp_mode readonly_mode enable_device_control

    if ! command -v codex >/dev/null 2>&1; then
        return 0
    fi

    # The Codex app connector is not available inside this Home Assistant add-on.
    # If it was migrated into /data/.codex, Codex prints an MCP startup warning.
    remove_codex_mcp_server "codex_apps"

    enable_ha_mcp="$(bashio::config "enable_ha_mcp" "true")"
    mcp_mode="$(bashio::config "mcp_mode" "ha-mcp")"
    readonly_mode="$(bashio::config "readonly_mode" "false")"
    enable_device_control="$(bashio::config "enable_device_control" "false")"

    if [ "$enable_ha_mcp" != "true" ] \
        || [ "$mcp_mode" = "disabled" ] \
        || [ "$readonly_mode" = "true" ] \
        || [ "$enable_device_control" != "true" ]; then
        remove_codex_mcp_server "home-assistant"
        remove_codex_mcp_server "home-assistant-official"
    fi
}

prepare_codex_cli() {
    bashio::log.info "Pregătesc configurația Codex CLI..."
    configure_codex_cli_defaults
    cleanup_unavailable_mcp_servers
}

install_runtime_helpers() {
    local helper

    for helper in \
        codex-task-picker \
        codex-ha \
        ha-context \
        ha-safe-edit \
        persist-install; do
        if [ -f "/opt/scripts/${helper}.sh" ]; then
            cp "/opt/scripts/${helper}.sh" "/usr/local/bin/${helper}"
            chmod +x "/usr/local/bin/${helper}"
        fi
    done

    bashio::addon.version > /opt/scripts/addon-version 2>/dev/null || echo "unknown" > /opt/scripts/addon-version
}

install_bundled_skills() {
    local skills_dir version_file addon_version existing_version skill_path skill_name

    if [ ! -d /opt/skills ]; then
        bashio::log.info "Nu există skill-uri Codex incluse"
        return 0
    fi

    skills_dir="${CODEX_HOME}/skills"
    version_file="${skills_dir}/.addon-version"
    addon_version="$(cat /opt/scripts/addon-version 2>/dev/null || echo "unknown")"
    existing_version="$(cat "$version_file" 2>/dev/null || echo "")"

    mkdir -p "$skills_dir"

    if [ "$existing_version" = "$addon_version" ]; then
        bashio::log.info "Skill-urile sunt deja actualizate pentru versiunea ${addon_version}"
        return 0
    fi

    bashio::log.info "Actualizez skill-urile Codex pentru versiunea ${addon_version}..."
    rm -rf "$skills_dir"
    mkdir -p "$skills_dir"

    for skill_path in /opt/skills/*; do
        [ -e "$skill_path" ] || continue
        skill_name="$(basename "$skill_path")"
        cp -a "$skill_path" "${skills_dir}/${skill_name}"
        bashio::log.info "Skill instalat: ${skill_name}"
    done

    echo "$addon_version" > "$version_file"
}

install_persistent_packages() {
    bashio::log.info "Verific pachetele persistente..."

    local persist_config="/data/persistent-packages.json"
    local apk_packages=""
    local pip_packages=""

    if bashio::config.has_value "persistent_apk_packages"; then
        apk_packages="$(bashio::config "persistent_apk_packages" || true)"
    fi

    if bashio::config.has_value "persistent_pip_packages"; then
        pip_packages="$(bashio::config "persistent_pip_packages" || true)"
    fi

    if [ -f "$persist_config" ]; then
        local local_apk local_pip
        local_apk="$(jq -r '.apk_packages | join(" ")' "$persist_config" 2>/dev/null || true)"
        local_pip="$(jq -r '.pip_packages | join(" ")' "$persist_config" 2>/dev/null || true)"
        apk_packages="${apk_packages} ${local_apk}"
        pip_packages="${pip_packages} ${local_pip}"
    fi

    apk_packages="$(echo "$apk_packages" | tr ' ' '\n' | sed '/^$/d;/^null$/d' | sort -u | tr '\n' ' ' | xargs || true)"
    pip_packages="$(echo "$pip_packages" | tr ' ' '\n' | sed '/^$/d;/^null$/d' | sort -u | tr '\n' ' ' | xargs || true)"

    if [ -n "$apk_packages" ]; then
        bashio::log.info "Instalez pachetele APK persistente: ${apk_packages}"
        # shellcheck disable=SC2086
        apk add --no-cache $apk_packages || bashio::log.warning "Unele pachete APK nu au putut fi instalate"
    fi

    if [ -n "$pip_packages" ]; then
        bashio::log.info "Instalez pachetele pip persistente: ${pip_packages}"
        # shellcheck disable=SC2086
        pip3 install --break-system-packages --no-cache-dir $pip_packages || bashio::log.warning "Unele pachete pip nu au putut fi instalate"
    fi
}

validate_codex_skills() {
    if [ -x /opt/scripts/validate-skills.sh ]; then
        bashio::log.info "Verific skill-urile Codex..."
        /opt/scripts/validate-skills.sh "${CODEX_HOME}/skills" 2>&1 | while IFS= read -r line; do
            bashio::log.info "$line"
        done || bashio::log.warning "Unul sau mai multe skill-uri nu au trecut verificarea"
    fi
}

generate_ha_context() {
    local ha_smart_context
    local refresh_minutes
    ha_smart_context="$(bashio::config "ha_smart_context" "true")"
    refresh_minutes="$(bashio::config "ha_context_refresh_minutes" "30")"

    if [ "$ha_smart_context" != "true" ]; then
        bashio::log.info "Generarea automată a datelor Home Assistant este dezactivată"
        return 0
    fi

    if command -v ha-context >/dev/null 2>&1; then
        bashio::log.info "Actualizez datele Home Assistant dacă sunt mai vechi de ${refresh_minutes} minute..."
        ha-context --refresh-minutes "$refresh_minutes" 2>&1 | while IFS= read -r line; do
            bashio::log.info "$line"
        done || bashio::log.warning "Datele Home Assistant nu au putut fi generate; pornirea continuă"
    fi
}

start_context_refresh_loop() {
    local ha_smart_context refresh_minutes interval_seconds

    ha_smart_context="$(bashio::config "ha_smart_context" "true")"
    refresh_minutes="$(bashio::config "ha_context_refresh_minutes" "30")"

    if [ "$ha_smart_context" != "true" ]; then
        return 0
    fi

    if ! [[ "$refresh_minutes" =~ ^[0-9]+$ ]]; then
        refresh_minutes=30
    fi

    interval_seconds=$((refresh_minutes * 60))
    [ "$interval_seconds" -gt 300 ] && interval_seconds=300
    [ "$interval_seconds" -lt 60 ] && interval_seconds=60

    bashio::log.info "Pornesc actualizarea periodică a datelor Home Assistant (verificare la ${interval_seconds}s, interval ${refresh_minutes}m)"

    (
        while true; do
            sleep "$interval_seconds"
            if command -v ha-context >/dev/null 2>&1; then
                ha-context --refresh-minutes "$refresh_minutes" >/tmp/codex-ha-context-periodic.log 2>&1 || true
            fi
        done
    ) &
}

setup_ha_mcp() {
    if [ -f /opt/scripts/setup-ha-mcp.sh ]; then
        bashio::log.info "Configurez integrarea MCP Home Assistant..."
        # shellcheck source=/dev/null
        source /opt/scripts/setup-ha-mcp.sh
        configure_ha_mcp_server || bashio::log.warning "MCP nu a putut fi configurat; pornirea continuă fără el"
    fi
}

run_background_initialization() {
    : > "$STARTUP_STATUS_FILE"
    chmod 600 "$STARTUP_STATUS_FILE"

    (
        {
            echo "Pornesc pregătirea în fundal..."
            install_persistent_packages
            install_bundled_skills
            generate_ha_context
            validate_codex_skills
            setup_ha_mcp
            echo "Pregătirea în fundal s-a încheiat"
        } >> "$STARTUP_STATUS_FILE" 2>&1
    ) &
}

get_codex_launch_command() {
    local auto_launch_codex
    auto_launch_codex="$(bashio::config "auto_launch_codex" "true")"

    if [ "$auto_launch_codex" != "true" ]; then
        echo 'ha-context --refresh-minutes "${HA_CONTEXT_REFRESH_MINUTES:-30}" >/tmp/codex-ha-context-refresh.log 2>&1 || true; bash -l'
        return
    fi

    echo "codex-task-picker"
}

start_web_terminal() {
    local web_port=7681
    local terminal_port=7682
    local launch_command
    local ttyd_theme

    launch_command="$(get_codex_launch_command)"
    export TTYD=1
    export TTYD_UPSTREAM="http://127.0.0.1:${terminal_port}"

    ttyd_theme='{"background":"#101418","foreground":"#d9e2ec","cursor":"#36c2a5","cursorAccent":"#101418","selectionBackground":"#315b7c","selectionForeground":"#ffffff","black":"#0b0f14","red":"#ff6b6b","green":"#8bd450","yellow":"#f5c542","blue":"#4ea1ff","magenta":"#c586f7","cyan":"#36c2a5","white":"#d9e2ec","brightBlack":"#52606d","brightRed":"#ff8787","brightGreen":"#a3e635","brightYellow":"#ffe066","brightBlue":"#74b9ff","brightMagenta":"#d0a2ff","brightCyan":"#5eead4","brightWhite":"#f8fafc"}'

    bashio::log.info "Pornesc terminalul Codex pe portul ${terminal_port}"

    ttyd \
        --port "$terminal_port" \
        --interface 127.0.0.1 \
        --writable \
        --ping-interval 30 \
        --client-option enableReconnect=true \
        --client-option reconnect=10 \
        --client-option reconnectInterval=5 \
        --client-option "theme=${ttyd_theme}" \
        --client-option fontSize=14 \
        bash -lc "$launch_command" &

    local ttyd_pid=$!
    trap 'kill "$ttyd_pid" 2>/dev/null || true' EXIT INT TERM

    bashio::log.info "Pornesc proxy-ul terminalului pe portul ${web_port}"
    python3 /opt/scripts/web-ui.py
}

main() {
    bashio::log.info "Pornesc Codex Terminal..."
    init_environment
    install_runtime_helpers
    prepare_codex_cli
    run_background_initialization
    start_context_refresh_loop
    start_web_terminal
}

main "$@"
