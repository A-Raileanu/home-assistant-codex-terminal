# Codex Terminal

## Despre

Codex Terminal e un add-on care pune **OpenAI Codex** direct în sidebar-ul Home Assistant. Deschizi terminalul din meniul lateral, te autentifici o singură dată cu contul tău OpenAI și ai un asistent care înțelege configurarea ta de HA — automatizări, dashboard-uri, scripturi, scene, dispozitive, template-uri Jinja2.

Codex citește automat starea curentă a HA (versiuni, integrări, automatizări, erori recente) și are skill-uri specializate în română pentru convenții de denumire, refactoring sigur și pattern-uri comune.

## Cum funcționează

1. Adaugă acest repository în Add-on Store.
2. Instalează **Codex Terminal**.
3. Pornește add-on-ul (activează **Start on boot** și **Show in sidebar** dacă vrei acces permanent).
4. Deschide **Codex Terminal** din sidebar.
5. La prima rulare: `codex login` — autentificare cu contul OpenAI. Auth-ul se salvează în `/data/.codex` și persistă peste restart-uri și update-uri.

La fiecare deschidere nouă a sidebar-ului vei vedea un **meniu de început** cu sarcini comune: sesiune nouă, dispozitiv nou, redenumire dispozitive, ajustare automatizări, reparare referințe sparte și regenerare manuală a contextului. Dacă există deja o conversație Codex activă, meniul îți oferă opțiunile de continuare, regenerare context sau repornire terminal.

## Caracteristici

- **Terminal complet în sidebar** — ingress deschide direct terminalul `ttyd`, fără panouri intermediare.
- **Autentificare persistentă** — salvată în `/data/.codex`, supraviețuiește restart-urilor.
- **Sesiuni `tmux`** — închizi sidebar-ul, revii la aceeași conversație.
- **Context Home Assistant** generat automat în Markdown și JSON structurat; se verifică periodic și la deschiderea terminalului, iar dacă e mai vechi de 30 minute se regenerează.
- **Skill-uri specializate** pentru HA (entități, dispozitive, automatizări, scripturi, scene, dashboards, template-uri, notificări, refactoring) cu convenții în română.
- **MCP integrat** — `ha-mcp` community sau endpoint-ul oficial Home Assistant MCP Server.
- **Editare sigură staged** prin `ha-safe-edit plan/apply` (backup + diff + validare YAML + `check_config`).
- **Client WebSocket** (`websocat`) pentru API-ul Home Assistant WebSocket.
- **Pachete persistente** Alpine/pip care se reinstalează la fiecare start.
- **Permisiuni automate activate implicit** — Codex nu cere aprobare la fiecare acțiune.

## Comenzi utile

```bash
codex --cd /config                 # pornește Codex în /config
codex login                        # (re)autentificare
codex resume --last                # reia ultima conversație
codex mcp list                     # listează serverele MCP înregistrate

codex-ha doctor                    # diagnostic: binare, HA API, MCP, skill-uri, safety
codex-ha check-config              # validează configurarea Home Assistant
codex-ha context-json              # listează contextul structurat JSON
codex-ha logs <addon_slug>         # ultimele linii de log ale unui add-on

ha-context                         # refresh contextul HA (respectă cache-ul)
ha-context --force                 # refresh forțat, ignoră cache-ul

ha-safe-edit check                 # validează YAML + check_config înainte de edit
ha-safe-edit plan /config/automations.yaml -- sh -c 'comanda-ta'
ha-safe-edit apply <plan_id>
ha-safe-edit backup /config/automations.yaml

persist-install list               # listează pachetele persistente
persist-install apk htop           # adaugă un pachet APK persistent

websocat ws://supervisor/core/api/websocket
```

`websocat` poate vorbi cu Home Assistant Core WebSocket API. Autentifică-te trimițând `{"type": "auth", "access_token": "$SUPERVISOR_TOKEN"}` ca primul mesaj JSON.

## Configurare

Cele mai folosite opțiuni:

| Opțiune                       | Default                              | Ce face                                                                                       |
| ----------------------------- | ------------------------------------ | --------------------------------------------------------------------------------------------- |
| `auto_launch_codex`           | `true`                               | Afișează task picker-ul la fiecare deschidere; `false` te lasă în bash.                       |
| `codex_full_permissions`      | `true`                               | Codex pornește fără prompt-uri de aprobare. `false` activează confirmarea pe fiecare acțiune. |
| `ha_smart_context`            | `true`                               | Generează contextul HA automat la start.                                                      |
| `ha_context_refresh_minutes`  | `30`                                 | Cache-ul contextului — sare peste regenerare dacă e mai recent decât valoarea asta.           |
| `context_detail_level`        | `standard`                           | `summary` / `standard` / `full` — câte detalii intră în context.                              |
| `mcp_mode`                    | `ha-mcp`                             | `ha-mcp` / `official` / `both` / `disabled`.                                                  |
| `readonly_mode`               | `false`                              | Dacă e `true`, helper-ele refuză orice modificare.                                            |
| `require_backup_before_edit`  | `true`                               | Workflow backup-first pe `ha-safe-edit`.                                                      |
| `persistent_apk_packages`     | `[]`                                 | Pachete Alpine reinstalate la fiecare start.                                                  |
| `persistent_pip_packages`     | `[]`                                 | Pachete pip reinstalate la fiecare start.                                                     |

Vezi README-ul repository-ului pentru tabelul complet.

## Home Assistant MCP

Cu `mcp_mode: ha-mcp` (default), add-on-ul înregistrează automat serverul `ha-mcp` în Codex, cu token-ul Supervisor:

```bash
codex mcp add home-assistant \
  --env HOMEASSISTANT_URL=http://supervisor/core \
  --env HOMEASSISTANT_TOKEN=$SUPERVISOR_TOKEN \
  -- uvx --index-strategy unsafe-best-match ha-mcp@3.5.1
```

Pentru `mcp_mode: official`, configurează întâi integrarea **Home Assistant MCP Server** din Settings → Devices & services. Pentru `mcp_mode: both`, sunt înregistrate ambele. Pentru a dezactiva complet: `mcp_mode: disabled`.

## Skill-uri integrate

Add-on-ul instalează în `/data/.codex/skills/` un skill umbrella `home-assistant` cu un index de rutare în română, entrypoint-uri scurte pe topic, referințe detaliate încărcate la nevoie și scripturi de audit:

- **ha-entities** — vocabular funcții (120+ termeni RO), entity IDs, device_class.
- **ha-devices-areas** — convenții pentru dispozitive, areas, labels și memoria runtime `rename_memory.json`.
- **ha-automations** — automatizări (mode, trigger IDs, choose, repeat, anti-patterns).
- **ha-scripts-steps** — scripturi cu parametri, alias, variabile.
- **ha-helpers-scenes** — helpers (boolean, number, timer, counter) și scene.
- **ha-dashboards** — views, cards, styling, custom cards HACS.
- **ha-templates** — Jinja2, template sensors, performanță, trigger-based templates.
- **ha-notifications** — notify.send_message, canale, notificări acționabile.
- **ha-device-control** — service calls, ZHA/Z2M, lights/climate/cover.
- **ha-refactoring** — redenumire entități, impact analysis, storage dashboards.
- **ha-examples** — exemple complete end-to-end cu best practices.

Detaliile lungi sunt în `home-assistant/references/`; entrypoint-urile `ha-*.md` rămân mici ca să reducă tokenii încărcați în Codex. Pentru audit rapid există `home-assistant/scripts/ha_rename_audit.py` și `home-assistant/scripts/ha_reference_scan.py`.

Toate convențiile sunt în română cu diacritice complete. Un al doilea skill `home-assistant-instance` se generează automat de fiecare dată de `ha-context` și conține flag-urile de runtime, safety și instrucțiuni pentru `/data/ha-context/rename_memory.json`.

## Editare sigură

Folosește `ha-safe-edit` ori de câte ori modifici fișiere din `/config`:

```bash
ha-safe-edit backup /config/configuration.yaml
ha-safe-edit check /config/configuration.yaml
ha-safe-edit plan /config/automations.yaml -- sh -c 'comanda-ta'
ha-safe-edit apply <plan_id>
```

Planurile staged se salvează în `/data/safe-edit-plans`. Backup-urile se salvează în `/data/safe-edit-backups` și sunt șterse automat după `safe_edit_backup_retention_days` zile (default 30).

## Securitate

Codex poate citi și edita fișierele de configurare HA mapate în add-on. Cu MCP activ, poate apela și service-uri HA (control entități, automatizări, dashboard-uri, scene).

**Recomandare:** revizuiește comenzile înainte să le rulezi pe o instalare live. Atenție specială la apeluri care:

- deblochează uși sau garaje;
- pornesc sau opresc alarme;
- controlează aparate de mare putere (boiler, încălzitor);
- trimit notificări către contacte de urgență.

Pentru un setup conservator, suprascrie default-urile permisive:

```yaml
readonly_mode: true
codex_full_permissions: false
mcp_mode: "ha-mcp"
context_detail_level: "summary"
```

Detalii complete și instrucțiuni avansate în README-ul repository-ului.
