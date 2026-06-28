---
name: ha-dashboards
description: Dashboards Lovelace HA — view types (sections/panel/sidebar/masonry), carduri built-in (39 tipuri), features, custom cards, CSS, HACS, anti-pattern-uri. Citește pentru creare/modificare dashboard.
---

# Dashboards Lovelace — Home Assistant

> Pentru afirmații legate de versiuni HA/frontend, verifică [ha-version-notes.md](ha-version-notes.md) înainte de schimbări critice.

## Principii de design

- **Designează dashboarduri pentru uz zilnic repetat, nu pentru showcase.** Prioritizează built-in Sections dashboards și Tile cards pentru simplitate.
- **Organizează pe cameră, rutină sau task** — nu pe estetică.
- **Poziționează controalele adiacent informațiilor relevante** pentru operare sigură.
- **Nu edita fișierele `.storage/` direct** când există opțiuni API/YAML disponibile.
- **Mobile-first:** testează pe viewport de telefon.
- **Consistență cu entity naming:** folosește entity_id-uri corecte din registru.

## Workflow

1. Cataloghează dashboardurile existente — determină dacă sunt storage-based sau YAML.
2. Verifică entity ID-urile înainte de implementare.
3. Folosește API/MCP pentru modificări — nu editare directă `.storage/`.
4. Testează pe viewport mobil.

---

## Structura dashboardului

```json
{
  "title": "Casa Mea",
  "icon": "mdi:home",
  "config": {
    "views": [
      {
        "title": "Privire generală",
        "path": "home",
        "type": "sections",
        "max_columns": 4,
        "sections": [
          {"title": "Climatizare", "cards": [...]},
          {"title": "Lumini", "cards": [...]}
        ]
      }
    ]
  }
}
```

**Reguli url_path:**
- Dashboardurile noi trebuie să conțină o cratimă: `my-dashboard` (nu `mydashboard`)
- Folosește `lovelace` pentru a ținti dashboardul implicit built-in
- `dashboard_id`: identificator intern (returnat la creare, folosit pentru update/delete)
- `url_path`: identificator URL (vizibil utilizatorului, folosit în URL-urile dashboardului)

---

## Tipuri de view

| Tip | Folosește pentru |
|------|---------|
| `sections` | Majoritatea dashboardurilor (RECOMANDAT) — grid-based, responsive |
| `panel` | Carduri unice pe tot ecranul (hărți, camere, iframes) |
| `sidebar` | Layout pe două coloane cu conținut primar/secundar |
| `masonry` | Legacy — aranjează cardurile automat, mai puțin control |

### Configurarea view-ului

```json
{
  "title": "Nume view",
  "path": "unique-path",
  "type": "sections",
  "icon": "mdi:icon",
  "max_columns": 4,
  "sections": [...],
  "subview": false,
  "badges": ["sensor.entity_id"],
  "background": {"image": "url(/local/background.jpg)", "opacity": 0.3}
}
```

---

## Carduri built-in

Home Assistant oferă **39 tipuri de carduri built-in**. Documentație pentru fiecare card disponibilă la:
```
https://raw.githubusercontent.com/home-assistant/home-assistant.io/refs/heads/current/source/_dashboards/{card_type}.markdown
```

Același pattern URL acoperă și 4 tipuri de view (`masonry`, `panel`, `sections`, `sidebar`) — setate la nivel de view via `"type"`, nu în arrays de carduri.

| Categorie | Carduri |
|----------|-------|
| **Modern Primary** | tile, area, button, grid |
| **Container** | vertical-stack, horizontal-stack, grid |
| **Logic** | conditional, entity-filter |
| **Display** | sensor, history-graph, statistics-graph, gauge, energy, calendar, distribution |
| **Legacy Control** | entity, entities, light, thermostat (folosește tile în schimb) |

**Default:** Folosește cardul `tile` pentru majoritatea entităților.

### Tile Card

```json
{
  "type": "tile",
  "entity": "climate.dormitor1_thermostat",
  "name": "Dormitor Principal",
  "icon": "mdi:thermostat",
  "features": [
    {"type": "target-temperature"},
    {"type": "climate-hvac-modes", "style": "dropdown"}
  ],
  "tap_action": {"action": "more-info"}
}
```

### Grid Card

```json
{
  "type": "grid",
  "columns": 3,
  "square": false,
  "cards": [
    {"type": "tile", "entity": "light.bucatarie_ceiling"},
    {"type": "tile", "entity": "light.dining_ceiling"},
    {"type": "tile", "entity": "light.hol_ceiling"}
  ]
}
```

