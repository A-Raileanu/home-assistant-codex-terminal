---
name: ha-scripts-steps
description: Scripturi HA (`Verb + context`) + fields cu selector types. Pași în secvențe: alias `Verb + ce + unde + valoare`, condiții ca pași, choose, repeat, variables, wait_for_trigger.
---

# Scripturi și Pași — Home Assistant

## Scripturi

### Format canonic

```
Acțiune [context]
```

Imperativ, concis. Scripturile sunt acțiuni, nu descrieri de stare.

### Exemple

```
Scenă film living
Scenă citit dormitor #1
Rutină bun dimineața
Rutină noapte bună
Plecare din casă
Sosire acasă
Stinge toate luminile
Mod vacanță — pornit
Mod vacanță — oprit
Anunță: coletul a sosit
Resetează alarma
Verifică ușile și ferestrele
```

### Reguli de format

- **Imperativ** — `Stinge`, `Pornește`, `Anunță`, `Verifică`, nu `Stingere lumini` sau `Lumini stinse`.
- **Context opțional** — adaugă camera sau ocazia dacă scriptul e specific: `Scenă film living`, nu doar `Film`.
- **Fără `[Zonă]` prefix** — scripturile nu au un singur declanșator, deci zona e în context, nu prefix.
- **Perechi cu ` — pornit / — oprit`** pentru scripturile toggle de mod.

### Area (categoria)

Fiecare script se asignează în aria zonei pe care o servește:

| Alias script | Area asignată |
| ------------ | ------------- |
| `Scenă film living` | Living |
| `Scenă citit dormitor #1` | Dormitor #1 |
| `Rutină bun dimineața Dormitor #1` | Dormitor #1 |
| `Stinge toate luminile` | *(fără arie — global)* |
| `Plecare din casă` | *(fără arie — global)* |
| `Mod vacanță — pornit` | *(fără arie — global)* |

**Cum asignezi:** Settings → Automations & Scenes → Scripts → [Script] → ⚙️ → Area

### Câmpul `description`

```yaml
description: >
  Pregătește livingul pentru vizionare: închide jaluzelele, aprinde bara LED
  la portocaliu 40%, pune soundbarul pe HDMI 1, stinge luminile principale.
  Rulat manual sau din scenă.
```

### Câmpul `fields:` (parametri)

Scripturile pot accepta parametri — valori trimise la momentul apelării. Astfel un script devine reutilizabil în contexte diferite: poți folosi același script „Aprinde lumina" pentru orice cameră, pasând camera ca parametru.

#### Reguli de denumire a câmpurilor

- **Slug în engleză, lowercase_underscore** — la fel ca entity_id slugs: `target_entity`, `brightness_level`, `color_temp_kelvin`
- **`name:`** — eticheta vizibilă în UI, în română: `Cameră țintă`, `Luminozitate`
- **`description:`** — ce face câmpul, în română, afișat ca hint în UI
- **`required: true`** — dacă scriptul nu poate rula fără el; `false` pentru câmpuri cu valori implicite
- **`default:`** — valoarea folosită dacă câmpul nu e furnizat
- **`example:`** — valoare concretă, ajută la testare și documentare în UI

#### Tipuri de selectori (`selector:`)

| Tip selector | Folosit pentru | Exemplu valoare |
| ------------ | -------------- | --------------- |
| `entity` | ID entitate HA, filtrat pe domain | `light.living_ceiling` |
| `target` | Țintă complexă (entity / area / device) | `{entity_id: light.baie1_ceiling}` |
| `area` | ID cameră/zonă HA | `living`, `dormitor1` |
| `number` | Valoare numerică cu min/max/step | `50`, `21.5` |
| `boolean` | Adevărat / Fals | `true`, `false` |
| `text` | Text liber | `"Lumina se stinge în 1 minut"` |
| `select` | Alegere dintr-o listă fixă de opțiuni | `"Film"`, `"Citit"` |
| `color_rgb` | Culoare ca array RGB | `[255, 100, 0]` |
| `color_temp_kelvin` | Temperatură culoare în Kelvin | `2700` (caldă) – `6500` (rece) |
| `time` | Oră în format HH:MM:SS | `"22:00:00"` |
| `date` | Dată în format YYYY-MM-DD | `"2025-12-31"` |
| `duration` | Durată cu ore/minute/secunde | `{hours: 0, minutes: 5, seconds: 0}` |
| `action` | O acțiune HA completă (service call) | — |
| `object` | Obiect JSON arbitrar | — |

#### Cum se apelează un script cu fields

Din automatizare sau alt script:

```yaml
- alias: Aprinde lumina din dormitor la 80% alb cald
  action: script.aprinde_lumina_in_camera
  data:
    target_entity: light.dormitor1_ceiling
    brightness_level: 80
    color_temp_kelvin: 2700
```

#### Exemplu complet — script parametrizat

