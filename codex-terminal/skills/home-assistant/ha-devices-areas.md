---
name: ha-devices-areas
description: Areas, labels (90+), format device names `[Cameră] Producător Model`, workflow device nou, schema inventory.yaml. Citește când adaugi/redenumești device-uri, arii sau actualizezi inventarul.
---

# Device-uri, Areas și Inventar — Home Assistant

## Areas

Sunt deja configurate. Lista canonică:

| Area Name      | Slug intern (pentru entity_id) | Iconă recomandată |
| -------------- | ------------------------------ | ----------------- |
| Living         | `living`                       | `mdi:sofa`        |
| Bucătărie      | `bucatarie`                    | `mdi:fridge`      |
| Dormitor #1    | `dormitor1`                    | `mdi:bed`         |
| Baie #1        | `baie1`                        | `mdi:shower-head` |
| Dormitor #2    | `dormitor2`                    | `mdi:bed`         |
| Baie #2        | `baie2`                        | `mdi:toilet`      |
| Cameră Tehnică | `tehnica`                      | `mdi:server`      |
| Curte          | `curte`                        | `mdi:tree`        |
| Garaj          | `garaj`                        | `mdi:garage`      |
| Acoperiș       | `acoperis`                     | `mdi:home-roof`   |
| Sistem         | `sistem`                       | `mdi:home-assistant` |
| Rețea          | `retea`                        | `mdi:lan`         |

> **Notă:** păstrează `#1`/`#2` în Area name (citibil), dar slug-ul intern devine `dormitor1` / `baie2`. Slug-ul rămâne în română (match cu Area), restul entity_id-ului e în engleză — e singurul punct de "tranziție" lingvistică în convenție.
>
> **Sistem și Rețea** sunt pseudo-arii pentru device-uri/entități fără cameră fizică (echipamente rețea, hub-uri, integrări cloud, template-uri/helpers globale).

---

## Labels

Labels-urile sunt categorisire **ortogonală** Area-urilor — răspund la întrebarea *"ce TIP de device e?"* indiferent de cameră. Permit filtrare rapidă în UI (`label:Senzor Mișcare` → vezi toate PIR-urile din casă), sortare în dashboarduri și grupare în automatizări.

### Regula de aur

**Folosește un label existent din lista de mai jos.** Un label nou se poate crea **DOAR dacă nu există deja unul potrivit în listă**. Când creezi un label nou:

1. Verifică încă o dată că nu există un sinonim (`Cameră Video` vs `Cameră Supraveghere` — folosește pe cel din listă).
2. Adaugi noul label aici, în această secțiune, în categoria potrivită.
3. Îl adaugi în `inventory.yaml` la `labels:` (cu name, slug, category, icon).
4. Documentezi motivația în `change_log` din `inventory.yaml`.

> Scopul: evităm proliferarea de label-uri (5 sinonime pentru aceeași noțiune anulează valoarea labels-urilor și fac filtrarea inutilă).

### Reguli format

- **Numele label-ului:** capitalizare pe fiecare cuvânt de conținut (`Aer Condiționat`, `Senzor Mișcare`, `Mașină Spălat Vase`).
- **Diacritice:** permise în numele afișat.
- **Slug:** lowercase ASCII, underscore-separated (`aer_conditionat`, `senzor_miscare`, `masina_spalat_vase`).
- **Un label primar per device.** Mai multe label-uri **doar** când device-ul are funcții cu adevărat distincte — ex: un Shelly 2PM care alimentează DOI consumatori diferiți (rar); sau un releu folosit ca atare + monitorizare consum (`Întrerupător` + `Contor`).

### Lista canonică

#### Control Electric & Iluminat