---

## Features

Controale rapide disponibile pe tile, area, humidifier și thermostat cards.

| Domeniu | Tipuri de feature |
|--------|--------------|
| Climate | `climate-hvac-modes`, `climate-fan-modes`, `climate-preset-modes`, `target-temperature` |
| Light | `light-brightness`, `light-color-temp` |
| Cover | `cover-open-close`, `cover-position`, `cover-tilt` |
| Fan | `fan-speed`, `fan-direction`, `fan-oscillate` |
| Media | `media-player-playback`, `media-player-volume-slider` |
| Valve | `valve-open-close`, `valve-position` |
| Other | `toggle`, `button`, `alarm-modes`, `lock-commands`, `numeric-input`, `datetime-picker` |

### Extra-uri Tile Card (2025.9+)

- **Trend graph:** sparkline 24h pentru entități numerice
- **Bar gauge:** afișare procentuală pentru entități numerice
- **Action buttons:** rulează automatizări/scripturi direct din tile cards

Feature `style` options: `"dropdown"` sau `"icons"`

---

## Acțiuni

```json
{
  "tap_action": {"action": "toggle"},
  "hold_action": {"action": "more-info"},
  "double_tap_action": {"action": "navigate", "navigation_path": "/lovelace/lights"}
}
```

Tipuri de acțiuni: `toggle`, `call-service`, `more-info`, `navigate`, `url`, `none`

### Condiții de vizibilitate

```json
{
  "visibility": [
    {"condition": "user", "users": ["user_id_hex"]},
    {"condition": "state", "entity": "sun.sun", "state": "above_horizon"}
  ]
}
```

---

## Carduri custom

Folosește custom JavaScript cards când cardurile built-in nu suportă vizualizarea dorită.

### Card custom minimal

```javascript
class MyCard extends HTMLElement {
  setConfig(config) {
    if (!config.entity) throw new Error("Please define an entity");
    this.config = config;
  }
  set hass(hass) {
    if (!this.content) {
      this.innerHTML = `<ha-card header="${this.config.title || 'My Card'}">
        <div class="card-content"></div>
      </ha-card>`;
      this.content = this.querySelector(".card-content");
    }
    const state = hass.states[this.config.entity];
    this.content.innerHTML = state ? `State: ${state.state}` : "Entity not found";
  }
  getCardSize() { return 2; }
}
customElements.define("my-card", MyCard);
window.customCards = window.customCards || [];
window.customCards.push({ type: "my-card", name: "My Card", description: "A custom card" });
```

Utilizare: `{"type": "custom:my-card", "entity": "sensor.temperature"}`

### Workflow card custom

1. Scrie clasa JavaScript (vezi Card custom minimal de mai sus)
2. Înregistreaz-o ca dashboard resource via HA REST API (`/api/config/lovelace/resources`) cu `resource_type: "module"`
3. Folosește cardul cu prefix `custom:` în config-ul dashboardului

```json
{
  "type": "custom:quick-status-card",
  "entity": "sensor.living_temperature",
  "name": "Living"
}
```

---

## Stilizare CSS

### Theme overrides

```css
:root {
  --primary-color: #03a9f4;
  --ha-card-background: rgba(26, 26, 46, 0.9);
  --ha-card-border-radius: 16px;
  --ha-card-box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}
```

### Card-mod (stilizare per card)

Necesită componenta HACS `card-mod`:

```yaml
type: entities
card_mod:
  style: |
    ha-card {
      --ha-card-background: teal;
      color: var(--primary-color);
    }
entities:
  - light.dormitor1_ceiling
```

---

## Integrare HACS

| Caz de utilizare | Soluție |
|----------|----------|
| Card comunitar popular | HACS — caută și instalează via HACS API |
| CSS styling mic | Inline CSS — înregistrează via HA dashboard resource API |
| Card custom one-off | Inline module — înregistrează via HA dashboard resource API |
| Card mare/complex | HACS sau filesystem (`/config/www/`) |

### Carduri HACS populare

- **mushroom** — Modern, clean card collection
- **button-card** — Highly customizable buttons
- **mini-graph-card** — Compact graphs
- **card-mod** — CSS styling for any card
- **layout-card** — Advanced layout control
- **apexcharts-card** — Professional charts

---

## Exemplu complet: dashboard multi-view

