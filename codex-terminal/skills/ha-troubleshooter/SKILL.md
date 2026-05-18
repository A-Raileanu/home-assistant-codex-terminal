---
name: ha-troubleshooter
description: "Use when diagnosing Home Assistant errors, unavailable entities, failed automations, add-on problems, repairs, logs, integrations, recorder issues, and startup failures."
---

# HA Troubleshooter

Diagnose from evidence first.

## Workflow

1. Run `codex-ha doctor`.
2. Refresh context with `ha-context`.
3. Check recent errors and relevant add-on logs.
4. Inspect unavailable/unknown entities by domain.
5. For automation bugs, check last-triggered state, traces when available, entity states, and mode.
6. For config issues, run `ha-safe-edit check`.
7. Provide a ranked root cause list and the smallest safe fix.

## Useful Commands

```bash
codex-ha doctor
codex-ha logs <addon_slug>
ha-context --full
ha-safe-edit check
```

Avoid speculative fixes before reading logs or current entity state.
