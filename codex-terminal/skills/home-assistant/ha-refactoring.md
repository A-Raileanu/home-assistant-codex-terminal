---
name: ha-refactoring
description: Punct de pornire pentru redenumiri și refactorizare Home Assistant: verificarea efectelor, referințe vechi, panouri stocate, configurarea integrărilor și `rename_memory.json`.
---

# Refactoring — Punct de pornire

Pentru procedura completa, citeste [references/ha-refactoring.md](references/ha-refactoring.md). Pentru query rapid al memoriei, citeste [references/rename-memory.md](references/rename-memory.md).

## Pași rapizi

1. Citeste `rename_memory.json` inainte de orice plan.
2. Sari peste intrarile canonical sau `skip_rename_by_default: true`, cu exceptia cererilor explicite.
3. Pentru friendly name/device name, impactul este in general cosmetic.
4. Pentru `entity_id`, cauta referinte inainte si dupa schimbare.
5. Verifica automatizari, scripturi, scene, groups/helpers, dashboards YAML, `.storage/lovelace*`, `customize`, șabloane si integrari externe.
6. Nu edita `.storage` manual daca exista API/UI. Pentru fisiere din `/config`, foloseste `ha-safe-edit`.
7. Dupa aplicare, ruleaza `ha-context --force` si verifica memoria actualizata.

## Tooling

```bash
python "$CODEX_HOME/skills/home-assistant/scripts/ha_rename_audit.py" --pending
python "$CODEX_HOME/skills/home-assistant/scripts/ha_reference_scan.py" sensor.vechi_entity_id
```

## Cand Sa Deschizi Referinta

| Ai nevoie de | Sectiune |
|---|---|
| Procedura completa de redenumire | [references/ha-refactoring.md](references/ha-refactoring.md) |
| Blind spots `.storage` / config entries | [references/ha-refactoring.md](references/ha-refactoring.md#config-entry-groups) |
| Exemplu end-to-end | [references/ha-refactoring.md](references/ha-refactoring.md#exemplu-end-to-end-redenumire-smart-plug) |

## TL;DR

Friendly name e cosmetic; `entity_id` cere audit. Nu repeta redenumiri deja canonical.
