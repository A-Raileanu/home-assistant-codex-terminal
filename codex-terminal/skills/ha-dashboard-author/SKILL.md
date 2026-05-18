---
name: ha-dashboard-author
description: "Use when designing or editing Home Assistant dashboards, Lovelace views, sections, cards, tile features, room views, mobile layouts, and dashboard refactors."
---

# HA Dashboard Author

Design dashboards around repeated daily use, not showcase layouts.

## Defaults

- Prefer built-in Sections dashboards, Tile cards, Mushroom-like density only when already installed, and mobile-first layouts.
- Group by room, routine, or operational task.
- Put controls near the information needed to use them safely.
- Use entity names and icons that match the Home Assistant registry.
- Keep dashboards resilient: avoid direct `.storage` edits unless no API/YAML alternative exists.

## Workflow

1. Inventory existing dashboards and relevant entities.
2. Identify whether the dashboard is storage-managed or YAML-managed.
3. Use APIs/MCP where available; otherwise use `ha-safe-edit` around YAML files.
4. Validate entity IDs and unavailable states before adding cards.
5. Summarize changed views/cards and any assumptions.

Read `home-assistant-best-practices/references/dashboard-guide.md` and `dashboard-cards.md` when available.
