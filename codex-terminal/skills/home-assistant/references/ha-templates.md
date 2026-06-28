---
name: ha-templates
description: Template-uri Jinja2 HA — când să le folosești vs native conditions/helpers, unique_id/availability/state_class, template-uri bazate pe trigger, accesare sigură (states, float(0), has_value), performanță, pattern-uri.
---

# Template-uri Jinja2 — Home Assistant

> Pentru funcții Jinja/YAML dependente de versiunea HA, verifică [ha-version-notes.md](ha-version-notes.md) înainte de schimbări critice.

> **Preferă un Template Helper față de YAML.**
> Înainte de a scrie orice bloc `template:`, creează un Template Helper via HA config flow (MCP tool sau API) sau via UI:
> Settings → Devices & Services → Helpers → Create Helper → Template.
> Folosește `template:` YAML doar dacă e explicit cerut sau dacă nu ai acces la UI/API.
>
> **Despre exemplele din acest fișier:** sunt didactice — arată sintaxa Jinja2 și pattern-uri YAML reutilizabile **și în Template Helper (UI), și în blocuri `template:` YAML**. Logica Jinja2 e identică; doar contextul de configurare diferă. Pentru cod nou de producție, copiază doar template-ul (expresia `state:`, `availability:` etc.) în Template Helper-ul UI.

## Workflow — înainte de a implementa un template

1. **Evaluează dacă un helper înlocuiește template-ul** — verifică `ha-helpers-scenes.md` pentru alternative native.
2. **Verifică dacă native triggers/conditions sunt potrivite** — consultă `ha-automations.md`.
3. **Dacă template-ul e necesar:** testează incremental înainte de a modifica configurația de producție.
4. **Validează YAML** cu `ha-safe-edit check` după modificări.
5. **Gestionează `unknown` și `unavailable`** — entitățile pot returna aceste stări; adaugă `availability:` și fallback-uri.

---

## Când sunt potrivite template-urile

Templates sunt alegerea CORECTĂ când:

### 1. Date dinamice pentru service calls

```yaml
actions:
  - action: light.turn_on
    target:
      entity_id: light.dormitor1_ceiling
    data:
      brightness_pct: "{{ states('input_number.default_brightness') | int }}"
      kelvin: "{{ 6500 if is_state('binary_sensor.daytime', 'on') else 2700 }}"
```

### 2. Mesaje dinamice în notificări

```yaml
actions:
  - action: notify.send_message
    target:
      entity_id: notify.telefon_andrei
    data:
      message: >
        {{ trigger.to_state.name }} este {{ trigger.to_state.state }}
        de {{ trigger.for.total_seconds() | int // 60 }} minute.
```

### 3. Procesarea datelor brute (MQTT, REST, command_line)

```yaml
rest:
  - resource: "http://api.example.com/data"
    sensor:
      - name: "Temperatură"
        value_template: "{{ value_json.current.temperature }}"
        unit_of_measurement: "°C"
```

### 4. Accesarea contextului trigger-ului

```yaml
actions:
  - action: notify.send_message
    target:
      entity_id: notify.telefon_andrei
    data:
      message: >
        {{ trigger.to_state.name }} s-a schimbat din
        {{ trigger.from_state.state }} în {{ trigger.to_state.state }}
```

### 5. Formatare complexă de string-uri

```yaml
template:
  - sensor:
      - name: "Uptime prietenos"
        state: >
          {% set uptime = states('sensor.system_uptime') | float(0) %}
          {% set days = (uptime // 86400) | int %}
          {% set hours = ((uptime % 86400) // 3600) | int %}
          {% set minutes = ((uptime % 3600) // 60) | int %}
          {{ days }}d {{ hours }}h {{ minutes }}m
```

### 6. Extragerea de atribute

```yaml
template:
  - sensor:
      - name: "Artist piesă curentă"
        state: "{{ state_attr('media_player.living_boxa', 'media_artist') }}"
```

### 7. Stare condiționată complexă

