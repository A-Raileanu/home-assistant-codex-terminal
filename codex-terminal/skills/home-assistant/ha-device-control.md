---
name: ha-device-control
description: Entry point rapid pentru service calls si control device-uri Home Assistant: target/data, lumini, climate, cover, media, vacuum, ZHA/Z2M si troubleshooting.
---

# Device Control — Entry Point

Pentru detalii si exemple complete, citeste [references/ha-device-control.md](references/ha-device-control.md) doar pentru domeniul implicat.

## Fast Path

1. Foloseste `action: domain.service`, `target:` pentru entitati/arii/devices si `data:` pentru parametri.
2. Preferi `entity_id` in loc de `device_id` cand exista entitate stabila.
3. Pentru lumini foloseste `brightness_pct`, `kelvin`/`color_temp_kelvin` si tranzitii explicite.
4. Pentru notificari foloseste `notify.send_message`; detalii in [ha-notifications.md](ha-notifications.md).
5. Pentru ZHA buttons prefera trigger pe event stabil cu `device_ieee`; pentru Zigbee2MQTT foloseste `mqtt` sau entitatea expusa.
6. Pentru comenzi dependente de versiunea HA, verifica [references/ha-version-notes.md](references/ha-version-notes.md).

## Cand Sa Deschizi Referinta

| Ai nevoie de | Sectiune |
|---|---|
| Structura service call | [references/ha-device-control.md](references/ha-device-control.md#service-calls-best-practices) |
| ZHA/Zigbee2MQTT | [references/ha-device-control.md](references/ha-device-control.md#zigbee-buttonremote-patterns) |
| Lumini, climate, cover, media, vacuum | [references/ha-device-control.md](references/ha-device-control.md#domain-specific-patterns) |
| Troubleshooting si add-on development | [references/ha-device-control.md](references/ha-device-control.md#diagnosticare-si-troubleshooting) |

## TL;DR

`entity_id` peste `device_id`, `target:` + `data:`, `color_temp_kelvin` peste `color_temp`, `notify.send_message` pentru notificari.
