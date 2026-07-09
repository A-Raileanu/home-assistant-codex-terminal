---
name: ha-automations
description: Punct de pornire pentru automatizări Home Assistant: nume românești, mod de rulare, declanșatoare, condiții native, așteptare, repetare, alegere și dezactivare.
---

# Automatizari — Punct de pornire

Citeste acest fisier pentru decizia rapida. Pentru detalii complete si exemple, deschide doar sectiunea necesara din [references/ha-automations.md](references/ha-automations.md).

## Pași rapizi

1. Alias in romana: `[Zona] Declansator - efect`, maximum aproximativ 60 caractere.
2. Adauga `description:` cand automatizarea are logica multipla, dependente externe sau risc de confuzie.
3. Alege `mode:` dupa comportament:
   - `restart`: lumini/prezenta cu countdown, unde ultimul eveniment castiga.
   - `queued`: anunturi, TTS, secvente care trebuie rulate pe rand.
   - `parallel`: alerte independente per camera/dispozitiv.
   - `single`: butoane one-shot sau actiuni unde click-urile repetate se ignora.
4. Pune `id:` pe triggere cand aceeasi automatizare are mai multe declansatoare si ramuri diferite.
5. Preferi conditii native (`state`, `numeric_state`, `time`, `sun`) in loc de template.
6. Preferi `wait_for_trigger` in loc de `wait_template`.
7. Preferi `entity_id` in loc de `device_id`, cu exceptia cazurilor unde integrarea cere explicit device trigger.
8. Pentru notificari foloseste `notify.send_message`; detalii in [ha-notifications.md](ha-notifications.md).

## Cand Sa Deschizi Referinta Detaliata

| Ai nevoie de | Sectiune |
|---|---|
| Format alias, `description`, `mode`, identificatori de declanșator | [references/ha-automations.md](references/ha-automations.md#automatizări) |
| Conditii native si modele | [references/ha-automations.md](references/ha-automations.md#bune-practici-și-modele) |
| Tipuri de triggere | [references/ha-automations.md](references/ha-automations.md#tipuri-de-declanșatori-triggers) |
| `wait`, `repeat`, `choose`, `continue_on_error` | [references/ha-automations.md](references/ha-automations.md#acțiuni-de-așteptare-wait) |
| Dezactivare temporara/permanenta | [references/ha-automations.md](references/ha-automations.md#dezactivarea-automatizărilor) |
| Anti-modele | [references/ha-automations.md](references/ha-automations.md#anti-modele) |
| Comportament nou sau versionat HA | [references/ha-version-notes.md](references/ha-version-notes.md) |

## TL;DR

`[Zona] Declansator - efect`; `restart` pentru countdown-uri, `queued` pentru secvente, `parallel` pentru alerte independente, `single` pentru one-shot. Trigger IDs pe multi-trigger. Conditii native peste template. `entity_id` peste `device_id`.
