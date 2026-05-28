---
name: ha-entities
description: Vocabular entity names HA (120+ termeni RO, 13 categorii), device_class recomandate, format entity ID `<domain>.<slug_camera>_<function>`, dezactivare entități post-import.
---

# Entități — Home Assistant

## Entity Names — Friendly Name (în Română)

### ⛔ Regulă obligatorie: prefix `[Area] Nume dispozitiv -` în friendly_name

**Fiecare entitate** (sensor, binary_sensor, switch, light, sub-funcție, statistic, diagnostic — fără excepție) trebuie să aibă `friendly_name` explicit setat în formatul de mai jos. Nu te baza pe `has_entity_name: True` pentru auto-concatenare — multe view-uri din HA (statistici, notificări, dropdown-uri, log filters, logbook, energy dashboard, voice assistants) afișează **doar `friendly_name`-ul entității**, fără device-ul de care aparține. Fără prefix obții liste imposibil de citit (`Procent CPU`, `Procent CPU`, `Procent CPU`, …).

### Format canonic

```
[Area] Nume dispozitiv - <Funcție>
```

Reguli stricte:
- `[Area]` între paranteze drepte exact ca în device name (vezi `ha-devices-areas.md#device-names`).
- `Nume dispozitiv` = restul device name-ului, fără paranteze (`Shelly Pro 3EM`, `Aqara FP2`, `Synology DS920+`).
- ` - ` (spațiu, liniuță, spațiu) ca separator între device și funcție.
- `<Funcție>` din vocabularul standard de mai jos (capitalizare pe primul cuvânt, diacritice corecte).
- Pentru **entitatea principală** a unui device (un singur switch/light/sensor): `friendly_name = [Area] Nume dispozitiv` (fără ` - <Funcție>`).

### Cum aplici prefixul (3 căi posibile)

1. **UI Settings → Devices & services → click entitate → Friendly name override** — cel mai rapid pentru entități auto-create. HA salvează override-ul în `core.entity_registry`.
2. **`customize:` în `configuration.yaml`** — pentru bulk renames sau când vrei să ții denumirile sub control git.
   ```yaml
   homeassistant:
     customize:
       sensor.synology_cpu_percent:
         friendly_name: "[Server] Synology DS920+ - Procent CPU"
   ```
3. **Template sensor / MQTT cu `has_entity_name: false` + `name:` explicit** — pentru entități create în YAML.
   ```yaml
   template:
     - sensor:
         - name: "[Cameră Tehnică] Shelly Pro 3EM - Putere totală"
           unique_id: tech_room_shelly_pro_3em_total_power
           state: "{{ states('sensor.shelly_pro_3em_a_power') | float + ... }}"
   ```

`has_entity_name: True` poate rămâne setat pe device-ul integrat, dar **override-ul de `friendly_name` are întâietate** la afișare — deci nu vei vedea dublare.

### Vocabular standard (doar partea `<Funcție>`)

Tabelele de mai jos listează **doar funcția** — partea care urmează după ` - ` în friendly_name. Combină-le obligatoriu cu prefixul `[Area] Nume dispozitiv -`.

Fiecare tabel conține trei coloane:
- **Funcție (RO)** — partea după ` - ` din friendly_name (vizibilă în UI)
- **Entity ID slug (EN)** — ce folosești în `<function>` din entity_id (vezi secțiunea Entity IDs)
- **Detaliu** — unitate de măsură, context, integrări

**Caută mai întâi în listele de mai jos.** Dacă funcția nu se regăsește, folosești un termen descriptiv nou în română — documentează-l în `change_log`.

> **Abrevieri tehnice** (CO2, TVOC, PM2.5, RSSI, pH etc.) rămân neschimbate în ambele coloane — sunt termeni universali.

---

#### Energie & Electric