| Label          | Slug             | Icon                       | Exemple device                            |
| -------------- | ---------------- | -------------------------- | ----------------------------------------- |
| Lumină         | `lumina`         | `mdi:lightbulb`            | Bec, bandă LED, spot, plafonieră smart    |
| Întrerupător   | `intrerupator`   | `mdi:toggle-switch`        | Releu Shelly 1PM, Sonoff în spatele întrerupătorului |
| Comutator      | `comutator`      | `mdi:gesture-double-tap`   | Buton de perete cu scene (Aqara H1, Shelly Wall) |
| Buton          | `buton`          | `mdi:gesture-tap-button`   | Buton wireless (Aqara Wireless Mini, IKEA STYRBAR) |
| Priză          | `priza`          | `mdi:power-socket-eu`      | Smart plug, prelungitor inteligent        |

#### Climatizare

| Label                | Slug                  | Icon                          | Exemple                                  |
| -------------------- | --------------------- | ----------------------------- | ---------------------------------------- |
| Termostat            | `termostat`           | `mdi:thermostat`              | Nest, Tado, Sonoff TRVZB controller      |
| Calorifer            | `calorifer`           | `mdi:radiator`                | TRV (valvă termostatică) — Aqara, Sonoff |
| Aer Condiționat      | `aer_conditionat`     | `mdi:air-conditioner`         | Split / mini-split via Daikin, Sensibo   |
| Ventilator           | `ventilator`          | `mdi:fan`                     | Fan standalone                           |
| Ventilator Tavan     | `ventilator_tavan`    | `mdi:ceiling-fan`             | Ceiling fan smart                        |
| Purificator Aer      | `purificator_aer`     | `mdi:air-purifier`            | Xiaomi, Dyson Pure                       |
| Umidificator         | `umidificator`        | `mdi:air-humidifier`          | Xiaomi Smartmi, Levoit                   |
| Dezumidificator      | `dezumidificator`     | `mdi:air-humidifier-off`      | Trotec, Meaco                            |
| Recuperator Căldură  | `recuperator_caldura` | `mdi:hvac`                    | HRV/ERV (recuperator de aer)             |

#### Încălzire & Apă Caldă

| Label             | Slug              | Icon                | Exemple                                |
| ----------------- | ----------------- | ------------------- | -------------------------------------- |
| Boiler            | `boiler`          | `mdi:water-boiler`  | Boiler electric / termoelectric        |
| Pompă Căldură     | `pompa_caldura`   | `mdi:heat-pump`     | Daikin Altherma, Mitsubishi Ecodan     |
| Centrală Termică  | `centrala_termica`| `mdi:gas-burner`    | Centrală pe gaz (Vaillant, Viessmann)  |

#### Energie

| Label                 | Slug                 | Icon                        | Exemple                              |
| --------------------- | -------------------- | --------------------------- | ------------------------------------ |
| Contor                | `contor`             | `mdi:meter-electric`        | Shelly Pro 3EM, P1 monitor, Iammeter |
| Inverter Solar        | `inverter_solar`     | `mdi:solar-power`           | SolarEdge, Huawei, Growatt           |
| Baterie Stocare       | `baterie_stocare`    | `mdi:battery-charging-high` | Tesla Powerwall, Huawei LUNA, Pylontech |
| Stație Încărcare EV   | `statie_incarcare_ev`| `mdi:ev-station`            | go-eCharger, Wallbox, Tesla Wall Connector |

#### Securitate & Acces

| Label              | Slug                 | Icon                  | Exemple                                |
| ------------------ | -------------------- | --------------------- | -------------------------------------- |
| Yală               | `yala`               | `mdi:lock-smart`      | Aqara U200, Nuki, Yale Linus           |
| Sonerie            | `sonerie`            | `mdi:doorbell-video`  | Aqara G4, Reolink, Ring                |
| Cameră Supraveghere| `camera_supraveghere`| `mdi:cctv`            | Reolink, UniFi Protect, Frigate        |
| Sirenă             | `sirena`             | `mdi:alarm-bell`      | Aqara Hub built-in, Bosch outdoor      |
| Alarmă             | `alarma`             | `mdi:shield-home`     | Sistem central de alarmă               |
| Keypad             | `keypad`             | `mdi:dialpad`         | Aqara S100, NFC entry pad              |

