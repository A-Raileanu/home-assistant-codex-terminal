---
name: ha-templates
description: Entry point rapid pentru template-uri Home Assistant: Jinja2, template sensors, trigger-based templates, performanta si alternative native.
---

# Template-uri — Entry Point

Pentru exemple si detalii Jinja2, citeste [references/ha-templates.md](references/ha-templates.md).

## Fast Path

1. Intreaba intai daca un helper sau o conditie nativa rezolva problema.
2. Foloseste template doar pentru logica derivata reala, agregari sau formatari care nu au alternativa nativa.
3. Pentru senzori YAML foloseste integrarea moderna `template:`, nu stilul legacy `sensor: - platform: template`.
4. Evita `states | selectattr...` peste toata instanta in senzori care se reevalueaza des.
5. Pentru senzori costisitori, prefera trigger-based templates.
6. Adauga fallback-uri pentru `unknown`, `unavailable`, `none`.
7. Pentru functii noi dependente de HA, verifica [references/ha-version-notes.md](references/ha-version-notes.md).

## Cand Sa Deschizi Referinta

| Ai nevoie de | Sectiune |
|---|---|
| Cand eviti template-uri | [references/ha-templates.md](references/ha-templates.md#cand-sa-eviti-template-urile) |
| Jinja2 si exemple | [references/ha-templates.md](references/ha-templates.md) |
| Performanta | [references/ha-templates.md](references/ha-templates.md#performanta-template-uri) |
| Trigger-based templates | [references/ha-templates.md](references/ha-templates.md#trigger-based-template-sensors) |

## TL;DR

Helper/native condition inainte de template. `template:` modern, fallback-uri sigure, trigger-based pentru calcule costisitoare.
