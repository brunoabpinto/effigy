# Effigy

A trading card game built around elemental decks and a sacrifice economy. Players
summon powerful creatures by consuming weaker ones. Basic creatures are generated
procedurally from a numeric seed — the same seed always produces the same creature.

Built with [LÖVE](https://love2d.org/) (Lua). All creature art is drawn from pixel
arrays at runtime — no image assets.

See [game-design.md](game-design.md) for the full design and [progress.md](progress.md)
for implementation notes.

## Running

Requires LÖVE 11+.

```sh
love .              # main menu (game entry point)
love . <id>         # dev card preview, e.g. love . 001
love . --dex        # dex: every registered creature in a grid
love . --parts      # preview the procedural basic-creature parts
./card <id>         # shortcut for the card preview
```

The main menu leads to **Campaign → choose a champion → deck view** (a scrollable
60-card deck for the chosen element).

## Concept

- **One stat: Power.** Basics are always power 1 — resources to sacrifice or block.
- **Five elements:** Fire, Water, Air, Earth, Aether — each with a champion.
- **Sacrifice to summon:** tribute basics from the board to summon stronger creatures.
- **Board control win:** clear the opponent's board, then attack their life.
- **Variants:** Normal, Shiny, Corrupted, Corrupted Shiny — all runtime transforms.

## Cards & sprites

- Sprites are indexed-palette JSON: `{ "w", "h", "palette": [[r,g,b],…], "pixels": [[x,y,i],…] }`.
- Canvas is **40×56** portrait. Fully transparent pixels are dropped.
- Authored art lives in `art/*.png`; convert to JSON with `tools/convert.sh`.
- Variants (shiny/corrupted) and the fog-of-war hidden state are generated at draw time.

### Procedural basics

Basic creatures are composited from feature parts (body, eyes, mouth, nose, limbs,
markings) under `data/basics/`. Parts store *palette slots* (0 outline, 1 base,
2 accent), not baked colors, so one part set works across all elements — the element
supplies the palette. `src/basic.lua` picks one variant per feature from a seed,
mirrors and composites them, and centers the result on the card canvas.

## Layout

```
main.lua            entry point; dispatches screens by mode
conf.lua            window config (1280x720)
card                launcher shortcut (love . "$@")

src/
  screens/
    menu.lua        main menu
    deckselect.lua  campaign champion / deck picker
    deckview.lua    scrollable 60-card deck grid
    dex.lua         grid of all registered creatures
    cardview.lua    single-card preview (base / shiny / corrupted)
    partsview.lua   dev preview of the basic-creature parts
  core/
    card.lua        reusable card renderer (frame, name, power, foil, glitch)
    sprite.lua      load JSON sprites + shiny/corrupted variants
    parts.lua       ASCII-grid parser for the basic-creature parts
    basic.lua       composites procedural basics from parts
    deck.lua        builds a 60-card deck (element cards + generated basics)

data/
  cards.lua         card registry (id -> name/element/power)
  <id>.json         authored sprites
  basics/           procedural creature parts (bodies.lua, eyes.lua, …)

art/                authoring sources (Aseprite PNGs)
tools/convert.sh    PNG -> indexed JSON converter
assets/fonts/       Cinzel-Bold.ttf
```
