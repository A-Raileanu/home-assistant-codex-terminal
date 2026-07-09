---
name: ha-version-notes
description: Note Home Assistant dependente de versiune si reguli pentru verificarea documentatiei oficiale.
---

# Note Sensibile La Versiunea Home Assistant

Aceste note sunt utile pentru compatibilitate, dar pot deveni stale. Daca instanta ruleaza o versiune mai veche sau daca modificarea depinde critic de o functionalitate noua, verifica documentatia oficiala Home Assistant inainte de implementare.

## Regula

- Nu trata notele de mai jos ca adevar permanent.
- Cand ai dubii, verifica versiunea instantei in `/data/ha-context/system.json` sau in UI.
- Pentru schimbari cu risc, consulta documentatia oficiala Home Assistant sau release notes.

## Note Grupate

| Zona | Nota din skill-uri |
|---|---|
| Notificari | `notify.send_message` este default-ul recomandat in skill; serviciile per-platforma raman fallback. |
| Lumini | `color_temp_kelvin` este forma recomandata; evita `color_temp` in mireds. |
| Automatizari | Triggerele/conditiile specifice persoanelor mentionate ca eliminate in skill trebuie verificate daca instanta este pe versiuni diferite. |
| Timer/media triggers | Notele despre triggere timer/media player introduse recent trebuie validate pe versiunea instalata. |
| Dashboards | Functionalitati precum Distribution card, section background colors, favorites si auto-height depind de versiunea frontend/HA. |
| Templates | Functii Jinja noi precum `entity_name()` sau `state_attr_translated()` trebuie verificate pe instanta curenta. |
| Add-ons | Termenul "Apps" poate aparea in UI/documentatie noua, dar add-on ramane termenul tehnic HA folosit frecvent. |

## Surse Recomandate

- Documentatia oficiala pentru integrare: `https://www.home-assistant.io/integrations/<domain>/`
- Dashboard docs: `https://www.home-assistant.io/dashboards/`
- Automation docs: `https://www.home-assistant.io/docs/automation/`
- Template docs: `https://www.home-assistant.io/docs/configuration/templating/`
- Release notes: `https://www.home-assistant.io/blog/categories/release-notes/`

## Cand Sa Blochezi Implementarea

Opreste-te si verifica oficial daca:

- automatizarea depinde de un trigger introdus/eliminat recent;
- un serviciu apare doar in exemple versionate;
- dashboard-ul foloseste card/features nou aparute;
- șablonul foloseste functie Jinja noua;
- schimbarea ar putea face o automatizare critica sa nu mai porneasca.