```yaml
alias: Aprinde lumina în cameră
description: >
  Aprinde o lumină la intensitatea și temperatura de culoare specificate.
  Poate fi apelat din orice automatizare sau scenă.
mode: parallel
max: 5

fields:
  target_entity:
    name: Entitate lumină
    description: Lumina care se aprinde
    required: true
    selector:
      entity:
        domain: light
    example: light.living_ceiling

  brightness_level:
    name: Luminozitate
    description: Intensitate lumină, 1–100%
    required: false
    default: 100
    selector:
      number:
        min: 1
        max: 100
        unit_of_measurement: "%"
    example: 80

  color_temp_kelvin:
    name: Temperatură culoare
    description: Temperatura în Kelvin — 2200 (caldă/portocaliu) până la 6500 (rece/alb)
    required: false
    default: 4000
    selector:
      number:
        min: 2200
        max: 6500
        unit_of_measurement: K
    example: 4000

sequence:
  - alias: Aprinde lumina la valorile specificate
    action: light.turn_on
    target:
      entity_id: "{{ target_entity }}"
    data:
      brightness_pct: "{{ brightness_level | default(100) }}"
      color_temp_kelvin: "{{ color_temp_kelvin | default(4000) }}"
```

> **Regulă:** dacă scriptul e apelat din UI (buton, dashboard), adaugă `description:` la fiecare câmp — HA le afișează ca tooltip. Dacă e apelat exclusiv din YAML, `description:` e opțional dar recomandat pentru documentare.

---

## Pași (Steps / Sequence)

Cel mai important aspect al acestui skill. Fiecare pas dintr-o automatizare sau script are un câmp `alias:` — acesta e singurul lucru pe care îl vede utilizatorul în interfață și în jurnalul de rulări (trace).

### Regula de aur

**Alias-ul unui pas = ce face, în română, fără cod.**

Cineva care vede jurnalul de erori nu ar trebui să deschidă YAML-ul ca să înțeleagă unde a eșuat automatizarea.

### Format

```
Verb + ce + [unde] + [la ce valoare / condiție]
```

- **Verb la imperativ** — același verb pe care l-ai folosi dacă i-ai da o instrucțiune unui om.
- **Ce** — device-ul sau entitatea, în română, fără entity_id.
- **Unde** — camera, dacă ajută la claritate.
- **Valoare / condiție** — parametrul relevant (`la 30%`, `la 21°C`, `dacă e seară`).

### Vocabular pentru verbe

| Situație                          | Verb recomandat                              |
| --------------------------------- | -------------------------------------------- |
| Pornire lumină / priză / switch   | `Aprinde`, `Pornește`                        |
| Oprire lumină / priză / switch    | `Stinge`, `Oprește`                          |
| Setare valoare numerică           | `Setează`                                    |
| Schimbare mod / scenă             | `Activează`, `Schimbă`                       |
| Trimitere notificare              | `Trimite notificare`, `Alertează`            |
| Anunț vocal (TTS)                 | `Anunță pe boxă`, `Spune`                    |
| Așteptare timp                    | `Așteaptă`                                   |
| Așteptare condiție                | `Așteaptă până când`                         |
| Verificare condiție (if/choose)   | `Dacă`, `Verifică dacă`                      |
| Deschidere / închidere acoperire  | `Deschide`, `Închide`, `Setează poziția`     |
| Armare / dezarmare alarmă         | `Armează alarma`, `Dezarmează alarma`        |
| Declanșare alt script             | `Rulează scriptul`                           |
| Declanșare scenă                  | `Activează scena`                            |
| Blocare / deblocare yală          | `Blochează`, `Deblochează`                   |
| Reîncărcare / restart             | `Repornește`                                 |
| Înregistrare / logare             | `Înregistrează în jurnal`                    |

### Pași de acțiune (actions)

```yaml
- alias: Aprinde lumina din baie la 10%
  action: light.turn_on
  target:
    entity_id: light.baie1_ceiling
  data:
    brightness_pct: 10

- alias: Setează termostatul din dormitor la 21°C
  action: climate.set_temperature
  target:
    entity_id: climate.dormitor1_thermostat
  data:
    temperature: 21

- alias: Trimite notificare — ușa garajului e deschisă
  action: notify.mobile_app_telefon_andrei
  data:
    message: Ușa garajului este deschisă de mai mult de 10 minute.
    title: Atenție garaj

- alias: Anunță pe boxă din living — lumina se stinge
  action: tts.speak
  target:
    entity_id: media_player.living_boxa
  data:
    message: Lumina din living se stinge în 1 minut.

- alias: Așteaptă 5 minute
  delay: "00:05:00"

- alias: Așteaptă până când nu mai e nimeni în baie
  wait_for_trigger:
    - trigger: state
      entity_id: binary_sensor.baie1_presence
      to: "off"

- alias: Închide jaluzelele din dormitor #1
  action: cover.close_cover
  target:
    entity_id: cover.dormitor1_blinds

- alias: Armează alarma — mod Plecat
  action: alarm_control_panel.alarm_arm_away
  target:
    entity_id: alarm_control_panel.alarma_casa

- alias: Activează scena Film în living
  action: scene.turn_on
  target:
    entity_id: scene.living_film

- alias: Rulează scriptul Plecare din casă
  action: script.plecare_din_casa
```

