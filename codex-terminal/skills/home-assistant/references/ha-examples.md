---
name: ha-examples
description: Exemple YAML HA complete și cheat sheet rapid — 4 exemple de bază + 8 modele compuse (mișcare, ZHA, yală, parallel, sonerie, rutină, MQTT, scenă cu transition). Citește pentru exemple concrete.
---

# Exemple complete și Cheat Sheet — Home Assistant

> Exemplele pot include note dependente de versiunea HA. Verifică [ha-version-notes.md](ha-version-notes.md) înainte de a copia un pattern critic.

## Exemple complete

### Automatizare: senzor de prezență în baie

```yaml
alias: "[Baie #1] Prezență detectată — Aprinde lumina"
description: >
  Aprinde lumina din baie când senzorul Aqara FP2 detectează prezență.
  Intensitatea depinde de oră: 10% noaptea (22:00–07:00), 100% ziua.
  Mode restart: re-detectarea prezenței anulează countdown-ul de stingere.
mode: restart

triggers:
  - trigger: state
    entity_id: binary_sensor.baie1_presence
    to: "on"

actions:
  - alias: Alege intensitatea în funcție de oră
    choose:
      - alias: Dacă e noapte — aprinde la 10%
        conditions:
          - condition: time
            after: "22:00:00"
            before: "07:00:00"
        sequence:
          - alias: Aprinde lumina din baie la 10%
            action: light.turn_on
            target:
              entity_id: light.baie1_ceiling
            data:
              brightness_pct: 10
              color_temp_kelvin: 2700
      - alias: Dacă e zi — aprinde la 100%
        conditions: []
        sequence:
          - alias: Aprinde lumina din baie la 100%
            action: light.turn_on
            target:
              entity_id: light.baie1_ceiling
            data:
              brightness_pct: 100
              color_temp_kelvin: 4000
```

### Automatizare: plecare din casă

```yaml
alias: "[Casă] Plecare confirmat — Stinge tot, armează alarma"
description: >
  Se declanșează când ultimul telefon iese din zona Casă.
  Stinge toate luminile, oprește clima, armează alarma în modul Plecat
  și trimite o confirmare pe telefon.
mode: single

triggers:
  - trigger: state
    entity_id: group.persoane_acasa
    to: "not_home"

actions:
  - alias: Rulează scriptul Plecare din casă
    action: script.plecare_din_casa

  - alias: Armează alarma — mod Plecat
    action: alarm_control_panel.alarm_arm_away
    target:
      entity_id: alarm_control_panel.alarma_casa

  - alias: Trimite confirmare pe telefon
    action: notify.send_message
    target:
      entity_id: notify.telefon_andrei
    data:
      message: Casa e securizată. Alarma e armată.
      title: Plecare confirmată
```

### Script: rutină de plecare

```yaml
alias: Plecare din casă
description: >
  Stinge toate luminile, oprește clima, închide jaluzelele și oprește
  prizele standby. Rulat din automatizarea de plecare sau manual.
mode: single

sequence:
  - alias: Stinge toate luminile din casă
    action: light.turn_off
    target:
      area_id:
        - living
        - bucatarie
        - dormitor1
        - baie1

  - alias: Oprește climatizarea
    action: climate.turn_off
    target:
      entity_id:
        - climate.dormitor1_thermostat
        - climate.living_ac

  - alias: Închide jaluzelele din dormitor #1
    action: cover.close_cover
    target:
      entity_id: cover.dormitor1_blinds

  - alias: Oprește prizele standby din living
    action: switch.turn_off
    target:
      entity_id:
        - switch.living_tv_socket
        - switch.living_desk_socket

  - alias: Așteaptă 5 secunde — confirmă starea finală
    delay: "00:00:05"
```

### Script: scenă film

