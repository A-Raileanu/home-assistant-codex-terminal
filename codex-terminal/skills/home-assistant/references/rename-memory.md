---
name: ha-rename-memory
description: Ghid pentru /data/ha-context/rename_memory.json si auditul dispozitivelor/entitatilor redenumite.
---

# Rename Memory

`/data/ha-context/rename_memory.json` este memoria de rulare generata de `ha-context` din registrele reale Home Assistant. Inlocuieste orice inventar manual.

## Regula De Aur

Nu propune si nu aplica redenumiri pentru intrari care sunt deja canonical sau au `skip_rename_by_default: true`, decat daca utilizatorul cere explicit acest lucru.

## Query Rapid

```bash
python "$CODEX_HOME/skills/home-assistant/scripts/ha_rename_audit.py" --summary
python "$CODEX_HOME/skills/home-assistant/scripts/ha_rename_audit.py" --pending
python "$CODEX_HOME/skills/home-assistant/scripts/ha_rename_audit.py" --kind entities --query living
python "$CODEX_HOME/skills/home-assistant/scripts/ha_rename_audit.py" --json --pending
```

Fallback fara script:

```bash
jq '.summary' /data/ha-context/rename_memory.json
jq '.devices[] | select(.skip_rename_by_default != true) | {name, area_name, manufacturer, model}' /data/ha-context/rename_memory.json
jq '.entities[] | select(.skip_rename_by_default != true) | {entity_id, friendly_name, disabled_by}' /data/ha-context/rename_memory.json
```

## Campuri Utile

| Camp | Sens |
|---|---|
| `summary` | Totaluri pentru dispozitive, entitati, canonical names si disabled entities. |
| `devices[].is_canonical_name` | Device-ul are deja nume in format `[Area] ...`. |
| `devices[].skip_rename_by_default` | Codex trebuie sa sara peste device implicit. |
| `entities[].is_canonical_friendly_name` | Friendly name-ul entitatii este deja canonical. |
| `entities[].disabled_by` | Entitate dezactivata; nu o redenumi pentru cosmetica. |
| `entities[].skip_rename_by_default` | Codex trebuie sa sara peste entitate implicit. |
| `label_details` | Labels rezolvate din registrul HA. |

## Flux Rename

1. Ruleaza `ha-context --force` daca memoria pare veche.
2. Interogheaza doar intrarile relevante.
3. Elimina din plan orice intrare canonical sau `skip_rename_by_default`.
4. Pentru ce ramane, aplica regulile din `ha-devices-areas.md` si `ha-entities.md`.
5. Daca schimbi `entity_id`, ruleaza auditul de referinte din `ha-refactoring.md`.
6. Dupa aplicare, ruleaza din nou `ha-context --force` si verifica intrarile atinse.

## Ce Nu Mai Exista

Nu folosi `inventory.yaml`. Memoria este generata automat si reflecta starea curenta din HA.