```yaml
template:
  - sensor:
      - name: "Nivel confort"
        state: >
          {% set temp = states('sensor.temperature') | float(20) %}
          {% set humidity = states('sensor.humidity') | float(50) %}
          {% if temp >= 20 and temp <= 24 and humidity >= 40 and humidity <= 60 %}
            Confortabil
          {% elif temp < 18 or humidity < 30 %}
            Prea rece/uscat
          {% else %}
            Acceptabil
          {% endif %}
```

### 8. Iterarea entităților

```yaml
template:
  - sensor:
      - name: "Număr ferestre deschise"
        state: >
          {{ states.binary_sensor
             | selectattr('attributes.device_class', 'eq', 'window')
             | selectattr('state', 'eq', 'on')
             | list
             | count }}
```

### 9. Calcule de dată/timp

```yaml
template:
  - sensor:
      - name: "Zile până la eveniment"
        state: >
          {% set event_date = as_datetime(states('input_datetime.event')) %}
          {% set today = now().replace(hour=0, minute=0, second=0, microsecond=0) %}
          {{ ((event_date - today).days) }}
        unit_of_measurement: "zile"
```

---

## Când să eviți template-urile

NU folosi templates când există o alternativă nativă:

| Nu folosi Template | Folosește Native |
|-------------------|------------|
| `{{ states('x') in ['a', 'b'] }}` | `condition: state` cu `state: ["a", "b"]` |
| `{{ states('x') \| float > 25 }}` | `condition: numeric_state` cu `above: 25` |
| `{{ now().hour >= 9 }}` | `condition: time` cu `after: "09:00:00"` |
| `{{ is_state('sun.sun', 'below_horizon') }}` | `condition: sun` cu `after: sunset` |
| `wait_template: "{{ is_state(...) }}"` | `wait_for_trigger` cu state trigger |
| Template sensor sumă/medie | `min_max` helper |
| Template binary sensor cu threshold | `threshold` helper |
| Template sensor medie în timp | `statistics` helper |

---

## Template Sensor — bune practici

### Include întotdeauna unique_id

```yaml
template:
  - sensor:
      - name: "Senzorul meu"
        unique_id: senzorul_meu  # Permite customizare din UI
        state: "{{ states('sensor.source') }}"
```

### Definește întotdeauna availability

Previne erori și stări `unknown`:

```yaml
template:
  - sensor:
      - name: "Senzor sigur"
        unique_id: senzor_sigur
        availability: >
          {{ has_value('sensor.source_a') and
             has_value('sensor.source_b') }}
        state: >
          {{ states('sensor.source_a') | float +
             states('sensor.source_b') | float }}
```

### Folosește device class potrivit

```yaml
template:
  - sensor:
      - name: "Temperatură calculată"
        device_class: temperature
        unit_of_measurement: "°C"
        state_class: measurement
        state: "{{ states('sensor.raw_temp') | float / 10 }}"
```

### Folosește state_class pentru statistici pe termen lung

**Dacă ai nevoie de statistici pe termen lung, setează `state_class`.** Fără el, HA nu scrie statistici — senzorul nu va apărea în History graphs.

`state_class` este opțional pentru senzori diagnostici sau one-shot unde statisticile nu sunt necesare.

> **Energy Dashboard:** `state_class` singur nu e suficient. Senzorul mai necesită și `device_class: energy` (sau `power`, `gas`) pentru a apărea ca sursă selectabilă.

```yaml
template:
  - sensor:
      - name: "Putere consum"
        device_class: power
        unit_of_measurement: "W"
        state_class: measurement  # activează statistici pe termen lung
        state: "{{ states('sensor.amps') | float * 230 }}"
```

### Template-uri bazate pe trigger — mai eficiente

Template-urile bazate pe trigger se actualizează DOAR când triggerul se declanșează:

```yaml
template:
  - triggers:                    # Plural (HA 2024.10+)
      - trigger: state
        entity_id:
          - sensor.dormitor1_temperature
          - sensor.living_temperature
    sensor:
      - name: "Temperatură medie"
        state: >
          {% set temps = [
            states('sensor.dormitor1_temperature') | float(0),
            states('sensor.living_temperature') | float(0)
          ] %}
          {{ (temps | sum / temps | count) | round(1) }}
        unit_of_measurement: "°C"
        state_class: measurement
```

**Beneficii:**
- Se evaluează doar la declanșarea triggerului (nu la orice schimbare de stare)
- Accesezi variabila `trigger`
- Mai eficient pentru template-uri complexe

