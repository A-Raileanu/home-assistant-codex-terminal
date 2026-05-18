#!/usr/bin/with-contenv bashio

set -e

configure_ha_mcp_server() {
    local enable_ha_mcp
    local mcp_mode
    local official_mcp_url
    enable_ha_mcp="$(bashio::config "enable_ha_mcp" "true")"
    mcp_mode="$(bashio::config "mcp_mode" "ha-mcp")"
    official_mcp_url="$(bashio::config "official_mcp_url" "http://supervisor/core/api/mcp")"

    if [ "$enable_ha_mcp" != "true" ]; then
        bashio::log.info "Home Assistant MCP integration disabled"
        return 0
    fi

    if [ "$mcp_mode" = "disabled" ]; then
        bashio::log.info "MCP mode is disabled"
        return 0
    fi

    if [ -z "${SUPERVISOR_TOKEN:-}" ]; then
        bashio::log.warning "SUPERVISOR_TOKEN is unavailable; skipping Home Assistant MCP setup"
        return 0
    fi

    if ! command -v codex >/dev/null 2>&1; then
        bashio::log.warning "codex command not found; skipping MCP setup"
        return 0
    fi

    if ! command -v uvx >/dev/null 2>&1; then
        bashio::log.warning "uvx command not found; skipping MCP setup"
        return 0
    fi

    case "$mcp_mode" in
        ha-mcp|ha_mcp|both)
            bashio::log.info "Registering ha-mcp stdio server with Codex..."
            codex mcp remove home-assistant >/dev/null 2>&1 || true
            if codex mcp add home-assistant \
                --env "HOMEASSISTANT_URL=http://supervisor/core" \
                --env "HOMEASSISTANT_TOKEN=${SUPERVISOR_TOKEN}" \
                -- uvx --index-strategy unsafe-best-match ha-mcp@3.5.1; then
                bashio::log.info "ha-mcp server configured"
            else
                bashio::log.warning "Failed to configure ha-mcp server"
            fi
            ;;
    esac

    case "$mcp_mode" in
        official|both)
            bashio::log.info "Registering official Home Assistant MCP endpoint with Codex..."
            codex mcp remove home-assistant-official >/dev/null 2>&1 || true
            if codex mcp add home-assistant-official \
                --url "$official_mcp_url" \
                --bearer-token-env-var HOMEASSISTANT_TOKEN; then
                bashio::log.info "Official Home Assistant MCP endpoint configured"
            else
                bashio::log.warning "Failed to configure official Home Assistant MCP endpoint"
                bashio::log.warning "Make sure the MCP Server integration is configured in Home Assistant and ${official_mcp_url} is reachable"
            fi
            ;;
    esac

    case "$mcp_mode" in
        ha-mcp|ha_mcp|official|both) ;;
        *)
            bashio::log.warning "Unknown mcp_mode '${mcp_mode}'. Use ha-mcp, official, both, or disabled."
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_ha_mcp_server
fi