```yaml
alias: Scenă film living
description: >
  Pregătește livingul pentru vizionare: coboară jaluzelele, aprinde bara
  LED la portocaliu 30%, stinge luminile principale, pornește soundbarul
  pe HDMI 1. Durează ~3 secunde.
mode: single

sequence:
  - alias: Coboară jaluzelele din living
    action: cover.close_cover
    target:
      entity_id: cover.living_blinds

  - alias: Stinge lumina principală din living
    action: light.turn_off
    target:
      entity_id: light.living_ceiling

  - alias: Aprinde bara LED din living la portocaliu 30%
    action: light.turn_on
    target:
      entity_id: light.living_tv_led
    data:
      brightness_pct: 30
      rgb_color: [255, 140, 0]
      transition: 3

  - alias: Pornește soundbarul pe HDMI 1
    action: media_player.select_source
    target:
      entity_id: media_player.living_soundbar
    data:
      source: HDMI 1
```

---

## Cheat sheet — Automatizări și Scripturi

### Automatizare

```
[Zonă] Declanșator — Ce face
```

| Dacă...                               | Scrieai înainte (greșit)              | Scrie acum (corect)                              |
| ------------------------------------- | ------------------------------------- | ------------------------------------------------ |
| PIR baie aprinde lumina               | `Baie motion light on`                | `[Baie #1] Prezență detectată — Aprinde lumina`  |
| Plecare stinge tot                    | `Away mode`                           | `[Casă] Plecare confirmat — Stinge tot`          |
| Apus retrage storuri                  | `Sunset blinds`                       | `[Living] Apus soare — Coboară jaluzelele`       |
| Consum ridicat alertă                 | `High power alert`                    | `[Cameră Tehnică] Putere > 4 kW — Alertă consum` |

### Script

```
Acțiune [context]
```

| Dacă...                     | Greșit               | Corect                    |
| --------------------------- | -------------------- | ------------------------- |
| Stinge tot                  | `All lights off`     | `Stinge toate luminile`   |
| Film în living              | `Movie scene`        | `Scenă film living`       |
| Rutină dimineață            | `Morning routine`    | `Rutină bun dimineața`    |

### Pas (step alias)

```
Verb + ce + [unde] + [la ce valoare]
```

| Dacă...                              | Greșit (cod în alias)                     | Corect                                          |
| ------------------------------------ | ----------------------------------------- | ----------------------------------------------- |
| Pornește lumina                      | `light.turn_on baie1_ceiling`             | `Aprinde lumina din baie`                       |
| Setează temperatura                  | `climate.set_temperature 21`              | `Setează termostatul din dormitor la 21°C`      |
| Notificare                           | `notify.mobile_app`                       | `Trimite notificare — ușa garajului e deschisă` |
| Condiție oră                         | `time condition 22:00`                    | `Continuă doar dacă e după ora 22:00`           |
| Delay                                | `delay 300`                               | `Așteaptă 5 minute`                             |

---

## Exemple modele (recomandări)

Opt exemple compuse care demonstrează multiple bune practici lucrând împreună.

### 1. Lumină activată de mișcare (restart mode + wait_for_trigger + condiție timp nativă)

```yaml
alias: "[Living] Mișcare detectată — Aprinde lumina"
description: >
  Aprinde lumina la detectarea mișcării (restart mode — re-detectarea resetează timer-ul).
  Intensitate 10% noaptea (22:00–07:00), 100% ziua. Stinge după 5 minute de inactivitate.
mode: restart

triggers:
  - trigger: state
    entity_id: binary_sensor.living_motion
    to: "on"

actions:
  - choose:
      - conditions:
          - condition: time
            after: "22:00:00"
            before: "07:00:00"
        sequence:
          - action: light.turn_on
            target:
              entity_id: light.living_ceiling
            data:
              brightness_pct: 10
              color_temp_kelvin: 2700
    default:
      - action: light.turn_on
        target:
          entity_id: light.living_ceiling
        data:
          brightness_pct: 100
          color_temp_kelvin: 4000

  - wait_for_trigger:
      - trigger: state
        entity_id: binary_sensor.living_motion
        to: "off"
        for:
          minutes: 5
    timeout:
      minutes: 30
    continue_on_timeout: true

  - action: light.turn_off
    target:
      entity_id: light.living_ceiling
```

