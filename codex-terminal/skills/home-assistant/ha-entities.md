---
name: ha-entities
description: Punct de pornire pentru entități Home Assistant: `friendly_name`, `entity_id`, vocabular românesc, `device_class` și verificări după redenumire.
---

# Entitati — Punct de pornire

Pentru vocabularul complet si exemple, citeste [references/ha-entities.md](references/ha-entities.md). Pentru impactul redenumirilor, citeste [ha-refactoring.md](ha-refactoring.md).

## Pași rapizi

1. Friendly name explicit pe fiecare entitate: `[Area] Nume dispozitiv - Functie`.
2. Entitatea principala fara functie separata: `[Area] Nume dispozitiv`.
3. `entity_id`: `<domain>.<area_slug>_<functie_slug>` sau `<domain>.<area_slug>_<device_slug>_<functie_slug>` cand e nevoie de dezambiguare.
4. Foloseste vocabularul romanesc existent pentru `Functie`; adauga termen nou doar daca nu exista sinonim canonic.
5. Seteaza `device_class`, `state_class` si `unit_of_measurement` cand domeniul o cere.
6. Nu schimba `entity_id` pentru cosmetica; foloseste friendly name. Daca schimbi `entity_id`, auditeaza referintele.
7. Dezactiveaza entitatile auto-create nefolosite dupa onboarding.

## Cand Sa Deschizi Referinta

| Ai nevoie de | Sectiune |
|---|---|
| Format friendly name | [references/ha-entities.md](references/ha-entities.md#format-canonic) |
| Vocabular functii | [references/ha-entities.md](references/ha-entities.md#vocabular-standard-doar-partea-funcție) |
| `device_class` / `state_class` | [references/ha-entities.md](references/ha-entities.md#device-classes-recomandate) |
| Reguli `entity_id` | [references/ha-entities.md](references/ha-entities.md#entity-ids) |
| Dezactivare post-import | [references/ha-entities.md](references/ha-entities.md#post-redenumire-dezactivare-entități-verificare-referințe) |

## TL;DR

Friendly name explicit, functie in romana, `entity_id` stabil in engleza. Redenumirea de `entity_id` cere audit de referinte.
