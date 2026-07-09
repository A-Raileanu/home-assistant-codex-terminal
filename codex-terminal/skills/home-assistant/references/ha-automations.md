---
name: ha-automations
description: Automatizări HA — format `[Zonă] Declanșator — Ce face`, mode (single/restart/queued/parallel), identificatori de declanșator, condiții native, tipuri trigger, wait actions, repeat, if/choose, dezactivare automatizări, greșeli frecvente.
---

# Automatizări — Home Assistant

> Pentru afirmații legate de versiuni HA, verifică [ha-version-notes.md](ha-version-notes.md) înainte de schimbări critice.

## Filozofie

O automatizare bine denumită se citește ca o propoziție:

> **"Când detectez mișcare în baie noaptea, aprind lumina la 10%."**

Un pas bine descris se citește ca o instrucțiune:

> **"Stinge toate luminile din living."**

Dacă un om care nu a văzut niciodată Home Assistant poate înțelege ce face automatizarea sau pasul doar citind numele, denumirea e corectă.

Trei reguli de bază:

- **Română peste tot** — alias-uri, description-uri, alias-uri de pași.
- **Fără cod în vizibil** — niciun `entity_id`, `service`, `platform` în alias. Acestea aparțin YAML-ului, nu numelui.
- **Un singur lucru pe pas** — dacă un pas face două lucruri, e de fapt doi pași.

---

## Automatizări

### Format canonic

```
[Zonă] Declanșator — Ce face
```

Trei componente, în ordine:

- `[Zonă]` — camera sau domeniul afectat, în paranteze drepte. Același slug ca la device names. Folosește `[Casă]` pentru automatizări globale.
- `Declanșator` — ce pornește automatizarea (mișcare, oră, stare, plecare etc.).
- `Ce face` — efectul principal, scurt (3–5 cuvinte).

Separatorul dintre declanșator și efect este ` — ` (spațiu, linie EM, spațiu).

### Exemple

```
[Baie #1] Prezență detectată — Aprinde lumina
[Baie #1] Prezență dispărută — Stinge lumina după 2 min
[Living] Apus soare — Coboară jaluzelele
[Dormitor #1] Ora 22:30 — Stinge tot și setează Do Not Disturb
[Casă] Plecare confirmat — Stinge tot, armează alarma
[Casă] Sosire acasă — Dezarmează, pornește clima
[Casă] Ușa garaj deschisă 10 min — Trimite notificare
[Exterior] Ploaie detectată — Retrage storurile
[Cameră Tehnică] Putere totală > 4 kW — Alertă consum ridicat
[Casă] Miezul nopții — Oprește prizele standby
[Casă] Baterie senzor scăzută — Notifică pe telefon
```

### Reguli de format

- **Capitalizare:** primul cuvânt cu majusculă, restul minuscule. Brand-urile și produsele proprii își păstrează scrierea.
- **Diacritice:** permise și recomandate.
- **Lungime maximă:** ~60 de caractere — afișat complet în lista UI.
- **Fără `Automation:` sau `Script:` prefix** — HA le grupează oricum separat.
- **Fără ID-uri tehnice** — nu scrie `binary_sensor.baie1_presence`, scrie `Prezență detectată`.

### Area (categoria)

Fiecare automatizare se asignează în **aria zonei** din prefixul `[Zonă]`:

| Alias automatizare | Area asignată |
| ------------------ | ------------- |
| `[Baie #1] Prezență detectată — Aprinde lumina` | Baie #1 |
| `[Living] Apus soare — Coboară jaluzelele` | Living |
| `[Dormitor #1] Ora 22:30 — Stinge tot` | Dormitor #1 |
| `[Casă] Plecare confirmat — Stinge tot` | *(fără arie — global)* |
| `[Casă] Baterie senzor scăzută — Notifică` | *(fără arie — global)* |

**Cum asignezi:** Settings → Automations & Scenes → [Automatizare] → ⚙️ → Area

### Câmpul `description`

Obligatoriu dacă automatizarea are condiții, excepții sau logică mai puțin evidentă.

Format liber, 1–3 propoziții în română:

```yaml
description: >
  Aprinde lumina din baie la 10% dacă e după ora 22:00 și înainte de 07:00.
  Dacă e zi, aprinde la 100%. Se declanșează doar când senzorul de prezență
  detectează ocupare — nu la simplă mișcare.
```