#### Acționare Mecanică

| Label              | Slug                | Icon                          | Exemple                              |
| ------------------ | ------------------- | ----------------------------- | ------------------------------------ |
| Jaluzele           | `jaluzele`          | `mdi:blinds-horizontal`       | Aqara Roller Blind, Soma             |
| Storuri            | `storuri`           | `mdi:roller-shade`            | Storuri exterioare motorizate        |
| Cortină            | `cortina`           | `mdi:curtains`                | Aqara Curtain Driver, SwitchBot      |
| Ușă Garaj          | `usa_garaj`         | `mdi:garage-variant`          | Shelly 2PM cu actuator, MyQ          |
| Poartă             | `poarta`            | `mdi:gate`                    | Motor poartă batantă / culisantă     |
| Acționare Geam     | `actionare_geam`    | `mdi:window-open-variant`     | Window opener motorizat              |

#### Apă & Irigație

| Label         | Slug            | Icon                     | Exemple                            |
| ------------- | --------------- | ------------------------ | ---------------------------------- |
| Robinet Apă   | `robinet_apa`   | `mdi:water-pump`         | Valvă electromecanică shut-off     |
| Pompă         | `pompa`         | `mdi:pump`               | Pompă fântână, pompă circulație    |
| Irigație      | `irigatie`      | `mdi:sprinkler-variant`  | Rachio, Hunter Hydrawise, OpenSprinkler |

#### Senzori

| Label              | Slug                | Icon                            | Exemple                              |
| ------------------ | ------------------- | ------------------------------- | ------------------------------------ |
| Senzor Mișcare     | `senzor_miscare`    | `mdi:motion-sensor`             | PIR Aqara, IKEA TRÅDFRI motion       |
| Senzor Prezență    | `senzor_prezenta`   | `mdi:human-greeting-variant`    | Aqara FP2, EP1, Tuya mmWave          |
| Senzor Climat      | `senzor_climat`     | `mdi:thermometer-water`         | Aqara T1 (temp+umid+presiune)        |
| Senzor Temperatură | `senzor_temperatura`| `mdi:thermometer`               | Sonoff TH16, DS18B20                 |
| Senzor Umiditate   | `senzor_umiditate`  | `mdi:water-percent`             | Sensor doar pentru umiditate         |
| Senzor Lumină      | `senzor_lumina`     | `mdi:brightness-6`              | Aqara T1 illuminance, BH1750         |
| Senzor Calitate Aer| `senzor_aer`        | `mdi:air-filter`                | Aqara TVOC, IKEA VINDRIKTNING, Awair |
| Senzor Fum         | `senzor_fum`        | `mdi:smoke-detector-variant`    | Heiman, Aqara smoke                  |
| Senzor Monoxid     | `senzor_monoxid`    | `mdi:molecule-co`               | CO detector                          |
| Senzor Gaz         | `senzor_gaz`        | `mdi:gas-cylinder`              | Natural gas leak detector            |
| Senzor Apă         | `senzor_apa`        | `mdi:water-alert`               | Water leak puck (Aqara T1, Heiman)   |
| Senzor Contact     | `senzor_contact`    | `mdi:door-open`                 | Door/window magnetic contact         |
| Senzor Vibrație    | `senzor_vibratie`   | `mdi:vibrate`                   | Aqara Vibration, Xiaomi Mi Vibration |
| Senzor Sol         | `senzor_sol`        | `mdi:sprout`                    | Soil moisture (Ecowitt, Xiaomi)      |
| Senzor Ploaie      | `senzor_ploaie`     | `mdi:weather-rainy`             | Rain gauge                           |
| Senzor Geam Spart  | `senzor_geam_spart` | `mdi:image-broken-variant`      | Glass break sensor                   |
| Stație Meteo       | `statie_meteo`      | `mdi:weather-partly-cloudy`     | Ecowitt GW2000, Davis Vantage        |

#### Electrocasnice

