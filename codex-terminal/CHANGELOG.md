# Changelog

## 1.3.1

- Corectează instalarea `ha-mcp 7.12.0` când indexul de pachete Home Assistant nu conține versiunea `websockets 16.0`; instalarea poate folosi acum versiunea compatibilă din PyPI.

## 1.3.0

### Actualizări

- Actualizează Codex CLI la `0.144.1` și serverul `ha-mcp` la `7.12.0`.
- Treci la baza Home Assistant 3.22 și instalează serverul MCP în imagine, pentru pornire rapidă pe `amd64`, `aarch64` și `armv7`.

### Interfață și performanță

- Elimină animațiile, actualizarea blocantă a datelor și procesele repetate din meniul de pornire.
- Adaugă conversație nouă, reluarea conversațiilor, un meniu de instrumente, stare clară și afișare adaptată la lățimea terminalului.
- Optimizează proxy-ul HTTP și WebSocket și evită reînregistrarea MCP când setările nu s-au schimbat.

### Limbă

- Rescrie textele în română simplă și corectează formulările greșite din meniu, cererile prestabilite, comenzi, documentație și skill-urile Home Assistant.

## 1.2.0

### Skills

- Replace the manual Home Assistant `inventory.yaml` workflow with generated runtime rename memory at `/data/ha-context/rename_memory.json`, derived from HA device/entity/area/label registries and current states.
- Update bundled Home Assistant skills and task-picker prompts to skip already-canonical devices/entities by default and refresh context with `ha-context --force` after renames.
- Rework the bundled `home-assistant` skill for progressive disclosure: compact topic entrypoints, detailed `references/`, shared core rules, version notes, UI metadata, and helper scripts for rename-memory and entity-reference audits.
- Align notification examples on `notify.send_message`, keep platform-specific notify services as fallback only, and replace the legacy template-sensor performance example with modern `template:` syntax.

### Dependencies

- Upgrade the bundled Codex CLI from `0.136.0` to `0.142.3` (latest stable on npm).

## 1.1.10

### UX

- Replace the normal welcome-menu restart option with manual context regeneration, while keeping terminal restart available only when an existing Codex session is active.

## 1.1.9

### UX

- Show the last Home Assistant context update time in the welcome status instead of the generic automatic refresh interval.

## 1.1.8

### Fixes

- Fix welcome menu right-border alignment for Romanian text with diacritics by padding strings based on visible Unicode cell width instead of byte length.

## 1.1.7

### Fixes

- Fix terminal welcome layout: remove the duplicated context line and align the right border of menu rows with the frame.

## 1.1.6

### UX

- Redesign the terminal welcome screen with a framed banner, clearer status rows, card-like menu entries, and short startup/context-check animations.

## 1.1.5

### UX

- Remove the dashboard/sidebar UI entirely. The ingress page now opens directly into the full terminal.

### Fixes

- Refresh Home Assistant context automatically when opening the terminal and from a periodic background loop if the generated context is older than the configured refresh window (30 minutes by default).

## 1.1.4

### Fixes

- Suppress Codex's `mentions_v2` unstable-feature warning by writing `suppress_unstable_features_warning = true` into `/data/.codex/config.toml` during startup.
- Remove unavailable/stale MCP servers before the terminal starts. The add-on now drops migrated `codex_apps` entries and removes Home Assistant MCP entries whenever MCP/device control is disabled, readonly mode is enabled, or setup cannot safely run.

## 1.1.3

### Fixes

- Remove the dashboard page scrollbar on desktop so scrolling belongs only to the embedded terminal area.

## 1.1.2

### UX

- Translate the dashboard UI fully into Romanian and make action labels clearer for less experienced Home Assistant users.
- Remove the visible "Edit plans" dashboard action.
- Add "Repornește terminalul" to the welcome menu. If a Codex session is already active, the menu now offers "Continuă sesiunea deschisă" or "Repornește terminalul" instead of auto-attaching immediately.

## 1.1.1

### Fixes

- Fix Home Assistant ingress routing for the new dashboard by using ingress-relative URLs for status/action calls and the embedded terminal. This fixes `404: Not Found` in the terminal pane and JSON parse errors from `/api/status` being requested at the Home Assistant root.

## 1.1.0

### Features