### Câmpul `mode`

Modul definește ce se întâmplă dacă automatizarea se declanșează din nou **înainte să termine rularea curentă**.

#### Cele 4 moduri

| Mod | Ce face când e re-declanșat | Folosit pentru |
| --- | --------------------------- | -------------- |
| `single` *(implicit)* | Ignoră re-declanșarea | O singură acțiune la un moment dat — buton scenă, apel script unic |
| `restart` | Abandonează rularea curentă, începe de la zero | Lumini cu delay: senzor de mișcare, timeout stingere |
| `queued` | Adaugă în coadă, rulează după ce termină curentul | Anunțuri TTS consecutive, acțiuni care nu trebuie pierdute |
| `parallel` | Rulează simultan mai multe instanțe | Alerte independente per cameră, acțiuni pe dispozitive diferite |

#### `max:` și `max_exceeded:`

- `max:` — numărul maxim de instanțe simultane (pentru `queued` și `parallel`). Default: 10.
- `max_exceeded:` — ce se întâmplă când se atinge limita: `silent` (ignoră silențios), `warning` (log), `error`. Default: `warning`.

```yaml
mode: queued
max: 5
max_exceeded: silent
```

#### Ghid de alegere

```
Lumini cu senzor de mișcare (delay la stingere)  →  restart
  (mișcarea re-detectată resetează timer-ul)

Alarmă / alertă per cameră independentă          →  parallel
  (mai multe camere pot declanșa simultan)

Anunțuri TTS sau notificări consecutive          →  queued
  (nu vrei să pierzi niciun mesaj)

Buton de scenă, script apelat manual             →  single
  (o singură rulare la un moment dat, ignoră dublu-click)
```

#### Exemple reale

```yaml
# Lumini motion — restart: mișcarea re-detectată resetează countdown-ul
alias: "[Baie #1] Prezență detectată — Aprinde lumina"
mode: restart
# Restart: re-detectarea prezenței anulează timer-ul de stingere.

# Alertă per cameră — parallel: mai multe camere pot alerta simultan
alias: "[Casă] Ușă lăsată deschisă — Alertă repetată"
mode: parallel
max: 10
max_exceeded: silent

# Anunțuri TTS — queued: anunțurile se execută pe rând, niciunul nu se pierde
alias: "[Casă] Anunț vocal programat"
mode: queued
max: 5

# Buton scenă — single: click dublu ignorat
alias: "[Living] Buton apăsat — Activează Film"
mode: single
```

#### Edge cases

- **`restart` și `delay`** — dacă automatizarea are un `delay:` și e re-declanșată în modul `restart`, tot ce era după `delay` se **abandonează**. Timer-ul se resetează la 0. Util pentru lumini cu timeout.
- **`queued` și condiții** — condițiile din secvență sunt re-evaluate la momentul **executării** (când iese din coadă), nu la momentul re-declanșării. O instanță poate eșua condiția la execuție chiar dacă a trecut-o la declanșare.
- **Delay-urile nu supraviețuiesc repornirii HA** — dacă HA se repornește în timp ce o automatizare cu `delay:` rulează, delay-ul se pierde. Folosește un `timer.` helper dacă ai nevoie de persistență.

---

### Trigger ID-uri

Când o automatizare are mai mulți declanșatori care necesită **răspunsuri diferite**, folosește `id:` pe fiecare trigger pentru a distinge sursa declanșării.

#### Format

```
id: <slug_english_lowercase>
```

- **Engleză, lowercase_underscore** — la fel ca slugurile de entity_id: `presence_on`, `presence_off`, `door_opened`
- **Descriptiv** — descrie evenimentul, nu dispozitivul: `motion_detected`, nu `fp2_trigger`

#### Când să folosești trigger ID-uri

✅ **Folosește** când:
- Aceleași entități/zone, dar stări diferite (on/off, home/away)
- Logică inversă în aceeași automatizare (aprinde vs. stinge)
- Reducere cod duplicat față de două automatizări aproape identice

❌ **Nu folosi** când:
- Zone complet independente → creează automatizări separate
- Triggerele nu au nicio relație logică între ele
- Logica diferă radical (mai mult de 2–3 ramuri)

#### Referințe în acțiuni

