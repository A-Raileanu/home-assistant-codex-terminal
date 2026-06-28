---
name: ha-notifications
description: Entry point rapid pentru notificari Home Assistant: notify.send_message, target, canale, prioritati, actiuni mobile, TTS si Jinja sigur.
---

# Notificari — Entry Point

Pentru canale, payload-uri mobile si exemple avansate, citeste [references/ha-notifications.md](references/ha-notifications.md).

## Fast Path

Foloseste implicit serviciul unificat:

```yaml
- action: notify.send_message
  target:
    entity_id: notify.telefon_andrei
  data:
    message: "Mesajul notificarii"
    title: "Titlu"
```

## Reguli

1. Preferi `notify.send_message` in loc de `notify.mobile_app_*`, `notify.alexa_media_*` sau alte servicii per-platforma.
2. Folosesti `target:` pentru destinatar si `data:` pentru mesaj/payload.
3. Pentru template-uri in notificari, adauga fallback-uri sigure pentru stari `unknown`/`unavailable`.
4. Pentru notificari actionabile, pastreaza action IDs stabile si scurte.
5. Pentru TTS/media, verifica serviciul concret expus de integrare inainte de a aplica.

## Cand Sa Deschizi Referinta

| Ai nevoie de | Sectiune |
|---|---|
| Canale si prioritati mobile | [references/ha-notifications.md](references/ha-notifications.md#canale-si-prioritati) |
| Notificari actionabile | [references/ha-notifications.md](references/ha-notifications.md#notificari-actionabile) |
| Imagini, TTS, rapoarte | [references/ha-notifications.md](references/ha-notifications.md) |
| Template/Jinja in mesaj | [ha-templates.md](ha-templates.md) |

## TL;DR

`notify.send_message` cu `target:`. Serviciile per-platforma sunt fallback explicit, nu default.
