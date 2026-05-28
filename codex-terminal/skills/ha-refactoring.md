---
name: ha-refactoring
description: Refactorizare sigură HA — workflow 5 pași, sibling discovery, Config-Entry-Groups, Config-Entry-Data (blind spots), storage dashboards, integrări YAML-only. Citește ÎNTÂI când redenumești sau restructurezi configurație existentă.
---

# Refactorizare Sigură — Home Assistant

Refactorizările în HA sunt probleme de cross-reference. Orice schimbare la un entity_id sau la o structură de automatizare poate rupe silențios componente care o referențiează.

## Regula de bază

**Caută toți consumatorii ÎNAINTE de a schimba ceva. Verifică zero referințe stale DUPĂ.**

Backup: stochează toate fișierele de backup sub `/data/safe-edit-backups`. Nu plasa backup-uri lângă fișierele sursă din `/config`.

---

## Workflow universal (5 pași)

### Pasul 1 — Identifică scopul complet al schimbării

Răspunde la trei întrebări înainte de a atinge orice:

1. **Ce se schimbă?** Entity ID, structura automatizării, tipul senzorului, semantica trigger-ului.
2. **Ce entități sibling partajează același device?** Fă un query pe device pentru a lista toate entitățile pe care le deține (senzor baterie, update entity, diagnostic button). Planifică schimbările pentru toți siblings împreună.
   - Via REST API: `GET /api/states/<entity_id>` sau inspectează **Settings → Devices**.
3. **Redenumești o entitate sau toate entitățile device-ului?** Device-urile grupează 2–6 entități. Dacă redenumești entitatea principală dar lași siblings cu schema de denumire veche, creezi inconsistență.

### Pasul 2 — Caută TOȚI consumatorii

Caută în fiecare tip de componentă care poate referenția entity IDs. Nu limita căutarea doar la componenta pe care o editezi.

| Componentă | Cum cauți |
|---|---|
| Automatizări | Via HA API sau `grep automations.yaml` |
| Dashboards | Via HA API sau `grep -r .storage/lovelace* ui-lovelace.yaml` |
| Scripturi | `grep scripts.yaml` |
| Scene | `grep scenes.yaml` |
| Grupuri UI (Config-Entry) | `GET /api/config/config_entries/entry?type=config&domain=group` — membrii în `options.entities`; redenumirile din entity registry NU le actualizează automat (→ vezi secțiunea Config-Entry-Groups) |
| Integrări Config-Entry (Better Thermostat, Generic Thermostat, Generic Hygrostat, Threshold Helper, Min/Max Helper) | `GET /api/config/config_entries/entry` — scanează câmpurile `data` și `options` pentru entity ID-ul vechi; redenumirile NU actualizează aceste câmpuri automat (→ vezi secțiunea Config-Entry-Data) |
| Altele | AppDaemon apps, Node-RED flows, Pyscript scripts, orice integrare custom |

Înregistrează fiecare locație găsită — această listă devine checklistul de actualizare pentru Pasul 4.

### Pasul 3 — Fă schimbarea

Redenumește entitatea, înlocuiește template sensor-ul, sau restructurează automatizarea.

### Pasul 4 — Actualizează fiecare consumator

Parcurge fiecare locație din checklistul tău din Pasul 2. Actualizează fiecare referință la noul entity ID, noul helper, sau noua structură de automatizare.

### Pasul 5 — Verifică

1. **Caută IDENTIFICATORUL VECHI** în toate tipurile de componente. Așteptate: zero rezultate.
2. **Caută IDENTIFICATORUL NOU** pentru a confirma că toate locațiile așteptate îl referențiează.
3. **Reîncarcă sau verifică dashboards** dacă s-au schimbat entity ID-uri.
4. **Dacă rămân referințe stale pe care nu le poți actualiza** — redenumește entitatea înapoi la ID-ul original pentru a restabili funcționalitatea, apoi raportează locațiile blocante utilizatorului.

---

## Redenumire entități

Cerințe adiționale față de workflow-ul universal:

### Descoperire siblings (Pasul 1)

HA grupează mai multe entități într-un singur device. Un smart plug poate expune `switch.*`, `sensor.*_energy` și `update.*`. Un multi-sensor expune motion, temperature, illuminance și battery. Redenumește toți siblings pentru a fi consistenți.

Exemplu — redenumire smart plug din default-uri de producător la nume bazate pe cameră:

| Domeniu | Entity ID vechi | Entity ID nou |
|---|---|---|
| `switch` | `switch.shellyplug_s_a1b2c3d4e5f6` | `switch.birou_radiator` |
| `sensor` | `sensor.shellyplug_s_a1b2c3d4e5f6_energy` | `sensor.birou_radiator_energy` |
| `update` | `update.shellyplug_s_a1b2c3d4e5f6` | `update.birou_radiator` |

