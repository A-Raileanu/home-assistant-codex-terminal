---
name: ha-device-control
description: Service calls HA — `target:`/`data:`, entity_id vs device_id, ZHA/Z2M buttons, pattern-uri lumini/climate/cover/media/vacuum, response_variable, troubleshooting, add-on dev.
---

# Controlul Device-urilor — Home Assistant

> Pentru servicii sau comportamente dependente de versiunea HA, verifică [ha-version-notes.md](ha-version-notes.md) înainte de schimbări critice.

## Entity ID vs Device ID

### Problema de bază

`device_id` este un identificator intern HA care **se schimbă când un device este re-adăugat** (ex: după Zigbee mesh repair, re-setup de integrare, sau înlocuire hardware). Automatizările care folosesc `device_id` se vor strica în tăcere.

`entity_id` este controlabil de utilizator, stabil la re-adăugarea device-ului, și poate fi redenumit pentru claritate.

### Trigger-uri device vs trigger-uri state

```yaml
# GREȘIT - device_id se schimbă dacă device-ul este re-adăugat
triggers:
  - trigger: device
    device_id: abc123def456
    domain: binary_sensor
    type: motion

# CORECT - entity_id este stabil și poate fi redenumit
triggers:
  - trigger: state
    entity_id: binary_sensor.hol_motion
    to: "on"
```

### Când device_id este acceptabil

1. **Device-only triggers** — Unele device-uri expun triggers fără entități (ex: Zigbee buttons — vezi secțiunea Zigbee)
2. **Automatizări temporare** — Quick tests pe care le vei șterge
3. **Z2M autodiscovery** — Zigbee2MQTT gestionează mapping-ul device-to-trigger

---

## Service calls — bune practici

### Folosește structura `target:`

```yaml
actions:
  - action: light.turn_on
    target:
      entity_id: light.living_ceiling
    data:
      brightness_pct: 100
```

### Tipuri de target

| Tip | Caz de utilizare | Persistență |
|------|----------|-------------|
| `entity_id` | Entități specifice | Stabil (recomandat) |
| `area_id` | Toate entitățile dintr-o cameră | Stabil |
| `device_id` | Toate entitățile de pe un device | Se schimbă la re-adăugare |

### Targets multiple

```yaml
# Entități multiple
target:
  entity_id:
    - light.living_ceiling
    - light.bucatarie_ceiling
    - light.dormitor1_ceiling

# Targeting pe arie (toate luminile din living)
target:
  area_id: living

# Combinat (entități + arii)
target:
  entity_id: light.hol_ceiling
  area_id:
    - dormitor1
    - baie1
```

> **`area_id` = slug-ul intern al ariei**, nu numele afișat. Verifică în UI: Settings → Areas → click pe arie → ID-ul intern (sau în `core.area_registry` din `.storage/`). Slugurile din convenția acestui repo (`living`, `dormitor1`, `baie1` etc.) trebuie să coincidă **exact** cu ID-urile reale ale ariilor în HA — dacă diferă, targeting-ul cu `area_id:` eșuează silențios.

### Template în targets

```yaml
# Selectare dinamică a entității
target:
  entity_id: "{{ state_attr('sensor.motion_zone', 'light_entity') }}"

# Toate luminile aprinse acum (avansat)
target:
  entity_id: >
    {{ states.light
       | selectattr('state', 'eq', 'on')
       | map(attribute='entity_id')
       | list }}
```

---

## Pattern-uri pentru butoane/remote-uri Zigbee

### ZHA (Zigbee Home Automation)

ZHA buttons fire `zha_event` events. Folosește **event triggers** cu `device_ieee` (adresa IEEE a device-ului), care este **persistentă** la re-adăugare.

```yaml
# Trigger buton ZHA — device_ieee este persistent
triggers:
  - trigger: event
    event_type: zha_event
    event_data:
      device_ieee: "00:15:8d:00:07:26:f2:8a"
      command: "toggle"
```

#### Găsirea datelor de eveniment ZHA

1. Mergi la **Developer Tools → Events**
2. Subscribe la `zha_event`
3. Apasă butonul
4. Copiază valorile `device_ieee` și `command`

### Zigbee2MQTT (Z2M)

Z2M creează **MQTT device triggers** autodiscovered. Sunt acceptabile pentru că Z2M gestionează mapping-ul device-to-trigger.

```yaml
# Trigger device Z2M — autodiscovered
triggers:
  - trigger: device
    device_id: abc123def456  # OK pentru Z2M, gestionat de autodiscovery
    domain: mqtt
    type: action
    subtype: single

# Alternativă: trigger pe topic MQTT (mai explicit)
triggers:
  - trigger: mqtt
    topic: "zigbee2mqtt/Buton Dormitor/action"
    payload: "single"
```

### Comparație Z2M vs ZHA