```yaml
# Varianta 1 — condiție directă pe trigger ID (cea mai clară)
- condition: trigger
  id: presence_on

# Varianta 2 — în template Jinja2
- alias: Loghează declanșatorul activ
  action: logbook.log
  data:
    message: "Declanșat de: {{ trigger.id }}"

# Varianta 3 — choose cu trigger ID
- alias: Alege acțiunea în funcție de trigger
  choose:
    - alias: Dacă e prezență detectată — aprinde
      conditions:
        - condition: trigger
          id: presence_on
      sequence:
        - alias: Aprinde lumina din baie
          action: light.turn_on
          target:
            entity_id: light.baie1_ceiling
    - alias: Dacă prezența a dispărut — stinge după delay
      conditions:
        - condition: trigger
          id: presence_off
      sequence:
        - alias: Așteaptă 2 minute
          delay: "00:02:00"
        - alias: Stinge lumina din baie
          action: light.turn_off
          target:
            entity_id: light.baie1_ceiling
```

#### Exemplu complet — prezență on/off în aceeași automatizare

```yaml
alias: "[Baie #1] Prezență — Controlează lumina"
description: >
  Aprinde lumina la detectarea prezenței și o stinge la 2 minute după dispariție.
  Intensitate 10% noaptea (22:00–07:00), 100% ziua.
mode: restart
# Restart: re-detectarea prezenței anulează countdown-ul de stingere.

triggers:
  - trigger: state
    entity_id: binary_sensor.baie1_presence
    to: "on"
    id: presence_on
  - trigger: state
    entity_id: binary_sensor.baie1_presence
    to: "off"
    id: presence_off

actions:
  - alias: Alege acțiunea în funcție de trigger
    choose:
      - alias: Dacă e prezență — aprinde lumina
        conditions:
          - condition: trigger
            id: presence_on
        sequence:
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
            default:
              - alias: Aprinde lumina din baie la 100%
                action: light.turn_on
                target:
                  entity_id: light.baie1_ceiling
                data:
                  brightness_pct: 100

      - alias: Dacă prezența a dispărut — stinge după 2 minute
        conditions:
          - condition: trigger
            id: presence_off
        sequence:
          - alias: Așteaptă 2 minute fără prezență
            delay: "00:02:00"
          - alias: Stinge lumina din baie
            action: light.turn_off
            target:
              entity_id: light.baie1_ceiling
```

---

## Bune practici și modele

### Flux — înainte de a scrie o automatizare

1. Inspectează entitățile, helpers, scripturile și automatizările existente înainte de a scrie YAML nou.
2. Preferă `entity_id` față de `device_id`, cu excepția cazului în care un device trigger e explicit mai stabil (ex: ZHA cu `device_ieee`).
3. Alege `mode:` deliberat — vezi ghidul de alegere din secțiunea Mode de mai sus.
4. Preferă condiții native (`state`, `numeric_state`, `time`, `sun`, `zone`) față de `condition: template`.
5. Folosește identificatori de declanșator și `choose` pentru automatizări cu mai multe ramuri.
6. Rulează `ha-safe-edit check` după editări.

**Evită:**
- Șabloane de polling când există un event trigger disponibil.
- Hard-coded device IDs.
- Editarea `.storage/` direct.
- Snippet-uri YAML fără validarea întregii configurații.

---

### Condiții native

Preferă întotdeauna condițiile native față de `condition: template`. Sunt validate la încărcare, nu la rulare — erorile apar imediat, nu în producție.

#### Condiție de stare (`state`)

```yaml
# Stare simplă
condition: state
entity_id: light.living_room
state: "on"

# Stări multiple acceptate (logică OR)
condition: state
entity_id: vacuum.robot
state:
  - "cleaning"
  - "returning"

# Verificare atribut
condition: state
entity_id: climate.thermostat
attribute: hvac_action
state: "heating"

# Durată — entitatea e în starea X de cel puțin N minute
condition: state
entity_id: binary_sensor.motion
state: "off"
for:
  minutes: 5
```

#### Condiție numerică (`numeric_state`)

```yaml
# Peste un prag
condition: numeric_state
entity_id: sensor.temperature
above: 25

# Sub un prag
condition: numeric_state
entity_id: sensor.humidity
below: 30

# Interval
condition: numeric_state
entity_id: sensor.battery
above: 20
below: 80

# Verificare atribut numeric
condition: numeric_state
entity_id: sun.sun
attribute: elevation
below: -6
```