### Locații de referință în dashboards (Pasul 2)

Cardurile din dashboard referențiează entități în mai multe locuri — caută în toate acestea:

- câmpul `entity:`
- `tap_action` și `hold_action` targets
- condiții ale cardurilor `conditional`
- blocuri Jinja2 în template cards
- `views[n].badges` — badge-urile sunt sibling-uri ale array-ului de carduri, nu copii — o căutare focalizată pe carduri le va rata; caută întotdeauna întreaga configurație de dashboard
- `views[n].header.card` — doar în sections view (HA 2025.3+); header-ul acceptă un Markdown card cu Jinja2 și poate conține referințe la entități; este sibling al array-ului de carduri și nu e accesibil printr-o căutare focalizată pe carduri

### Feature util în HA UI

La redenumirea unui entity ID din UI, HA propune să actualizeze automat referințele în automations/scripts/scenes/groups. **Acceptă opțiunea** — economisește ~90% din muncă. Restul (template-uri, Config-Entry-Groups, Config-Entry-Data, storage dashboards, integrări externe) rămâne de verificat manual.

---

## Înlocuire helpers (template sensor → helper built-in)

Când înlocuiești un template sensor cu un helper nativ (`min_max`, `threshold`, `derivative`):

**Nou entity ID (Pasul 1):**
Helper-ul creează o entitate nouă cu un entity_id diferit. Vechiul entity_id al template sensor-ului dispare. Actualizează fiecare consumator al entity_id-ului vechi.

**Verificare echivalență (Pasul 5):**
Verifică că noul helper produce aceleași valori ca vechiul template sensor. Compară unitățile, precizia și comportamentul la stări `unavailable`.

---

## Restructurare triggers

Când convertești triggers `device_id` → `entity_id` sau înlocuiești `wait_template` cu `wait_for_trigger`:

**Echivalență comportamentală (Pasul 1):**
`wait_for_trigger` așteaptă o **schimbare** de stare; `wait_template` face polling pe **starea curentă**. Diferă când starea target e deja `true` la momentul pornirii: `wait_for_trigger` blochează nedefinit, `wait_template` returnează imediat.

**Callers ai automatizării (Pasul 2):**
Caută scripturi sau alte automatizări care apelează automatizarea restructurată via `automation.trigger` sau `automation.turn_on`. Redenumirea sau împărțirea unei automatizări îi schimbă entity_id-ul și strică acești callers.

---

## Config-Entry-Groups

Când redenumești entități care sunt membre ale unui **grup creat din UI** (Config-Entry-based group, platform: `group`):

**Redenumirile din entity registry NU actualizează automat membrii grupului.**

Entity ID-urile membrilor grupului sunt stocate în `options.entities` al Config Entry-ului grupului — nu în entity registry. O redenumire din registry lasă grupul referențiind entity ID-ul vechi (acum inexistent), rupând grupul în tăcere.

### Detectare (Pasul 2)

Listează toate grupurile Config-Entry pentru a obține valorile `entry_id`:

```http
GET /api/config/config_entries/entry?type=config&domain=group
```

> **Notă:** Unele HA MCP integrations pot să nu expună `options.entities` în răspunsul API. Folosește endpoint-ul REST de mai sus pentru a confirma membrii actuali.

Pentru a inspecta membrii actuali ai unui grup specific, inițiază un Options Flow și citește `suggested_value` din câmpul `data_schema.entities`:

```http
POST /api/config/config_entries/options/flow
{"handler": "<group_config_entry_id>"}
```

> **Un singur Options Flow activ per Config Entry.** Dacă ai deschis un flow de detecție, abandonează-l sau completează-l înainte de a iniția flow-ul de fix:
>
> ```http
> DELETE /api/config/config_entries/options/flow/<flow_id>
> ```

### Fix (Pasul 4)

1. Inițiază un nou fix flow (flow-ul de detecție de mai sus trebuie abandonat sau completat mai întâi). Citește valorile curente din `suggested_value`. Notează `flow_id`:

```http
POST /api/config/config_entries/options/flow
{"handler": "<group_config_entry_id>"}
```

2. Trimite lista actualizată de membri, păstrând valoarea existentă a `hide_members`. Include `all` **doar dacă era prezent în răspunsul de la pasul 1** — doar grupurile de tip `light`, `switch` și `binary_sensor` îl suportă; pentru celelalte tipuri (fan, lock, media_player, sensor etc.) omite-l complet:

```http
POST /api/config/config_entries/options/flow/<flow_id>
{"entities": ["new.entity_id_1", "new.entity_id_2"], "hide_members": <suggested_value>}
```