| Funcție (RO)             | Entity ID slug (EN)     | Detaliu                                              |
| ------------------------ | ----------------------- | ---------------------------------------------------- |
| `Putere`                 | `power`                 | W, kW                                                |
| `Energie`                | `energy`                | kWh, Wh                                              |
| `Energie returnată`      | `energy_returned`       | kWh — invertere solare, prosumatori                  |
| `Tensiune`               | `voltage`               | V                                                    |
| `Curent`                 | `current`               | A                                                    |
| `Frecvență`              | `frequency`             | Hz                                                   |
| `Factor de putere`       | `power_factor`          | 0.0–1.0                                              |
| `Putere aparentă`        | `apparent_power`        | VA, kVA                                              |
| `Putere reactivă`        | `reactive_power`        | VAR, kVAR                                            |
| `Putere fază A`          | `phase_a_power`         | înlocuiește `a` cu `b` / `c` pentru celelalte faze   |
| `Energie fază A`         | `phase_a_energy`        | idem                                                 |
| `Tensiune fază A`        | `phase_a_voltage`       | idem                                                 |
| `Curent fază A`          | `phase_a_current`       | idem                                                 |
| `Putere canal 1`         | `channel_1_power`       | relee dual (Shelly 2PM etc.); înlocuiește `1` cu `2` |
| `Energie canal 1`        | `channel_1_energy`      | idem                                                 |
| `Putere totală`          | `total_power`           | sumă canale / faze                                   |
| `Energie totală`         | `total_energy`          | sumă canale / faze                                   |

---

#### Climat & Mediu Interior

| Funcție (RO)             | Entity ID slug (EN)     | Detaliu                                              |
| ------------------------ | ----------------------- | ---------------------------------------------------- |
| `Temperatură`            | `temperature`           | °C                                                   |
| `Temperatură țintă`      | `target_temperature`    | setpoint termostat                                   |
| `Temperatură apă`        | `water_temperature`     | boiler, circuit termic                               |
| `Temperatură suprafață`  | `surface_temperature`   | senzor de contact pe țeavă                          |
| `Umiditate`              | `humidity`              | %                                                    |
| `Umiditate țintă`        | `target_humidity`       | setpoint umidificator                                |
| `Punct de rouă`          | `dew_point`             | °C                                                   |
| `Temperatură resimțită`  | `feels_like`            | °C — heat index + wind chill combinat                |
| `Indice de căldură`      | `heat_index`            | °C — temperatură + umiditate                         |
| `Răceală vânt`           | `wind_chill`            | °C — temperatură + vânt                              |
| `Presiune`               | `pressure`              | hPa                                                  |
| `Umiditate sol`          | `moisture`              | % — senzori sol, plante                              |

---

#### Iluminare & Radiație

| Funcție (RO)             | Entity ID slug (EN)     | Detaliu                                              |
| ------------------------ | ----------------------- | ---------------------------------------------------- |
| `Iluminare`              | `illuminance`           | lx — fotoresistență, BH1750                          |
| `Iradianță`              | `irradiance`            | W/m² — piranometru, stații meteo                     |
| `Indice UV`              | `uv_index`              | 0–11+ — stații meteo, Ecowitt                        |
| `Temperatură culoare`    | `color_temperature`     | K — dacă expusă ca senzor separat                    |

---

#### Mișcare, Prezență & Ocupare

| Funcție (RO)             | Entity ID slug (EN)     | Detaliu                                              |
| ------------------------ | ----------------------- | ---------------------------------------------------- |
| `Mișcare`                | `motion`                | binary — orice PIR standard                          |
| `Mișcare persoană`       | `person_motion`         | AI camera (Reolink, Frigate)                         |
| `Mișcare vehicul`        | `vehicle_motion`        | AI camera                                            |
| `Mișcare animal`         | `animal_motion`         | AI camera                                            |
| `Prezență`               | `presence`              | binary — Aqara FP2, EP1, Tuya mmWave                 |
| `Ocupare`                | `occupancy`             | binary — când integrarea diferențiază de Prezență    |
| `Activitate`             | `activity`              | binary — generic, când niciunul de mai sus nu se potrivește |

---

#### Securitate & Acces