| Label              | Slug               | Icon                          | Exemple                            |
| ------------------ | ------------------ | ----------------------------- | ---------------------------------- |
| Aspirator Robot    | `aspirator_robot`  | `mdi:robot-vacuum`            | Roborock, Roomba, Dreame, Xiaomi   |
| Mașină Spălat      | `masina_spalat`    | `mdi:washing-machine`         | LG ThinQ, Bosch Home Connect       |
| Uscător            | `uscator`          | `mdi:tumble-dryer`            | Heat pump dryer cu API             |
| Mașină Spălat Vase | `masina_spalat_vase`| `mdi:dishwasher`             | Bosch, Miele                       |
| Frigider           | `frigider`         | `mdi:fridge`                  | Samsung Family Hub, LG ThinQ       |
| Cuptor             | `cuptor`           | `mdi:stove`                   | Bosch, Miele oven                  |
| Cuptor Microunde   | `cuptor_microunde` | `mdi:microwave`               | Microwave cu conectivitate         |
| Plită              | `plita`            | `mdi:induction`               | Plită inducție smart               |
| Hotă               | `hota`             | `mdi:range-hood`              | Hotă cu integrare HA               |
| Cafetieră          | `cafetiera`        | `mdi:coffee-maker`            | DeLonghi, Jura, Philips LatteGo    |

#### Multimedia

| Label          | Slug             | Icon                         | Exemple                            |
| -------------- | ---------------- | ---------------------------- | ---------------------------------- |
| Televizor      | `televizor`      | `mdi:television`             | LG WebOS, Samsung Tizen, Android TV |
| Boxă           | `boxa`           | `mdi:speaker`                | Sonos, HomePod, Echo, Google Nest  |
| Soundbar       | `soundbar`       | `mdi:speaker-multiple`       | Sonos Beam, Samsung Q-series       |
| Receiver AV    | `receiver_av`    | `mdi:audio-video`            | Denon, Marantz, Yamaha             |
| Streaming Box  | `streaming_box`  | `mdi:apple-tv`               | Apple TV, Chromecast, Fire TV      |
| Proiector      | `proiector`      | `mdi:projector`              | Epson, Optoma, BenQ                |

#### Rețea & IT

| Label          | Slug            | Icon                              | Exemple                            |
| -------------- | --------------- | --------------------------------- | ---------------------------------- |
| Router         | `router`        | `mdi:router-wireless`             | UniFi UDM, Mikrotik, OPNsense      |
| Switch Rețea   | `switch_retea`  | `mdi:switch`                      | UniFi USW, Netgear ProSafe         |
| Access Point   | `access_point`  | `mdi:access-point-network`        | UniFi U6, Aruba Instant On         |
| Modem          | `modem`         | `mdi:router`                      | DOCSIS, fiber ONT                  |
| Gateway        | `gateway`       | `mdi:hubspot`                     | Z2M coordinator, ConBee, Sonoff ZBDongle |
| Repetor Zigbee | `repetor_zigbee`| `mdi:zigbee`                      | Routere Zigbee (priză smart-routed)|
| NAS            | `nas`           | `mdi:nas`                         | Synology, QNAP, TrueNAS            |
| Server         | `server`        | `mdi:server`                      | HA Yellow, Proxmox host, mini PC   |
| UPS            | `ups`           | `mdi:power-plug-battery`          | APC, CyberPower, Eaton             |

#### Asistenți & Hub-uri

| Label             | Slug                | Icon                            | Exemple                            |
| ----------------- | ------------------- | ------------------------------- | ---------------------------------- |
| Asistent Vocal    | `asistent_vocal`    | `mdi:microphone-message`        | Alexa, Google Home, HomePod        |
| Display Inteligent| `display_inteligent`| `mdi:tablet`                    | Echo Show, Nest Hub                |
| Hub               | `hub`               | `mdi:home-assistant`            | Aqara M2/M3, Hue Bridge, SmartThings |

#### Animale de Companie