Dacă tipul grupului suportă `all`, adaugă-l explicit:

```http
POST /api/config/config_entries/options/flow/<flow_id>
{"entities": ["new.entity_id_1", "new.entity_id_2"], "hide_members": <suggested_value>, "all": <suggested_value>}
```

> **Regulă sigură:** Derivă întotdeauna câmpurile prezente din răspunsul `data_schema` al pasului 1 — nu le hardcoda. Trimiterea câmpurilor necunoscute poate produce o eroare de validare.

### Verificare (Pasul 5)

Re-inițiază Options Flow pentru `entry_id`-ul grupului și confirmă că `suggested_value` pentru `entities` conține doar entity ID-urile noi. Endpoint-ul REST `GET /api/config/config_entries/entry` nu expune `options.entities` — Options Flow este singura cale pentru a citi membrii actuali.

---

## Config-Entry-Data — Blind spots la redenumiri

**Redenumirile din entity registry actualizează doar Entity Registry.** Integrațiile care colectează entity_ids în timpul setup flow-ului le stochează în Config Entry — nu în YAML și nu în Entity Registry. O redenumire din registry lasă aceste referințe pointând la entity ID-ul vechi (acum inexistent).

### Integrații afectate

| Integrație | Câmp stocare | Câmpuri cu entity_ids |
|---|---|---|
| **Better Thermostat** | `data` (inaccesibil via REST — vezi nota) | `temperature_sensor`, `humidity_sensor`, `outdoor_sensor`, `window_sensors` |
| Generic Thermostat | `options` | `heater`, `target_sensor` |
| Generic Hygrostat | `options` | `humidifier`, `target_sensor` |
| Threshold Helper | `options` | `entity_id` |
| Min/Max Helper | `options` | `entity_ids` |

**Simptom:** Integrația raportează "associated entity missing" sau funcționează incorect după restart.

**Timing critic:** Patchuiește câmpurile Config-Entry **înainte de restartul HA**. O integrație care pornește cu entity_ids stale poate eșua complet la setup.

### Detectare (Pasul 2)

```http
GET /api/config/config_entries/entry
```

Iterează intrările returnate și caută entity ID-ul vechi în câmpurile `data` și `options`.

> **Notă:** Unele integrații custom (inclusiv Better Thermostat) nu expun referințele lor în `data` sau `options` via acest endpoint — câmpurile pot apărea goale chiar dacă integrația este configurată. Pentru acestea, scanul REST nu va returna niciun rezultat.

### Fix (Pasul 4)

**Pentru integrații cu entity_ids în `options`** (Generic Thermostat, Generic Hygrostat, Threshold Helper, Min/Max Helper): folosește Options Flow — vezi pattern-ul complet din secțiunea Config-Entry-Groups.

**Pentru integrații cu entity_ids în `data`** (Better Thermostat): câmpurile `data` scrise în Config Flow inițial nu au o cale API standard pentru modificare post-setup. Options Flow actualizează doar `options`. Nu există cale de fix via API — documentează această limitare utilizatorului înainte de a proceda cu redenumirea.

---

## Storage dashboards (`.storage/lovelace.*`)

**Redenumirile din entity registry NU actualizează dashboardurile Lovelace stocate.**

### Fix recomandat — fără restart

Folosește Lovelace WebSocket API:

```
1. Citește configurația dashboardului:
   WS → {"type": "lovelace/config", "url_path": "<path>"}
   Notă: dashboardul default (Overview) necesită "url_path": null;
         dashboardurile custom folosesc path-ul lor ca string.

2. Înlocuiește entity IDs — Python JSON-aware (boundary-safe):
   def _replace_ids(obj, old_id, new_id):
       if isinstance(obj, str): return new_id if obj == old_id else obj
       if isinstance(obj, list): return [_replace_ids(i, old_id, new_id) for i in obj]
       if isinstance(obj, dict): return {(new_id if k == old_id else k): _replace_ids(v, old_id, new_id) for k, v in obj.items()}
       return obj
   new_config = _replace_ids(config, "old.entity_id", "new.entity_id")
   # NU folosi string replace pe json.dumps() — nu e boundary-safe și poate potrivi
   # entity IDs care apar ca subșiruri în alte câmpuri JSON.

3. Scrie configurația actualizată:
   WS → {"type": "lovelace/config/save", "url_path": "<path>", "config": new_config}
   → intră în vigoare imediat, fără restart.
```

**Listează toate storage dashboards:**

```
WS → {"type": "lovelace/dashboards/list"}
→ returnează toate dashboardurile cu url_path-ul lor.
```

---

## Integrări YAML-only

Folosește YAML config editing cu backup și validare `check_config` pentru integrații fără config flow și fără REST/WebSocket API.

