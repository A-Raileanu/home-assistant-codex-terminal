# Codex Terminal

Codex Terminal adaugă OpenAI Codex în bara laterală Home Assistant. Deschizi aplicația, te autentifici o singură dată și lucrezi direct în `/config`.

## Prima pornire

1. Pornește aplicația.
2. Deschide **Codex Terminal** din bara laterală.
3. Rulează `codex login` dacă autentificarea nu pornește automat.
4. Alege o conversație din meniul de pornire.

Autentificarea și configurarea Codex sunt păstrate în `/data/.codex`.

## Opțiuni

| Opțiune | Valoare implicită | Rol |
| --- | --- | --- |
| `auto_launch_codex` | `true` | Afișează meniul de pornire când deschizi terminalul. |
| `ha_smart_context` | `true` | Pregătește automat date despre sistemul Home Assistant. |
| `ha_context_refresh_minutes` | `30` | Actualizează datele automate numai când sunt mai vechi decât acest interval. |
| `context_detail_level` | `standard` | Cantitatea de date: `summary`, `standard` sau `full`. |
| `include_addon_logs` | `false` | Include fragmente din jurnalele aplicațiilor. |
| `enable_ha_mcp` | `true` | Permite înregistrarea serverului MCP Home Assistant. |
| `mcp_mode` | `ha-mcp` | Alege `ha-mcp`, `official`, `both` sau `disabled`. |
| `ha_mcp_version` | `7.12.0` | Versiunea serverului `ha-mcp`. |
| `readonly_mode` | `false` | Oprește modificările făcute de comenzile ajutătoare. |
| `enable_device_control` | `false` | Permite fluxurile care controlează dispozitive. |
| `codex_full_permissions` | `true` | Rulează Codex fără confirmare pentru fiecare comandă. |
| `safe_edit_backup_retention_days` | `30` | Șterge copiile de siguranță mai vechi decât numărul ales de zile. |
| `persistent_apk_packages` | `[]` | Pachete Alpine reinstalate la pornire. |
| `persistent_pip_packages` | `[]` | Pachete Python reinstalate la pornire. |

## Date Home Assistant

`ha-context` scrie datele generate în:

- `$CODEX_HOME/AGENTS.md`
- `$CODEX_HOME/skills/home-assistant-instance/SKILL.md`
- `/data/ha-context/*.json`
- `/data/ha-context/rename_memory.json`

Pentru actualizare imediată:

```bash
ha-context --force
```

## Integrarea MCP

Versiunea implicită `ha-mcp 7.12.0` este instalată în imagine și pornește fără descărcare la fiecare restart. Dacă alegi altă versiune prin `ha_mcp_version`, aplicația o pornește cu `uvx`.

Înregistrarea MCP este omisă când `readonly_mode` este activ sau `enable_device_control` este dezactivat.

Verificare:

```bash
codex mcp list
codex-ha doctor
```

## Editare sigură

```bash
ha-safe-edit backup /config/configuration.yaml
ha-safe-edit check
ha-safe-edit plan /config/automations.yaml -- sh -c 'comanda-de-editare'
ha-safe-edit apply <plan_id>
```

Planul păstrează fișierul original, verifică rezultatul și aplică schimbarea numai după confirmare.

## Depanare

- Rulează `codex-ha doctor` pentru programe, acces, MCP, skill-uri și opțiuni de siguranță.
- Rulează `ha-context --force` pentru a verifica accesul la Supervisor.
- Verifică jurnalul aplicației dacă terminalul nu se deschide.
- Alege `mcp_mode: disabled` dacă ai nevoie numai de terminal.