| Label             | Slug              | Icon                       | Exemple                            |
| ----------------- | ----------------- | -------------------------- | ---------------------------------- |
| Hrănitor          | `hranitor`        | `mdi:dog-side`             | PetKit, Petlibro feeder            |
| Adăpător          | `adapator`        | `mdi:water-pump`           | Petlibro fountain, Petkit Eversweet|
| Litieră Automată  | `litiera_automata`| `mdi:cat`                  | Litter-Robot, PetKit Pura Max      |

#### Exterior & Diverse

| Label             | Slug              | Icon                       | Exemple                            |
| ----------------- | ----------------- | -------------------------- | ---------------------------------- |
| Robot Tuns Iarba  | `robot_iarba`     | `mdi:robot-mower`          | Husqvarna Automower, Worx Landroid |
| Acvariu           | `acvariu`         | `mdi:fishbowl`             | Fluval, Eheim controllers          |

#### Tracking & Personal

| Label    | Slug      | Icon                       | Exemple                              |
| -------- | --------- | -------------------------- | ------------------------------------ |
| Telefon  | `telefon` | `mdi:cellphone`            | iPhone, Android (via Companion app)  |
| Wearable | `wearable`| `mdi:watch-variant`        | Apple Watch, Garmin, Fitbit          |
| Tracker  | `tracker` | `mdi:crosshairs-gps`       | AirTag, Tile, Mi Tag                 |
| Cântar   | `cantar`  | `mdi:scale-bathroom`       | Withings Body+, Eufy Smart Scale     |

### Cum atribui labels

În UI: **Settings → Devices & Services → [Device] → ⋮ → Manage labels**.
În YAML (custom integrations): nu se setează label-uri din YAML, doar din UI sau via REST API.
În `inventory.yaml`: câmpul `labels:` al device-ului — listă de slug-uri (vezi Secțiunea Inventar).

---

## Areas pentru entități orfane

Orice entitate creată din `template:`, `helpers`, sau `script:` ar trebui asignată unei Area. Pentru lucruri globale folosește pseudo-ariile (vezi tabelul Areas):

- `Sistem` — consumuri agregate, statistici HA, integrări cloud (`sensor.sistem_total_power`)
- `Rețea` — echipamente UniFi, switch-uri, AP-uri (`sensor.retea_internet_speed`)

---

## Device Names

### Format canonic

```
[Cameră] Producător Model [#N]
```

Trei componente, în ordine:

- `[Cameră]` — exact numele Area-ului, în paranteze drepte. Sortează vizual lista de devices pe camere.
- `Producător Model` — așa cum scrie producătorul oficial (`Shelly Pro 3EM`, nu `shelly pro 3em`).
- `#N` — sufix doar dacă există **mai multe device-uri identice în aceeași cameră** (același producător + model).

Funcția device-ului **NU** intră în device name. Tipul e descris de Label, iar funcția specifică e implicit în entity_id (ex: `light.living_ceiling` vs `light.living_tv_led`) și opțional în câmpul `notes` din `inventory.yaml`.

### Exemple

```
[Living] Shelly Pro 3EM
[Living] Aqara FP2
[Living] Sonoff ZBMINI #1
[Living] Sonoff ZBMINI #2
[Dormitor #1] IKEA TRÅDFRI E27
[Dormitor #1] Aqara T1
[Baie #1] Shelly 1PM Mini
[Cameră Tehnică] Shelly Pro 3EM
[Cameră Tehnică] UniFi UDM Pro
[Curte] Reolink RLC-823A
[Garaj] Shelly 2PM
[Acoperiș] Ecowitt GW2000
```

### De ce paranteze drepte pentru cameră

- `[Living]` se sortează grupat (toate `[L...]` ajung împreună alfabetic).
- E vizual distinctiv în UI și în liste de notificări/loguri.
- Slash-ul `/` se confundă cu separator de path; cratima `-` se folosește deja în multe nume de model (`RLC-823A`).

### Dezambiguare multipli device-uri identice

Când `#N` nu e suficient pentru a-ți aminti rolul fiecărui device:

- **Folosește `notes` în `inventory.yaml`** — descrie ce face fiecare (`"Sonoff ZBMINI #1: plafonieră Living"`).
- **Entity_id-urile sunt descriptive** — `light.living_ceiling` și `light.living_tv_led` îți spun imediat care e care.
- **Label-urile diferă** dacă funcția e cu adevărat diferită — un Sonoff folosit pentru lumină ia `Lumină`+`Întrerupător`, unul pentru hotă ia doar `Întrerupător`.

### Dispozitive fără cameră fizică

Echipamente de rețea, hub-uri, integrări cloud — folosește `[Rețea]` sau `[Sistem]` ca pseudo-area:

```
[Rețea] UniFi USW-Pro-24-PoE
[Rețea] UniFi U6 Pro #1
[Rețea] UniFi U6 Pro #2
[Sistem] Home Assistant Yellow
[Sistem] Zigbee2MQTT
```

---

## Cheat sheet — adăugare device nou

Când adaugi un device nou, parcurge în ordine:

1. **Citește `inventory.yaml`** pentru a vedea ce există deja (evită duplicări, găsește următorul `#N`, vezi ce labels sunt deja folosite).
2. **Adaugă device-ul în area corectă** (din lista canonică de mai sus).
3. **Setează device name:** `[Area] Producător Model [#N]`.
4. **Atribuie label-ul de tip** (din lista canonică). Dacă niciun label existent nu se potrivește, creează unul nou și actualizează lista + `labels:` din inventory.
5. **Pentru fiecare entitate setează `friendly_name` explicit cu prefix `[Area] Nume dispozitiv - <Funcție>`** (vezi `ha-entities.md` pentru format complet și vocabularul de funcții):
   - entitatea principală a device-ului → `friendly_name = [Area] Nume dispozitiv` (fără ` - <Funcție>`)
   - sub-funcție → `friendly_name = [Area] Nume dispozitiv - <Funcție>` cu funcția în română din vocabular
   - regula se aplică indiferent dacă integrarea respectă `has_entity_name` sau nu — UI-ul afișează `friendly_name`-ul explicit în multe view-uri unde device-ul nu apare deloc (statistici, dropdown-uri, log filters, notificări)
6. **Verifică entity_id-urile:** dacă au sufixe random (`_a1b2c3`), redenumește la `<slug_camera>_<function>`.
7. **Pentru bulk renames sau control prin git**, folosește `customize:` în `configuration.yaml` în loc de UI rename (vezi `ha-entities.md` secțiunea "Cum aplici prefixul").
8. **Dezactivează entitățile auto-create pe care nu le folosești** (vezi `ha-entities.md` secțiunea dezactivare).
9. **Dacă device-ul înlocuiește unul existent sau ai schimbat entity_id-uri:** verifică automatizările, scripturile, scenele, grupurile și helpers (vezi `ha-refactoring.md`).
10. **Actualizează `inventory.yaml`** cu device-ul nou, entitățile și labels-urile lui (vezi secțiunea Inventar de mai jos).

---

## Cazuri speciale frecvente

### Shelly cu mai multe faze/canale (energy meter)

```
Device: [Cameră Tehnică] Shelly Pro 3EM
Labels: [Contor]
Entities:
  - "Putere fază A"     → sensor.tehnica_phase_a_power
  - "Tensiune fază A"   → sensor.tehnica_phase_a_voltage
  - "Curent fază A"     → sensor.tehnica_phase_a_current
  - "Energie fază A"    → sensor.tehnica_phase_a_energy
  - "Putere totală"     → sensor.tehnica_total_power
Disabled (post-import): linkquality, last_reboot, ssid, rssi
```

### Lumini cu mai multe canale (releu dublu)

```
Device: [Living] Shelly 2PM
Labels: [Întrerupător, Lumină]
Entities:
  - "Canal 1"   → light.living_ceiling    (sau "Lumină tavan" dacă funcția e clară)
  - "Canal 2"   → light.living_tv_led     (sau "Bandă LED TV")
Notes: "Canal 1 = plafonieră, Canal 2 = bandă LED zona TV"
```