### 2. Telecomandă cu mai multe butoane (ZHA device_ieee + identificatori de declanșator + choose)

```yaml
alias: "[Dormitor #1] Buton Aqara — Controlează lumina"
description: >
  Apăsare scurtă: toggle lumina. Apăsare dublă: scena Citit. Apăsare lungă: scena Somn.
  Folosește device_ieee persistent (ZHA), nu device_id.
mode: single

triggers:
  - trigger: event
    event_type: zha_event
    event_data:
      device_ieee: "00:15:8d:00:07:26:f2:8a"
      command: "toggle"
    id: single_press

  - trigger: event
    event_type: zha_event
    event_data:
      device_ieee: "00:15:8d:00:07:26:f2:8a"
      command: "double"
    id: double_press

  - trigger: event
    event_type: zha_event
    event_data:
      device_ieee: "00:15:8d:00:07:26:f2:8a"
      command: "hold"
    id: long_press

actions:
  - choose:
      - conditions:
          - condition: trigger
            id: single_press
        sequence:
          - action: light.toggle
            target:
              entity_id: light.dormitor1_ceiling

      - conditions:
          - condition: trigger
            id: double_press
        sequence:
          - action: scene.turn_on
            target:
              entity_id: scene.dormitor1_reading

      - conditions:
          - condition: trigger
            id: long_press
        sequence:
          - action: scene.turn_on
            target:
              entity_id: scene.dormitor1_sleep
```

### 3. Notificare yală garaj (queued mode + atribut stare + mesaj template)

```yaml
alias: "[Garaj] Yală deblocată — Notifică și înregistrează"
description: >
  Notifică la deblocare, cu mod queued pentru procesare secvențială.
  Verifică atributul `changed_by` pentru deblocare manuală vs cod.
mode: queued
max: 5

triggers:
  - trigger: state
    entity_id: lock.garaj_door
    to: "unlocked"

actions:
  - alias: Continuă doar dacă nu e mod vacanță
    condition: state
    entity_id: input_boolean.vacation_mode
    state: "off"

  - action: notify.send_message
    target:
      entity_id: notify.telefon_andrei
    data:
      title: "[Garaj] Yală deblocată"
      message: >
        Yala garajului a fost deblocată la {{ now().strftime('%H:%M') }}.
        {% if trigger.to_state.attributes.changed_by %}
        Deblocat de: {{ trigger.to_state.attributes.changed_by }}.
        {% endif %}
      data:
        channel: device_warnings
        actions:
          - action: LOCK_GARAJ
            title: Blochează înapoi
          - action: IGNORA
            title: Ignoră

  - alias: Înregistrează în jurnal
    action: logbook.log
    data:
      name: "Garaj"
      message: "Yală deblocată"
      entity_id: lock.garaj_door
```

### 4. Control ferestre în paralel (parallel mode + trigger.entity_id în template)

```yaml
alias: "[Casă] Fereastră deschisă prea mult — Alertă"
description: >
  Mode parallel: fiecare fereastră poate alerta simultan.
  `trigger.entity_id` în template: mesaj personalizat per fereastră.
mode: parallel
max: 10

triggers:
  - trigger: state
    entity_id:
      - binary_sensor.dormitor1_window_contact
      - binary_sensor.dormitor2_window_contact
      - binary_sensor.living_window_contact
    to: "on"
    for:
      minutes: 30

actions:
  - action: notify.send_message
    target:
      entity_id: notify.telefon_andrei
    data:
      title: "[Casă] Fereastră lăsată deschisă"
      message: >
        {{ state_attr(trigger.entity_id, 'friendly_name') }}
        este deschisă de 30 de minute.
      data:
        channel: device_warnings
```

### 5. Anunț sonerie (if/then + condiție ore liniștite)

