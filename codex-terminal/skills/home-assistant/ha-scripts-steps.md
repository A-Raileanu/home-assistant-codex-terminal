---
name: ha-scripts-steps
description: Entry point rapid pentru scripturi Home Assistant: alias, fields, sequence, variables, choose, repeat si pasi cu alias.
---

# Scripturi — Entry Point

Pentru detalii si exemple, citeste [references/ha-scripts-steps.md](references/ha-scripts-steps.md).

## Fast Path

1. Alias in romana si scop clar.
2. Defineste `fields:` pentru parametri expusi UI/automatizari.
3. Pune `alias:` pe pasii importanti din `sequence`.
4. Foloseste `variables:` pentru valori reutilizate sau calcule intermediare.
5. Foloseste `choose` pentru ramificari clare.
6. Foloseste `repeat` doar cand numarul de iteratii/conditia e explicita.
7. Pentru notificari in scripturi, foloseste `notify.send_message`.

## Cand Sa Deschizi Referinta

| Ai nevoie de | Sectiune |
|---|---|
| `fields:` si selectori | [references/ha-scripts-steps.md](references/ha-scripts-steps.md#campul-fields-parametri) |
| `sequence` si alias pe pasi | [references/ha-scripts-steps.md](references/ha-scripts-steps.md#pasi-steps--sequence) |
| Variabile | [references/ha-scripts-steps.md](references/ha-scripts-steps.md#variabile-reutilizabile--variables) |
| Exemple complete | [references/ha-scripts-steps.md](references/ha-scripts-steps.md) |

## TL;DR

Scriptul este procedura reutilizabila. Parametri in `fields`, pasi lizibili cu `alias`, notificari prin `notify.send_message`.