#### Condiție timp (`time`)

```yaml
# Interval orar (gestionează trecerea peste miezul nopții automat)
condition: time
after: "22:00:00"
before: "06:00:00"

# Filtru zile ale săptămânii
condition: time
weekday:
  - mon
  - tue
  - wed
  - thu
  - fri

# Combinat: program de lucru
condition: time
after: "09:00:00"
before: "17:00:00"
weekday:
  - mon
  - tue
  - wed
  - thu
  - fri
```

#### Condiție soare (`sun`)

```yaml
# După apus
condition: sun
after: sunset

# Înainte de răsărit cu offset
condition: sun
before: sunrise
before_offset: "01:00:00"

# La 30 de minute după apus
condition: sun
after: sunset
after_offset: "00:30:00"
```

#### Condiție zonă (`zone`)

```yaml
# Persoana e acasă
condition: zone
entity_id: person.andrei
zone: zone.home

# Persoana NU e acasă
condition: not
conditions:
  - condition: zone
    entity_id: person.andrei
    zone: zone.home
```

#### And / Or / Not

```yaml
# AND — implicit când listezi mai multe condiții
condition: and
conditions:
  - condition: state
    entity_id: light.kitchen
    state: "on"
  - condition: numeric_state
    entity_id: sensor.brightness
    below: 100

# OR — cel puțin una adevărată
condition: or
conditions:
  - condition: state
    entity_id: person.andrei
    state: "home"
  - condition: state
    entity_id: person.maria
    state: "home"

# NOT
condition: not
conditions:
  - condition: state
    entity_id: alarm_control_panel.home
    state: "armed_away"

# Sintaxă scurtă
conditions:
  - and:
      - condition: state
        entity_id: input_boolean.guest_mode
        state: "on"
      - condition: time
        after: "08:00:00"
```

#### Template ca condiție (când e necesar)

```yaml
# Forma scurtă (preferată dacă trebuie template)
conditions:
  - "{{ trigger.to_state.attributes.brightness > 100 }}"

# Forma lungă (echivalent)
conditions:
  - condition: template
    value_template: "{{ trigger.to_state.attributes.brightness > 100 }}"
```

---

### Tipuri de declanșatori (triggers)

#### Tabel de selecție rapidă

| Vrei să declanșezi pe... | Folosește trigger | Notă |
|---|---|---|
| Schimbare stare entitate | `state` | Cel mai frecvent — `to:`, `from:`, `for:` |
| Prag numeric (temp > 25) | `numeric_state` | `above:` / `below:` cu `for:` |
| Oră fixă / pattern timp | `time` / `time_pattern` | Suportă `input_datetime` |
| Răsărit / apus + offset | `sun` | `event: sunrise` cu `offset:` |
| Buton ZHA wireless | `event` (`zha_event`) | Cu `device_ieee` persistent |
| Buton Z2M | `device` sau `mqtt` | Z2M e safe pentru `device_id` |
| Topic MQTT brut | `mqtt` | Cu `topic:` și `payload:` |
| Timer terminat | `event` (`timer.finished`) | HA 2026.5+ — vezi mai jos |
| Webhook extern | `webhook` | URL HA pentru integrări externe |
| Schimbare zonă (geo) | `zone` | `event: enter` / `leave` |
| Conjuncție OR de triggere | Listă cu `id:` per trigger | Combinabil cu `choose` pe ID |

#### Triggere specifice scopului (HA 2026.2+)

Editorul vizual HA oferă **triggere specifice conceptelor reale** (ușă deschisă, mișcare detectată, prag temperatură, baterie scăzută etc.) independent de domeniul tehnic al entității. Acestea generează în YAML triggere standard (`state`, `numeric_state` etc.) — sintaxa YAML rămâne neschimbată.

#### Trigger stare (`state`) — principalul trigger

```yaml
# Schimbare la o valoare specifică
triggers:
  - trigger: state
    entity_id: binary_sensor.motion
    to: "on"

# Din stare → în stare
triggers:
  - trigger: state
    entity_id: light.bedroom
    from: "off"
    to: "on"

# Orice schimbare de stare (omite to/from)
triggers:
  - trigger: state
    entity_id: sensor.temperature

# Schimbare de atribut
triggers:
  - trigger: state
    entity_id: climate.thermostat
    attribute: current_temperature

# Durată — entitatea e în stare X de cel puțin N minute
triggers:
  - trigger: state
    entity_id: light.porch
    to: "on"
    for:
      minutes: 30

# Entități multiple
triggers:
  - trigger: state
    entity_id:
      - binary_sensor.motion_kitchen
      - binary_sensor.motion_hallway
    to: "on"
```

