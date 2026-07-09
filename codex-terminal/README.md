# Codex Terminal

Interfață în terminal pentru OpenAI Codex CLI, integrată în Home Assistant.

## Funcții

- Acces din bara laterală prin Home Assistant ingress.
- Terminal complet în browser, fără pagini intermediare.
- Autentificare și configurare Codex păstrate în `/data/.codex`.
- Pornire în `/config`, pregătită pentru fișierele Home Assistant.
- Conversații păstrate cu `tmux` când închizi bara laterală.
- Date Home Assistant generate în Markdown și JSON structurat.
- Integrare opțională cu serverul MCP pentru Home Assistant.
- Skill-uri compacte pentru automatizări, panouri, șabloane, redenumiri și depanare.
- Diagnostic cu `codex-ha doctor` și editare sigură cu `ha-safe-edit plan/apply`.

## Utilizare

Deschide **Codex Terminal** din bara laterală. Meniul permite să începi o conversație, să reiei una salvată sau să alegi o acțiune Home Assistant.

La prima folosire, autentifică-te:

```bash
codex login
```

Comenzi utile:

```bash
ha-context
ha-context --force
codex-ha doctor
ha-safe-edit check
ha-safe-edit plan /config/automations.yaml -- sh -c 'comanda-de-editare'
ha-safe-edit apply <plan_id>
codex mcp list
```