```json
{
  "views": [
    {
      "title": "Privire generală",
      "path": "home",
      "type": "sections",
      "max_columns": 4,
      "badges": ["person.andrei", "person.maria"],
      "sections": [
        {
          "title": "Acțiuni rapide",
          "cards": [{
            "type": "grid",
            "columns": 4,
            "square": false,
            "cards": [
              {"type": "button", "name": "Lumini", "icon": "mdi:lightbulb", "tap_action": {"action": "navigate", "navigation_path": "/lovelace/lights"}},
              {"type": "button", "name": "Climatizare", "icon": "mdi:thermostat", "tap_action": {"action": "navigate", "navigation_path": "/lovelace/climate"}},
              {"type": "button", "name": "Securitate", "icon": "mdi:shield-home", "tap_action": {"action": "navigate", "navigation_path": "/lovelace/security"}},
              {"type": "button", "name": "Energie", "icon": "mdi:lightning-bolt", "tap_action": {"action": "navigate", "navigation_path": "/lovelace/energy"}}
            ]
          }]
        },
        {
          "title": "Favorite",
          "cards": [{
            "type": "grid",
            "columns": 3,
            "square": false,
            "cards": [
              {"type": "tile", "entity": "light.living_ceiling", "features": [{"type": "light-brightness"}]},
              {"type": "tile", "entity": "climate.dormitor1_thermostat", "features": [{"type": "target-temperature"}]},
              {"type": "tile", "entity": "lock.usa_intrare"}
            ]
          }]
        }
      ]
    },
    {
      "title": "Lumini",
      "path": "lights",
      "type": "sections",
      "icon": "mdi:lightbulb",
      "max_columns": 3,
      "sections": [
        {
          "title": "Living",
          "cards": [{
            "type": "grid",
            "columns": 3,
            "cards": [
              {"type": "tile", "entity": "light.living_ceiling", "features": [{"type": "light-brightness"}]},
              {"type": "tile", "entity": "light.living_tv_led", "features": [{"type": "light-brightness"}]},
              {"type": "tile", "entity": "light.living_accent", "features": [{"type": "light-color-temp"}]}
            ]
          }]
        }
      ]
    }
  ]
}
```

---

## Capcane frecvente

| Problemă | Soluție |
|-------|----------|
| url_path respins | Dashboardurile noi au nevoie de o cratimă: `my-dashboard` nu `mydashboard`. Folosește `lovelace` pentru dashboardul implicit. |
| Entitate negăsită | Folosește entity ID complet: `light.living_ceiling` nu `living_ceiling` |
| Features nu funcționează | Potrivește tipul de feature cu domeniul entității (ex: `light-brightness` merge doar pe `light.*`) |
| Card custom nu se încarcă | Verifică ca tipul de resource să fie `module` și că URL-ul este accesibil |
| Card prea mare pentru inline | Folosește HACS sau filesystem în schimb |

---

## Bune practici moderne (2024+)

- Folosește tipul de view **sections** cu layout grid-based
- Folosește **tile** cards ca tip principal (înlocuiește cardurile legacy entity/light/climate)
- Folosește **grid** cards pentru layout multi-coloană în sections
- Creează **multiple views** cu navigation paths (evită single-view cu scroll infinit)
- Folosește **area** cards cu navigare pentru organizare ierarhică

### Funcționalități recente de dashboard (2026.2–2026.4)

| Feature | Versiune | Detalii |
|---------|---------|---------|
| **Distribution card** | 2026.2 | Bare orizontale proporționale pentru multiple entități |
| **Section background colors** | 2026.4 | Sections suportă `background_color` personalizat cu opacitate ajustabilă |
| **Card favorites** | 2026.4 | Light color favorites și cover position favorites pe tile/light cards |
| **Auto-height cards** | 2026.4 | Cardurile se ajustează automat la înălțime bazat pe conținut |

### Legacy patterns de evitat

- Single-view dashboards cu toate cardurile într-un scroll lung
- Utilizare excesivă de vertical-stack/horizontal-stack în locul grid
- Masonry view (auto-layout) — folosește sections pentru control precis
- Toate entitățile în carduri generice "entities"

---

## Workflow iterativ vizual

Pentru design iterativ cu feedback vizual, adaugă un MCP server de browser automation:

### Workflow

```
1. Creează/actualizează dashboard via HA config API
2. Navighează browser-ul la URL-ul dashboardului
3. Fă screenshot pentru a vedea layout-ul curent
4. Analizează screenshot-ul pentru probleme (spacing, alignment, culori)
5. Ajustează configurația și repetă
```

---

**TL;DR:** View type `sections` + cardul `tile` ca default. Grid cards pentru layout multi-coloană. Multiple views cu navigation. Nu edita `.storage/` direct — folosește API. `url_path` necesită cratimă pentru dashboarduri noi.