- Add an ingress dashboard in front of the terminal. The page shows Codex/auth/tmux/context status, quick actions (`doctor`, context refresh, config check, MCP list, staged edit plans), startup logs, and keeps the full `ttyd` terminal embedded through a local proxy.
- Add staged safe edits: `ha-safe-edit plan <file> -- <command...>` creates a backup, runs the edit, validates YAML and `check_config`, stores a diff under `/data/safe-edit-plans`, restores the original file, and prints an apply command. `ha-safe-edit apply <plan_id>` applies only if the target file has not changed since the plan was created.
- Generate structured Home Assistant context in `/data/ha-context/*.json` alongside `$CODEX_HOME/AGENTS.md`, including entity states, entity/device/area/label registries, add-ons, integration summaries, automations/scripts/scenes, unavailable entities, repairs, and a manifest.
- Upgrade the bundled Codex CLI from `0.134.0` to `0.136.0`.

### UX

- Update task picker prompts and Home Assistant skills to prefer `ha-safe-edit plan/apply` for `/config` writes.
- Add `codex-ha context-json` and `codex-ha plans` helper commands.

## 1.0.8

### UX

- Welcome task picker — the four actionable presets (#2 "Am adăugat un dispozitiv nou", #3 "Redenumește dispozitivele și senzorii", #4 "Ajustează automatizările", #5 "Repară referințele sparte") now tell Codex to first present a summary of the proposed changes and wait for explicit confirmation before writing anything to `/config`. Codex applies (and reports) only after you approve, and re-summarises if you ask for adjustments. Option #1 "Sesiune nouă" is unchanged. A shared `PROMPT_CONFIRM` gate keeps the wording consistent across all four presets.

### Fixes

- Web terminal scrollback now works: `tmux` mouse support is enabled (`set -g mouse on` in `tmux.conf`), so the scroll wheel scrolls back through the Codex conversation / pane history (50 000-line buffer). Hold `Shift` to fall back to the browser's native text selection and copy.

## 1.0.7

### Features

- New task picker entry "Am adăugat un dispozitiv nou" — a welcome prompt that tells Codex one or more new devices were added, asks the user which device(s) before doing anything, then renames just those devices and their entities to convention (`[Cameră] Producător Model [#N]`, per-entity `friendly_name`, label, `entity_id` cleanup) and records them in `inventory.yaml`. Menu navigation hint and quick-jump keys updated from `1-4` to `1-5`.

## 1.0.6

### UX

- Task picker descriptions rewritten in plain Romanian — dropped jargon (`friendly_name`, "Idempotent", "Refactorize", "trigger IDs", `[Area] Producător Model`) in favour of friendly one-liners that a non-technical user understands at a glance. Option 2 renamed "Redenumește dispozitivele și senzorii"; option 4 renamed "Repară referințele sparte".
- Sidebar icon changed from `mdi:code-braces` to `mdi:robot` — the add-on shows up as a robot in the Home Assistant sidebar.
- `config.yaml` `description` translated to Romanian and reframed around the user outcome ("OpenAI Codex direct din sidebar — generează și depanează automatizări, dashboard-uri și YAML cu un asistent care înțelege instalarea ta de Home Assistant.").
- `codex-terminal/DOCS.md` (shown in the add-on Documentation tab) fully translated to Romanian, restructured, and updated to reflect the current skill layout (`home-assistant` umbrella + `home-assistant-instance` dynamic), the task picker, websocat bundling, and the current `codex_full_permissions` default.

### Fixes

- Task picker Enter key was a no-op because `key=$(read_key)` stripped the trailing newline via command substitution. Read now runs inline in the main loop and the Enter case accepts `''`, `\n`, and `\r`.

## 1.0.5

### UX

- Replace `codex-session-picker` with a new `codex-task-picker` shown at every fresh terminal open. Existing `tmux` session is auto-attached transparently; otherwise the user sees a 4-option menu and can choose:
  1. **Sesiune nouă** (default) — plain Codex launch without a preset prompt.
  2. Redenumește device-urile și entitățile conform convenției — sare peste ce respectă deja convenția.
  3. Ajustează automatizările conform convențiilor — alias, mode, description, trigger IDs.
  4. Repară automatizările și dashboard-urile cu entități declarate greșit.
- Options 2–4 launch Codex with a pre-filled initial prompt (passed as positional argument to `codex --cd /config`), so the requested workflow starts immediately without the user having to type it.
- Picker preset prompts explicitly tell Codex to ignore items already following the convention, so re-running them is idempotent.
- `auto_launch_codex: false` now drops the user directly into `bash -l` instead of the old session picker (which was redundant with Codex's built-in `/new` and `/resume`).
- Task picker UI is now interactive and themed: ANSI 256-color cyan accent, bold highlighted selection with arrow indicator, live status line (full permissions state · current tmux session), `↑`/`↓` arrow navigation with smooth `cursor-home + clear` redraw, numeric shortcuts `1`–`4` for instant jump, `Q` or `Esc` to exit. Banner shows current add-on version and Codex CLI version.

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
