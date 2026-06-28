---
name: ha-notifications
description: Notificări și TTS HA — `notify.send_message` (2024.7+), titlu `[Zonă] — Status` max 50 chars, canale (critical_alerts/device_warnings/information/updates), notificări acționabile, TTS, Jinja2 date dinamice.
---

# Notificări și TTS — Home Assistant

> Pentru servicii de notificare dependente de versiunea HA, verifică [ha-version-notes.md](ha-version-notes.md) înainte de schimbări critice.

## Notificări

Notificările sunt prima interacțiune umană a casei inteligente. Un format consistent le face imediat lizibile și acționabile — nu ai nevoie să deschizi HA ca să înțelegi ce s-a întâmplat.

### Serviciul recomandat — `notify.send_message` (HA 2024.7+)

HA a unificat serviciile de notificare într-un singur serviciu cu `target:`. **Preferă** `notify.send_message` în loc de servicii per-platformă (`notify.mobile_app_*`, `notify.alexa_media_*`, etc.) — e mai stabil la redenumiri și uniform între integrări.

```yaml
# Modern (preferat) — funcționează la orice notify entity
- action: notify.send_message
  target:
    entity_id: notify.telefon_andrei
  data:
    title: "[Garaj] Ușă lăsată deschisă"
    message: Ușa garajului este deschisă de 10 minute.

# Legacy: serviciile per-platformă de forma `notify.mobile_app_*`
# pot exista, dar nu le folosi ca default pentru cod nou.
```

**Câmpul `data:`** rămâne aceeași în ambele variante — `channel`, `importance`, `actions`, `image`, etc. sunt suportate identic.

### Anatomia unei notificări

```
[Sursă/Zonă] — Status scurt
Propoziție completă: ce, unde, când, valoare actuală, acțiune sugerată.
```

### Format titlu

```
[Sursă/Zonă] — Status
```

- **`[Sursă/Zonă]`** — zona sau sistemul: `[Garaj]`, `[Alarmă]`, `[Consum]`, `[Casă]`
- **Status** — ce s-a întâmplat, concis: `Ușă deschisă`, `Consum ridicat`, `Baterie descărcată`
- **Lungime maximă:** ~50 caractere — afișat complet pe ecranul de blocare

Exemple:
```
[Garaj] Ușă lăsată deschisă
[Alarmă] Mișcare detectată
[Consum] Putere > 4 kW
[Senzor Baie #1] Baterie 8%
```

### Format mesaj

O propoziție completă în română care răspunde la: **ce** / **unde** / **când** / **valoare actuală** / **acțiune sugerată**.

```
Ușa garajului este deschisă de 10 minute. Ultima deschidere: 15:32.
Consumul depășește limita setată: 4.8 kW / limită 4 kW.
Bateria senzorului din Baie #1 a ajuns la 8%. Înlocuiește bateria curând.
```

Reguli:
- **Fraze complete, nu telegrafice** — `Ușa garajului este deschisă` nu `usa garaj open`
- **Fără cod tehnic** — `Senzor Baie #1` nu `binary_sensor.baie1_door`
- **Include valoarea actuală** când e relevantă — `4.8 kW`, `8%`, `21°C`
- **Include ora** pentru evenimente rare sau urgente

### Canale (`channel`)

Grupează notificările pe canale pentru a putea controla silențiozitatea per tip:

| Channel | Tipul de alertă | Exemple |
| ------- | --------------- | ------- |
| `critical_alerts` | Urgențe care cer acțiune imediată | Alarmă declanșată, gaz detectat, inundație |
| `device_warnings` | Avertizări dispozitive | Baterie descărcată, senzor offline, ușă lăsată deschisă |
| `information` | Stare și confirmare | Plecare confirmată, sistemul armat, scena activată |
| `updates` | Rapoarte periodice | Consum zilnic, temperaturi, sumar noapte |

```yaml
- alias: Trimite alertă critică — gaz detectat
  action: notify.send_message
  target:
    entity_id: notify.telefon_andrei
  data:
    title: "[Alarmă] Gaz detectat în bucătărie"
    message: >
      Senzorul de gaz din bucătărie a detectat gaz. Ventilează imediat și
      verifică aragazul. Dacă mirosul persistă, evacuează și sună 112.
    data:
      channel: critical_alerts
      importance: high
      ttl: 0
      priority: high
```

### Priorități

