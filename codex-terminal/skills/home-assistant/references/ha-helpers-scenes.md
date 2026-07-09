---
name: ha-helpers-scenes
description: Helpers HA (input_*, timer, counter, template sensors) + scene-uri `[Zonă] Activitate`. Decision matrix pentru alegerea helper-ului potrivit. Friendly name în română, entity_id slug în engleză.
---

# Helpers și Scene-uri — Home Assistant

## Helpers

Helpers sunt entități virtuale create manual în HA pentru a stoca stare, configurații sau valori de prag folosite în automatizări. Spre deosebire de dispozitive (care există fizic), helpers există doar în HA și sunt editabile din UI fără a modifica YAML.

### Tipuri de helpers

| Tip | Domeniu | Scopul | Stări |
| --- | ------- | ------ | ----- |
| Input Boolean | `input_boolean` | Flag pornit/oprit — mod vacanță, mod noapte | `on` / `off` |
| Input Number | `input_number` | Valoare numerică — limită consum, offset, delay | număr |
| Input Select | `input_select` | Alegere din opțiuni fixe — mod, scenă activă | text |
| Input Text | `input_text` | Text liber — mesaj alertă, anunț TTS | text |
| Input DateTime | `input_datetime` | Dată/oră — programare culcare, dată revenire | datetime |
| Timer | `timer` | Cronometru invers cu control start/stop/pause | `idle` / `active` / `paused` |
| Counter | `counter` | Contor integer — cicluri aparat, alerte/zi | integer |
| Senzor template | `sensor` (template) | Valoare calculată din alte entități | orice |
| Senzor binar template | `binary_sensor` (template) | Boolean calculat din alte entități | `on` / `off` |

### Limbă și entity_id

- **Friendly name (vizibil în UI)** → în română (consistent cu entity names din convenția de dispozitive)
- **Entity_id** → HA îl generează automat din nume (diacritice eliminate, spații → underscore, lowercase). Redenumește-l manual din UI după creare pentru a urma convenția în engleză.

| Friendly name (RO) | Entity ID recomandat (EN) |
| ------------------ | ------------------------- |
| `Mod vacanță` | `input_boolean.vacation_mode` |
| `Mod noapte` | `input_boolean.night_mode` |
| `Limită consum` | `input_number.power_limit` |
| `Offset termostat Dormitor #1` | `input_number.dormitor1_thermostat_offset` |
| `Mod automatizare` | `input_select.automation_mode` |
| `Mesaj alertă` | `input_text.alert_message` |
| `Oră culcare Dormitor #1` | `input_datetime.dormitor1_bedtime` |
| `Temporizator ușă garaj` | `timer.garaj_door_alert` |
| `Contor cicluri mașină spălat` | `counter.masina_spalat_cycles` |

### Format nume helpers

**Global / casă întreagă → aria „Sistem":**
```
Funcție [Calificator]
```
Exemplu: `Mod vacanță`, `Limită consum`, `Mod automatizare`

**Specific unei camere → aria camerei respective:**
```
Funcție + Camera (ca sufix, nu prefix)
```
Exemplu: `Offset termostat Dormitor #1`, `Oră culcare Dormitor #1`, `Delay lumină Living`

> Nu folosi `[Cameră]` prefix cu paranteze drepte la helpers — în lista UI helperele sunt separate de dispozitive, prefixul nu e necesar. Camera apare ca sufix sau prin aria asignată.

### Area (categoria)

Fiecare helper se asignează în aria zonei pe care o servește:

| Friendly name helper | Area asignată |
| -------------------- | ------------- |
| `Delay lumină mișcare Living` | Living |
| `Oră culcare Dormitor #1` | Dormitor #1 |
| `Temporizator ușă garaj` | Garaj |
| `Offset termostat Dormitor #1` | Dormitor #1 |
| `Mod vacanță` | *(fără arie — global)* |
| `Limită consum` | *(fără arie — global)* |
| `Mod automatizare` | *(fără arie — global)* |

