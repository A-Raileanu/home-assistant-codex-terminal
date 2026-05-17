#!/usr/bin/with-contenv bashio

set -e
set -o pipefail

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
        ha-context \
        health-check \
        persist-install \
        welcome; do
        if [ -f "/opt/scripts/${helper}.sh" ]; then
            cp "/opt/scripts/${helper}.sh" "/usr/local/bin/${helper}"
            chmod +x "/usr/local/bin/${helper}"
        fi
    done

    bashio::addon.version > /opt/scripts/addon-version 2>/dev/null || echo "unknown" > /opt/scripts/addon-version
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

generate_ha_context() {
    local ha_smart_context
    ha_smart_context="$(bashio::config "ha_smart_context" "true")"

    if [ "$ha_smart_context" != "true" ]; then
        bashio::log.info "HA smart context disabled"
        return 0
    fi

    if command -v ha-context >/dev/null 2>&1; then
        bashio::log.info "Generating Home Assistant context for Codex..."
        ha-context 2>&1 | while IFS= read -r line; do
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

get_codex_launch_command() {
    local auto_launch_codex
    local welcome_prefix=""

    auto_launch_codex="$(bashio::config "auto_launch_codex" "true")"

    if command -v welcome >/dev/null 2>&1; then
        welcome_prefix="welcome; "
    fi

    if [ "$auto_launch_codex" = "true" ]; then
        echo "${welcome_prefix}tmux new-session -A -s codex 'codex --cd /config'"
    else
        echo "${welcome_prefix}codex-session-picker"
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

run_health_check() {
    if command -v health-check >/dev/null 2>&1; then
        bashio::log.info "Running health check..."
        health-check || bashio::log.warning "Health check reported warnings"
    fi
}

main() {
    bashio::log.info "Initializing Codex Terminal add-on..."
    init_environment
    install_runtime_helpers
    run_health_check
    install_persistent_packages
    generate_ha_context
    setup_ha_mcp
    start_web_terminal
}

main "$@"