| Funcție (RO)             | Entity ID slug (EN)     | Detaliu                                              |
| ------------------------ | ----------------------- | ---------------------------------------------------- |
| `Contact`                | `contact`               | binary — senzor magnetic ușă/fereastră               |
| `Ușă`                    | `door`                  | binary — device class `door`                         |
| `Fereastră`              | `window`                | binary — device class `window`                       |
| `Blocat`                 | `lock`                  | entitate `lock` domain                               |
| `Alarmă`                 | `alarm`                 | binary — sirenă, panel alarmă                        |
| `Vibrație`               | `vibration`             | binary — Aqara Vibration, Xiaomi                     |
| `Geam spart`             | `glass_break`           | binary — senzor audio                                |
| `Manipulare`             | `tamper`                | binary — capac deschis, tamper detectat              |
| `Sabotaj`                | `sabotage`              | sinonim Manipulare, folosit de unele integrări Zigbee |
| `Acces`                  | `access`                | binary — keypad, card reader                         |

---

#### Apă, Scurgeri & Irigație

| Funcție (RO)             | Entity ID slug (EN)     | Detaliu                                              |
| ------------------------ | ----------------------- | ---------------------------------------------------- |
| `Scurgere`               | `leak`                  | binary — water leak puck                             |
| `Inundație`              | `flooding`              | binary — sinonim Scurgere, device class `moisture`   |
| `Debit apă`              | `water_flow`            | L/min, m³/h                                          |
| `Consum apă`             | `water_consumption`     | L, m³                                                |
| `Presiune apă`           | `water_pressure`        | bar, PSI                                             |
| `Nivel apă`              | `water_level`           | %, cm — cisternă, rezervor                           |
| `Ploaie`                 | `rain`                  | mm — total acumulat                                  |
| `Intensitate ploaie`     | `rain_rate`             | mm/h                                                 |

---

#### Calitate Aer & Gaze

| Funcție (RO)             | Entity ID slug (EN)     | Detaliu                                              |
| ------------------------ | ----------------------- | ---------------------------------------------------- |
| `CO2`                    | `co2`                   | ppm — Aqara TVOC, SCD40, Aranet4                     |
| `CO`                     | `co`                    | ppm — detector monoxid de carbon                     |
| `TVOC`                   | `tvoc`                  | ppb, µg/m³ — Aqara TVOC, Awair                       |
| `Calitate aer`           | `air_quality`           | AQI 0–500 — când integrarea expune AQI generic       |
| `PM1`                    | `pm1`                   | µg/m³                                                |
| `PM2.5`                  | `pm25`                  | µg/m³ — IKEA VINDRIKTNING, Dyson, Awair              |
| `PM10`                   | `pm10`                  | µg/m³                                                |
| `Ozon`                   | `ozone`                 | ppb                                                  |
| `NO2`                    | `no2`                   | ppb — dioxid de azot                                 |
| `SO2`                    | `so2`                   | ppb — dioxid de sulf                                 |
| `Radon`                  | `radon`                 | Bq/m³ — Airthings                                    |
| `Formaldehidă`           | `formaldehyde`          | µg/m³ — Aqara TVOC v2, Airthings                     |
| `Gaz`                    | `gas`                   | ppm — detector gaz natural / metan                   |
| `pH`                     | `ph`                    | 0–14 — senzori acvariu, piscină                      |

---

#### Baterie & Semnal

| Funcție (RO)             | Entity ID slug (EN)     | Detaliu                                              |
| ------------------------ | ----------------------- | ---------------------------------------------------- |
| `Baterie`                | `battery`               | % — senzor principal                                 |
| `Tensiune baterie`       | `battery_voltage`       | V — dezactivează dacă există `Baterie` ca %          |
| `Încărcare baterie`      | `battery_charging`      | binary — On/Off                                      |
| `Putere semnal`          | `signal_strength`       | dBm — WiFi / Zigbee                                  |
| `RSSI`                   | `rssi`                  | dBm — alternativ la `Putere semnal`                  |
| `Calitate semnal`        | `link_quality`          | 0–255 LQI — ZHA, Z2M; de obicei dezactivat           |
| `Timp funcționare`       | `uptime`                | ore, zile — routere, servere                         |

---

#### Rețea & Conectivitate