### Structura blocurilor YAML (HA 2024.10+)

**Folosește chei plural în trigger-based template blocks.** `triggers:` și `actions:` (plural) sunt formele recomandate. Formele singular funcționează, dar nu sunt recomandate.

**Consolidează senzori state-based de același tip într-un singur bloc:**

```yaml
# CORECT — state-based sensors: un bloc, multiple entries:
template:
  - binary_sensor:
      - name: "Mișcare cameră A"
        unique_id: motion_room_a
        state: "{{ ... }}"
      - name: "Mișcare cameră B"
        unique_id: motion_room_b
        state: "{{ ... }}"

# DE EVITAT — state-based sensors în blocuri separate:
template:
  - binary_sensor:
      - name: "Mișcare cameră A"
        state: "{{ ... }}"
  - binary_sensor:
      - name: "Mișcare cameră B"
        state: "{{ ... }}"
```

---

## Template-uri în automatizări — bune practici

### Folosește sintaxa shorthand

```yaml
# Shorthand (preferat)
conditions:
  - "{{ trigger.to_state.attributes.brightness > 100 }}"

# Forma lungă (echivalent dar verbose)
conditions:
  - condition: template
    value_template: "{{ trigger.to_state.attributes.brightness > 100 }}"
```

### Accesează contextul trigger corect

```yaml
automation:
  - triggers:
      - trigger: state
        entity_id: light.dormitor1_ceiling
    actions:
      - action: notify.send_message
        target:
          entity_id: notify.telefon_andrei
        data:
          message: >
            Lumina s-a schimbat din {{ trigger.from_state.state }}
            în {{ trigger.to_state.state }}
            Entitate: {{ trigger.entity_id }}
            Luminozitate: {{ trigger.to_state.attributes.brightness | default('N/A') }}
```

---

## Pattern-uri comune

### Accesare sigură a stării

Folosește întotdeauna funcția `states()`, nu `states.sensor.x.state`:

```yaml
# BINE - returnează 'unknown' dacă entitatea nu există
{{ states('sensor.temperature') }}

# GREȘIT - eroare dacă entitatea nu există
{{ states.sensor.temperature.state }}
```

### Conversie numerică sigură

```yaml
# BINE - valoare default dacă conversia eșuează
{{ states('sensor.temperature') | float(0) }}

# GREȘIT - eroare dacă starea e 'unavailable' sau 'unknown'
{{ states('sensor.temperature') | float }}
```

### Verifică starea validă

```yaml
{% if has_value('sensor.temperature') %}
  Temperatura este {{ states('sensor.temperature') }}°C
{% else %}
  Temperatură indisponibilă
{% endif %}
```

### Acces la atribut cu valoare default

```yaml
{{ state_attr('light.dormitor1_ceiling', 'brightness') | default(0) }}
```

### Timp de la schimbarea stării

```yaml
{% set last_changed = states.binary_sensor.living_motion.last_changed %}
{% set seconds = (now() - last_changed).total_seconds() %}
{{ (seconds / 60) | round(0) }} minute în urmă
```

### Filtrare entități după atribut

```yaml
{% set open_windows = states.binary_sensor
   | selectattr('attributes.device_class', 'defined')
   | selectattr('attributes.device_class', 'eq', 'window')
   | selectattr('state', 'eq', 'on')
   | list %}
{{ open_windows | count }} ferestre deschise
```

### Verificare stări multiple

```yaml
{% if states('alarm_control_panel.home') in ['armed_home', 'armed_away', 'armed_night'] %}
  Alarma este armată
{% endif %}
```

---

## Tratarea erorilor

### Valori default

```yaml
# Pentru operații numerice
{{ states('sensor.x') | float(default=0) }}
{{ states('sensor.x') | int(default=-1) }}

# Pentru accesarea atributelor
{{ state_attr('light.x', 'brightness') | default(100) }}

# Pentru eșecuri complete de template
{{ states('sensor.missing') | default('Necunoscut', true) }}
```

### Template availability

```yaml
template:
  - sensor:
      - name: "Valoare calculată"
        availability: "{{ has_value('sensor.input') }}"
        state: "{{ states('sensor.input') | float * 2 }}"
```