| Nivel | `importance` | `priority` | Comportament |
| ----- | ------------ | ---------- | ------------ |
| CRITICAL | `high` | `high` | Sunet + vibrație, trece Do Not Disturb (Android) |
| HIGH | `high` | `normal` | Sunet + vibrație |
| NORMAL | `default` | `normal` | Sunet normal |
| LOW | `low` | `low` | Silențios, doar în bara de notificări |

> Pe iOS folosește `push.sound` cu `critical: 1` și `volume: 1.0` pentru a trece Silent Mode.

### Notificări acționabile (`actions:`)

Adaugă butoane direct în notificare pentru răspuns rapid fără a deschide HA:

```yaml
- alias: Trimite alertă — ușă garaj deschisă cu opțiuni
  action: notify.send_message
  target:
    entity_id: notify.telefon_andrei
  data:
    title: "[Garaj] Ușă lăsată deschisă"
    message: Ușa garajului este deschisă de 10 minute. Acționează acum.
    data:
      channel: device_warnings
      actions:
        - action: INCHIDE_USA_GARAJ
          title: Închide ușa
        - action: AMINTESTE_DUPA_30MIN
          title: Amintește în 30 min
        - action: IGNORA_ALERTA
          title: Ignoră

# Automatizare separată — gestionează răspunsul la acțiunea din notificare
alias: "[Garaj] Răspuns notificare — Închide ușa"
triggers:
  - trigger: event
    event_type: mobile_app_notification_action
    event_data:
      action: INCHIDE_USA_GARAJ
actions:
  - alias: Închide ușa garajului
    action: cover.close_cover
    target:
      entity_id: cover.garaj_door
```

### Imagine în notificare

```yaml
- alias: Trimite snapshot cameră exterioară
  action: notify.send_message
  target:
    entity_id: notify.telefon_andrei
  data:
    title: "[Exterior] Mișcare detectată"
    message: Mișcare detectată la intrarea principală.
    data:
      image: "{{ state_attr('camera.exterior_intrare', 'entity_picture') }}"
      channel: device_warnings
```

### TTS (Text-to-Speech) — anunțuri vocale

| Regulă | Greșit | Corect |
| ------ | ------ | ------ |
| Fraze complete | `Usa deschisa` | `Ușa garajului a rămas deschisă` |
| Max 30 cuvinte/propoziție | (fraze lungi) | Împarte în 2 propoziții |
| Fără abrevieri | `temp 21 grade` | `Temperatura este 21 de grade` |
| Fără cod tehnic | `sensor dot baie1` | `Senzorul din baie` |
| Română cu diacritice | `Usa ramasa deschisa` | `Ușa a rămas deschisă` |

```yaml
- alias: Anunță pe boxă — ușa garajului a rămas deschisă
  action: tts.speak
  target:
    entity_id: media_player.living_boxa
  data:
    message: >
      Atenție! Ușa garajului a rămas deschisă de mai mult de zece minute.
      Te rog s-o închizi înainte să pleci.
    language: ro
```

### Date dinamice cu Jinja2

```yaml
- alias: Trimite raport consum zilnic
  action: notify.send_message
  target:
    entity_id: notify.telefon_andrei
  data:
    title: "[Consum] Raport zilnic"
    message: >
      Consum ieri: {{ states('sensor.energy_daily') | round(1) }} kWh.
      Față de media săptămânii: {{ states('sensor.energy_weekly_avg') | round(1) }} kWh/zi.
      {% if states('sensor.energy_daily') | float(0) > 15 %}
      Consum ridicat față de obișnuit!
      {% endif %}
    data:
      channel: updates

- alias: Trimite alertă cu valori live
  action: notify.send_message
  target:
    entity_id: notify.telefon_andrei
  data:
    title: "[Consum] Putere > {{ states('input_number.power_limit') | int }} W"
    message: >
      Consumul actual este {{ states('sensor.home_total_power') | round(0) }} W,
      peste limita setată de {{ states('input_number.power_limit') | int }} W.
      Verificat la {{ now().strftime('%H:%M') }}.
    data:
      channel: device_warnings
      importance: high
```

---

**TL;DR:** Titlu: `[Zonă] — Status` max 50 chars. Mesaj: propoziție completă cu ce/unde/când/valoare. Canal: `critical_alerts` → urgențe, `device_warnings` → avertizări, `information` → confirmare, `updates` → rapoarte. TTS: fraze complete, max 30 cuvinte/propoziție, diacritice corecte.
