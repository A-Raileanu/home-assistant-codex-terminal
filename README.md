# Codex Terminal pentru Home Assistant

[![Adaugă repository-ul în Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FA-Raileanu%2Fhome-assistant-codex-terminal)

Rulează OpenAI Codex direct din sidebar-ul Home Assistant — terminal browser în pagina HA, cu context generat automat despre instalarea ta, skill-uri specializate pentru HA și unelte de editare sigură.

## Ce face

Codex Terminal este util când vrei ajutor pentru:

- YAML-ul Home Assistant, packages și `configuration.yaml`.
- Automatizări, scripturi, scene, helpers.
- Dashboards Lovelace (UI și YAML).
- Template-uri Jinja2 și debugging template sensors.
- Dezvoltare de add-on-uri.
- Citit logs și depanare integrări.
- Refactoring sigur (redenumire entități, migrare helpers).

Add-on-ul pornește în `/config`, deci Codex lucrează direct cu fișierele tale de configurare.

## Caracteristici principale

- **Acces din sidebar** prin Home Assistant ingress (nu trebuie port forward sau autentificare separată).
- **Terminal complet în sidebar** — pagina din Home Assistant deschide direct terminalul `ttyd`, fără panouri intermediare.
- **Persistență completă** — autentificarea și configurarea Codex stau în `/data/.codex`, supraviețuiesc restart-urilor și update-urilor de add-on.
- **Sesiuni `tmux`** — închizi sidebar-ul și revii la aceeași conversație, fără să pierzi contextul.
- **Context Home Assistant generat automat** în `$CODEX_HOME/AGENTS.md` și `/data/ha-context/*.json`: sistem, entități, registries, integrări, automatizări, scripturi, scene, repairs, recorder, erori recente, logs add-on-uri.
- **Memorie runtime pentru redenumiri** în `/data/ha-context/rename_memory.json`, derivată din registrele HA; Codex sare peste device-urile și entitățile deja aduse la convenție.
- **Refresh automat de context** — se verifică periodic și la deschiderea terminalului; dacă e mai vechi de 30 minute (configurabil), se regenerează.
- **Skill-uri Home Assistant integrate (în română):**
  - `home-assistant` — umbrella skill cu index de rutare, entrypoint-uri scurte pe topic, referințe detaliate încărcate la nevoie și scripturi pentru auditul memoriei de redenumiri.
  - `home-assistant-instance` — generat automat la fiecare boot de `ha-context`, conține flag-urile de runtime și safety ale instalării tale.
- **Integrare MCP opțională** (`ha-mcp` community, server oficial HA MCP, ambele, sau dezactivat).
- **Diagnostic** prin `codex-ha doctor`.
- **Editare sigură staged** cu `ha-safe-edit plan/apply` (backup automat + diff + validare YAML + `check_config` înainte de aplicare).
- **Client WebSocket bundlat** (`websocat`) pentru `ws://supervisor/core/api/websocket`.
- **Pachete persistente** APK și pip configurate o singură dată, reinstalate la fiecare start.
- **Permisiuni automate activate implicit** — Codex nu mai cere aprobare la fiecare acțiune (configurabil).

## Cerințe

- **Home Assistant OS**, **Home Assistant Supervised** sau **Home Assistant Container cu Supervisor** (add-on-urile au nevoie de Supervisor).
- Acces la internet (pentru `npm install @openai/codex` la primul build și pentru auth-ul Codex).
- Un cont OpenAI cu acces la Codex (subscripția ChatGPT Plus / Pro / Business sau API key cu acces Codex).
- Arhitectură suportată: `amd64`, `aarch64`, `armv7` (vezi `build.yaml`).

## Instalare

### Metoda 1: Buton 1-click (recomandat)

Apasă pe badge-ul din capul README-ului. Home Assistant se va deschide direct pe ecranul de adăugare a repository-ului — confirmă, apoi continuă cu pasul 5 de mai jos.

### Metoda 2: Adăugare manuală a repository-ului

1. Deschide Home Assistant în browser.
2. Navighează la **Settings → Add-ons → Add-on Store**.
3. Apasă pe meniul cu trei puncte (⋮) din colțul din dreapta sus → **Repositories**.
4. Lipește URL-ul repository-ului:

   ```text
   https://github.com/A-Raileanu/home-assistant-codex-terminal
   ```

   Apasă **Add**, apoi **Close**.

### Pași comuni (după ce repository-ul e adăugat)

5. **Refresh** pagina **Add-on Store** (Ctrl+F5 sau pull-to-refresh pe mobil).
6. Scroll în jos până la secțiunea **Codex Terminal Add-on Repository** și deschide add-on-ul **Codex Terminal**.
7. Apasă **Install**. Primul build durează 3–8 minute (descarcă imaginea de bază Alpine + dependențe + Codex CLI).
8. *(Opțional, dar recomandat)* În tab-ul **Configuration**, verifică/ajustează opțiunile (vezi tabelul [Opțiuni add-on](#opțiuni-add-on)). Apasă **Save**.
9. În tab-ul **Info**:
   - Activează **Start on boot** dacă vrei ca Codex Terminal să pornească odată cu HA.
   - Activează **Watchdog** ca Supervisor să-l repornească dacă se închide neașteptat.
   - Activează **Show in sidebar** ca să apară iconița în meniul lateral HA.
10. Apasă **Start**. În tab-ul **Log** ar trebui să vezi `Background initialization completed` în 10–30 secunde.
11. Deschide terminalul din **sidebar** (iconița nouă) sau apasă **Open Web UI** din pagina add-on-ului.

### Primul login Codex

La prima deschidere a terminalului, autentifică-te în Codex:

```bash
codex login
```

Urmează instrucțiunile (cont OpenAI sau API key). Auth-ul se salvează în `/data/.codex` și persistă peste restart-uri și update-uri.

### Task picker la fiecare deschidere

Cu `auto_launch_codex: true` (default), la fiecare deschidere de sidebar Codex Terminal afișează un picker scurt cu sarcini comune:

```text
  Ce vrei să faci?

  1) Sesiune nouă (Codex pornit fără prompt prestabilit)
  2) Am adăugat un dispozitiv nou
     (te întreabă ce dispozitiv ai adăugat, apoi îl redenumește pe el și entitățile lui)
  3) Redenumește device-urile și entitățile conform convenției
     (ignoră ce respectă deja convenția)
  4) Ajustează automatizările conform convențiilor
     (alias, mode, description, trigger IDs — ignoră ce e deja OK)
  5) Repară automatizările și dashboard-urile cu entități declarate greșit
     (entity_id-uri inexistente, referințe moarte, integrări vechi)
  6) Regenerează contextul
     (citește din nou datele Home Assistant pentru Codex)

  Apasă [1-6] (default: 1):
```

- **Opțiunea 1** lansează Codex normal, fără mesaj inițial — alege asta pentru conversații libere.
- **Opțiunea 2** te întreabă întâi ce dispozitiv (sau dispozitive) tocmai ai adăugat, apoi îți arată un sumar cu modificările propuse pentru acel device și entitățile lui și așteaptă confirmarea ta înainte să scrie ceva pe `/config`.
- **Opțiunile 3–5** pornesc Codex cu un prompt pre-completat care citește skill-urile relevante și pregătește modificările conform convențiilor. Înainte de a scrie pe `/config`, Codex îți afișează un sumar cu tot ce vrea să schimbe și te întreabă dacă să pregătească planul tehnic. Aplică doar după confirmarea ta finală.
- **Opțiunea 6** regenerează manual contextul Home Assistant și revine la meniu cu ora ultimei actualizări afișată.
- Toate trei sunt **idempotente** — sare peste ce respectă deja convenția, deci poți rula opțiunea 2 lunar fără să strice nimic.
- Dacă există deja o sesiune activă (ai închis sidebar-ul și revii), meniul îți arată trei opțiuni simple: continui conversația existentă, regenerezi contextul sau repornești terminalul.

Pentru a sări complet peste picker și a primi shell-ul direct, setează `auto_launch_codex: false` în opțiunile add-on-ului. Vei intra în `bash`; pornește manual Codex cu `codex --cd /config`.

## Comenzi utile

```bash
codex --cd /config                 # pornește Codex în /config
codex login                        # (re)autentificare
codex resume --last                # continuă ultima conversație
codex mcp list                     # listează serverele MCP înregistrate

codex-ha doctor                    # diagnostic complet (binare, HA API, MCP, skills, safety)
codex-ha safety                    # afișează opțiunile de safety active
codex-ha check-config              # rulează check_config pe Home Assistant
codex-ha context-json              # listează contextul structurat JSON
codex-ha logs <addon_slug>         # ultimele linii de log ale unui add-on

ha-context                         # refresh contextul HA (respectă cache-ul)
ha-context --force                 # refresh forțat, ignoră cache-ul
ha-context --full --force          # context detaliat, refresh forțat

ha-safe-edit check                 # validează YAML + check_config înainte de edit
ha-safe-edit plan /config/automations.yaml -- sh -c 'your-edit-command'
ha-safe-edit apply <plan_id>       # aplică un plan staged după confirmare
ha-safe-edit backup /config/automations.yaml

persist-install list               # listează pachetele persistente
persist-install apk htop           # adaugă un pachet APK persistent
persist-install pip requests       # adaugă un pachet pip persistent

websocat ws://supervisor/core/api/websocket
```

`websocat` poate vorbi cu Home Assistant Core WebSocket API la `ws://supervisor/core/api/websocket`. Autentifică-te trimițând `{"type": "auth", "access_token": "$SUPERVISOR_TOKEN"}` ca primul mesaj JSON imediat după ce conexiunea se deschide.

## Cum redenumești device-uri, entități și ajustezi automatizările

Skill-urile bundlate (`home-assistant/SKILL.md` + topic entrypoints + `references/`) definesc convenții stricte de denumire. **Când îi ceri lui Codex să redenumească ceva, aplică automat aceste reguli** — nu trebuie să i le repeți. Conversația cu Codex se desfășoară în română.

### Convențiile pe scurt

| Element                                 | Format                                | Exemple                                                                |
| --------------------------------------- | ------------------------------------- | ---------------------------------------------------------------------- |
| Device                                  | `[Area] Producător Model [#N]`        | `[Living] Aqara T1`, `[Dormitor #1] IKEA TRÅDFRI E27`                  |
| Entitate (`friendly_name`)              | `[Area] Nume dispozitiv - Funcție`    | `[Living] Aqara T1 - Temperatură`, `[Server] Synology DS920+ - Procent CPU` |
| Entitate principală (un singur sensor)  | `[Area] Nume dispozitiv`              | `[Dormitor #1] IKEA TRÅDFRI E27`                                       |
| Area                                    | slug RO scurt                         | `living`, `dormitor1`, `cameratehnica`                                 |
| Label                                   | slug RO scurt, **transversal pe tip** | `lumina`, `senzor_miscare`, `priza_smart`                              |
| Automatizare / script / scenă / helper  | `alias` descriptiv în română          | `"Aprinde lumina living la apus"`, `"Curăță notificările vechi"`       |
| Limbă                                   | română peste tot, diacritice complete | `entity_id` slugs + câmpuri tehnice YAML rămân în engleză              |

Detalii complete: deschide skill-urile direct (`cat $CODEX_HOME/skills/home-assistant/SKILL.md`) sau cere-i lui Codex să-ți explice o convenție anume (`Explică-mi convenția de naming pentru entități`).

### Redenumire device-uri

În terminalul Codex:

```text
> Redenumește toți senzorii Aqara din dormitor conform convenției.
```

Codex execută automat:
1. Citește `/data/ha-context/rename_memory.json` ca să vadă device-urile existente, area-urile, labels și ce respectă deja convenția.
2. Citește `ha-devices-areas.md` pentru regulile de format (`[Area] Producător Model [#N]`).
3. Propune un plan cu device-urile afectate (ex: `aqara_temperature_sensor_5b1c` → `[Dormitor #1] Aqara T1`).
4. Aplică modificările prin Settings API (WebSocket) sau prin editare în `core.device_registry` cu backup `ha-safe-edit`.
5. Asignează area corect și label-urile potrivite (`temperatura`, `umiditate` etc.).
6. Rulează `ha-context --force` și verifică `rename_memory.json`, ca următoarea sesiune să sară peste elementele deja redenumite.

Alte prompt-uri tipice:

```text
> Redenumește device-ul cu entity_id sensor.foo_temperature conform convenției.
> Toate device-urile fără area asignată — citește rename_memory.json și asignează area corectă.
> Verifică labels-urile pe device-urile din curte; adaugă "exterior" celor care lipsesc.
> Găsește toate device-urile cu sufixe random (_a1b2c3) în nume și propune redenumiri.
```

### Redenumire entități (`friendly_name`)

```text
> Adaugă prefixul "[Area] Nume dispozitiv -" la toate entitățile fără el.
```

Codex execută:
1. Listează entitățile fără prefix (interogare WebSocket la `core.entity_registry`).
2. Pentru fiecare, deduce device-ul și area din `core.device_registry`.
3. Construiește `friendly_name` în format `[Area] Nume dispozitiv - Funcție` (folosind vocabularul din `ha-entities.md` pentru partea de funcție: `Temperatură`, `Umiditate`, `Mișcare`, `Procent baterie`, etc.).
4. Te întreabă cum vrei să aplice override-ul:
   - **UI override** prin Settings API (rapid, dar invizibil în git);
   - **`customize:`** în `configuration.yaml` (git-controlled, recomandat dacă ai versioning).
5. Aplică modificările cu validare + backup.

Alte prompt-uri:

```text
> Pe toți senzorii de temperatură, setează friendly_name conform convenției.
> Entitatea sensor.kitchen_motion_1a2b — propune un friendly_name corect.
> Curăță entity_id-urile cu sufixe random și redenumește-le ca slug stabil <slug_camera>_<function>.
> Pe entitățile principale (cele fără sub-funcție), setează friendly_name = [Area] Nume dispozitiv.
```

### Ajustare automatizări (alias, mode, descriere)

```text
> Citește automations.yaml și propune redenumiri pentru toate aliasurile generice.
```

Codex execută:
1. Parsează `/config/automations.yaml`.
2. Identifică alias-urile generice (`"New Automation"`, `"Untitled Automation"`, slug-uri auto-generate de UI).
3. Citește `ha-automations.md` pentru convenții (limbă, format, când să folosească `description:`, când să folosească `id:`).
4. Propune alias-uri descriptive în română + `description:` pentru cele complexe.
5. Verifică `mode:` — pe trigger-e motion sugerează `restart`, pe acțiuni secvențiale `queued`, pe acțiuni paralele independente `parallel`.
6. Rulează `ha-safe-edit check` și aplică doar dacă `check_config` trece.

Alte prompt-uri:

```text
> Adaugă description pe toate automatizările care n-au.
> Verifică mode pe toate automatizările cu trigger.platform=state pe motion — ar trebui restart.
> Refactorează automatizarea "Lumini seara" — împărți condițiile native în loc de template.
> Adaugă trigger IDs (id:) pe automatizările multi-trigger ca să devină ușor de citit în acțiuni.
> Convertește automatizarea cu wait_template într-un wait_for_trigger nativ.
```

### Scripturi cu parametri (`fields:`)

```text
> Convertește scriptul script.notification_test într-un script cu parametri (mesaj + target).
```

Codex aplică convențiile din `ha-scripts-steps.md`:
- Definește `fields:` cu `selector:` corect (`text`, `entity`, `area`, `boolean`, `number` cu unit).
- Adaugă `alias:` pe fiecare pas din `sequence:` ca să fie ușor de citit în trace.
- Folosește `variables:` când reutilizezi valori în mai mulți pași.
- Adaugă `description:` la nivel de script când e necesar.

### Helpers și scene

```text
> Am nevoie de un timer pentru "ștergere notificare după 5 minute". Ce helper sugerezi?
```

Codex citește `ha-helpers-scenes.md` (matricea de selecție helper) și recomandă tipul potrivit (`timer`, `input_datetime`, `input_boolean`, `counter`, `input_number`, etc.) cu motivare scurtă.

Pentru scene:

```text
> Creează o scenă "Living seara" cu lumini calde la 40% și TV pornit.
> Refactorează scena existentă "Trezit dimineața" — momentan duplică valorile, mutăm într-un script cu parametri.
```

### Refactoring sigur

Înainte de redenumiri de entități cu impact larg:

```text
> Sunt pe cale să redenumesc light.living_ceiling în light.living_lampa_tavan. Verifică impactul.
```

Codex citește `ha-refactoring.md` și caută referințele entității în:
- Automatizări (`automations.yaml` + `.storage/automations`)
- Scripturi, scene, helpers
- Dashboards (UI mode + YAML mode + storage)
- Template sensors și template binary sensors
- Grupuri și `customize:`
- `recorder:` include/exclude
- Energy Dashboard
- Voice assistants și exposed entities

Apoi propune un plan de migrare în ordinea sigură (entitate nouă cu același `unique_id` → migrare referințe → cleanup).

### Notificări și template-uri

```text
> Scrie o notificare care alertează când usa de la intrare e deschisă mai mult de 2 minute.
> Refactorează template sensor pentru "consum lunar electricitate" — folosește utility_meter în loc de template.
> Debug template — de ce {{ states('sensor.foo') | float }} întoarce 0?
```

Codex aplică conventiile din `ha-notifications.md` (`notify.send_message`, canale, Jinja2 cu fallback-uri sigure) și `ha-templates.md` (când să eviți template-urile, performanță, trigger-based templates).

### Workflow-ul automat al lui Codex

Pașii pe care Codex îi urmează automat la **orice** modificare tangibilă (vezi `home-assistant/SKILL.md` → "Reguli obligatorii"):

1. Identifică tipul elementului atins (device / entitate / automatizare / script / scenă / helper / dashboard / template / notificare).
2. Citește fișierul `ha-*.md` corespunzător + `/data/ha-context/rename_memory.json` dacă atinge device sau entitate.
3. Aplică toate convențiile integral (limbă, casing, slug-uri, structură, prefix `friendly_name`, `mode`, etc.).
4. Sare peste device-urile și entitățile deja canonical, cu excepția cazului în care ceri explicit redenumirea lor.
5. Întreabă utilizatorul dacă o convenție pare neclară sau lipsește — **nu inventează**.
6. Folosește `ha-safe-edit` (backup + validare) înainte de orice edit pe `/config`.
7. La final, rulează `ha-context --force` ca memoria runtime să fie actualizată.

Dacă vezi că Codex sare peste un pas (rar, dar se întâmplă în conversații lungi), spune-i direct: `Aplică convențiile din ha-entities.md` sau `Regenerează contextul cu ha-context --force`.

## Contextul Home Assistant

La start, add-on-ul generează un context Home Assistant pentru Codex în `$CODEX_HOME/AGENTS.md`. Conține:

- Versiune HA Core, Supervisor, OS, arhitectură.
- Sumar entități pe domain (light, sensor, switch, …) cu numărători.
- Lista add-on-urilor instalate (slug, versiune, stare).
- Integrări configurate (config entries).
- Automatizări, scripturi, scene definite (cu alias-uri și stare enabled/disabled).
- Memorie runtime pentru device-uri și entități redenumite (`rename_memory.json`).
- Entități `unavailable` sau `unknown` (semnal pentru integrări sparte).
- Probleme din Repairs și System Health.
- Statistici recorder (mărime DB, oldest entry).
- Erori recente din `home-assistant.log`.
- Sample-uri de log pentru add-on-urile rulând (opțional, vezi `include_addon_logs`).

Refresh-ul automat e cache-uit 30 minute (configurabil):

```yaml
ha_context_refresh_minutes: 30
```

Forțează refresh după modificări mari — integrări noi, redenumire entități, automatizări noi, troubleshooting erori:

```bash
ha-context --force
```

## Editare sigură (`ha-safe-edit`)

Folosește `ha-safe-edit plan/apply` ori de câte ori modifici fișiere din `/config`. `plan` creează backup, rulează comanda, validează YAML + `check_config`, salvează diff-ul în `/data/safe-edit-plans` și restaurează fișierul original. `apply` aplică doar planul aprobat și refuză dacă fișierul s-a schimbat între timp.

```bash
# Backup explicit
ha-safe-edit backup /config/configuration.yaml

# Validare (YAML + check_config) — folosit înainte de orice edit
ha-safe-edit check /config/configuration.yaml

# Pregătește un plan staged, cu diff și validare
ha-safe-edit plan /config/automations.yaml -- sh -c 'your-edit-command'

# Aplică planul după ce ai verificat diff-ul
ha-safe-edit apply <plan_id>

# Compatibilitate: aplicare directă cu backup + validare
ha-safe-edit /config/automations.yaml -- sh -c 'your-edit-command'
```

Backup-urile se salvează în:

```text
/data/safe-edit-backups
```

Planurile staged se salvează în:

```text
/data/safe-edit-plans
```

Sunt curățate automat după `safe_edit_backup_retention_days` zile (default 30).

## Moduri MCP

MCP (Model Context Protocol) permite Codex să folosească *unelte* HA, nu doar să citească fișiere. Default-ul registrează serverul `ha-mcp` community.

| Mod         | Comportament                                                                 |
| ----------- | ---------------------------------------------------------------------------- |
| `ha-mcp`    | Default. Registrează serverul stdio `homeassistant-ai/ha-mcp` (via `uvx`).   |
| `official`  | Registrează endpoint-ul Home Assistant MCP Server (HTTP streamable oficial). |
| `both`      | Registrează ambele.                                                          |
| `disabled`  | Nu registrează nimic.                                                        |

Pentru modul `official`, configurează întâi integrarea **Home Assistant MCP Server** din Settings → Devices & services → Add Integration, apoi:

```yaml
mcp_mode: "official"
official_mcp_url: "http://supervisor/core/api/mcp"
```

Pentru ambele:

```yaml
mcp_mode: "both"
```

Pentru a dezactiva MCP complet:

```yaml
mcp_mode: "disabled"
```

## Opțiuni add-on

| Opțiune                          | Default                              | Descriere                                                                                                                                       |
| -------------------------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `auto_launch_codex`              | `true`                               | `true` — afișează task picker-ul la fiecare deschidere de sidebar (sau atașează sesiunea `tmux` existentă). `false` — sare peste picker, dropă direct în `bash -l`. |
| `ha_smart_context`               | `true`                               | Generează contextul HA și skill-ul instance la start.                                                                                           |
| `ha_context_refresh_minutes`     | `30`                                 | Sare peste regenerarea contextului dacă cache-ul e mai recent decât această valoare.                                                            |
| `context_detail_level`           | `standard`                           | Nivelul contextului: `summary`, `standard` sau `full`.                                                                                          |
| `include_addon_logs`             | `false`                              | Include sample-uri de log de la add-on-urile rulând în contextul generat.                                                                       |
| `enable_ha_mcp`                  | `true`                               | Activează setup-ul MCP la start.                                                                                                                |
| `mcp_mode`                       | `ha-mcp`                             | Alege `ha-mcp`, `official`, `both` sau `disabled`.                                                                                              |
| `official_mcp_url`               | `http://supervisor/core/api/mcp`     | URL-ul endpoint-ului oficial HA MCP.                                                                                                            |
| `ha_mcp_version`                 | `3.5.1`                              | Versiunea pachetului `ha-mcp` folosită la registration.                                                                                         |
| `readonly_mode`                  | `false`                              | Face ca helper-ele să refuze orice edit (skill-urile instruiesc AI-ul în consecință).                                                           |
| `require_backup_before_edit`     | `true`                               | Păstrează workflow-ul "backup-first" ca implicit recomandat.                                                                                    |
| `enable_device_control`          | `false`                              | Marcaj de safety pentru workflow-uri care apelează direct service calls (`light.turn_on`, etc.).                                                |
| `enable_file_tools`              | `true`                               | Permite operațiunile pe fișiere.                                                                                                                |
| `enable_yaml_editing`            | `true`                               | Permite editarea YAML prin `ha-safe-edit`.                                                                                                      |
| `codex_full_permissions`         | `true`                               | Pornește Codex cu `--dangerously-bypass-approvals-and-sandbox`, fără prompt-uri de confirmare la fiecare acțiune. Pune `false` ca să le recapeți. |
| `max_log_lines`                  | `80`                                 | Limita liniilor de log în context și output-ul helper-elor.                                                                                     |
| `safe_edit_backup_retention_days`| `30`                                 | Șterge backup-urile mai vechi de N zile.                                                                                                        |
| `persistent_apk_packages`        | `[]`                                 | Pachete Alpine (apk) reinstalate la fiecare start.                                                                                              |
| `persistent_pip_packages`        | `[]`                                 | Pachete Python (pip) reinstalate la fiecare start.                                                                                              |

## Pachete persistente

Containerul HA Add-on e stateless între restart-uri — orice `apk add` sau `pip install` făcut manual se pierde. Folosește mecanismul persistent:

```bash
persist-install apk htop
persist-install pip requests
persist-install list
```

Sau configurează direct în opțiunile add-on-ului:

```yaml
persistent_apk_packages:
  - htop
  - mtr
persistent_pip_packages:
  - requests
  - pyyaml
```

La fiecare start, scriptul instalează aceste pachete înainte de restul inițializării.

## Actualizare

Când apare o versiune nouă:

1. În Home Assistant, deschide pagina add-on-ului **Codex Terminal**.
2. Apasă **Update** (Supervisor verifică automat versiunile, dar poți forța din meniul ⋮ → **Check for updates**).
3. Așteaptă build-ul (1–5 minute, mai rapid decât prima instalare datorită cache-ului Docker).
4. **Restart** add-on-ul dacă nu pornește automat după update.
5. Verifică în Log-uri `Background initialization completed` și `Resetting Codex skills directory to match bundle for X.X.X` (la version-change skill-urile bundlate se resincronizează automat).
6. În terminal:

   ```bash
   codex-ha doctor
   ```

   Confirmă că toate binarele și skill-urile sunt OK.

## Depanare

### Terminalul din sidebar nu se încarcă

- Verifică în pagina add-on-ului tab-ul **Log** — caută erori la `ttyd` sau `bash`.
- Asigură-te că add-on-ul e în starea **Running** (verde, nu portocaliu).
- Verifică **Show in sidebar** e bifat. Dacă tocmai ai activat opțiunea, fă **Restart** la HA Core sau reîncarcă pagina cu Ctrl+F5.
- Dacă rulezi HA în spatele unui reverse proxy, confirmă că WebSocket-urile sunt forwardate corect (ingress folosește WebSocket).

### Codex îmi cere autentificare din nou

```bash
codex login
```

Auth-ul ar trebui să persiste în `/data/.codex`. Dacă nu, verifică log-urile pentru erori de permisiuni pe `/data` (rar — apare doar dacă storage-ul a fost remontat manual).

### Codex nu vede skill-urile Home Assistant

```bash
codex-ha doctor
```

`codex-ha doctor` validează skill-urile bundlate. Dacă tocmai ai făcut update la add-on, restartează-l manual ca să forțezi resincronizarea skill-urilor.

### Contextul e vechi

```bash
ha-context --force
```

Sau scade refresh window-ul:

```yaml
ha_context_refresh_minutes: 10
```

### MCP nu funcționează

```bash
codex mcp list
codex-ha doctor
```

Pentru modul `official`, integrarea **Home Assistant MCP Server** trebuie configurată întâi (Settings → Devices & services). Un `404` de la `/api/mcp` înseamnă că integrarea nu e activă.

Pentru `ha-mcp`, verifică în log-urile add-on-ului dacă `uvx` a reușit să instaleze `ha-mcp` la prima rulare (necesită acces la internet).

### Validarea config-ului HA eșuează

```bash
ha-safe-edit check
```

Citește output-ul `check_config` înainte de restart — restart-ul cu config invalid poate pica HA.

### Codex tot mă întreabă de aprobări

Verifică în opțiuni:

```yaml
codex_full_permissions: true
```

Dacă era pe `false` și tocmai ai schimbat, **Restart** add-on-ul ca să prindă valoarea nouă (variabila de mediu se citește la start).

## Note de securitate

Add-on-ul e puternic. Codex poate citi fișierele tale de configurare HA, rulează comenzi în terminal și, când MCP e activ, interacționează cu API-urile HA (inclusiv service calls).

Default-urile de instalare favorizează un workflow fără friction: `codex_full_permissions: true` sare peste prompt-urile de aprobare și sandbox-ul. Dacă preferi ca Codex să întrebe înainte de fiecare acțiune, setează `codex_full_permissions: false`.

Exemplu de configurare conservatoare (opt-in, suprascrie default-urile permisive):

```yaml
readonly_mode: true
require_backup_before_edit: true
enable_device_control: false
enable_yaml_editing: true
mcp_mode: "ha-mcp"
codex_full_permissions: false
context_detail_level: "summary"
include_addon_logs: false
```

Pentru un setup și mai restrictiv:

```yaml
readonly_mode: true
mcp_mode: "disabled"
```

**Revizuiește comenzile** înainte să le rulezi pe o instalare live. Atenție specială la service calls care:
- deblochează uși sau garaje,
- pornesc/opresc alarme,
- modifică climatul în extremă,
- controlează aparate de mare putere (boiler, încălzitor),
- declanșează scenarii de panică sau notificări către contacte de urgență.

## Structura repository-ului

```text
repository.yaml                                  # marker repository HA add-on
codex-terminal/
  config.yaml                                    # schema opțiunilor + metadata add-on
  build.yaml                                     # imagini de bază pe arhitectură
  Dockerfile                                     # build instructions (apk install, Codex CLI, etc.)
  run.sh                                         # entrypoint: init env, install skills, start ttyd + ingress proxy
  CHANGELOG.md                                   # istoric versiuni
  DOCS.md                                        # documentație internă add-on
  scripts/
    codex-ha.sh                                  # diagnostic: doctor / safety / check-config / logs
    codex-task-picker.sh                         # task picker afișat la deschiderea sidebar-ului
    ha-context.sh                                # generator AGENTS.md + /data/ha-context JSON + skill instance
    ha-safe-edit.sh                              # plan/apply staged + backup + validare YAML/check_config
    web-ui.py                                    # proxy ingress către terminalul ttyd
    persist-install.sh                           # pachete APK/pip persistente
    setup-ha-mcp.sh                              # registrare servere MCP
    validate-skills.sh                           # validator intern al skill-urilor
    tmux.conf                                    # config tmux pentru session persistence
  skills/
    home-assistant/
      SKILL.md                                   # umbrella + index de rutare
      ha-automations.md                          # automatizări (mode, trigger IDs, choose, repeat)
      ha-dashboards.md                           # views, cards, styling, custom cards
      ha-device-control.md                       # service calls, ZHA/Z2M, lights/climate/cover
      ha-devices-areas.md                        # device names, areas, labels, rename memory
      ha-entities.md                             # vocabular RO funcții, entity IDs, device_class
      ha-examples.md                             # exemple complete end-to-end
      ha-helpers-scenes.md                       # helpers (boolean/number/timer/etc.), scene
      ha-notifications.md                        # notify.send_message, canale, Jinja
      ha-refactoring.md                          # redenumire entități, storage dashboards
      ha-scripts-steps.md                        # scripts, fields, sequence, variables
      ha-templates.md                            # Jinja2, template sensors, performanță
      references/                                # documentația detaliată încărcată doar la nevoie
        core-rules.md                            # reguli comune cross-topic
        rename-memory.md                         # ghid /data/ha-context/rename_memory.json
        ha-version-notes.md                      # note dependente de versiunea Home Assistant
        ha-*.md                                  # referințele complete pentru fiecare topic
      scripts/
        ha_rename_audit.py                       # listează rapid ce mai trebuie redenumit
        ha_reference_scan.py                     # caută referințe entity_id în /config
        ha_skill_lint.py                         # lint intern pentru skill-ul HA
```

## Licență

Apache License 2.0 — vezi fișierul `LICENSE` în rădăcina repository-ului.
