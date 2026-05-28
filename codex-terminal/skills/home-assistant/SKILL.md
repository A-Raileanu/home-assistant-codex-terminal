---
name: home-assistant
description: Index principal Home Assistant Skills. Citește acest fișier întâi pentru a determina ce fișier specific să folosești.
---

# Home Assistant Skills — Index

Skill-uri pentru inventar consistent și automatizări lizibile. **Citește doar fișierul relevant pentru taskul curent** — nu citi tot repo-ul.

---

## Quick start (pentru AI)

1. **Identifică taskul** în tabelul de rutare de mai jos.
2. **Citește DOAR fișierul corespunzător** + `inventory.yaml` dacă taskul atinge device-uri/entități.
3. **La sfârșit** dacă ai modificat ceva tangibil în HA (device, entitate, redenumire): actualizează `inventory.yaml` cu o intrare nouă în `change_log:`.
4. **Nu citi în avans** fișiere care nu se aplică — token-uri irosite.

**Convenție generală a repo-ului:** română peste tot (alias-uri, comentarii, friendly names, descrieri) cu diacritice complete; engleză doar pentru entity_id slugs, slug-uri de label și câmpuri tehnice YAML.

---

## Rutare — ce fișier să citești

| Task | Fișier |
| ---- | ------ |
| Adaugă / redenumește o area | [ha-devices-areas.md](ha-devices-areas.md#areas) |
| Găsește / creează / atribuie un label (tip device) | [ha-devices-areas.md](ha-devices-areas.md#labels) |
| Numește un device nou (`[Cameră] Producător Model`) | [ha-devices-areas.md](ha-devices-areas.md#device-names) |
| Shelly multi-canal, senzor multi-funcție, cameră video | [ha-devices-areas.md](ha-devices-areas.md#cazuri-speciale-frecvente) |
| Workflow complet adăugare device (10 pași) | [ha-devices-areas.md](ha-devices-areas.md#cheat-sheet--adăugare-device-nou) |
| Schema `inventory.yaml` / workflow actualizare | [ha-devices-areas.md](ha-devices-areas.md#inventar-persistent--inventoryyaml) |
| Găsește entity name (RO) corect — vocabular funcții | [ha-entities.md](ha-entities.md) |
| 120+ termeni entity: Energie, Climat, Mișcare, Securitate... | [ha-entities.md](ha-entities.md) |
| Format entity ID, reguli stricte | [ha-entities.md](ha-entities.md#entity-ids) |
| `device_class` recomandat pentru template sensors | [ha-entities.md](ha-entities.md#device-classes-recomandate) |
| Dezactivare entități nefolosite post-import | [ha-entities.md](ha-entities.md#post-redenumire-dezactivare-entități--verificare-referințe) |
| Creează / redenumește o automatizare | [ha-automations.md](ha-automations.md) |
| Alege `mode:` (single/restart/queued/parallel) | [ha-automations.md](ha-automations.md#câmpul-mode) |
| Trigger IDs (`id:` pe declanșatori) | [ha-automations.md](ha-automations.md#trigger-id-uri) |
| Bune practici, condiții native, wait actions, repeat | [ha-automations.md](ha-automations.md#bune-practici-și-pattern-uri) |
| Dezactivare automatizări (Metoda 1 vs Metoda 2) | [ha-automations.md](ha-automations.md#dezactivarea-automatizărilor) |
| Anti-pattern-uri automatizări | [ha-automations.md](ha-automations.md#anti-pattern-uri) |
| Creează / redenumește un script | [ha-scripts-steps.md](ha-scripts-steps.md) |
| Definește `fields:` (parametri script, selector types) | [ha-scripts-steps.md](ha-scripts-steps.md#câmpul-fields-parametri) |
| Scrie alias-uri pentru pași (`alias:` în sequence) | [ha-scripts-steps.md](ha-scripts-steps.md#pași-steps--sequence) |
| `variables:` în secvențe (reutilizare valori) | [ha-scripts-steps.md](ha-scripts-steps.md#variabile-reutilizabile--variables) |
| Creează un helper (boolean, number, timer, counter, etc.) | [ha-helpers-scenes.md](ha-helpers-scenes.md) |
| Alege între helpers (decision matrix) | [ha-helpers-scenes.md](ha-helpers-scenes.md#ghid-selectare-helper-când-să-folosești-ce) |
| Creează o scenă | [ha-helpers-scenes.md](ha-helpers-scenes.md#scene-uri) |
| Scrie o notificare / alertă / anunț TTS | [ha-notifications.md](ha-notifications.md) |
| `notify.send_message` (HA 2024.7+) | [ha-notifications.md](ha-notifications.md#serviciul-recomandat--notifysend_message-ha-20247) |
| Canale, priorități, notificări acționabile, Jinja2 | [ha-notifications.md](ha-notifications.md) |
| Creează sau modifică un dashboard Lovelace | [ha-dashboards.md](ha-dashboards.md) |
| View types, carduri built-in, features, custom cards | [ha-dashboards.md](ha-dashboards.md) |
| CSS styling, HACS, anti-pattern-uri dashboard | [ha-dashboards.md](ha-dashboards.md) |
| Scrie sau depanează template-uri Jinja2 | [ha-templates.md](ha-templates.md) |
| Când să folosești templates vs native conditions | [ha-templates.md](ha-templates.md#când-să-eviți-template-urile) |
| Performanță templates, trigger-based templates | [ha-templates.md](ha-templates.md) |
| Redenumire entități, impact analysis | [ha-refactoring.md](ha-refactoring.md) |
| Config-Entry-Groups, Config-Entry-Data (blind spots) | [ha-refactoring.md](ha-refactoring.md#config-entry-groups) |
| Storage dashboards, YAML-only integrations | [ha-refactoring.md](ha-refactoring.md#storage-dashboards-storagelovelace) |
| Exemplu concret end-to-end refactoring | [ha-refactoring.md](ha-refactoring.md#exemplu-end-to-end--redenumire-smart-plug) |
| Service calls, structura `target:` / `data:` | [ha-device-control.md](ha-device-control.md#service-calls-best-practices) |
| ZHA buttons (`device_ieee`), Z2M triggers | [ha-device-control.md](ha-device-control.md#zigbee-buttonremote-patterns) |
| Lumini (`color_temp_kelvin`), climate, cover, vacuum | [ha-device-control.md](ha-device-control.md#domain-specific-patterns) |
| Diagnosticare device-uri și troubleshooting | [ha-device-control.md](ha-device-control.md#diagnosticare-și-troubleshooting) |
| Add-on (App) development, Supervisor API | [ha-device-control.md](ha-device-control.md#add-on-development) |
| Exemple YAML complete și cheat sheet rapid | [ha-examples.md](ha-examples.md) |
| Pattern-uri compuse (8 exemple best practice) | [ha-examples.md](ha-examples.md#exemple-pattern-uri-best-practices) |

---

## Inventarul

[`inventory.yaml`](inventory.yaml) este **sursa de adevăr** pentru toate device-urile și entitățile gestionate în HA-ul utilizatorului. AI-ul îl citește la începutul oricărei sesiuni care implică device-uri și îl actualizează la sfârșit (`devices:` + `change_log:`). Schema completă: vezi `ha-devices-areas.md` secțiunea Inventar.

---

## Glosar — termeni HA folosiți des

| Termen | Definiție |
|---|---|
| **Entity** | O unitate funcțională în HA (`light.living_ceiling`). Format: `<domain>.<slug>`. Are stare + atribute. |
| **Device** | Grupare logică a mai multor entități care aparțin aceluiași hardware fizic (un Aqara T1 = `sensor.temperature` + `sensor.humidity` + `sensor.battery`). |
| **Area** | O „cameră" sau locație logică (`living`, `dormitor1`). Entitățile și device-urile se asignează unei arii. |
| **Label** | Etichetă transversală pe TIPUL de device (`lumina`, `senzor_miscare`). Independentă de arie. |
| **Entity Registry** | `core.entity_registry` din `.storage/`. Conține entity_id, friendly name, disabled state, area, labels, unique_id. |
| **Device Registry** | `core.device_registry` din `.storage/`. Conține device_id, manufacturer, model, identifiers, area. |
| **Config Entry** | Configurare per-integrare în `core.config_entries`. Conține `data` (setup inițial) + `options` (modificate via Options Flow). |
| **Config Flow** | UI wizard la prima setare a unei integrări. Scrie în `data` al Config Entry. |
| **Options Flow** | UI wizard pentru modificarea unei integrări existente. Scrie în `options`. Unul activ per Config Entry. |
| **Helper** | Entitate virtuală creată din UI (input_boolean, input_number, timer, counter, template helper, etc.). |
| **Service call** | Acțiunea unei automatizări/script. Format: `action: domain.service_name` + `target:` + `data:`. |
| **Trigger** | Eveniment care pornește o automatizare (`state`, `numeric_state`, `event`, `time`, `mqtt`, etc.). |
| **`has_entity_name: True`** | Convenție HA 2023+ — entity name se concatenează automat cu device name la afișare. |
| **`.storage/`** | Directorul intern HA cu fișiere JSON de stare (`lovelace.*`, `core.entity_registry`, `core.device_registry`, `core.config_entries`). **Nu se editează direct** — folosește REST/WebSocket API. |
| **`unique_id`** | ID unic intern pentru o entitate, persistent la redenumiri. Permite customizare din UI. Obligatoriu pentru template sensors. |
| **`device_class`** | Etichetă semantică HA (`power`, `temperature`, `motion`) care influențează unități, iconițe, integrarea în Energy Dashboard. |
| **`state_class`** | `measurement` / `total` / `total_increasing` — controlează cum HA generează statistici pe termen lung. |
