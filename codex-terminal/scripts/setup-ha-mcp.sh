#!/usr/bin/with-contenv bashio

set -e

REGISTRATION_STATE="/data/ha-mcp-registration.sha256"

mcp_server_configured() {
    local server_name="$1"
    local config_file="${CODEX_HOME:-/data/.codex}/config.toml"
    [ -f "$config_file" ] && grep -Fq "[mcp_servers.${server_name}]" "$config_file"
}

remove_ha_mcp_servers() {
    if command -v codex >/dev/null 2>&1; then
        if mcp_server_configured home-assistant; then
            codex mcp remove home-assistant >/dev/null 2>&1 || true
        fi
        if mcp_server_configured home-assistant-official; then
            codex mcp remove home-assistant-official >/dev/null 2>&1 || true
        fi
    fi
    rm -f "$REGISTRATION_STATE"
}

configure_ha_mcp_server() {
    local enable_ha_mcp
    local mcp_mode
    local official_mcp_url
    local readonly_mode
    local enable_device_control
    local ha_mcp_version
    local bundled_ha_mcp_version
    local registration_signature
    local registration_hash
    local current_hash
    local configured_ok=true
    local -a ha_mcp_args=()
    enable_ha_mcp="$(bashio::config "enable_ha_mcp" "true")"
    mcp_mode="$(bashio::config "mcp_mode" "ha-mcp")"
    official_mcp_url="$(bashio::config "official_mcp_url" "http://supervisor/core/api/mcp")"
    readonly_mode="$(bashio::config "readonly_mode" "false")"
    enable_device_control="$(bashio::config "enable_device_control" "false")"
    ha_mcp_version="$(bashio::config "ha_mcp_version" "7.12.0")"
    bundled_ha_mcp_version="${BUNDLED_HA_MCP_VERSION:-7.12.0}"

    if [ "$enable_ha_mcp" != "true" ]; then
        bashio::log.info "Integrarea MCP pentru Home Assistant este dezactivată"
        remove_ha_mcp_servers
        return 0
    fi

    if [ "$mcp_mode" = "disabled" ]; then
        bashio::log.info "Conexiunile MCP sunt dezactivate"
        remove_ha_mcp_servers
        return 0
    fi

    if [ "$readonly_mode" = "true" ]; then
        bashio::log.info "Modul doar pentru citire este activ; conexiunile MCP nu sunt înregistrate"
        remove_ha_mcp_servers
        return 0
    fi

    if [ "$enable_device_control" != "true" ]; then
        bashio::log.info "Controlul dispozitivelor este dezactivat; conexiunile MCP nu sunt înregistrate"
        remove_ha_mcp_servers
        return 0
    fi

    if [ -z "${SUPERVISOR_TOKEN:-}" ]; then
        bashio::log.warning "Tokenul Supervisor nu este disponibil; configurarea MCP este omisă"
        remove_ha_mcp_servers
        return 0
    fi

    if ! command -v codex >/dev/null 2>&1; then
        bashio::log.warning "Comanda codex nu este disponibilă; configurarea MCP este omisă"
        return 0
    fi

    if [ "$ha_mcp_version" = "$bundled_ha_mcp_version" ] \
        && [ -x /opt/ha-mcp/bin/ha-mcp ]; then
        ha_mcp_args=(/opt/ha-mcp/bin/ha-mcp)
    else
        if ! command -v uvx >/dev/null 2>&1; then
            bashio::log.warning "Comanda uvx nu este disponibilă; versiunea MCP aleasă nu poate fi pornită"
            return 0
        fi
        ha_mcp_args=(uvx --index-strategy unsafe-best-match "ha-mcp@${ha_mcp_version}")
    fi

    registration_signature="${mcp_mode}|${official_mcp_url}|${ha_mcp_version}|${ha_mcp_args[*]}|$(printf '%s' "$SUPERVISOR_TOKEN" | sha256sum | awk '{print $1}')"
    registration_hash="$(printf '%s' "$registration_signature" | sha256sum | awk '{print $1}')"
    current_hash="$(cat "$REGISTRATION_STATE" 2>/dev/null || true)"

    if [ "$current_hash" = "$registration_hash" ]; then
        case "$mcp_mode" in
            ha-mcp|ha_mcp) mcp_server_configured home-assistant && return 0 ;;
            official) mcp_server_configured home-assistant-official && return 0 ;;
            both)
                if mcp_server_configured home-assistant \
                    && mcp_server_configured home-assistant-official; then
                    return 0
                fi
                ;;
        esac
    fi

    case "$mcp_mode" in
        ha-mcp|ha_mcp)
            if mcp_server_configured home-assistant-official; then
                codex mcp remove home-assistant-official >/dev/null 2>&1 || true
            fi
            ;;
        official)
            if mcp_server_configured home-assistant; then
                codex mcp remove home-assistant >/dev/null 2>&1 || true
            fi
            ;;
    esac

    case "$mcp_mode" in
        ha-mcp|ha_mcp|both)
            bashio::log.info "Înregistrez serverul ha-mcp în Codex..."
            if mcp_server_configured home-assistant; then
                codex mcp remove home-assistant >/dev/null 2>&1 || true
            fi
            if codex mcp add home-assistant \
                --env "HOMEASSISTANT_URL=http://supervisor/core" \
                --env "HOMEASSISTANT_TOKEN=${SUPERVISOR_TOKEN}" \
                -- "${ha_mcp_args[@]}"; then
                bashio::log.info "Serverul ha-mcp este configurat"
            else
                bashio::log.warning "Serverul ha-mcp nu a putut fi configurat"
                configured_ok=false
            fi
            ;;
    esac

    case "$mcp_mode" in
        official|both)
            bashio::log.info "Înregistrez serverul MCP oficial Home Assistant în Codex..."
            if mcp_server_configured home-assistant-official; then
                codex mcp remove home-assistant-official >/dev/null 2>&1 || true
            fi
            if codex mcp add home-assistant-official \
                --url "$official_mcp_url" \
                --bearer-token-env-var HOMEASSISTANT_TOKEN; then
                bashio::log.info "Serverul MCP oficial este configurat"
            else
                bashio::log.warning "Serverul MCP oficial nu a putut fi configurat"
                bashio::log.warning "Verifică integrarea MCP Server din Home Assistant și adresa ${official_mcp_url}"
                configured_ok=false
            fi
            ;;
    esac

    case "$mcp_mode" in
        ha-mcp|ha_mcp|official|both) ;;
        *)
            bashio::log.warning "Valoare necunoscută pentru mcp_mode: '${mcp_mode}'. Folosește ha-mcp, official, both sau disabled."
            configured_ok=false
            ;;
    esac

    if [ "$configured_ok" = "true" ]; then
        printf '%s\n' "$registration_hash" > "$REGISTRATION_STATE"
        chmod 600 "$REGISTRATION_STATE"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_ha_mcp_server
fi
