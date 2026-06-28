---
name: ha-examples
description: Entry point rapid pentru exemple YAML Home Assistant end-to-end si pattern-uri compuse.
---

# Exemple — Entry Point

Nu citi exemplele din reflex. Deschide [references/ha-examples.md](references/ha-examples.md) doar cand utilizatorul cere un exemplu complet sau cand un pattern compus este mai sigur decat instructiuni abstracte.

## Cand Merita

- Automatizare completa cu trigger, conditii, actiuni si notificare.
- Refactoring end-to-end al unui device/entitati.
- Pattern multi-component: helper + automatizare + script + dashboard.
- Exemplu de naming complet pentru device si entitati.

## Reguli Inainte De A Copia Un Exemplu

1. Adapteaza `entity_id`-urile la instanta curenta.
2. Verifica `rename_memory.json` pentru canonical names.
3. Inlocuieste notificari legacy cu `notify.send_message`.
4. Verifica notele versionate din [references/ha-version-notes.md](references/ha-version-notes.md).

## TL;DR

Exemplele sunt biblioteca de pattern-uri, nu primul fisier de citit.
