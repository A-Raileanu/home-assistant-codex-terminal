---
name: ha-helpers-scenes
description: Punct de pornire pentru elemente ajutătoare și scene Home Assistant: `input_boolean`, `input_number`, `input_select`, temporizatoare, contoare și șabloane.
---

# Helpers si Scene — Punct de pornire

Pentru matricea completa si exemple YAML, citeste [references/ha-helpers-scenes.md](references/ha-helpers-scenes.md).

## Pași rapizi Helpers

1. Foloseste helper nativ cand exprima starea mai clar decat un template.
2. `input_boolean`: moduri, flaguri, override manual.
3. `input_number`: praguri si setari ajustabile din UI.
4. `input_select`: moduri mutual exclusive.
5. `timer`: countdown-uri cu stare si eveniment de final.
6. `counter`: numarari persistente.
7. Template helper doar cand logica derivata nu are alternativa nativa.

## Pași rapizi Scene

1. Scena seteaza o stare dorita; scriptul executa pasi.
2. Alias in romana, clar si scurt.
3. Scenele de lumini folosesc valori explicite pentru brightness/temperatura/culoare.
4. Daca scena declanseaza actiuni secventiale, foloseste script in loc de scena.

## Cand Sa Deschizi Referinta

| Ai nevoie de | Sectiune |
|---|---|
| Matrice alegere helper | [references/ha-helpers-scenes.md](references/ha-helpers-scenes.md#ghid-selectare-helper-când-să-folosești-ce) |
| Exemple input_boolean/input_number/timer/counter | [references/ha-helpers-scenes.md](references/ha-helpers-scenes.md#helpers) |
| Scene vs scripturi | [references/ha-helpers-scenes.md](references/ha-helpers-scenes.md#scene-vs-scripturi) |
| Exemple scene | [references/ha-helpers-scenes.md](references/ha-helpers-scenes.md#exemple) |

## TL;DR

Helper pentru stare/configurare, scena pentru stare dorita, script pentru pasi.