| Aspect | ZHA | Zigbee2MQTT |
|--------|-----|-------------|
| Tipul de trigger | trigger `event` | trigger `device` sau `mqtt` |
| Identificator | `device_ieee` (persistent) | `device_id` (autodiscovered) |
| Nume eveniment | `zha_event` | MQTT device trigger |
| Acțiuni de buton | câmpul `command` | `type` și `subtype` |

---

## Pattern-uri specifice pe domeniu

### Lumini

**Color temperature:** Folosește întotdeauna `color_temp_kelvin` (ex: `3000`). Parametrul legacy `color_temp` (în mireds) a fost eliminat în 2026.3.

```yaml
# Aprinde cu luminozitate și tranziție
actions:
  - action: light.turn_on
    target:
      entity_id: light.living_ceiling
    data:
      brightness_pct: 80
      transition: 2
      color_temp_kelvin: 3000

# Aprinde mai multe lumini diferit
actions:
  - action: light.turn_on
    target:
      entity_id: light.living_ceiling
    data:
      brightness_pct: 100
  - action: light.turn_on
    target:
      entity_id: light.living_accent
    data:
      brightness_pct: 30
      rgb_color: [255, 147, 41]
```

### Climatizare

```yaml
# Setează temperatura cu modul HVAC
actions:
  - action: climate.set_temperature
    target:
      entity_id: climate.living_thermostat
    data:
      temperature: 22
      hvac_mode: heat

# Setează modul preset
actions:
  - action: climate.set_preset_mode
    target:
      entity_id: climate.living_thermostat
    data:
      preset_mode: away
```

### Covers (jaluzele/rulouri)

```yaml
# Setează poziție specifică (0 = închis, 100 = deschis)
actions:
  - action: cover.set_cover_position
    target:
      entity_id: cover.living_jaluzele
    data:
      position: 50

# Control înclinare
actions:
  - action: cover.set_cover_tilt_position
    target:
      entity_id: cover.living_jaluzele
    data:
      tilt_position: 75
```

### Media players

```yaml
# Redă media
actions:
  - action: media_player.play_media
    target:
      entity_id: media_player.living_boxa
    data:
      media_content_id: "https://example.com/audio.mp3"
      media_content_type: music

# Setează volumul (0.0 la 1.0)
actions:
  - action: media_player.volume_set
    target:
      entity_id: media_player.living_boxa
    data:
      volume_level: 0.5
```

### Notificări

```yaml
# Notificare în aplicația mobilă prin serviciul unificat
actions:
  - action: notify.send_message
    target:
      entity_id: notify.telefon_andrei
    data:
      title: "Mișcare detectată"
      message: "Mișcare în {{ trigger.to_state.attributes.friendly_name }}"
      data:
        tag: "motion-alert"
        actions:
          - action: "DISMISS"
            title: "Închide"
          - action: "VIEW_CAMERA"
            title: "Vezi camera"

# Notificare persistentă
actions:
  - action: notify.persistent_notification
    data:
      title: "Reminder"
      message: "Verifică rufele"
      notification_id: "rufele_reminder"
```

### Control aspirator

```yaml
# Pornește curățarea
actions:
  - action: vacuum.start
    target:
      entity_id: vacuum.aspirator

# Curăță arii specifice (2026.3+ — folosește HA areas, nu vendor room IDs)
# Necesită maparea segmentelor aspiratorului la HA areas în setările entității mai întâi
actions:
  - action: vacuum.clean_area
    target:
      entity_id: vacuum.aspirator
    data:
      area_id:
        - bucatarie
        - living
```

**Preferă `vacuum.clean_area`** când utilizatorul a mapat segmentele aspiratorului la HA areas. Funcționează între integrații suportate fără vendor lock-in.

**Fallback:** Când integrația nu suportă `clean_area` sau segmentele nu sunt mapate:

```yaml
actions:
  - action: vacuum.send_command
    target:
      entity_id: vacuum.aspirator
    data:
      command: app_segment_clean
      params:
        - 16  # ID-uri de cameră specifice vendor-ului
        - 17
```

---

## Date de răspuns

Unele servicii returnează date. Folosește `response_variable` pentru a le captura:

```yaml
actions:
  - action: weather.get_forecasts
    target:
      entity_id: weather.home
    data:
      type: hourly
    response_variable: forecast
  - action: notify.send_message
    target:
      entity_id: notify.telefon_andrei
    data:
      message: "Maxima de mâine: {{ forecast['weather.home'].forecast[0].temperature }}°C"
```

---

## Greșeli frecvente

### Folosirea entity_id în data în loc de target (deprecated)

```yaml
# GREȘIT (deprecated)
actions:
  - action: light.turn_on
    data:
      entity_id: light.living_ceiling
      brightness: 255

# CORECT
actions:
  - action: light.turn_on
    target:
      entity_id: light.living_ceiling
    data:
      brightness: 255
```

