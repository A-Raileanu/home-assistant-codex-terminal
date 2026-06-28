---
name: ha-core-rules
description: Reguli comune Home Assistant pentru naming, service calls, notificari, template-uri si refactoring.
---

# Reguli Comune

Citeste acest fisier cand un task atinge mai multe zone Home Assistant si vrei doar regulile generale.

## Naming

- Limba vizibila este romana cu diacritice: alias-uri, descrieri, friendly names, labels si comentarii.
- Cheile tehnice raman in engleza: `entity_id`, slug-uri, `device_class`, servicii si YAML.
- Device name: `[Camera] Producator Model [#N]`.
- Entity friendly name: `[Camera] Nume dispozitiv - Functie`.
- Entitatea principala fara sub-functie: `[Camera] Nume dispozitiv`.
- `entity_id` stabil: `<domain>.<area_slug>_<functie_slug>` sau cu `device_slug` cand e necesara dezambiguarea.

## Rename Safety

- `rename_memory.json` este sursa curenta pentru ce exista si ce este deja canonical.
- Nu redenumi intrari cu `skip_rename_by_default: true`.
- Nu repeta redenumiri canonical decat daca utilizatorul cere explicit.
- Friendly name si device name sunt in general cosmetice.
- `entity_id` este cheie tehnica si cere audit de referinte inainte si dupa schimbare.

## Service Calls

- Foloseste forma moderna:

```yaml
- action: light.turn_on
  target:
    entity_id: light.living_lustra
  data:
    brightness_pct: 60
```

- Preferi `entity_id` peste `device_id` cand exista entitate stabila.
- Folosesti `target:` pentru destinatie si `data:` pentru parametri.
- Pentru lumini folosesti `color_temp_kelvin`, nu `color_temp`.

## Automations

- `restart`: evenimente care reseteaza countdown-ul.
- `queued`: pasi secventiali care nu trebuie pierduti.
- `parallel`: alerte independente per camera/dispozitiv.
- `single`: one-shot sau butoane unde repetarea se ignora.
- Trigger IDs pe automatizari multi-trigger.
- Conditii native inainte de template-uri.

## Helpers Si Templates

- Helper nativ inainte de template cand exprima aceeasi logica.
- Template sensors YAML folosesc integrarea moderna `template:`.
- Trigger-based template pentru calcule scumpe.
- Fallback pentru `unknown`, `unavailable`, `none`.

## Notifications

- Default: `notify.send_message` cu `target:`.
- Serviciile per-platforma (`notify.mobile_app_*`, `notify.alexa_media_*`) sunt fallback explicit.
- Action IDs pentru notificari actionabile trebuie sa fie stabile.

## Validare

- Pentru fisiere din `/config`, foloseste `ha-safe-edit plan` si aplica doar dupa confirmare.
- Dupa schimbari tangibile de device/entitate/label/entity_id: `ha-context --force`.
- Pentru referinte stale: `scripts/ha_reference_scan.py`.