**Nu se aplică la:** automatizări/scripturi/scene (folosește config APIs), integrații configurate din UI, fișiere `.storage/` (folosește REST/WebSocket APIs), helpers ca input_number/input_boolean (au config flow).

| Tip integrație | Acțiune post-editare | Note |
|---|---|---|
| `template` | Reload disponibil | Preferă Template Helper (UI) când e posibil |
| `mqtt` (platform-based) | Reload disponibil | Platformă `mqtt:` — MQTT devices via config entry sunt separate |
| `group` (YAML-defined) | Reload disponibil | Grupuri definite în YAML; grupurile UI folosesc config entries |
| `command_line` | Restart necesar | Sensors, switches, binary sensors via shell |
| `rest` | Restart necesar | REST sensors, binary sensors |
| `shell_command` | Restart necesar | Comenzi shell denumite |
| `notify` (legacy) | Restart necesar | Majority platform-urilor notify folosesc acum config entries |
| `sensor` / `binary_sensor` | Restart necesar | Platform-style YAML definitions |
| `switch` / `light` / `fan` / `cover` / `climate` | Restart necesar | Platform-based YAML definitions |

Confirmă cu utilizatorul înainte de orice restart — întrerupe scurt toate automatizările și integrările.

---

## Exemplu end-to-end — redenumire smart plug

Redenumim `switch.shellyplug_s_a1b2c3d4e5f6` → `switch.birou_radiator` pentru un Shelly Plug care alimentează radiatorul din birou.

### Pasul 1 — Identifică scopul

Device-ul are 3 entități sibling:

| Domain | Vechi | Nou |
|---|---|---|
| `switch` | `switch.shellyplug_s_a1b2c3d4e5f6` | `switch.birou_radiator` |
| `sensor` | `sensor.shellyplug_s_a1b2c3d4e5f6_energy` | `sensor.birou_radiator_energy` |
| `update` | `update.shellyplug_s_a1b2c3d4e5f6` | `update.birou_radiator` |

### Pasul 2 — Caută toți consumatorii

```bash
grep -rn "shellyplug_s_a1b2c3d4e5f6" /config/ 2>/dev/null
```

Rezultate găsite (exemplu):
- `automations.yaml`: 2 referințe (`[Birou] Radiator pornit`, `[Casă] Consum total — Alertă`)
- `scripts.yaml`: 1 referință (`Plecare din casă`)
- `.storage/lovelace`: 3 referințe (vue Birou — tile + history-graph)
- Config-Entry-Group `Consumatori birou`: 1 referință în `options.entities`
- Template sensor `home_total_power`: 1 referință în formula de sumă

### Pasul 3 — Fă schimbarea

UI: Settings → Devices → [Shelly Plug] → entity → ⚙️ → Entity ID → schimbă în `switch.birou_radiator`. HA prompt: "Update entity ID in automations, scripts, scenes, groups?" → **Accept**.

Repetă pentru `sensor.*_energy` și `update.*` (sibling discovery — Pasul 1).

### Pasul 4 — Actualizează consumatorii rămași

HA a actualizat automat: ✅ automations, ✅ scripts.

Manual rămase:
1. **Storage dashboard** — WebSocket `lovelace/config` → înlocuire boundary-safe (vezi secțiunea Storage dashboards) → `lovelace/config/save`.
2. **Config-Entry-Group** — Options Flow pe `Consumatori birou`, citește `suggested_value`, trimite `entities:` actualizat (vezi secțiunea Config-Entry-Groups).
3. **Template sensor** — editare `configuration.yaml` / `templates.yaml`, reload Template.

### Pasul 5 — Verifică

```bash
grep -rn "shellyplug_s_a1b2c3d4e5f6" /config/ 2>/dev/null
# așteptat: zero rezultate

grep -rn "birou_radiator" /config/ 2>/dev/null
# așteptat: toate locațiile (automations + scripts + dashboard + group + template)
```

Reîncarcă dashboard-ul, declanșează manual automatizările atinse, confirmă că totul răspunde la noul entity_id.

**Actualizează `inventory.yaml`:** `previous_entity_id` pe fiecare entitate, intrare în `change_log` cu `references_updated: {automations: 2, scripts: 1, groups: 1, dashboards: 1, helpers: 1}`.

---

**TL;DR:** Caută toți consumatorii ÎNAINTE de orice schimbare. Verifică zero referințe stale DUPĂ. Acceptă prompt-ul din UI la redenumire (actualizează 90% automat). Redenumirile din registry NU actualizează: Config-Entry-Groups (`options.entities`), Config-Entry-Data (`data`/`options` ale integrațiilor), storage dashboards (`.storage/lovelace.*`) — acestea necesită pași manuali separați descriși în secțiunile de mai sus.