> Dacă știi exact ce controlează fiecare canal, folosește funcția direct în entity_id (`ceiling`, `tv_led`) și entity name-ul descriptiv în română (`Lumină tavan`, `Bandă LED TV`); altfel păstrează `Canal 1/2` și descrie în notes.

### Senzor multi-funcție (Aqara, multi-sensor)

```
Device: [Dormitor #1] Aqara T1
Labels: [Senzor Climat]
Entities:
  - "Temperatură"   → sensor.dormitor1_temperature
  - "Umiditate"     → sensor.dormitor1_humidity
  - "Presiune"      → sensor.dormitor1_pressure
  - "Baterie"       → sensor.dormitor1_climate_battery  (sufix "climate" doar dacă ai >1 senzor)
Disabled: linkquality, voltage (battery e suficient)
```

### Camere video

```
Device: [Curte] Reolink RLC-823A
Labels: [Cameră Supraveghere]
Entities:
  - (None)              → camera.curte_main
  - "Mișcare persoană"  → binary_sensor.curte_person_motion
  - "Mișcare vehicul"   → binary_sensor.curte_vehicle_motion
  - (None)              → light.curte_spotlight
Disabled: pet_motion (nu ai animale outdoor), AI face detection (folosești doar person/vehicle)
```

---

## Inventar Persistent — `inventory.yaml`

**Acesta e fișierul-cheie pentru memoria AI-ului între sesiuni.** După fiecare set de redenumiri, claude actualizează acest fișier. Înainte de o nouă sesiune, claude îl citește pentru a ști ce există deja.

### Locație

`inventory.yaml` trăiește în rădăcina repo-ului de skills, alături de fișierele `ha-*.md`.

### Workflow (obligatoriu)

1. **Înainte de redenumire:** citește `inventory.yaml` ca să afli starea curentă (devices, labels disponibile, slug-uri).
2. **În timpul sesiunii:** ține o listă mentală cu fiecare device atins (device_name vechi → nou, identifier, integration, labels, entități atinse, entități dezactivate).
3. **La final, înainte de a închide sesiunea cu utilizatorul:**
   - adaugă/actualizează entry-urile în `devices:`
   - marchează `enabled: false` pe entitățile dezactivate
   - dacă a fost necesar un label nou, adaugă-l în `labels:` și în secțiunea Labels din acest fișier
   - adaugă o intrare în `change_log:` cu data, titlul sesiunii, lista de devices atinse, entități dezactivate, referințe actualizate (automations/scripts/scenes/groups/helpers), un sumar de 1-3 fraze
   - bumpează `last_updated` la data curentă
   - validează YAML-ul (`yq` sau `python3 -c "import yaml; yaml.safe_load(open('inventory.yaml'))"`)

### Schema

```yaml
schema_version: 3
last_updated: "2026-05-28"

# Lista canonică de area-uri.
areas:
  - name: Living
    slug: living
  # ... (toate area-urile din secțiunea Areas)

# Lista canonică de labels — match cu secțiunea Labels.
labels:
  - name: Lumină
    slug: lumina
    category: "Control Electric & Iluminat"
    icon: "mdi:lightbulb"
  # ... (toate labels-urile din secțiunea Labels)

# Toate device-urile din casă. O intrare per device fizic.
devices:
  - device_name: "[Cameră Tehnică] Shelly Pro 3EM"
    area: "Cameră Tehnică"
    manufacturer: Shelly
    model: "Pro 3EM"
    identifier: "84CCA8B5XXXX"
    integration: shelly
    labels: [contor]                                # slugi din labels:
    notes: "Tablou electric principal, 3 faze + neutru"
    renamed_at: "2026-05-28"
    previous_name: "shellypro3em-84cca8b5xxxx"
    entities:
      - entity_id: sensor.tehnica_phase_a_power
        name: "Putere fază A"
        previous_entity_id: "sensor.shellypro3em_84cca8b5xxxx_a_act_power"
      - entity_id: sensor.tehnica_phase_a_energy
        name: "Energie fază A"
        previous_entity_id: "sensor.shellypro3em_84cca8b5xxxx_a_total_energy"
      - entity_id: sensor.tehnica_linkquality
        name: "Calitate semnal"
        enabled: false                              # dezactivat post-import

# Device-uri eliminate fizic — păstrate pentru istoric.
archived_devices: []

# Append-only log al sesiunilor de redenumire.
change_log:
  - date: "2026-05-28"
    session: "Initial rollout convenție pe tabloul principal"
    devices_touched:
      - "[Cameră Tehnică] Shelly Pro 3EM"
    labels_added: []
    entities_disabled:
      - sensor.tehnica_linkquality
    references_updated:
      automations: 2
      scripts: 1
      scenes: 0
      groups: 0
      helpers: 0
      dashboards: 1
    summary: "Aplicat convenția pe Shelly 3EM; 8 entități redenumite, 1 dezactivată; 2 automatizări + 1 script + 1 dashboard actualizate."
```