```yaml
alias: "[Casă] Sonerie apăsată — Anunț vocal"
description: >
  Dacă e în program normal: anunț vocal pe boxa din living.
  Dacă e în ore liniștite (22:00–08:00): doar notificare pe telefon, fără TTS.
mode: single

triggers:
  - trigger: state
    entity_id: binary_sensor.sonerie_button
    to: "on"

actions:
  - if:
      - condition: time
        after: "08:00:00"
        before: "22:00:00"
    then:
      - action: tts.speak
        target:
          entity_id: media_player.living_boxa
        data:
          message: "Cineva este la ușă."
          language: ro
      - action: notify.send_message
        target:
          entity_id: notify.telefon_andrei
        data:
          title: "[Casă] Sonerie"
          message: Cineva este la ușă.
          data:
            channel: information
    else:
      - action: notify.send_message
        target:
          entity_id: notify.telefon_andrei
        data:
          title: "[Casă] Sonerie (ore liniștite)"
          message: >
            Cineva este la ușă. Ora: {{ now().strftime('%H:%M') }}.
          data:
            channel: device_warnings
            importance: high
```

### 6. Script rutină noapte bună (fields + sequence + multiple apeluri de servicii)

```yaml
alias: Rutină noapte bună
description: >
  Stinge luminile, setează termostatul, închide jaluzelele.
  Acceptă parametri: aria țintă și temperatura de noapte.
mode: single

fields:
  target_area:
    name: Cameră
    description: Camera pentru rutina de noapte
    required: false
    default: dormitor1
    selector:
      area:
    example: dormitor1

  night_temperature:
    name: Temperatură de noapte
    description: Temperatura setată pentru termostat
    required: false
    default: 19
    selector:
      number:
        min: 15
        max: 24
        unit_of_measurement: "°C"
    example: 19

sequence:
  - alias: Stinge luminile din cameră
    action: light.turn_off
    target:
      area_id: "{{ target_area }}"

  - alias: Setează termostatul la temperatura de noapte
    action: climate.set_temperature
    target:
      entity_id: climate.dormitor1_thermostat
    data:
      temperature: "{{ night_temperature }}"

  - alias: Închide jaluzelele
    action: cover.close_cover
    target:
      area_id: "{{ target_area }}"

  - alias: Activează Do Not Disturb
    action: input_boolean.turn_on
    target:
      entity_id: input_boolean.do_not_disturb
```

### 7. Configurare entități MQTT

Trei metode recomandate pentru entități MQTT, în ordine de preferință:

**Metoda 1 — MQTT Subentries via UI (recomandat):**
Settings → Devices & Services → MQTT → Configure → Add Device

**Metoda 2 — MQTT Discovery (pentru dispozitive compatibile):**
```yaml
# Device-ul trimite un mesaj de discovery automat către:
# homeassistant/<component>/<device_id>/config
# HA îl detectează și creează entități automat
```

**Metoda 3 — Legacy YAML (fallback, când celelalte nu sunt disponibile):**
```yaml
# În configuration.yaml sau packages/mqtt.yaml
mqtt:
  sensor:
    - name: "Temperatură living"
      unique_id: living_temperature_mqtt
      state_topic: "home/living/temperature"
      unit_of_measurement: "°C"
      device_class: temperature
      state_class: measurement
      value_template: "{{ value_json.temperature }}"
      availability_topic: "home/living/availability"
      payload_available: "online"
      payload_not_available: "offline"
```

> Post-editare pentru YAML `mqtt:` platform-based: Reload MQTT integration (nu restart complet).

### 8. Scenă cu transition coordonat (lumini cu fade + jaluzele instant)

```yaml
# Configuration in scenes.yaml or via UI:
scene:
  - id: dormitor1_wakeup
    name: "[Dormitor #1] Trezire"
    icon: mdi:weather-sunrise
    transition: 30          # implicit pentru lumini — fade lent de 30 secunde
    entities:
      light.dormitor1_ceiling:
        state: "on"
        brightness_pct: 80
        color_temp_kelvin: 3500
      light.dormitor1_bedside_left:
        state: "on"
        brightness_pct: 30
        color_temp_kelvin: 2700
      # Cover-ul ignoră transition — se ridică imediat
      cover.dormitor1_blinds:
        state: open
      # Termostat — setare instant
      climate.dormitor1_thermostat:
        state: heat
        temperature: 21
```

