---
name: ha-template-debugger
description: "Use when debugging or writing Home Assistant Jinja templates, template sensors, template binary sensors, template triggers, variables, availability templates, and state conversion."
---

# HA Template Debugger

Templates are a fallback, not the default.

## First Checks

- Can a helper replace this template?
- Can a native trigger/condition replace this expression?
- Is this better as a Template Helper than YAML?

## Template Rules

- Use `states('sensor.x')`, not `states.sensor.x.state`.
- Guard numeric conversion with defaults: `| float(0)`, `| int(0)`.
- Add availability checks for sensors that depend on external entities.
- Avoid `now()` in frequently evaluated sensors unless time-based updates are intended.
- Prefer explicit units, device classes, and state classes for sensors.

## Validation

- Test small expressions before editing production config.
- Use `ha-safe-edit check` after YAML changes.
- Mention entities that can be `unknown` or `unavailable`.

Read `home-assistant-best-practices/references/template-guidelines.md` when available.
