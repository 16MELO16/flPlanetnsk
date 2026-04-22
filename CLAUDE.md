# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Single-file static website for **«Цветочная планета»** — a flower market in Novosibirsk. The entire application lives in `index.html` with no build step, no dependencies, and no server-side code.

## Running the site

Open `index.html` directly in a browser, or serve it locally:

```bash
python3 -m http.server 8080
# then open http://localhost:8080
```

No installation, no compilation, no package manager.

## Architecture

Everything is in one file (`index.html`) in three logical sections:

1. **`<style>`** — all CSS, using CSS custom properties (`--bg`, `--emerald`, `--rose`, etc.) defined in `:root` for theming. Media queries are inlined near the components they affect.

2. **`<body>` HTML** — static structure with 5 tabs (cut flowers, potted plants, cuttings, bouquets, contacts). Product grids (`#grid-cut`, `#grid-pot`, `#grid-cuttings`, `#grid-bouquets`) are empty containers populated by JS. Modals for add/delete are at the bottom of `<body>`.

3. **`<script>`** — vanilla JS, no frameworks. Key subsystems:
   - **Data**: `DEFAULT_PRODUCTS` object holds all catalog items hardcoded. Sections: `cut`, `pot`, `cuttings`, `bouquets`.
   - **Storage**: `localStorage` via `fp_deleted` (Set of deleted IDs), `fp_added` (array of user-added products), `fp_photos` (map of product ID → base64 data URL). `getProducts(section)` merges defaults minus deleted plus added.
   - **Render**: `buildCardHTML(p, section, isBouq)` → HTML string; `renderSection(section)` writes to the grid div and binds event listeners. Called once on init and after any mutation.
   - **Edit mode**: toggled by the admin button; adds `edit-mode` class to `<body>` and `<header>`. CSS uses these classes to show delete (✕) buttons and photo-edit buttons on cards.
   - **Photos**: stored as compressed base64 in `localStorage` via `fp_photos`. Images are compressed with `<canvas>` before storage to stay within browser limits.
   - **Modals**: add-item modal (`#addModal`) and delete-confirm modal (`#deleteModal`), shown/hidden via the `hidden` attribute.
   - **Contact form**: submits to web3forms API using `access_key` in a hidden field. Validation is done client-side before submission.
   - **Animations**: `IntersectionObserver` adds `.visible` class to cards as they scroll into view. Re-triggered on tab switch via `observeCards()`.

## Deployment

Planned hosting: **GitHub Pages** with a custom domain. No build pipeline needed — push `index.html` to `main` and GitHub Pages serves it directly.

The contact form uses the **web3forms** API (`access_key` is hardcoded in the HTML — this is a public web3forms key, not a secret).

## Key patterns

- All user content is HTML-escaped through `esc()` before insertion to prevent XSS.
- Product IDs are stable strings like `cut-1`, `pot-3`, `bouq-2` — used as localStorage keys for photos and deletion tracking. New user-added products get IDs via `Date.now()`.
- The `bouquets` section uses a 2-column grid (`.grid-2`) and has an extra `comp` (composition) field; all other sections use 3-column (`.grid-3`).
- Badges are one of: `hit`, `rare`, `new` — mapped to CSS classes and display labels via `BADGE_CLASSES` / `BADGE_LABELS`.