| Funcție (RO)             | Entity ID slug (EN)     | Detaliu                                              |
| ------------------------ | ----------------------- | ---------------------------------------------------- |
| `Conectat`               | `connected`             | binary — device online/offline                       |
| `Viteză descărcare`      | `download_speed`        | Mbps                                                 |
| `Viteză încărcare`       | `upload_speed`          | Mbps                                                 |
| `Latență`                | `latency`               | ms                                                   |
| `Trafic descărcat`       | `download_traffic`      | GB — total pe interfață                              |
| `Trafic urcat`           | `upload_traffic`        | GB                                                   |
| `SSID`                   | `ssid`                  | text — rețeaua WiFi; de obicei dezactivat            |
| `Adresă IP`              | `ip_address`            | text; de obicei dezactivat                           |

---

#### Acoperiri Mecanice (Cover)

| Funcție (RO)             | Entity ID slug (EN)     | Detaliu                                              |
| ------------------------ | ----------------------- | ---------------------------------------------------- |
| *(None)*                 | —                       | entitatea cover principală — moștenește device name  |
| `Poziție`                | `position`              | 0–100% — dacă expusă separat ca senzor               |
| `Înclinare`              | `tilt`                  | 0–100% — jaluzele cu lamele orientabile              |

---

#### Solar & Energie Verde

| Funcție (RO)             | Entity ID slug (EN)     | Detaliu                                              |
| ------------------------ | ----------------------- | ---------------------------------------------------- |
| `Putere PV`              | `pv_power`              | W, kW — producție instantanee panouri solare         |
| `Energie PV`             | `pv_energy`             | kWh — total produs                                   |
| `Putere rețea`           | `grid_power`            | W — putere luată din rețea                           |
| `Energie rețea`          | `grid_energy`           | kWh — energie importată                              |
| `Energie exportată`      | `grid_energy_returned`  | kWh — returnată în rețea                             |
| `Tensiune rețea`         | `grid_voltage`          | V                                                    |
| `Frecvență rețea`        | `grid_frequency`        | Hz                                                   |
| `Putere inverter`        | `inverter_power`        | W                                                    |
| `Temperatură inverter`   | `inverter_temperature`  | °C                                                   |
| `Stare inverter`         | `inverter_status`       | text/enum                                            |
| `Iradianță`              | `irradiance`            | W/m²                                                 |

---

#### Stocare Energie (Baterie de casă) & EV

| Funcție (RO)             | Entity ID slug (EN)     | Detaliu                                              |
| ------------------------ | ----------------------- | ---------------------------------------------------- |
| `Nivel încărcare`        | `state_of_charge`       | % — baterie stocare (Powerwall, LUNA) sau EV         |
| `Autonomie`              | `range`                 | km — EV                                              |
| `Putere încărcare`       | `charging_power`        | kW                                                   |
| `Putere descărcare`      | `discharging_power`     | kW                                                   |
| `Energie stocată`        | `stored_energy`         | kWh                                                  |
| `Temperatură baterie`    | `battery_temperature`   | °C                                                   |
| `Stare baterie`          | `battery_status`        | text — Charging / Discharging / Idle                 |
| `Curent încărcare`       | `charging_current`      | A — stație EV                                        |
| `Timp încărcare`         | `charging_time`         | min, ore                                             |
| `Stare stație`           | `charger_status`        | text — Available / Charging / Unavailable            |
| `Energie sesiune`        | `session_energy`        | kWh — energia în sesiunea curentă de încărcare EV   |

---

#### Meteo (Stație externă)

| Funcție (RO)             | Entity ID slug (EN)     | Detaliu                                              |
| ------------------------ | ----------------------- | ---------------------------------------------------- |
| `Viteză vânt`            | `wind_speed`            | m/s, km/h                                            |
| `Rafală vânt`            | `wind_gust`             | m/s                                                  |
| `Direcție vânt`          | `wind_direction`        | grade (0–360)                                        |
| `Vizibilitate`           | `visibility`            | km                                                   |
| `Ploaie`                 | `rain`                  | mm — total acumulat                                  |
| `Intensitate ploaie`     | `rain_rate`             | mm/h                                                 |
| `Presiune nivel mării`   | `sea_level_pressure`    | hPa — corectat la nivel mării                        |
| `Temperatură`            | `temperature`           | °C — stația meteo, device name indică locația        |
| `Temperatură interior`   | `indoor_temperature`    | °C — unele stații expun și senzorul interior         |

