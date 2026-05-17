#!/usr/bin/with-contenv bashio

set -e

configure_ha_mcp_server() {
    local enable_ha_mcp
    enable_ha_mcp="$(bashio::config "enable_ha_mcp" "true")"

    if [ "$enable_ha_mcp" != "true" ]; then
        bashio::log.info "Home Assistant MCP integration disabled"
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

    bashio::log.info "Registering Home Assistant MCP server with Codex..."

    codex mcp remove home-assistant >/dev/null 2>&1 || true

    if codex mcp add home-assistant \
        --env "HOMEASSISTANT_URL=http://supervisor/core" \
        --env "HOMEASSISTANT_TOKEN=${SUPERVISOR_TOKEN}" \
        -- uvx --index-strategy unsafe-best-match ha-mcp@3.5.1; then
        bashio::log.info "Home Assistant MCP server configured"
    else
        bashio::log.warning "Failed to configure Home Assistant MCP server"
        bashio::log.warning "Manual command: codex mcp add home-assistant --env HOMEASSISTANT_URL=http://supervisor/core --env HOMEASSISTANT_TOKEN=\\$SUPERVISOR_TOKEN -- uvx --index-strategy unsafe-best-match ha-mcp@3.5.1"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_ha_mcp_server
fi