### Pași de condiție (conditions ca pași în secvență)

Când o condiție oprește execuția secvenței dacă nu e îndeplinită:

```yaml
- alias: Continuă doar dacă e după ora 22:00
  condition: time
  after: "22:00:00"

- alias: Continuă doar dacă cineva e acasă
  condition: state
  entity_id: group.persoane_acasa
  state: "home"

- alias: Continuă doar dacă lumina nu e deja aprinsă
  condition: state
  entity_id: light.living_ceiling
  state: "off"

- alias: Continuă doar dacă temperatura e sub 20°C
  condition: numeric_state
  entity_id: sensor.dormitor1_temperature
  below: 20
```

### Ramificații — `choose` (dacă/altfel)

Alias pe blocul `choose`, pe fiecare `option` și, opțional, pe `default`:

```yaml
- alias: Alege intensitatea luminii în funcție de oră
  choose:
    - alias: Dacă e noapte (22:00–07:00) — aprinde la 10%
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
    - alias: Dacă e zi — aprinde la 100%
      conditions:
        - condition: time
          after: "07:00:00"
          before: "22:00:00"
      sequence:
        - alias: Aprinde lumina din baie la 100%
          action: light.turn_on
          target:
            entity_id: light.baie1_ceiling
          data:
            brightness_pct: 100
  default:
    - alias: Aprinde lumina din baie la 50% (fallback)
      action: light.turn_on
      target:
        entity_id: light.baie1_ceiling
      data:
        brightness_pct: 50
```

### Variabile reutilizabile — `variables:`

Folosește `variables:` ca pas în secvență pentru a calcula o valoare o singură dată și a o referenția mai jos. Util când aceeași expresie apare în mai mulți pași.

```yaml
sequence:
  - alias: Calculează intensitatea pe baza orei
    variables:
      target_brightness: >
        {% if now().hour >= 22 or now().hour < 7 %}10{% else %}100{% endif %}
      target_temp_k: >
        {% if now().hour >= 22 or now().hour < 7 %}2700{% else %}4000{% endif %}

  - alias: Aprinde plafoniera la valorile calculate
    action: light.turn_on
    target:
      entity_id: light.dormitor1_ceiling
    data:
      brightness_pct: "{{ target_brightness }}"
      color_temp_kelvin: "{{ target_temp_k }}"

  - alias: Aprinde lampa de noptieră cu aceleași valori
    action: light.turn_on
    target:
      entity_id: light.dormitor1_bedside_left
    data:
      brightness_pct: "{{ target_brightness }}"
      color_temp_kelvin: "{{ target_temp_k }}"
```

> **`variables:` la nivel top-level** (frate cu `sequence:`) — variabilele sunt vizibile în toată secvența.
> **`variables:` ca pas** — variabilele sunt vizibile doar în pașii care urmează.

### Repetare — `repeat`

```yaml
- alias: Trimite alertă de 3 ori la interval de 1 minut
  repeat:
    count: 3
    sequence:
      - alias: Trimite notificare — mișcare detectată în curte
        action: notify.mobile_app_telefon_andrei
        data:
          message: Mișcare detectată în curte!
      - alias: Așteaptă 1 minut înainte de alertă următoare
        delay: "00:01:00"
```

### Declanșatoare descrise în `description`

Triggerele nu au câmp `alias` în HA, dar le descrii în `description`-ul automatizării:

| Tip trigger              | Cum îl descrii în description                                  |
| ------------------------ | -------------------------------------------------------------- |
| Stare entitate           | „Se declanșează când senzorul de mișcare detectează mișcare"   |
| Numeric state            | „Se declanșează când puterea depășește 4 kW"                   |
| Timp fix                 | „Se declanșează în fiecare zi la ora 07:00"                    |
| Apus / răsărit           | „Se declanșează la 15 minute după apusul soarelui"             |
| Template                 | „Se declanșează când temperatura resimțită scade sub 0°C"      |
| Webhook / MQTT           | „Se declanșează la apăsarea butonului fizic din dormitor"      |
| Geo (zone)               | „Se declanșează când telefonul Andrei intră în zona Casă"      |

---

**TL;DR:** Script: `Verb + context` imperativ — `Stinge toate luminile`. Fields: slug EN, `name:` RO, `required:` + `default:` + `selector:`. Pas alias: `Verb + ce + unde + valoare` — `Aprinde lumina din baie la 10%`. Condiție: `Continuă doar dacă [condiție]`. Choose: alias pe bloc + pe fiecare opțiune.