---

#### Electrocasnice & Stare Aparate

| Funcție (RO)             | Entity ID slug (EN)     | Detaliu                                              |
| ------------------------ | ----------------------- | ---------------------------------------------------- |
| `Stare`                  | `status`                | text/enum — Running / Idle / Finished / Error        |
| `Mod`                    | `mode`                  | text/enum — Eco / Bumbac / Rapid etc.                |
| `Timp rămas`             | `remaining_time`        | min                                                  |
| `Temperatură program`    | `wash_temperature`      | °C — mașină de spălat                                |
| `Turație`                | `spin_speed`            | rpm                                                  |
| `Nivel murdărie`         | `soil_level`            | text/enum                                            |
| `Ciclu`                  | `cycle`                 | text/enum                                            |
| `Eroare`                 | `error`                 | text/enum sau binary                                 |
| `Ușă blocată`            | `door_lock`             | binary — ușa mașinii de spălat                      |
| `Energie`                | `energy`                | kWh — via priză monitorizată                         |

---

#### Multimedia & AV

| Funcție (RO)             | Entity ID slug (EN)     | Detaliu                                              |
| ------------------------ | ----------------------- | ---------------------------------------------------- |
| *(None)*                 | —                       | entitatea `media_player` principală                  |
| `Volum`                  | `volume`                | 0–100% — dacă expus separat                          |
| `Mut`                    | `mute`                  | binary                                               |
| `Sursă`                  | `source`                | text/enum — intrare selectată                        |

---

#### Diverse / Utility

| Funcție (RO)             | Entity ID slug (EN)     | Detaliu                                              |
| ------------------------ | ----------------------- | ---------------------------------------------------- |
| *(None)*                 | —                       | entitatea principală — moștenește device name        |
| `Funcționează`           | `running`               | binary — aspirator robot, pompă, circuit             |
| `Problemă`               | `problem`               | binary — stare de eroare generică                    |
| `Actualizare disponibilă`| `update_available`      | binary — firmware update                             |
| `Versiune firmware`      | `firmware_version`      | text; de obicei dezactivat                           |
| `Distanță`               | `distance`              | m, cm — senzori ultrasonic, LiDAR                    |
| `Viteză`                 | `speed`                 | km/h, m/s — trackere GPS, vehicule                  |
| `Cost`                   | `cost`                  | RON, EUR — energie, apă                              |
| `Durată`                 | `duration`              | min, s                                               |
| `Contor`                 | `count`                 | integer — număr cicluri, pași                        |
| `Canal 1`                | `channel_1`             | releu multi-canal fără funcție definită clar         |

---

### Exemple complete (friendly_name explicit)

`friendly_name` setat explicit pe entitate, cu prefix `[Area] Nume dispozitiv -`:

| Device                                | Funcție                 | friendly_name                                                  |
| ------------------------------------- | ----------------------- | -------------------------------------------------------------- |
| `[Cameră Tehnică] Shelly Pro 3EM`     | `Putere fază A`         | `[Cameră Tehnică] Shelly Pro 3EM - Putere fază A`              |
| `[Cameră Tehnică] Shelly Pro 3EM`     | `Energie totală`        | `[Cameră Tehnică] Shelly Pro 3EM - Energie totală`             |
| `[Dormitor #1] IKEA TRÅDFRI E27`      | *(principal)*           | `[Dormitor #1] IKEA TRÅDFRI E27`                               |
| `[Baie #1] Aqara FP2`                 | `Prezență`              | `[Baie #1] Aqara FP2 - Prezență`                               |
| `[Baie #1] Aqara FP2`                 | `Iluminare`             | `[Baie #1] Aqara FP2 - Iluminare`                              |
| `[Curte] Reolink RLC-823A`            | `Mișcare persoană`      | `[Curte] Reolink RLC-823A - Mișcare persoană`                  |
| `[Dormitor #1] Aqara T1`              | `Punct de rouă`         | `[Dormitor #1] Aqara T1 - Punct de rouă`                       |
| `[Acoperiș] Ecowitt GW2000`           | `Viteză vânt`           | `[Acoperiș] Ecowitt GW2000 - Viteză vânt`                      |
| `[Acoperiș] Ecowitt GW2000`           | `Intensitate ploaie`    | `[Acoperiș] Ecowitt GW2000 - Intensitate ploaie`               |
| `[Cameră Tehnică] Huawei SUN2000`     | `Putere PV`             | `[Cameră Tehnică] Huawei SUN2000 - Putere PV`                  |
| `[Garaj] go-eCharger HOME+`           | `Putere încărcare`      | `[Garaj] go-eCharger HOME+ - Putere încărcare`                 |
| `[Bucătărie] Bosch WAU28U00BY`        | `Timp rămas`            | `[Bucătărie] Bosch WAU28U00BY - Timp rămas`                    |
| `[Server] Synology DS920+`            | `Procent CPU`           | `[Server] Synology DS920+ - Procent CPU`                       |
| `[Server] Synology DS920+`            | `Cea mai nouă versiune` | `[Server] Synology DS920+ - Cea mai nouă versiune`             |