**Cum asignezi:** Settings → Devices & Services → Helpers → [Helper] → ⚙️ → Area

---

#### Input Boolean — flaguri și moduri

Folosit pentru: comutator on/off logic — mod vacanță, mod noapte, override manual, simulare prezență.

**Format:** `Mod <Funcție>` sau `<Stare> activă`

| Friendly name | Entity ID | Iconă | Scop |
| ------------- | --------- | ----- | ---- |
| `Mod vacanță` | `input_boolean.vacation_mode` | `mdi:beach` | Dezactivează automatizările când ești plecat |
| `Mod noapte` | `input_boolean.night_mode` | `mdi:sleep` | Intensitate redusă, fără notificări |
| `Mod oaspeți` | `input_boolean.guest_mode` | `mdi:account-multiple` | Ajustează automatizările pentru vizitatori |
| `Nu deranja` | `input_boolean.do_not_disturb` | `mdi:bell-off` | Mute alerte și notificări |
| `Control manual activ` | `input_boolean.manual_override` | `mdi:hand-back-right` | Suspendă automatizările temporar |
| `Mod întreținere` | `input_boolean.maintenance_mode` | `mdi:wrench` | Flag pentru service / reparații |
| `Simulare prezență` | `input_boolean.presence_simulation` | `mdi:account-check` | Aprinde lumini aleator la plecare |

```yaml
# Utilizare în automatizare — continuă doar dacă NU e mod vacanță
- alias: Continuă doar dacă nu e mod vacanță
  condition: state
  entity_id: input_boolean.vacation_mode
  state: "off"
```

---

#### Input Number — praguri, offset-uri, setări

Folosit pentru: valori numerice modificabile din UI fără a edita YAML — limitele alertelor, offset calibrare senzori, durate delay.

**Format:** `<Funcție> [Camera]`

| Friendly name | Entity ID | Min/Max | Unitate | Iconă |
| ------------- | --------- | ------- | ------- | ----- |
| `Limită consum` | `input_number.power_limit` | 500–10000 | W | `mdi:flash` |
| `Offset termostat Dormitor #1` | `input_number.dormitor1_thermostat_offset` | -5–5 | °C | `mdi:tune` |
| `Delay lumină mișcare Living` | `input_number.living_motion_light_delay` | 30–600 | s | `mdi:clock-outline` |
| `Luminozitate noapte` | `input_number.night_brightness` | 1–30 | % | `mdi:brightness-3` |
| `Minute jaluzele înainte apus` | `input_number.blinds_before_sunset` | 0–60 | min | `mdi:blinds-horizontal` |
| `Volum alerte boxă` | `input_number.alert_volume` | 0–100 | % | `mdi:volume-high` |

```yaml
# Utilizare în automatizare — alertă când puterea depășește limita setată în helper
- alias: Continuă doar dacă puterea depășește limita setată
  condition: numeric_state
  entity_id: sensor.home_total_power
  above: "{{ states('input_number.power_limit') | float(4000) }}"
```

---

#### Input Select — moduri cu opțiuni multiple

Folosit pentru: setări cu mai mult de 2 stări (mod automatizare, nivel alertă, activitate curentă).

**Format:** `Mod <Funcție>` sau `<Funcție> curentă`

| Friendly name | Entity ID | Opțiuni | Iconă |
| ------------- | --------- | ------- | ----- |
| `Mod automatizare` | `input_select.automation_mode` | Manual / Semi-auto / Complet | `mdi:cog` |
| `Nivel alertă` | `input_select.alert_level` | Silențios / Redus / Normal / Urgent | `mdi:bell-ring` |
| `Activitate curentă` | `input_select.current_activity` | Acasă / Plecat / Somn / Film | `mdi:human-greeting-variant` |
| `Mod climatizare Living` | `input_select.living_climate_mode` | Oprit / Încălzire / Răcire / Auto | `mdi:air-conditioner` |

