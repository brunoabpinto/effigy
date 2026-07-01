# Effigy — Progress

## Status
Card pipeline working end to end: PNG → indexed JSON → registry → in-game card
render (frame, gradient, name plate, power badge, holo foil) with base / shiny /
corrupted variants. Preview a card with `love . <id>` (e.g. `love . 001`).

## Decisions

### Sprite representation
- Indexed-palette JSON: `{"w","h","palette":[[r,g,b],...],"pixels":[[x,y,i],...]}`
  - RGB 0–255 ints, palette indices 0-based.
  - Fully transparent pixels (`a == 0`) are dropped, not stored.
- Authoring source is a PNG (e.g. Aseprite indexed mode). JSON is the shipped artifact.
- Card canvas: **40×56 portrait** (matches the full-bleed card aspect; maximizes art).
- Variants are generated at runtime, never stored.

### Card registry (`data/cards.lua`)
- Metadata not in the sprite: `id -> { name, element, power }`.
- Sprite pixels come from `data/<id>.json`; the registry supplies the rest.
- Champions: 001 Rootbound Colossus (earth, 11), 002 Fire Colossus (fire, 10),
  003 The Abyssal Shell (water, 9), 004 The Gale Phantom (air, 8),
  005 The Unnamed (aether, 12).
  - Note: 001/002 use custom names; 003–005 follow the design-doc names.
  - 002 power (10) is a placeholder pending confirmation.

### Card rendering (`src/card.lua`)
- Reusable `card.draw(sprite, element, x, y, scale, opts)`; `opts` = `{ name, power, holo, time }`.
- Element-colored frame with a vertical gradient (dark top → element color), rounded,
  masked via stencil. Dark gradient art well, groove for depth.
- Name plate: semi-transparent bottom bar, **Cinzel Bold** (`assets/fonts/`), auto-shrinks to fit.
- Power badge: fixed bottom-right circle (own zone so long names never collide),
  element-gradient interior + matching frame ring, mirrors the card construction.
- Holo foil (shiny): animated rainbow + light-streak GLSL shader, masked to the card.
- Element colors: fire red, water blue, air pale sky, earth green, aether purple.

### Variants (`src/sprite.lua`)
- **Shiny**: swap the palette, keep pixel indices.
- **Corrupted**: invert palette colors (`255 - c`) + seeded pixel displacement.
- RNG: `love.math.newRandomGenerator(seed)` (deterministic in LÖVE).
- JS/website determinism deferred — dropped for now to focus on the game.

### Converter (`tools/convert.sh`)
- Plain ImageMagick + awk, no GUI. Two modes:
  - `sh tools/convert.sh <in.png> <out.json>` — one file.
  - `sh tools/convert.sh` — batch every `art/*.png` → `data/<name>.json`.
- Reason: running the converter inside LÖVE opened a blocking GUI window. A shell
  tool is simpler and can't hang.
- Assumes clean flat-color art (no quantizer in the pipeline).

### Running
- `love .` — game loop (clean stub for now).
- `love . <id>` — dev card preview (`src/cardview.lua`); renders base/shiny/corrupted.
- Runs from the project root so `love.filesystem` reaches `src/`, `data/`, `assets/`
  (no `io`/sandbox hacks).

## Files
```
main.lua            game loop; with an id arg, enters card preview mode
conf.lua            window config (high-dpi on)
card                launcher (love . "$@")
src/sprite.lua      load JSON + shiny/corrupted variants
src/card.lua        reusable card renderer (frame, name, power, holo)
src/cardview.lua    dev preview: base/shiny/corrupted for one card id
data/cards.lua      card registry (id -> name/element/power)
data/<id>.json      shipped indexed sprites (001–005)
art/<id>.png        authoring sources (Aseprite)
tools/convert.sh    PNG -> indexed JSON converter (single + batch)
assets/fonts/       Cinzel-Bold.ttf
image.png           original reference (WebP-in-PNG)
game-design.md      design doc
```