### Reguli pentru `inventory.yaml`

- **Niciodată nu ștergi entries** din `devices:` decât dacă device-ul e fizic eliminat (mută-l în `archived_devices:`).
- **`change_log` e append-only** — adaugi mereu la final, nu modifici intrările vechi.
- **`labels` la nivel de device** = listă de slug-uri (nu nume). Toate slug-urile trebuie să existe în `labels:` top-level.
- **`enabled: false`** pe entități = au fost dezactivate post-import; lipsa câmpului = activă (default).
- **`previous_name` și `previous_entity_id`** — string unic (nu listă) — păstrează doar valoarea anterioară imediată. Istoricul complet trăiește în `change_log:` (append-only).
- **`identifier`** (MAC, serial, IEEE address) e esențial pentru device-uri identice — fără el nu poți distinge `Sonoff ZBMINI #1` de `#2`.
- **Ordine în `devices:`** — alfabetic după `device_name`.
- **Ordine în `labels:`** — grupate pe `category`, alfabetic în interiorul categoriei.

### Migrarea unui inventar existent

Când redenumești ce există deja:

1. **Backup la `.storage/`** înainte de modificări mari (`cp -r /config/.storage /config/.storage_backup_YYYY-MM-DD`).
2. **Începe cu device names** — efectul se propagă automat la friendly names dacă entitățile au `has_entity_name: True`.
3. **Atribuie labels-urile** după ce device-urile au nume final — în UI poți selecta multiple device-uri și atribui label-ul în masă.
4. **Folosește feature-ul "Rename entity ID" din UI** — îți oferă opțiunea de a actualiza referințele automat în automations/scripts/scenes/groups/helpers/dashboards. **Acceptă opțiunea.**
5. **Verifică ce a scăpat de update-ul automat** (template:, integrări externe, customize.yaml) — vezi `ha-refactoring.md`.
6. **Scoate brand-ul din entity_id, lasă-l în device name** — modificare structurală riscantă; o singură dată, complet.
7. **NU schimba slug-ul de cameră** după ce e folosit în automatizări fără search&replace complet.
8. **Dezactivează entitățile nefolosite** pentru fiecare device atins (vezi `ha-entities.md`).
9. **După fiecare batch de redenumiri, scrie în `inventory.yaml`** — nu lăsa pe "la sfârșit", e ușor să pierzi context. Marchează în `change_log` câte automations/scripts/etc. ai actualizat.

---

**TL;DR:** Areas sunt fixe — slug în română (`living`, `dormitor1`). Labels din lista canonică — NU creezi label nou dacă există sinonim. Un label primar per device; mai multe doar dacă funcțiile sunt cu adevărat distincte. Device name: `[Cameră] Producător Model [#N]` — brand/model în scriere oficială, fără funcție. Citește `inventory.yaml` înainte de orice sesiune. Actualizează la final: `devices:` + `labels:` + entități dezactivate + intrare nouă în `change_log`.