---

#### Input Text — stocare text

Folosit pentru: mesaje dinamice de notificat, anunțuri TTS, note pentru oaspeți.

**Format:** `Mesaj <Context>` sau `Anunț <Context>`

| Friendly name | Entity ID | Scop |
| ------------- | --------- | ---- |
| `Mesaj alertă` | `input_text.alert_message` | Text custom pentru notificări urgente |
| `Anunț TTS` | `input_text.tts_announcement` | Text de anunțat pe boxă la next trigger |
| `Notă oaspeți` | `input_text.guest_notes` | Instrucțiuni afișate oaspeților |

---

#### Input DateTime — programări

Folosit pentru: ore de culcare / trezire configurabile din UI, date de revenire din vacanță.

**Format:** `Oră/Dată <Funcție> [Camera]`

| Friendly name | Entity ID | Are dată | Are oră | Scop |
| ------------- | --------- | -------- | ------- | ---- |
| `Oră culcare Dormitor #1` | `input_datetime.dormitor1_bedtime` | Nu | Da | Automatizare noapte bună |
| `Oră trezire Dormitor #1` | `input_datetime.dormitor1_wakeup` | Nu | Da | Automatizare dimineață |
| `Dată revenire vacanță` | `input_datetime.vacation_end` | Da | Nu | Repornire automatizări |

---

#### Timer — cronometre inverse

Folosit pentru: delay înainte de stingere lumină, alertă dacă ușa rămâne deschisă, interval între notificări repetate.

**Format:** `Temporizator <eveniment>` — ce se întâmplă sau se verifică la expirare

| Friendly name | Entity ID | Durată implicită | Iconă | Scop |
| ------------- | --------- | ---------------- | ----- | ---- |
| `Temporizator ușă garaj` | `timer.garaj_door_alert` | 5 min | `mdi:door-open` | Alertă dacă ușa rămâne deschisă |
| `Temporizator lumină Living` | `timer.living_motion_light` | 3 min | `mdi:motion-sensor` | Stinge lumina după inactivitate |
| `Temporizator alertă repetată` | `timer.alert_repeat` | 1 min | `mdi:repeat` | Interval între notificări repetate |

```yaml
# Pornire timer la deschidere ușă
- alias: Pornește temporizatorul la deschiderea ușii garajului
  action: timer.start
  target:
    entity_id: timer.garaj_door_alert
  data:
    duration: "00:05:00"

# Automatizare separată — declanșată la expirarea timerului
alias: "[Garaj] Temporizator expirat — Alertă ușă deschisă"
triggers:
  - trigger: event
    event_type: timer.finished
    event_data:
      entity_id: timer.garaj_door_alert
```

---

#### Counter — contoare

Folosit pentru: număr cicluri aparat (întreținere), limitare spam notificări, statistici.

**Format:** `Contor <eveniment>`

| Friendly name | Entity ID | Iconă | Scop |
| ------------- | --------- | ----- | ---- |
| `Contor cicluri mașină spălat` | `counter.masina_spalat_cycles` | `mdi:washing-machine` | Urmărire întreținere |
| `Contor alerte astăzi` | `counter.alerts_today` | `mdi:bell` | Prevenire spam notificări |
| `Contor mișcări noapte` | `counter.night_motion_count` | `mdi:motion-sensor` | Debug senzor |

```yaml
# Incrementare contor + verificare înainte de notificare
- alias: Continuă doar dacă nu am trimis mai mult de 3 alerte astăzi
  condition: numeric_state
  entity_id: counter.alerts_today
  below: 4

- alias: Incrementează contorul de alerte
  action: counter.increment
  target:
    entity_id: counter.alerts_today
```

---

#### Senzori template

Folosiți pentru: valori calculate din alte entități — sume, medii, stări derivate. Nu sunt configurabile din UI, se definesc în YAML.

**Format:** `<Valoare calculată>` — fără prefix de zonă dacă e globală

