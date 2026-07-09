---
name: home-assistant
description: Ghid principal pentru lucrul cu Home Assistant în Codex. Folosește-l înainte să creezi, redenumești sau modifici dispozitive, entități, camere, etichete, automatizări, scripturi, scene, elemente ajutătoare, panouri, notificări, șabloane ori apeluri de servicii.
---

# Home Assistant — Ghid rapid

Foloseste acest skill ca index. Citeste doar entrypoint-ul relevant, apoi doar referinta indicata de acel entrypoint daca ai nevoie de detalii.

## Flux Obligatoriu

1. Identifica elementul atins si deschide fisierul din tabelul de rutare.
2. Daca atingi dispozitive sau entitati, consulta `/data/ha-context/rename_memory.json` inainte de plan.
3. Nu redenumi nimic care are `skip_rename_by_default: true`, `is_canonical_name: true` sau `is_canonical_friendly_name: true`, cu exceptia cazului in care utilizatorul cere explicit redenumirea.
4. Aplica romana cu diacritice pentru alias-uri, descrieri, friendly names si labels vizibile; pastreaza engleza pentru `entity_id`, slug-uri si chei YAML.
5. Pentru entitati, seteaza explicit `friendly_name: "[Area] Nume dispozitiv - Functie"`; pentru entitatea principala fara sub-functie foloseste `"[Area] Nume dispozitiv"`.
6. Pentru `/config`, planifica intai cu `ha-safe-edit plan <file> -- <command...>` si aplica doar dupa confirmare.
7. Dupa schimbari tangibile de device, entitate, label sau `entity_id`, ruleaza `ha-context --force`.

## Rutare

| Task | Citeste intai |
|---|---|
| Device, arii, labels, onboarding device nou | [ha-devices-areas.md](ha-devices-areas.md) |
| Entity ID, friendly name, vocabular functii, `device_class` | [ha-entities.md](ha-entities.md) |
| Automatizari, identificatori de declanșator, `mode`, conditii, dezactivare | [ha-automations.md](ha-automations.md) |
| Scripturi, `fields`, `sequence`, variabile | [ha-scripts-steps.md](ha-scripts-steps.md) |
| Helpers, scene, alegerea intre helper/template/script | [ha-helpers-scenes.md](ha-helpers-scenes.md) |
| Dashboard Lovelace, views, cards, styling | [ha-dashboards.md](ha-dashboards.md) |
| Notificari, alerte, TTS | [ha-notifications.md](ha-notifications.md) |
| Șabloane Jinja2 si template sensors | [ha-templates.md](ha-templates.md) |
| Apeluri de servicii, lumini, climate, cover, media, ZHA/Z2M | [ha-device-control.md](ha-device-control.md) |
| Redenumiri, impact analysis, referinte stale | [ha-refactoring.md](ha-refactoring.md) |
| Exemple end-to-end | [ha-examples.md](ha-examples.md) |
| Reguli comune scurte | [references/core-rules.md](references/core-rules.md) |
| Note sensibile la versiunea HA | [references/ha-version-notes.md](references/ha-version-notes.md) |

## Memorie de redenumire

`/data/ha-context/rename_memory.json` inlocuieste orice inventar manual. Pentru audit rapid, ruleaza:

```bash
python "$CODEX_HOME/skills/home-assistant/scripts/ha_rename_audit.py" --summary
python "$CODEX_HOME/skills/home-assistant/scripts/ha_rename_audit.py" --pending
```

Pentru cautarea referintelor unui `entity_id` in `/config`:

```bash
python "$CODEX_HOME/skills/home-assistant/scripts/ha_reference_scan.py" sensor.living_temperatura
```

Detalii: [references/rename-memory.md](references/rename-memory.md).

## Reguli Comune

- `entity_id` este cheia tehnica; friendly name este cosmetic. Redenumirea de `entity_id` cere audit de referinte.
- Preferi `entity_id` in loc de `device_id` cand exista alternativa stabila.
- Folosesti `target:` si `data:` in apeluri de servicii.
- Folosesti `color_temp_kelvin`, nu `color_temp`.
- Preferi helpers/native conditions in loc de șabloane cand exprima aceeasi logica.
- Preferi `notify.send_message` cu `target:` in loc de servicii per-platforma.
- Pentru reguli dependente de versiunea HA, verifica [references/ha-version-notes.md](references/ha-version-notes.md) si documentatia oficiala daca instanta ruleaza alta versiune.

## Glosar Minimal

| Termen | Sens |
|---|---|
| Entity | Unitate functionala HA: `domain.slug`, cu stare si atribute. |
| Device | Grupare logica pentru entitatile aceluiasi hardware. |
| Area | Camera sau locatie logica. |
| Label | Eticheta transversala pentru tipuri de device/functii. |
| Helper | Entitate virtuala HA: `input_boolean`, `timer`, `counter`, template helper etc. |
| Service call | Actiune `domain.service` cu `target:` si `data:`. |
| Config Entry | Configurarea interna a unei integrari in `.storage/core.config_entries`. |