Apelare cu transition diferit:

```yaml
# Apelează scena cu transition override (10s în loc de 30s implicit)
- action: scene.turn_on
  target:
    entity_id: scene.dormitor1_wakeup
  data:
    transition: 10
```

> **Observație:** `transition:` afectează doar entitățile care suportă (lumini, unele media players). Cover-urile, switch-urile, climate-ul ignoră parametrul și se setează instant.

---

**TL;DR pentru AI:** când lucrezi în Home Assistant pentru acest utilizator:

#### Dispozitive & Entități

- **Device name:** `[Cameră] Producător Model [#N]` — Cameră în română, brand/model în scriere oficială. **Fără funcție românească în nume.**
- **Label (RO):** unul din lista canonică (`ha-devices-areas.md`). NU creezi label-uri noi dacă există deja un sinonim.
- **Entity name (RO):** funcția în română din vocabularul `ha-entities.md` (`Putere`, `Mișcare`, `Temperatură`). Dacă nu există în vocabular, folosești un termen descriptiv nou în română și îl adaugi în vocabular când devine reutilizabil. Abrevieri tehnice (CO2, TVOC, RSSI) rămân neschimbate.
- **Entity ID:** `<domain>.<slug_camera>_<function>[_<detail>]` — slug în română, restul în engleză.
- **Post-redenumire:** (1) dezactivează entitățile nefolosite (`linkquality`, `last_seen`, etc.); (2) verifică automatizările, scripturile, scenele, grupurile, helpers și dashboards pentru referințe vechi (vezi `ha-refactoring.md`).
- **La final:** rulează `ha-context --force` și verifică `/data/ha-context/rename_memory.json` pentru dispozitive, friendly names, labels și entități dezactivate.
- Brand-ul rămâne în device name, NICIODATĂ în entity_id.

#### Automatizări & Scripturi

- **Automatizare:** `[Zonă] Declanșator — Ce face` — română, fără cod tehnic, max 60 caractere.
- **Script:** `Verb + context` la imperativ — `Stinge toate luminile`, `Scenă film living`.
- **Pas (alias):** `Verb + ce + unde + valoare` — `Aprinde lumina din baie la 10%`, `Setează termostatul la 21°C`.
- **Condiție ca pas:** `Continuă doar dacă [condiție în română]`.
- **Choose:** alias pe bloc (`Alege intensitatea în funcție de oră`) + alias pe fiecare opțiune (`Dacă e noapte — aprinde la 10%`).
- **description:** obligatoriu dacă există logică condiționată sau excepții; 1–3 propoziții în română.
- **Niciun entity_id, service sau platformă** în alias-uri — aparțin YAML-ului, nu numelui vizibil.
- **Mode:** `restart` pentru lumini cu delay, `parallel` pentru alerte per cameră, `queued` pentru TTS consecutiv, `single` pentru butoane.
- **Trigger IDs:** `id: presence_on / presence_off` când on și off se gestionează în aceeași automatizare.
- **Script fields:** slug-uri în engleză (`brightness_level`), `name:` în română, `required:` + `default:` + `selector:`.

#### Helpers, Scene-uri & Notificări

- **Helpers:** friendly name în română, entity_id slug în engleză; `input_boolean` pentru flaguri, `input_number` pentru praguri, `timer` pentru delay persistent.
- **Scene-uri:** `[Zonă] Activitate` — `[Living] Film` → `scene.living_movie`; snapshot static, fără logică.
- **Notificări:** titlu `[Zonă] — Status` max 50 caractere, mesaj propoziție completă cu ce/unde/când/valoare, canal `critical_alerts / device_warnings / information / updates`. Preferă `notify.send_message` (HA 2024.7+) cu `target: entity_id: notify.*`.

---

**TL;DR:** Automatizare: `[Zonă] Declanșator — Ce face`. Script: `Verb context`. Pas: `Verb + ce + unde + valoare`. Condiție: `Continuă doar dacă...`. Choose: alias pe bloc + alias pe fiecare opțiune.