### Atribute None

```yaml
{% set attr = state_attr('sensor.x', 'some_attr') %}
{% if attr is not none %}
  Valoare atribut: {{ attr }}
{% else %}
  Atribut indisponibil
{% endif %}
```

---

## Considerații de performanță

### Evită operații costisitoare în value templates

Template-urile din `value_template` se actualizează la FIECARE schimbare de stare a sursei.

```yaml
# COSTISITOR - sintaxă modernă, dar logică scumpă la fiecare update relevant
template:
  - sensor:
      - name: "Calcul costisitor"
        state: >
          {% for entity in states %}  {# Iterează TOATE entitățile #}
            ...
          {% endfor %}
```

### Folosește trigger-based templates pentru logică complexă

```yaml
# EFICIENT - rulează doar la triggere specificate
template:
  - triggers:
      - trigger: time_pattern
        minutes: "/5"  # La fiecare 5 minute
    sensor:
      - name: "Calcul complex"
        state: >
          {% set total = 0 %}
          {% for sensor in states.sensor | selectattr('attributes.device_class', 'eq', 'energy') %}
            {% set total = total + states(sensor.entity_id) | float(0) %}
          {% endfor %}
          {{ total }}
```

### Cache calcule complexe

Dacă ai nevoie de aceeași valoare în mai multe locuri, creează un template sensor și referențiază-l:

```yaml
template:
  - sensor:
      - name: "Număr persoane acasă"
        state: >
          {{ states.person | selectattr('state', 'eq', 'home') | list | count }}

automation:
  - condition: numeric_state
    entity_id: sensor.numar_persoane_acasa
    above: 0
```

---

## Quick Reference: funcții și filtre

### Funcții de stare

| Funcție | Scop |
|----------|---------|
| `states('entity_id')` | Obține starea entității (string) |
| `state_attr('entity_id', 'attr')` | Obține valoarea unui atribut |
| `is_state('entity_id', 'state')` | Verifică dacă entitatea are starea |
| `is_state_attr('entity_id', 'attr', 'value')` | Verifică valoarea unui atribut |
| `has_value('entity_id')` | True dacă nu e unknown/unavailable |
| `entity_name('entity_id')` | Obține numele afișat al entității (2026.4+) |
| `state_attr_translated('entity_id', 'attr')` | Obține valoarea atributului tradusă (2026.4+) |

### Filtre comune

| Filtru | Scop |
|--------|---------|
| `float(default)` | Conversie la float |
| `int(default)` | Conversie la int |
| `round(precision)` | Rotunjire număr |
| `default(value)` | Valoare de rezervă |
| `timestamp_custom(format)` | Formatează un timestamp |
| `from_json` | Parsează string JSON |
| `to_json` | Convertește la string JSON |
| `regex_match(pattern)` | Potrivire regex |
| `regex_replace(find, replace)` | Înlocuire regex |

### Funcții de timp

| Funcție | Scop |
|----------|---------|
| `now()` | Datetime curent |
| `utcnow()` | Datetime UTC curent |
| `today_at('HH:MM')` | Astăzi la o oră specifică |
| `as_timestamp(dt)` | Conversie la timestamp Unix |
| `as_datetime(ts)` | Conversie de la timestamp |
| `as_timedelta(string)` | Parsează un string de durată |

### Filtre pentru colecții

| Filtru | Scop |
|--------|---------|
| `selectattr('attr', 'eq', 'value')` | Filtrare după atribut |
| `rejectattr('attr', 'eq', 'value')` | Excludere după atribut |
| `map(attribute='state')` | Extrage atribut dintr-o listă |
| `list` | Conversie la listă |
| `count` | Numără elemente |
| `first` / `last` | Primul / ultimul element |
| `sum` / `min` / `max` | Valori agregate |

---

**TL;DR:** Folosește Template Helper (UI) în loc de YAML `template:`. `states()` nu dot notation. `| float(0)` nu `| float`. `has_value()` pentru check de disponibilitate. Template-uri bazate pe trigger pentru eficiență. Adaugă `unique_id:` și `availability:` la orice template sensor. Evită template-uri când există native conditions/helpers.
