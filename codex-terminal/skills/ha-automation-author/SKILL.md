---
name: ha-automation-author
description: "Use when creating, reviewing, or changing Home Assistant automations, scripts, scenes, triggers, conditions, waits, action modes, notifications, and device-control flows."
---

# HA Automation Author

Use native Home Assistant automation constructs before templates.

## Workflow

1. Inspect existing entities, helpers, scripts, and automations before writing new YAML.
2. Prefer `entity_id` over `device_id`, except where a device trigger is explicitly more stable.
3. Choose `mode` deliberately:
   - `restart` for motion/timeouts.
   - `queued` for sequential actions.
   - `parallel` for independent per-entity actions.
   - `single` only for one-shot flows.
4. Prefer native `state`, `numeric_state`, `time`, `sun`, and `zone` conditions over `condition: template`.
5. Use trigger IDs and `choose` for multi-path automations.
6. Run `ha-safe-edit check` after edits.

## Avoid

- Polling templates when an event trigger exists.
- Hard-coded device IDs.
- Editing `.storage/` directly.
- Writing YAML snippets without validating the whole config.

Read `home-assistant-best-practices` references for detailed automation patterns.