#### Trigger numeric (`numeric_state`)

```yaml
triggers:
  - trigger: numeric_state
    entity_id: sensor.temperature
    above: 25
    for:
      minutes: 5
```

#### Trigger timp

```yaml
# Oră fixă
triggers:
  - trigger: time
    at: "07:00:00"

# Helper input_datetime ca oră de declanșare
triggers:
  - trigger: time
    at: input_datetime.morning_alarm

# Pattern timp (la fiecare 5 minute)
triggers:
  - trigger: time_pattern
    minutes: "/5"

# La :30 în fiecare oră
triggers:
  - trigger: time_pattern
    minutes: 30
```

#### Trigger soare

```yaml
# Cu 30 de minute înainte de apus
triggers:
  - trigger: sun
    event: sunset
    offset: "-00:30:00"
```

#### Trigger eveniment (`event`)

```yaml
# Buton ZHA — device_ieee e persistent, nu se schimbă la re-adăugare
triggers:
  - trigger: event
    event_type: zha_event
    event_data:
      device_ieee: "00:11:22:33:44:55:66:77"
      command: "on"

# Eveniment custom
triggers:
  - trigger: event
    event_type: my_custom_event
```

**Guard pentru `trigger.event` în automatizări cu triggere mixte:** Dacă amesteci triggere de tip event și non-event, `trigger.event` este `LoggingUndefined` pentru triggerele non-event. Accesul la atribute (`.data`, `.split()`) ridică `UndefinedError`. Folosește un guard:

```yaml
# EVITĂ — ridică UndefinedError când se declanșează un trigger non-event
conditions:
  - "{{ 'light.kitchen' in trigger.event.data.entity_id }}"

# CORECT — guard previne evaluarea pe triggere non-event
conditions:
  - "{{ trigger.platform == 'event' and 'light.kitchen' in trigger.event.data.entity_id }}"
```

#### Trigger MQTT

```yaml
triggers:
  - trigger: mqtt
    topic: "zigbee2mqtt/button/action"
    payload: "single"
```

#### Trigger device (folosește cu precauție)

`device_id` nu e persistent — se schimbă dacă dispozitivul e re-adăugat. Preferă triggere pe `entity_id`.

```yaml
# Evită dacă există alternativă cu entity_id
triggers:
  - trigger: device
    domain: mqtt
    device_id: abc123
    type: action
    subtype: single
```

#### Prezență persoane — triggere și condiții eliminate în 2026.5

`entered_home`/`left_home` (trigger) și `is_home`/`is_not_home` (condition) au fost **eliminate în 2026.5**:

```yaml
# EVITĂ (eliminate în 2026.5)
triggers:
  - trigger: device
    domain: person
    type: entered_home
    entity_id: person.andrei

# CORECT — trigger de stare
triggers:
  - trigger: state
    entity_id: person.andrei
    to: "home"

# CORECT — condiție de stare
condition: state
entity_id: person.andrei
state: "home"
```

#### Triggere timer (HA 2026.5+)

Entitățile timer expun acum evenimente ca triggere în editorul UI. În YAML, folosește trigger `event`:

```yaml
# Timer terminat (și: timer.started, timer.paused, timer.restarted, timer.cancelled)
triggers:
  - trigger: event
    event_type: timer.finished
    event_data:
      entity_id: timer.cooking
```

#### Triggere media player (HA 2026.5+)

Media player-urile au acum triggere și condiții specifice în editorul UI. În YAML, mapează pe `state` și `numeric_state`:

```yaml
# Stare redare — to: "playing", "paused", "idle", "off"
triggers:
  - trigger: state
    entity_id: media_player.living_room
    to: "playing"

# Prag volum
triggers:
  - trigger: numeric_state
    entity_id: media_player.living_room
    attribute: volume_level
    above: 0.7
```

---

### Acțiuni de așteptare (wait)

#### `wait_for_trigger` (preferat)

Așteaptă event-driven — mai eficient decât polling.

