# Changelog

## 1.0.4

### Skills

- Change the entity friendly_name convention: every entity must now have `friendly_name` set explicitly to `"[Area] Nume dispozitiv - <Funcție>"`. The previous "rely on `has_entity_name: True` auto-concatenation" approach broke down in HA views that show only the entity friendly_name without device context (statistics list, dropdowns, log filters, notifications, voice assistants). The umbrella `SKILL.md`, `ha-entities.md` (intro, examples, rules), and `ha-devices-areas.md` (new-device cheat sheet) all reflect the new rule; the function vocabulary tables now expose the post-separator `<Funcție>` instead of a full entity name.

## 1.0.3

### Tooling

- Upgrade the bundled Codex CLI from `0.130.0` to `0.134.0` (latest stable on npm at release time).
- Bundle the `websocat` WebSocket client (Alpine `websocat` package) so Codex can talk to the Home Assistant Core WebSocket API at `ws://supervisor/core/api/websocket`. Authenticate by sending `{"type": "auth", "access_token": "$SUPERVISOR_TOKEN"}` as the first JSON message after the connection opens.
- `codex-ha doctor` now checks for the `websocat` binary and flags it if missing.
- The dynamic `home-assistant-instance` skill, the README, and the DOCS cheat-sheets include a one-line websocat example so Codex discovers the tool at session start.

## 1.0.2

### Skills

- Strict skills cleanup on version change: `$CODEX_HOME/skills/` is now wiped and reinstalled from the bundle on every add-on upgrade. Only skills shipped in the repo remain; ad-hoc or user-added skill directories are removed. The dynamic `home-assistant-instance/` skill is regenerated immediately afterwards by `ha-context` during background initialization.
- Make the umbrella `home-assistant` skill enforce naming conventions. The `SKILL.md` description and a new "Reguli obligatorii" block require the AI to consult the relevant `ha-*.md` file before creating, renaming, or modifying any device, entity, area, label, automation, script, scene, helper, dashboard, notification, template, or device-control call — and to ask the user instead of improvising when a convention is unclear.

## 1.0.1

### Defaults

- Flip `codex_full_permissions` default to `true`. Codex launches with `--dangerously-bypass-approvals-and-sandbox`, so it no longer prompts for approvals on every action. Set the option to `false` to restore per-action confirmation and the sandbox.

## 1.0.0

### Skills

- Consolidate the Home Assistant skills into a single discoverable umbrella at `$CODEX_HOME/skills/home-assistant/` so Codex auto-loads them on every session.
- The umbrella `SKILL.md` is the topic-focused routing index; the topic references (`ha-entities.md`, `ha-devices-areas.md`, `ha-automations.md`, `ha-scripts-steps.md`, `ha-helpers-scenes.md`, `ha-dashboards.md`, `ha-templates.md`, `ha-notifications.md`, `ha-device-control.md`, `ha-refactoring.md`, `ha-examples.md`) and the persistent `inventory.yaml` live alongside it.
- Split per-installation runtime config and safety flags into a separate `home-assistant-instance/` skill written by `ha-context`. The bundled umbrella is never overwritten between syncs.
- One-shot migration in `install_bundled_skills` detects the legacy auto-generated `home-assistant/SKILL.md` (lone file, references deleted skills) and replaces it with the bundled umbrella on upgrade. User customizations (additional files in the directory) are preserved.

### Scripts and UX

- Remove `welcome.sh` (was a blocking "Press Enter to continue" banner with stale "What's new" content).
- Remove `health-check.sh` and the `run_health_check` startup hook. `codex-ha doctor` is now the single health check; it already covers binaries, the HA Core API, MCP, skills validation, and safety options.
- Trim `codex-session-picker` to four options: reconnect, new, resume last, resume from list, exit. Drop the custom-args / login / bash-shell sub-flows.
- `validate-skills` is no longer installed on `PATH`; it is invoked internally by `run.sh` and `codex-ha doctor` from `/opt/scripts/validate-skills.sh`.
- Drop the redundant `codex-ha context-force` alias; use `codex-ha context --force` instead.
- Update `README.md` and `DOCS.md` to reflect the new bundled-skills layout, the umbrella vs. instance split, and the slimmer command set.

## 0.2.1

- Add `ha_context_refresh_minutes` option with a 30 minute default.
- Skip automatic `ha-context` regeneration while cached context is fresh.
- Add `ha-context --force` and `--refresh-minutes` controls.

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
