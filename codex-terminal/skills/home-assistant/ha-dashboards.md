---
name: ha-dashboards
description: Punct de pornire pentru panouri Home Assistant: pagini, secțiuni, carduri, funcțiile cardurilor Tile, carduri personalizate și greșeli frecvente.
---

# Panouri — Punct de pornire

Pentru detalii complete, exemple si matrici de carduri, citeste [references/ha-dashboards.md](references/ha-dashboards.md) doar cand taskul cere modificari Lovelace.

## Pași rapizi

1. Alege pagina dupa scop: `sections` pentru panouri moderne, `panel` pentru o singura experienta full-width, `masonry` doar pentru layout-uri vechi.
2. Pune informatia actionabila sus: lumini, climat, securitate, energie, media.
3. Foloseste carduri native inainte de carduri personalizate. Custom doar cand native nu acopera interactiunea.
4. Pentru entity cards, foloseste entitatile canonical din `rename_memory.json`; nu introduce `entity_id` vechi.
5. Pentru modificari in `.storage/lovelace*`, nu edita JSON manual daca ai alternativa prin API/UI; vezi [ha-refactoring.md](ha-refactoring.md).
6. Pentru functionalitati dependente de versiunea HA, verifica [references/ha-version-notes.md](references/ha-version-notes.md).

## Cand Sa Deschizi Referinta

| Ai nevoie de | Sectiune |
|---|---|
| View types si structura Lovelace | [references/ha-dashboards.md](references/ha-dashboards.md) |
| Carduri built-in si tile features | [references/ha-dashboards.md](references/ha-dashboards.md#carduri-incluse) |
| HACS/carduri personalizate | [references/ha-dashboards.md](references/ha-dashboards.md#carduri-personalizate) |
| Styling si greșeli frecvente | [references/ha-dashboards.md](references/ha-dashboards.md#capcane-frecvente) |

## TL;DR

Sections view, carduri native, entitati canonical, fara JSON storage editat manual cand exista API/UI.