| Friendly name | Entity ID | Scop |
| ------------- | --------- | ---- |
| `Putere totală casă` | `sensor.home_total_power` | Suma consumului pe toate fazele |
| `Temperatură medie casă` | `sensor.home_avg_temperature` | Media temperaturii din toate camerele |
| `Cineva acasă` | `binary_sensor.anyone_home` | `on` dacă cel puțin o persoană e acasă |
| `Toate ușile închise` | `binary_sensor.all_doors_closed` | `on` dacă toate contactele sunt `off` |
| `Alertă consum ridicat` | `binary_sensor.high_power_alert` | `on` când puterea depășește limita setată |

```yaml
template:
  - sensor:
      - name: "Putere totală casă"
        unique_id: home_total_power
        unit_of_measurement: "W"
        device_class: power
        state_class: measurement
        state: >
          {{ (states('sensor.tehnica_phase_a_power') | float(0) +
              states('sensor.tehnica_phase_b_power') | float(0) +
              states('sensor.tehnica_phase_c_power') | float(0)) | round(1) }}
        icon: mdi:lightning-bolt

  - binary_sensor:
      - name: "Alertă consum ridicat"
        unique_id: high_power_alert
        device_class: power
        state: >
          {{ states('sensor.home_total_power') | float(0) >
             states('input_number.power_limit') | float(4000) }}
        icon: mdi:flash-alert
```

### Ghid selectare helper (când să folosești ce)

Înainte de a crea un template sensor sau o automatizare complexă, verifică dacă există un helper dedicat. Folosește tabelul de mai jos.

#### Decision Matrix

| Nevoie | Helper | NU |
|------|--------|-----|
| Media/min/max/suma mai multor senzori | `min_max` (type: mean/sum/min/max) | Template cu matematică |
| Media în timp | `statistics` | Template ce trackează istoria |
| Rata de schimbare | `derivative` | Template ce calculează delta |
| On/off la threshold | `threshold` | Template binary sensor |
| Consum per perioadă | `utility_meter` | Counter cu reset automation |
| Timp în stare | `history_stats` | Template ce trackează timestamps |
| Putere → energie | `integration` (Riemann sum) | Template aproximativ |
| Toggle on/off | `input_boolean` | — |
| Valoare numerică ajustabilă | `input_number` | — |
| Alegere dintr-o listă | `input_select` | — |
| Numărare evenimente | `counter` | input_number + automation |
| Cronometru invers | `timer` | delay + input_datetime |
| Program săptămânal | `schedule` | Template cu weekday checks |
| Timp din zi | `tod` (time of day) | Template cu time checks |
| Orice-on / toți-on | `group` | Template binary sensor |
| Netezire senzor zgomotos | `filter` | statistics cu mean |
| Limitare rată update | `filter` (throttle/time_throttle) | Automation cu delays |
| Respingere valori out-of-range | `filter` (range) | Template cu bounds check |
| Termostat din switch + senzor temp | `generic_thermostat` | Automation cu logică hysteresis |
| Umidificator din switch + senzor umiditate | `generic_hygrostat` | Automation cu hysteresis |
| Switch prezentat ca light/cover/lock | `switch_as_x` | Template light/cover/lock |
| Valoare random | `random` | Template cu `range()` |
| Logică custom, niciun alt helper nu se potrivește | `template` helper (via UI flow) | YAML `template:` platform sensor |

#### Cele mai importante substituții

**În loc de template sensor pentru agregare numerică → `min_max`:**

```yaml
# GREȘIT - Template sensor pentru mediere
template:
  - sensor:
      - name: "Temperatură medie"
        state: >
          {{ ((states('sensor.dormitor1_temperature') | float) +
              (states('sensor.living_temperature') | float)) / 2 }}

# CORECT - helper min_max
sensor:
  - platform: min_max
    name: "Temperatură medie"
    type: mean
    entity_ids:
      - sensor.dormitor1_temperature
      - sensor.living_temperature
```