### Device classes recomandate

`device_class` permite HA să formateze valoarea corect, să aleagă iconițe potrivite și să integreze în Energy Dashboard / Long-term statistics. Setează-l pe template sensors și pe orice entitate fără device_class auto-detectat.

| Funcție (RO)       | Domain          | `device_class`     | Cu `state_class`         |
| ------------------ | --------------- | ------------------ | ------------------------ |
| `Putere`           | `sensor`        | `power`            | `measurement`            |
| `Energie`          | `sensor`        | `energy`           | `total_increasing`       |
| `Tensiune`         | `sensor`        | `voltage`          | `measurement`            |
| `Curent`           | `sensor`        | `current`          | `measurement`            |
| `Frecvență`        | `sensor`        | `frequency`        | `measurement`            |
| `Temperatură`      | `sensor`        | `temperature`      | `measurement`            |
| `Umiditate`        | `sensor`        | `humidity`         | `measurement`            |
| `Presiune`         | `sensor`        | `pressure`         | `measurement`            |
| `Iluminare`        | `sensor`        | `illuminance`      | `measurement`            |
| `CO2`              | `sensor`        | `carbon_dioxide`   | `measurement`            |
| `PM2.5`            | `sensor`        | `pm25`             | `measurement`            |
| `Baterie`          | `sensor`        | `battery`          | `measurement`            |
| `Putere semnal`    | `sensor`        | `signal_strength`  | `measurement`            |
| `Distanță`         | `sensor`        | `distance`         | `measurement`            |
| `Viteză vânt`      | `sensor`        | `wind_speed`       | `measurement`            |
| `Ploaie` (total)   | `sensor`        | `precipitation`    | `total_increasing`       |
| `Mișcare`          | `binary_sensor` | `motion`           | —                        |
| `Prezență`         | `binary_sensor` | `occupancy`        | —                        |
| `Contact / Ușă`    | `binary_sensor` | `door` / `window`  | —                        |
| `Scurgere`         | `binary_sensor` | `moisture`         | —                        |
| `Fum`              | `binary_sensor` | `smoke`            | —                        |
| `Gaz`              | `binary_sensor` | `gas`              | —                        |
| `Vibrație`         | `binary_sensor` | `vibration`        | —                        |
| `Sabotaj`          | `binary_sensor` | `tamper`           | —                        |
| `Conectat`         | `binary_sensor` | `connectivity`     | —                        |
| `Încărcare baterie`| `binary_sensor` | `battery_charging` | —                        |
| `Problemă`         | `binary_sensor` | `problem`          | —                        |
| `Actualizare disp.`| `binary_sensor` | `update`           | —                        |

> **Important pentru Energy Dashboard:** un senzor de energie are nevoie de `device_class: energy` + `state_class: total_increasing` (sau `total`) + `unit_of_measurement: kWh` pentru a apărea ca sursă selectabilă.

### Reguli pentru friendly_name

