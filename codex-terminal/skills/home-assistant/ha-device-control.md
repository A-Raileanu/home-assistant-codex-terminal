---
name: ha-device-control
description: Punct de pornire pentru apeluri de servicii și controlul dispozitivelor Home Assistant: lumini, climatizare, jaluzele, media, aspiratoare, ZHA/Z2M și depanare.
---

# Device Control — Punct de pornire

Pentru detalii si exemple complete, citeste [references/ha-device-control.md](references/ha-device-control.md) doar pentru domeniul implicat.

## Pași rapizi

1. Foloseste `action: domain.service`, `target:` pentru entitati/arii/devices si `data:` pentru parametri.
2. Preferi `entity_id` in loc de `device_id` cand exista entitate stabila.
3. Pentru lumini foloseste `brightness_pct`, `kelvin`/`color_temp_kelvin` si tranzitii explicite.
4. Pentru notificari foloseste `notify.send_message`; detalii in [ha-notifications.md](ha-notifications.md).
5. Pentru ZHA buttons prefera trigger pe event stabil cu `device_ieee`; pentru Zigbee2MQTT foloseste `mqtt` sau entitatea expusa.
6. Pentru comenzi dependente de versiunea HA, verifica [references/ha-version-notes.md](references/ha-version-notes.md).

## Cand Sa Deschizi Referinta

| Ai nevoie de | Sectiune |
|---|---|
| Structura service call | [references/ha-device-control.md](references/ha-device-control.md#apeluri-de-servicii-bune-practici) |
| ZHA/Zigbee2MQTT | [references/ha-device-control.md](references/ha-device-control.md#modele-pentru-butoane-și-telecomenzi-zigbee) |
| Lumini, climate, cover, media, vacuum | [references/ha-device-control.md](references/ha-device-control.md#modele-specifice-pe-domeniu) |
| Depanare si add-on development | [references/ha-device-control.md](references/ha-device-control.md#diagnosticare-și-depanare) |

## TL;DR

`entity_id` peste `device_id`, `target:` + `data:`, `color_temp_kelvin` peste `color_temp`, `notify.send_message` pentru notificari.
