---
name: ha-add-on-developer
description: "Use when building, debugging, or improving Home Assistant add-ons/apps, ingress panels, add-on config.yaml, build.yaml, Supervisor API use, Dockerfiles, and add-on release workflows."
---

# HA Add-on Developer

Home Assistant add-ons are supervised containers with explicit permissions.

## Checklist

- Keep `config.yaml` permissions minimal and explain broad access.
- Use ingress for sidebar UIs and bind internal services to `0.0.0.0`.
- Persist user state in `/data`, not image layers.
- Access Home Assistant through `http://supervisor/core/api` with `SUPERVISOR_TOKEN`.
- Prefer Home Assistant base images and multi-arch `build.yaml`.
- Validate shell scripts and YAML before release.

## Common Commands

```bash
codex-ha doctor
codex-ha check-config
codex mcp list
```

For this add-on, Codex state lives in `/data/.codex` and generated HA context lives in `$CODEX_HOME/AGENTS.md`.