- **friendly_name începe ÎNTOTDEAUNA cu `[Area] Nume dispozitiv -`** — fără excepție, indiferent că entitatea e auto-creată, template, MQTT, statistic sau diagnostic. Vezi secțiunea de format canonic de mai sus.
- **Caută funcția în vocabularul de mai sus.** Folosește termenul exact din coloana *Funcție (RO)* — majusculă pe primul cuvânt, diacritice corecte.
- **Dacă funcția nu există în niciun tabel**, folosești un termen descriptiv nou în română. Documentează-l în `change_log` la `summary`.
- **Abrevieri tehnice** (CO2, TVOC, PM2.5, RSSI, pH, SSID) se păstrează neschimbate — sunt termeni universali.
- **Pentru relee/canale numerotate fără funcție clară:** `Canal 1`, `Canal 2`. Dacă funcția e clară, folosește-o direct (`Lumină tavan`, `Bandă LED TV`).
- **Pentru entitatea "principală" a device-ului** (un singur switch/light/sensor), `friendly_name = [Area] Nume dispozitiv` (fără ` - <Funcție>`).
- **Nu pune unități de măsură** în nume (`W`, `°C`, `lux`) — sunt deja la state.
- **Nu repeta domeniul** în funcție (`light.living_ceiling` cu device `[Living] IKEA TRÅDFRI E27` → friendly_name `[Living] IKEA TRÅDFRI E27`, fără `- Lumină`).
- **Verifică listele "fără context"** după redenumire: deschide Developer Tools → Statistics și Settings → Devices → orice device atins; toate entitățile trebuie să apară cu prefix complet.

---

## Entity IDs

### Format canonic

```
<domain>.<slug_camera>_<function>[_<detail>]
```

**Fără brand, fără model.** Dacă schimbi Shelly cu Sonoff, entity_id rămâne valid.

- `<slug_camera>` — în română (`living`, `dormitor1`, `tehnica`), match cu Area.
- `<function>` — în engleză, lowercase (`power`, `motion`, `temperature`).
- `<detail>` — opțional, în engleză (`tv_socket`, `bedside_left`, `phase_a`).

### Exemple

```
light.dormitor1_ceiling
light.dormitor1_bedside_left
light.dormitor1_bedside_right
light.living_tv_led

switch.curte_irrigation_pump
switch.garaj_door_actuator
switch.bucatarie_hood

sensor.tehnica_phase_a_power
sensor.tehnica_phase_a_energy
sensor.tehnica_phase_a_voltage
sensor.tehnica_total_power
sensor.living_tv_socket_power

binary_sensor.baie1_presence
binary_sensor.baie2_presence
binary_sensor.dormitor1_window_contact
binary_sensor.curte_person_motion
binary_sensor.curte_vehicle_motion

climate.dormitor1_thermostat
climate.living_ac

cover.dormitor1_blinds
cover.garaj_door

camera.curte_main
camera.curte_garage
```

### Excepție permisă

Dacă într-o cameră ai **mai multe device-uri cu aceeași funcție** (ex: 3 prize monitorizate în Living), adaugă disambiguator descriptiv în engleză — NU brandul:

```
sensor.living_tv_socket_power
sensor.living_desk_socket_power
sensor.living_aquarium_socket_power
```

### Reguli stricte

- Doar `[a-z0-9_]`. Fără diacritice, fără cratime, fără spații.
- Începe cu `<slug_camera>` (vezi tabelul din Areas).
- Nu repeta domeniul în slug (`light.living_lamp_x` → `light.living_x` dacă e clar).
- Nu schimba entity_id-uri existente fără să verifici automatizările/dashboard-urile — folosește **friendly name** pentru cosmetică, **entity_id** doar când chiar trebuie (vezi `ha-refactoring.md`).

---

## Post-redenumire: dezactivare entități + verificare referințe

După orice redenumire sau adăugare de device, sunt două sarcini obligatorii care **previn ulterior probleme** (clutter în UI, automatizări sparte, recorder-ul aglomerat cu date inutile).

### Dezactivează entitățile auto-create pe care nu le folosești

Multe integrări creează **zeci** de entități per device — multe sunt diagnostic sau redundante. Lasă-le active doar pe cele de care chiar te folosești.

**Cum:** UI → **Settings → Devices & Services → [Device] → entitate → ⚙️ → Enabled (toggle off)**. Sau bulk: select multiple entități → Disable.

**Candidați frecvenți pentru dezactivare:**