**În loc de template binary sensor cu threshold → `threshold`:**

```yaml
# GREȘIT
template:
  - binary_sensor:
      - name: "Temperatură ridicată"
        state: "{{ states('sensor.living_temperature') | float > 25 }}"

# CORECT - helper threshold (cu hysteresis built-in)
binary_sensor:
  - platform: threshold
    name: "Temperatură ridicată"
    entity_id: sensor.living_temperature
    upper: 25
    hysteresis: 1  # ON la >26, OFF la <24
```

**În loc de template cu logică any-on/all-on → `group`:**

```yaml
# GREȘIT
template:
  - binary_sensor:
      - name: "Vreo ușă deschisă"
        state: >
          {{ is_state('binary_sensor.usa_intrare', 'on') or
             is_state('binary_sensor.usa_spate', 'on') }}

# CORECT - helper group
group:
  toate_usile:
    name: "Toate ușile"
    entities:
      - binary_sensor.usa_intrare
      - binary_sensor.usa_spate
    all: false  # ON dacă ORICARE e on (logică OR)
```

**În loc de template pentru rate of change → `derivative`:**

```yaml
sensor:
  - platform: derivative
    name: "Rata de schimbare a puterii"
    source: sensor.power
    unit_time: min
    time_window:
      minutes: 5
```

**În loc de switch ca light/cover/lock → `switch_as_x`** (UI-only, no YAML):
- Settings → Devices & Services → Helpers → Create Helper → Switch as X
- Ascunde switch-ul original și creează o entitate de domeniu corect (light/cover/lock)

**Dacă niciun helper dedicat nu se potrivește → `template` helper via UI:**
- Settings → Devices & Services → Helpers → Create Helper → Template
- NU scrie `template:` YAML decât dacă e explicit cerut sau dacă nu ai acces la UI/API

---

## Scene-uri

Scenele sunt snapshot-uri statice ale stării dorite — setează mai multe dispozitive simultan, fără logică sau delay. Spre deosebire de scripturi, o scenă nu poate lua decizii, nu poate aștepta și nu poate trimite notificări.

### Scene vs. scripturi

| | Scenă | Script |
| - | ----- | ------ |
| **Ce face** | Setează stări simultan, instant | Execută acțiuni secvențial |
| **Logică** | Nu (snapshot static) | Da (condiții, delay, ramificații) |
| **Viteză** | Instant (toate dispozitivele odată) | Respectă delay-uri și condiții |
| **Conținut** | Stări lumini, jaluzele, climat, media | Orice acțiune HA |
| **Folosit pentru** | Ambianțe, moduri de iluminare | Rutine, fluxuri complexe, notificări |

> **Combinație recomandată:** scriptul orchestrează (închide jaluzelele, activează scena, trimite notificare), scena definește starea (iluminare Film).

### Format canonic

```
[Zonă] Activitate
```

- `[Zonă]` — camera în paranteze drepte. Omite dacă scena afectează mai multe camere.
- `Activitate` — ce stare e creată: `Film`, `Citit`, `Dimineață`, `Somn`, `Relaxare`

**Entity ID:** `scene.<slug_camera>_<activitate_en>` — slug cameră în română, activitate în engleză (ca entity_id-urile de device).

### Exemple

```
[Living] Film           → scene.living_movie
[Living] Citit          → scene.living_reading
[Living] Seară          → scene.living_evening
[Living] Dimineață      → scene.living_morning
[Dormitor #1] Somn      → scene.dormitor1_sleep
[Dormitor #1] Trezire   → scene.dormitor1_wakeup
[Dormitor #1] Citit     → scene.dormitor1_reading
[Baie #1] Dimineață     → scene.baie1_morning
[Baie #1] Noapte        → scene.baie1_night
Noapte bună             → scene.goodnight        (mai multe camere)
Plecare                 → scene.leaving           (mai multe camere)
Primire oaspeți         → scene.guests_welcome    (mai multe camere)
```