### Hardcoding device_id pentru device-uri obișnuite

```yaml
# GREȘIT - se strică la re-adăugarea device-ului
actions:
  - action: light.turn_on
    target:
      device_id: abc123def456

# CORECT
actions:
  - action: light.turn_on
    target:
      entity_id: light.living_ceiling
```

### Brightness_pct la nivelul greșit

```yaml
# GREȘIT - brightness_pct la nivel greșit
actions:
  - action: light.turn_on
    target:
      entity_id: light.living_ceiling
    brightness_pct: 100

# CORECT - brightness_pct în interiorul data
actions:
  - action: light.turn_on
    target:
      entity_id: light.living_ceiling
    data:
      brightness_pct: 100
```

---

## Quick Reference: structura unui service call

```yaml
actions:
  - action: domain.service_name   # Obligatoriu
    target:                       # Opțional, dar recomandat
      entity_id: entity.id        # Unic sau listă
      area_id: area_name          # Unic sau listă
      device_id: device_id        # Evită, cu excepția Z2M
    data:                         # Parametri specifici serviciului
      parameter: value
    response_variable: result     # Capturează răspunsul (dacă e necesar)
```

## Quick Reference: tipuri de trigger pentru device-uri

| Tip device | ZHA | Zigbee2MQTT | Generic |
|-------------|-----|-------------|---------|
| Buton/remote | `event` (zha_event) | `device` sau `mqtt` | `state` |
| Senzor mișcare | `state` | `state` | `state` |
| Ușă/fereastră | `state` | `state` | `state` |
| Temperatură | `state` sau `numeric_state` | `state` sau `numeric_state` | `state` sau `numeric_state` |
| Switch | `state` | `state` | `state` |

Preferă întotdeauna `state` triggers cu `entity_id` pentru senzori și switch-uri. Folosește event/device triggers doar pentru dispozitive stateless (buttons, remotes).

---

## Diagnosticare și Troubleshooting

### Workflow de diagnostic

1. Rulează `codex-ha doctor` pentru a obține o vedere de ansamblu.
2. Actualizează contextul cu `ha-context`.
3. Verifică erorile recente și log-urile de add-on relevante.
4. Inspectează entitățile `unavailable`/`unknown` pe domeniu.
5. Pentru bug-uri în automatizări: verifică starea `last-triggered`, traces când sunt disponibile, stările entităților, și mode-ul.
6. Pentru probleme de config: rulează `ha-safe-edit check`.
7. Oferă o listă ordonată de root causes și cel mai mic fix sigur.

### Comenzi utile

```bash
codex-ha doctor
codex-ha logs <addon_slug>
ha-context --full
ha-safe-edit check
```

Nu propune fix-uri speculative înainte de a citi log-urile sau starea curentă a entității.

---

## Dezvoltare add-on

Home Assistant add-ons (cunoscute ca **Apps** din 2026.2) sunt containere supervizate cu permisiuni explicite.

### Checklist

- Păstrează permisiunile `config.yaml` minime și explică accesul larg.
- Folosește ingress pentru UI-uri în sidebar și bind servicii interne pe `0.0.0.0`.
- Persistă starea utilizatorului în `/data`, nu în layere de imagine.
- Accesează Home Assistant prin `http://supervisor/core/api` cu `SUPERVISOR_TOKEN`.
- Preferă imagini HA de bază și `build.yaml` multi-arch.
- Validează shell scripts și YAML înainte de release.

### Comenzi comune

```bash
codex-ha doctor
codex-ha check-config
codex mcp list
```

Starea Codex e în `/data/.codex` și contextul HA generat e în `$CODEX_HOME/AGENTS.md`.

---

## Accesarea documentației pe domeniu

Pentru a accesa documentația oficială HA pentru un domeniu sau integrație:

```
https://raw.githubusercontent.com/home-assistant/home-assistant.io/refs/heads/current/source/_integrations/{domain}.markdown
```

**Exemple de domenii comune:** `light`, `climate`, `mqtt`, `cover`, `media_player`, `sensor`, `binary_sensor`, `lock`, `vacuum`, `alarm_control_panel`, `notify`, `person`, `device_tracker`, `automation`, `script`, `scene`, `group`, `input_boolean`, `input_number`, `timer`, `counter`, `template`, `rest`, `command_line`, `tts`, `camera`, `switch`, `fan`, `humidifier`, `valve`

---

**TL;DR:** Folosește `entity_id` nu `device_id`. `target:` + `data:` pentru service calls. ZHA buttons → `event` trigger cu `device_ieee`. Z2M → `device` sau `mqtt` trigger. `color_temp_kelvin` nu `color_temp`. `vacuum.clean_area` cu `area_id` pentru roboți. `response_variable` pentru capturarea datelor returnate.
