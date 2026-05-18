# Changelog

## 0.2.0

- Bundle Home Assistant best-practices skill content.
- Add focused Home Assistant Codex skills for automations, dashboards, templates, safe refactors, add-on development, and troubleshooting.
- Add `codex-ha` diagnostics and Home Assistant helper command.
- Add `ha-safe-edit` backup and validation workflow.
- Expand Home Assistant context generation with integrations, automations, scripts, scenes, unavailable entities, repairs, recorder size, and add-on logs.
- Add MCP mode selection for `ha-mcp`, official Home Assistant MCP endpoint, both, or disabled.
- Add startup skill validation and safety-mode options.

## 0.1.1

- Fix generated Home Assistant skill frontmatter YAML.
- Install `bubblewrap` so Codex can use system `bwrap`.

## 0.1.0

- Initial Codex Terminal add-on.
- Adds browser terminal ingress with `ttyd`.
- Installs OpenAI Codex CLI.
- Persists Codex config and auth in `/data/.codex`.
- Generates Home Assistant context and Codex skill.
- Optionally configures Home Assistant MCP.