```yaml
# Așteaptă ca ușa să se închidă
- wait_for_trigger:
    - trigger: state
      entity_id: binary_sensor.door
      to: "off"
  timeout:
    minutes: 5
  continue_on_timeout: false  # Oprește automatizarea dacă se depășește timeout-ul

# Așteaptă oricare din mai multe triggere
- wait_for_trigger:
    - trigger: state
      entity_id: binary_sensor.door
      to: "off"
    - trigger: event
      event_type: mobile_app_notification_action
      event_data:
        action: "CLOSE_DOOR"
```

#### Verificarea rezultatului wait

Ambele tipuri de wait setează `wait.completed` și `wait.remaining`:

```yaml
- wait_for_trigger:
    - trigger: state
      entity_id: binary_sensor.door
      to: "off"
  timeout:
    minutes: 5

- if:
    - "{{ not wait.completed }}"
  then:
    - action: notify.send_message
      target:
        entity_id: notify.telefon_andrei
      data:
        message: "Ușa e deschisă de mai mult de 5 minute!"
```

#### `wait_template` (folosește rar)

Face polling până când șablonul devine true. **Continuă imediat dacă condiția e deja adevărată la pornire.**

```yaml
- wait_template: "{{ states('sensor.temperature') | float > 25 }}"
  timeout:
    minutes: 10
```

**Diferența cheie față de `wait_for_trigger`:**
- `wait_for_trigger` — așteaptă o **schimbare** de stare (dacă starea e deja corectă, blochează nedefinit)
- `wait_template` — verifică o **condiție** (dacă e deja adevărată, trece imediat)

---

### Continuare la eroare (`continue_on_error`)

```yaml
actions:
  - action: light.turn_on
    target:
      entity_id: light.terasa
    continue_on_error: true  # Automatizarea continuă chiar dacă această acțiune eșuează
  - action: notify.send_message
    target:
      entity_id: notify.telefon_andrei
    data:
      message: "Acțiunea pe lumină a fost încercată"
```

Disponibil și din editorul vizual (HA 2026.3+) via meniul celor trei puncte de pe orice acțiune. Folosește cu precauție — ascunde erori și face debugging dificil. Potrivit pentru acțiuni non-critice (logare, notificări opționale) unde un eșec nu trebuie să blocheze restul automatizării.

---

### Repetare acțiuni (`repeat`)

```yaml
# Repetă de N ori
- repeat:
    count: 3
    sequence:
      - action: light.toggle
        target:
          entity_id: light.dormitor1_ceiling

# Repetă cât timp condiția e adevărată
- repeat:
    while:
      - condition: state
        entity_id: binary_sensor.door
        state: "on"
    sequence:
      - action: notify.send_message
        target:
          entity_id: notify.telefon_andrei
        data:
          message: "Ușa e încă deschisă"
      - delay:
          minutes: 5

# Repetă până când condiția devine adevărată
- repeat:
    until:
      - condition: numeric_state
        entity_id: sensor.temperature
        below: 25
    sequence:
      - delay:
          minutes: 1

# Repetă pentru fiecare element dintr-o listă
- repeat:
    for_each:
      - "light.kitchen"
      - "light.bedroom"
      - "light.hallway"
    sequence:
      - action: light.turn_off
        target:
          entity_id: "{{ repeat.item }}"
```

În interiorul secvenței ai acces la `repeat.index` (1-based) și `repeat.item` (pentru `for_each`).

---

### `if/then` vs `choose`

**`if/then/else`** — pentru condiții binare simple (da/nu):

```yaml
actions:
  - if:
      - condition: state
        entity_id: sun.sun
        state: "below_horizon"
    then:
      - action: light.turn_on
        target:
          entity_id: light.terasa
    else:
      - action: light.turn_off
        target:
          entity_id: light.terasa
```

**`choose`** — pentru mai multe ramuri (switch/case):

```yaml
actions:
  - choose:
      - conditions:
          - condition: trigger
            id: "morning"
        sequence:
          - action: scene.turn_on
            target:
              entity_id: scene.living_morning
      - conditions:
          - condition: trigger
            id: "evening"
        sequence:
          - action: scene.turn_on
            target:
              entity_id: scene.living_evening
    default:
      - action: light.turn_off
        target:
          area_id: living
```

---

### Dezactivarea automatizărilor

HA oferă două metode distincte cu comportamente diferite.

#### Metoda 1 — Oprire temporară (state machine)