| Categorie                | Exemple concrete                                                                       | Motiv                                    |
| ------------------------ | -------------------------------------------------------------------------------------- | ---------------------------------------- |
| Diagnostic rețea         | `linkquality` (Zigbee), `rssi` (WiFi), `lqi`, `signal_strength`                        | Folosești-le doar dacă debug-ezi rețeaua |
| Versiuni firmware        | `firmware_version`, `sw_version`, `update_available` (păstrează update_available util) | Nu sunt utile day-to-day                 |
| Timestamps               | `last_seen`, `last_updated`, `last_reset`                                              | Rar consultate, încarcă recorder         |
| Battery voltage          | `battery_voltage` (când există `battery` ca procent)                                   | Procentul e suficient                    |
| Configurări per-canal    | Per-channel power factor, per-channel frequency dacă urmărești doar totalul            | Reduce zgomot vizual                     |
| Eventuri raw buton       | `action_press`, `action_double_press` (dacă device class îi expune frumos)             | Folosești doar event-uri standardizate   |
| Cloud-specific           | `cloud_connected`, `last_reboot_reason` pentru integrări cloud                         | Nu impactează automatizările locale      |

**Reguli:**

- **NU dezactiva** o entitate referențiată în automatizări / dashboards / scripts — verifică întâi.
- **NU șterge** entitățile — doar le dezactivezi (toggle Enabled). Pot fi reactivate oricând.
- **Marchează în `inventory.yaml`** entitățile dezactivate cu `enabled: false`:
  ```yaml
  entities:
    - entity_id: sensor.tehnica_linkquality
      name: "Link quality"
      enabled: false
  ```

### Verifică automatizări, scripturi, scene, grupuri și helpers

După orice redenumire de **entity_id**, toate referințele de mai jos trebuie auditate. Friendly name și device name se schimbă fără impact, dar `entity_id` e cheia tehnică folosită peste tot. Procedura completă în `ha-refactoring.md`.

**Locuri de verificat (în ordinea probabilității):**

| Locație                              | Cum verifici                                                                     |
| ------------------------------------ | -------------------------------------------------------------------------------- |
| Automations (UI + YAML)              | Settings → Automations & Scenes → search după entity_id vechi sau nou            |
| Scripts                              | Settings → Automations & Scenes → Scripts → search                               |
| Scenes                               | Settings → Automations & Scenes → Scenes → search                                |
| Groups                               | `configuration.yaml` / `groups.yaml`                                              |
| Helpers (input_*, counter, timer)    | Settings → Devices & Services → Helpers → check entitățile referite în scripturi |
| Dashboards (Lovelace)                | Search în UI sau `.storage/lovelace*` și fișiere YAML                            |
| Template sensors / binary_sensors    | `configuration.yaml`, `templates.yaml`, `template:` blocks                       |
| `customize.yaml` / `customize:`      | Override-uri vechi pe entity_id                                                  |
| Notify / shell_command / rest_command| Referințe pe entity sau friendly_name în payload                                 |
| Integrări externe                    | Node-RED flows, AppDaemon apps, Grafana panels, InfluxDB queries                 |

**Tooling:**

```bash
# Caută referințe la un entity_id în /config
grep -rn "sensor.shellypro3em_84cca8b5xxxx_a_act_power" /config/

# Sau în repo Git separat dacă ții configul versionat
git grep "sensor.vechi_id"
```

**Feature util în HA UI:** la redenumirea unui entity_id, HA propune să actualizeze automat referințele în automations/scripts/scenes/groups. **Acceptă opțiunea** — economisește 90% din muncă. Restul (template-uri, integrări externe) rămân de verificat manual.

---

**TL;DR:** Entity name (friendly name) în română din coloana *Entity name (RO)*. Dacă termenul nu există, creezi unul descriptiv în română și îl documentezi în `change_log`. Abrevieri tehnice (CO2, TVOC, RSSI) rămân neschimbate. Entity ID: `<domain>.<slug_camera>_<function>[_<detail>]` — slug cameră în română, restul în engleză. Fără brand. Post-redenumire: (1) dezactivează entitățile nefolosite; (2) verifică automations, scripts, scenes, groups, helpers, dashboards, templates.
