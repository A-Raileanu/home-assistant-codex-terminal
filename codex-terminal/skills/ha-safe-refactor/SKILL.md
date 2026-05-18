---
name: ha-safe-refactor
description: "Use when renaming entities, replacing helpers, restructuring automations, changing scripts/scenes, migrating integrations, or updating references across Home Assistant config."
---

# HA Safe Refactor

Home Assistant refactors are cross-reference problems.

## Required Workflow

1. Search `/config` for every old entity/helper/script/scene name.
2. Check automations, scripts, scenes, dashboards, groups, templates, and packages.
3. Check Config Entry-backed consumers when changing helpers or entity IDs.
4. Back up every edited file with `ha-safe-edit backup`.
5. Make the smallest change set that preserves behavior.
6. Run `ha-safe-edit check`.
7. Report changed files, backup paths, and follow-up reload/restart steps.

## Avoid

- Bulk renames without impact analysis.
- Editing `.storage` unless explicitly approved.
- Assuming dashboard references update automatically.

Read `home-assistant-best-practices/references/safe-refactoring.md` when available.