### Categorii și parametri recomandați

#### Ambianță per cameră

| Activitate | Entity ID (exemplu) | Luminozitate | Temperatură culoare |
| ---------- | ------------------- | ------------ | ------------------- |
| Film | `scene.living_movie` | 10–20% | Caldă (2700 K) |
| Citit | `scene.living_reading` | 70–100% | Neutru (4000 K) |
| Seară / relaxare | `scene.living_evening` | 30–50% | Caldă (2700 K) |
| Dimineață / lucru | `scene.living_morning` | 80–100% | Rece (5000 K) |
| Concentrare | `scene.living_focus` | 100% | Rece (5500 K) |
| Somn | `scene.dormitor1_sleep` | 0–5% | Roșu/portocaliu |
| Trezire | `scene.dormitor1_wakeup` | 30→100% | Neutru (3500 K) |
| Noapte (baie) | `scene.baie1_night` | 5–10% | Caldă (2200 K) |

#### Scene globale (mai multe camere)

```
Noapte bună          → scene.goodnight
Plecare              → scene.leaving
Film acasă           → scene.movie_home
Primire oaspeți      → scene.guests_welcome
Mod curățenie        → scene.cleaning   (100% pe tot)
```

### Reguli de format

- **Fără detalii tehnice** în nume — `[Living] Film`, nu `[Living] LED portocaliu 20%`
- **Un cuvânt sau două** pentru activitate — scurt și intuitiv
- **Setează `icon:`** — face scena recunoscută rapid în dashboard
- **Setează `transition:`** — 3–10 secunde pentru lumini, 0 pentru jaluzele/media
- **Nu duplica device name** în scenă — scena conține dispozitivul, nu îl menționează în nume

### Icoane recomandate

| Activitate | Iconă |
| ---------- | ----- |
| Film | `mdi:movie` |
| Citit | `mdi:book-open` |
| Somn / Noapte bună | `mdi:sleep` |
| Trezire / Dimineață | `mdi:weather-sunrise` |
| Seară / Relaxare | `mdi:weather-sunset` |
| Concentrare / Lucru | `mdi:desk-lamp` |
| Curățenie / Luminos | `mdi:white-balance-sunny` |
| Oaspeți | `mdi:account-multiple` |
| Plecare | `mdi:door-open` |
| Petrecere | `mdi:party-popper` |
| Noapte (noapte bună) | `mdi:moon-waning-crescent` |

### Exemplu YAML

```yaml
scene:
  - id: living_movie
    name: "[Living] Film"
    icon: mdi:movie
    transition: 3
    entities:
      light.living_ceiling:
        state: "off"
      light.living_tv_led:
        state: "on"
        brightness_pct: 20
        color_name: orange
      cover.living_blinds:
        state: closed

  - id: dormitor1_sleep
    name: "[Dormitor #1] Somn"
    icon: mdi:sleep
    transition: 10
    entities:
      light.dormitor1_ceiling:
        state: "off"
      light.dormitor1_bedside_left:
        state: "on"
        brightness_pct: 3
        color_temp_kelvin: 2000
      cover.dormitor1_blinds:
        state: closed

  - id: goodnight
    name: "Noapte bună"
    icon: mdi:moon-waning-crescent
    transition: 5
    entities:
      light.living_ceiling:
        state: "off"
      light.dormitor1_ceiling:
        state: "off"
      light.baie1_ceiling:
        state: "off"
      cover.living_blinds:
        state: closed
      cover.dormitor1_blinds:
        state: closed
```

---

**TL;DR:** Helpers: friendly name RO, entity_id slug EN. `input_boolean` → flaguri (`vacation_mode`), `input_number` → praguri (`power_limit`), `timer` → delay persistent. Scene-uri: `[Living] Film` → `scene.living_movie`; snapshot static, fără logică, cu `transition:` și `icon:`.