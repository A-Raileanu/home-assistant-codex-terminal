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

    bashio::log.info "Initializing Codex environment in /data..."

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
    export HA_MCP_VERSION="$(bashio::config "ha_mcp_version" "3.5.1")"
    export SAFE_EDIT_BACKUP_RETENTION_DAYS="$(bashio::config "safe_edit_backup_retention_days" "30")"

    migrate_legacy_codex_files "$codex_home"
    install_tmux_config

    bashio::log.info "Environment initialized:"
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
            bashio::log.info "Migrating Codex files from ${legacy_path}"
            cp -a "$legacy_path"/. "$target_dir"/ 2>/dev/null || bashio::log.warning "Migration failed from ${legacy_path}"
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

install_runtime_helpers() {
    local helper

    for helper in \
        codex-session-picker \
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
    local skills_dir version_file addon_version existing_version skill_path skill_name target bundled_count target_entry_count target_skill_md

    if [ ! -d /opt/skills ]; then
        bashio::log.info "No bundled Codex skills found"
        return 0
    fi

    skills_dir="${CODEX_HOME}/skills"
    version_file="${skills_dir}/.addon-version"
    addon_version="$(cat /opt/scripts/addon-version 2>/dev/null || echo "unknown")"
    existing_version="$(cat "$version_file" 2>/dev/null || echo "")"

    mkdir -p "$skills_dir"

    if [ "$existing_version" = "$addon_version" ]; then
        bashio::log.info "Bundled skills already synced for add-on version ${addon_version}"
        return 0
    fi

    bashio::log.info "Syncing bundled Codex skills (preserving user overrides)..."
    for skill_path in /opt/skills/*; do
        [ -e "$skill_path" ] || continue
        skill_name="$(basename "$skill_path")"
        target="${skills_dir}/${skill_name}"

        if [ -d "$skill_path" ] && [ -d "$target" ]; then
            bundled_count="$(find "$skill_path" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
            target_entry_count="$(find "$target" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
            target_skill_md="${target}/SKILL.md"
            if [ "$bundled_count" -gt 1 ] && [ "$target_entry_count" = "1" ] && [ -f "$target_skill_md" ]; then
                bashio::log.info "Replacing legacy auto-generated skill: ${skill_name}"
                rm -rf "$target"
            fi
        fi

        if [ ! -e "$target" ]; then
            cp -a "$skill_path" "$target"
            bashio::log.info "Installed bundled skill: ${skill_name}"
        fi
    done
    echo "$addon_version" > "$version_file"
}

install_persistent_packages() {
    bashio::log.info "Checking persistent packages..."

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
        bashio::log.info "Installing persistent APK packages: ${apk_packages}"
        # shellcheck disable=SC2086
        apk add --no-cache $apk_packages || bashio::log.warning "Some APK packages failed to install"
    fi

    if [ -n "$pip_packages" ]; then
        bashio::log.info "Installing persistent pip packages: ${pip_packages}"
        # shellcheck disable=SC2086
        pip3 install --break-system-packages --no-cache-dir $pip_packages || bashio::log.warning "Some pip packages failed to install"
    fi
}

validate_codex_skills() {
    if [ -x /opt/scripts/validate-skills.sh ]; then
        bashio::log.info "Validating Codex skills..."
        /opt/scripts/validate-skills.sh "${CODEX_HOME}/skills" 2>&1 | while IFS= read -r line; do
            bashio::log.info "$line"
        done || bashio::log.warning "One or more Codex skills failed validation"
    fi
}

generate_ha_context() {
    local ha_smart_context
    local refresh_minutes
    ha_smart_context="$(bashio::config "ha_smart_context" "true")"
    refresh_minutes="$(bashio::config "ha_context_refresh_minutes" "30")"

    if [ "$ha_smart_context" != "true" ]; then
        bashio::log.info "HA smart context disabled"
        return 0
    fi

    if command -v ha-context >/dev/null 2>&1; then
        bashio::log.info "Refreshing Home Assistant context when older than ${refresh_minutes} minutes..."
        ha-context --refresh-minutes "$refresh_minutes" 2>&1 | while IFS= read -r line; do
            bashio::log.info "$line"
        done || bashio::log.warning "HA context generation failed, continuing"
    fi
}

setup_ha_mcp() {
    if [ -f /opt/scripts/setup-ha-mcp.sh ]; then
        bashio::log.info "Configuring Home Assistant MCP integration..."
        # shellcheck source=/dev/null
        source /opt/scripts/setup-ha-mcp.sh
        configure_ha_mcp_server || bashio::log.warning "HA MCP setup failed, continuing without MCP"
    fi
}

run_background_initialization() {
    : > "$STARTUP_STATUS_FILE"
    chmod 600 "$STARTUP_STATUS_FILE"

    (
        {
            echo "Starting background initialization..."
            install_persistent_packages
            install_bundled_skills
            generate_ha_context
            validate_codex_skills
            setup_ha_mcp
            echo "Background initialization completed"
        } >> "$STARTUP_STATUS_FILE" 2>&1
    ) &
}

get_codex_launch_command() {
    local auto_launch_codex
    local codex_base_command="codex --cd /config"

    auto_launch_codex="$(bashio::config "auto_launch_codex" "true")"

    if [ "${CODEX_HA_FULL_PERMISSIONS}" = "true" ]; then
        codex_base_command="codex --dangerously-bypass-approvals-and-sandbox --cd /config"
    fi

    if [ "$auto_launch_codex" = "true" ]; then
        echo "tmux new-session -A -s codex '${codex_base_command}'"
    else
        echo "codex-session-picker"
    fi
}

start_web_terminal() {
    local port=7681
    local launch_command
    local ttyd_theme

    launch_command="$(get_codex_launch_command)"
    export TTYD=1

    ttyd_theme='{"background":"#101418","foreground":"#d9e2ec","cursor":"#36c2a5","cursorAccent":"#101418","selectionBackground":"#315b7c","selectionForeground":"#ffffff","black":"#0b0f14","red":"#ff6b6b","green":"#8bd450","yellow":"#f5c542","blue":"#4ea1ff","magenta":"#c586f7","cyan":"#36c2a5","white":"#d9e2ec","brightBlack":"#52606d","brightRed":"#ff8787","brightGreen":"#a3e635","brightYellow":"#ffe066","brightBlue":"#74b9ff","brightMagenta":"#d0a2ff","brightCyan":"#5eead4","brightWhite":"#f8fafc"}'

    bashio::log.info "Starting Codex web terminal on port ${port}"

    exec ttyd \
        --port "$port" \
        --interface 0.0.0.0 \
        --writable \
        --ping-interval 30 \
        --client-option enableReconnect=true \
        --client-option reconnect=10 \
        --client-option reconnectInterval=5 \
        --client-option "theme=${ttyd_theme}" \
        --client-option fontSize=14 \
        bash -lc "$launch_command"
}

main() {
    bashio::log.info "Initializing Codex Terminal add-on..."
    init_environment
    install_runtime_helpers
    run_background_initialization
    start_web_terminal
}

main "$@"
