---
name: ha-templates
description: Punct de pornire pentru șabloane Home Assistant: Jinja2, senzori bazați pe șabloane, declanșatoare, performanță și alternative native.
---

# Șabloane — Punct de pornire

Pentru exemple si detalii Jinja2, citeste [references/ha-templates.md](references/ha-templates.md).

## Pași rapizi

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
| Cand eviti șabloane | [references/ha-templates.md](references/ha-templates.md#când-să-eviți-șabloanele) |
| Jinja2 si exemple | [references/ha-templates.md](references/ha-templates.md) |
| Performanta | [references/ha-templates.md](references/ha-templates.md#considerații-de-performanță) |
| Trigger-based templates | [references/ha-templates.md](references/ha-templates.md#folosește-trigger-based-templates-pentru-logică-complexă) |

## TL;DR

Helper/native condition inainte de template. `template:` modern, fallback-uri sigure, trigger-based pentru calcule costisitoare.