`automation.turn_off` dezactivează triggerele configurate. Entitatea rămâne în state machine cu starea `off` și poate fi apelată manual via `automation.trigger`.

```yaml
- action: automation.turn_off
  target:
    entity_id: automation.my_automation
  data:
    stop_actions: true  # default: true — oprește și rulările active
```

| Atribut | Valoare |
| --- | --- |
| `stop_actions` | Oprește rulările active. Default `true`. |
| Supraviețuiește reload? | Da — starea e în `core.restore_state` |
| Supraviețuiește restart? | Doar dacă automatizarea are câmpul `id:` (fără `id:`, entity_id e instabil) |
| Entitate în state machine? | Da — starea e `off` |
| Reactivare via | `automation.turn_on` |

**Override `initial_state`:** Dacă YAML-ul automatizării conține `initial_state`, acesta suprascrie starea stocată la restart (`true` → forțat pornit, `false` → forțat oprit, indiferent de starea salvată).

#### Metoda 2 — Dezactivare permanentă (entity registry)

Via UI: *Settings → Automations → deschide automatizarea → ⋮ → Settings → buton Enabled*. Setează `disabled_by: user` în `core.entity_registry`. Entitatea dispare complet din state machine.

| Atribut | Valoare |
| --- | --- |
| Supraviețuiește reload? | Da — stocat în `core.entity_registry` |
| Supraviețuiește restart? | Da |
| Entitate în state machine? | **Nu** — `GET /api/states/<entity_id>` returnează 404 |
| Necesită câmpul `id:`? | Da — devine `unique_id`, necesar pentru intrarea în entity registry |
| Reactivare via | Butonul Enabled din UI sau WebSocket API (`config/entity_registry/update` cu `{"disabled_by": null}`) |

**Notă:** Toggle-ul din lista de automatizări (`/config/automation/dashboard`) apelează `automation.turn_on/off` (Metoda 1). Butonul Enabled din *Settings → open automation → ⋮ → Settings* modifică entity registry-ul (Metoda 2). Ambele pot fi active simultan — o automatizare poate fi activă în registry dar cu starea `off`, sau dezactivată în registry cu stare salvată `on`.

#### EVITĂ: `enabled: false` în automations.yaml

```yaml
# EVITĂ — enabled: nu este o cheie validă la nivel top-level în automations.yaml
- alias: My Automation
  enabled: false       # respins la schema validation → automatizarea devine unavailable
  triggers: ...

# CORECT — dezactivare temporară (Metoda 1)
- action: automation.turn_off
  target:
    entity_id: automation.my_automation

# CORECT — dezactivare permanentă (Metoda 2)
# UI: Settings → Automations → open automation → ⋮ → Settings → Enabled toggle
```

---

### Anti-modele

| Anti-pattern | Folosește în schimb | De ce |
|---|---|---|
| `condition: template` cu `float > 25` | `condition: numeric_state` | Validat la încărcare, nu la rulare |
| `wait_template: "{{ is_state(...) }}"` | `wait_for_trigger` cu state trigger | Event-driven, nu polling; semantică diferită (voir secțiunea Wait) |
| `device_id` în triggers | `entity_id` (sau `device_ieee` pentru ZHA) | `device_id` se schimbă la re-adăugare |
| `mode: single` pentru lumini cu mișcare | `mode: restart` | Re-triggerele trebuie să reseteze timer-ul |
| `enabled: false` ca cheie top-level | `automation.turn_off` (temporar) sau entity registry disable (permanent) | Cheie invalidă — automatizarea devine `unavailable` |
| `entered_home`/`left_home` triggers pentru persoane | `state` trigger `to: home` / `to: not_home` | Eliminate în 2026.5 |
| `color_temp` (mireds) în apeluri de servicii pentru lumini | `color_temp_kelvin` | Parametrul `color_temp` eliminat în 2026.3 |

---

**TL;DR:** `[Zonă] Declanșator — Ce face` — română, max 60 caractere. Mode: `restart` → lumini cu delay, `parallel` → alerte per cameră, `queued` → TTS consecutiv, `single` → butoane. Trigger IDs: `id: slug_en` pe fiecare trigger când aceeași automatizare gestionează on/off. Condiții native > template. `wait_for_trigger` > `wait_template`. Nu folosi `device_id` dacă există `entity_id`. `color_temp_kelvin` în loc de `color_temp`.
