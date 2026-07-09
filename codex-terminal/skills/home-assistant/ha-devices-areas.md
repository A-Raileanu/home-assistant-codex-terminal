---
name: ha-devices-areas
description: Punct de pornire pentru dispozitive, camere, etichete și memoria de redenumire `rename_memory.json` din Home Assistant.
---

# Dispozitive, Arii si Labels — Punct de pornire

Pentru liste canonice, exemple si cazuri speciale, citeste [references/ha-devices-areas.md](references/ha-devices-areas.md). Pentru memoria de redenumiri, citeste [references/rename-memory.md](references/rename-memory.md).

## Pași rapizi

1. Device name: `[Camera] Producator Model [#N]`.
2. `[#N]` se foloseste doar cand exista acelasi model in aceeasi arie.
3. Area este camera/logica HA; pastreaza slug-urile existente si nu inventa arii fara motiv.
4. Label-ul descrie tipul/functia dispozitivului, nu camera. Alege un label existent inainte sa creezi unul nou.
5. Inainte de redenumire, verifica `rename_memory.json`; sari peste intrarile deja canonical sau cu `skip_rename_by_default: true`.
6. Pentru fiecare entitate a dispozitivului, aplica formatul din [ha-entities.md](ha-entities.md).

## Flux Device Nou

1. Gaseste dispozitivul in registrul HA sau in `rename_memory.json`.
2. Stabileste area, producatorul si modelul oficial.
3. Verifica daca exista duplicat in aceeasi camera pentru `#N`.
4. Alege label-ul canonic.
5. Stabileste friendly names pentru toate entitatile.
6. Dezactiveaza entitatile auto-create nefolosite.
7. Daca schimbi `entity_id`, ruleaza auditul din [ha-refactoring.md](ha-refactoring.md).
8. Ruleaza `ha-context --force` dupa aplicare.

## Cand Sa Deschizi Referinta

| Ai nevoie de | Sectiune |
|---|---|
| Lista arii | [references/ha-devices-areas.md](references/ha-devices-areas.md#areas) |
| Lista labels | [references/ha-devices-areas.md](references/ha-devices-areas.md#labels) |
| Cazuri Shelly, multi-sensor, camere video | [references/ha-devices-areas.md](references/ha-devices-areas.md#cazuri-speciale-frecvente) |
| Query rapid pentru memoria de rename | [references/rename-memory.md](references/rename-memory.md) |

## TL;DR

Device: `[Camera] Producator Model [#N]`. Label: tip device. Nu repeta redenumiri canonical. `rename_memory.json` este sursa curenta, nu un inventar manual.
