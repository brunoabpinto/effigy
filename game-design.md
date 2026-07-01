# Effigy
> *Trading Card Game — Design Document*

---

## Concept

A trading card game built around elemental decks and a sacrifice economy. Players summon increasingly powerful creatures by consuming weaker ones. Basic creatures are procedurally generated from a numeric seed — the same number always produces the same creature, anywhere, forever.

---

## Core Philosophy

- Simple rules, deep decisions
- Every basic creature is unique but expendable
- The board is everything — you cannot win without clearing it
- Power is the only stat that matters

---

## Elements

Five classical elements, each with a distinct mechanical identity.

| Element | Identity |
|--------|----------|
| 🔥 Fire | Aggressive, burns everything down, snowballs |
| 💧 Water | Attrition, hard to kill, wins late |
| 🌬️ Air | Speed, pressure, denies setup |
| 🌍 Earth | Walls, outlasts, makes attacks costly |
| ✨ Aether | Flexible, unpredictable, adapts |

Decks can mix elements freely (see Deck Building). Champions still anchor a deck's identity since they require 5 matching basics to summon.

---

## Cards

### Basic Creatures

- Generated procedurally from a numeric seed (e.g. Fire Creature #1234)
- Same seed = same creature, always
- Built from combined pixel arrays: each feature (body, eyes, mouth, nose, limbs, markings) is its own named array composited at render time
- Each has one passive trait also derived from seed
- Low power, used as blockers or sacrifice fodder

### Summoned Creatures

- Stronger, hand-crafted creatures
- Require sacrificing a set number of basics from the board
- The more powerful the creature, the more basics required

---

## Stats

Only one stat: **Power**

No attack/defense split. Power is used for everything.

**Basic creatures have 1 power**, regardless of element or seed. They are not combatants — they are resources to sacrifice or expendable blockers.

---

## Combat

### Attacking
- Declare an attack with one of your creatures targeting an enemy creature
- Defender chooses which creature blocks (defender's choice, not attacker's)
- Must block if able — at least one creature must be assigned to block
- One blocker per attacker, no gang blocking

### Damage Resolution
Combat is asymmetric, based on relative power:

- **Attacker stronger than defender**: defender dies. Attacker takes no damage.
- **Attacker weaker than or equal to defender**: mutual damage. Defender loses power equal to attacker's power. Attacker dies if defender's power ≥ attacker's power.
- **Equal power**: both die.

Damage does not persist between combats — survivors return to full power afterward. No coin flip, no randomness in combat. Pure power comparison.

Attacking something weaker is always free. Attacking something equal or stronger always risks the attacker. This naturally makes basics (power 1) bad attackers and bad blockers in isolation — they exist to be sacrificed, not to fight. Blocking with a basic to protect a stronger creature is a valid, intentional trade: the basic dies for nothing combat-wise, but it absorbed the hit.

### Summoning Rules
- Creatures cannot attack the turn they are summoned
- Exception: Air creatures can attack immediately on summon
- Basics can be sacrificed immediately on the turn they are played — sacrificing is a resource action, not a combat action

---

## Turn Structure

1. Flip coin at game start — winner chooses who goes first *(this coin flip is unrelated to combat — combat itself has no randomness)*
2. Draw 1 card
3. Play basics from hand to board freely
4. Sacrifice basics to summon creatures — as many as resources allow, up to 5 creature board limit
5. Attack with any eligible creatures
6. End turn

**Hand size**: 7 cards  
**Board limit**: 5 creatures per player  
**Save system**: autosave

---

## Win Condition

**Yugioh-style board control.**

- Both players start with **20 life points**
- You **cannot attack life points directly** while the opponent has creatures on the board
- Clear all opponent creatures → attack life points directly
- First player to reach 0 life loses

---

## Elemental Passives

### 🔥 Fire
- **Board passive**: your creatures deal 1 residual damage to any creature they fight, win or lose
- **Sacrifice bonus**: each basic sacrificed adds +1 power to the summon permanently

### 💧 Water
- **Board passive**: once per turn, discard a basic from hand to reduce incoming damage by 1
- **Sacrifice bonus**: summon enters with a temporary shield equal to the number of basics sacrificed

### 🌬️ Air
- **Board passive**: your creatures can attack the turn they are summoned
- **Sacrifice bonus**: each basic sacrificed grants the summon +1 power when attacking (stacks with base power)

### 🌍 Earth
- **Board passive**: your creatures gain +1 power while blocking
- **Sacrifice bonus**: summon enters with bonus power equal to half the basics sacrificed (rounded up)

### ✨ Aether
- **Board passive**: basics can be treated as any element for sacrifice purposes
- **Sacrifice bonus**: summon inherits the passive trait of the strongest basic sacrificed

---

## Summoning

- Sacrifice basics **from the board**, not from hand
- Sacrificed basics are removed from play
- Summoned creature enters the board immediately
- Sacrificing from the board creates a real decision: you are giving up defenders

---

## Deck Building

- **Deck size: 60 cards**, standard
- Mixed elements allowed — no mono-element restriction
- Duplicate seeds allowed freely — any number of any seed/element combo
- Generic summons: sacrifice any basics regardless of element
- Champions: require 5 matching element basics to summon
- Aether basics count as any element for champion sacrifice
- Starting deck basic ratio: roughly similar to MTG's land ratio (~20-24 basics out of 60) — exact number to be tuned in playtesting

---

## Technical Stack

- **Engine**: Love2D (Lua)
- **Creature rendering**: pixel array, drawn in real-time — no image assets
- **Storage**: seed + element only. Everything else reconstructed at runtime
- **Website**: same pixel array logic reimplemented in JavaScript — identical output for same seed

### Creature Representation

Every creature is an array of pixel positions and colors. No image files, no sprites, no assets.

```lua
-- Each entry is {x, y, {r, g, b}}
local creature = {
  {2, 3, {1.0, 0.3, 0.0}},
  {3, 3, {1.0, 0.3, 0.0}},
  {4, 3, {0.8, 0.1, 0.0}},
}

function drawCreature(pixels, ox, oy, scale)
  for _, p in ipairs(pixels) do
    love.graphics.setColor(p[3])
    love.graphics.rectangle("fill", ox + p[1]*scale, oy + p[2]*scale, scale, scale)
  end
end
```

### Seed System

```lua
function generateCreature(seed, element)
  local rng = love.math.newRandomGenerator(seed)
  -- seed drives structure, element drives color palette
  local pixels = {}
  -- build pixel array from RNG + element palette
  return pixels
end
```

### Variant Transforms

Variants are array transforms applied at render time. No extra storage needed.

```lua
function toCorrupted(pixels, seed)
  local rng = love.math.newRandomGenerator(seed)
  local result = {}
  for _, p in ipairs(pixels) do
    local c = p[3]
    local x = p[1] + (rng:random() < 0.15 and rng:random(-2, 2) or 0)
    local y = p[2] + (rng:random() < 0.15 and rng:random(-2, 2) or 0)
    result[#result+1] = {x, y, {1-c[1], 1-c[2], 1-c[3]}}
  end
  return result
end
```

### Creature Variants

Every creature has four possible states:

| Variant | Drop Rate | Visual |
|---------|-----------|--------|
| Normal | Common | Base palette |
| Corrupted | Rare | Negative colors + displaced pixels |
| Shiny | Rare | Alternate striking palette |
| Corrupted Shiny | Extremely rare | Both transforms combined |

**Sacrificing a shiny basic** transfers its shiny status to the summoned creature. The shiny basic is permanently destroyed — not discarded, gone forever from the collection.

**#000000** — exists outside the system. Hand-crafted pixel array designed to look broken. Pixels outside normal bounds, contradictory colors, intentional gaps. The only creature not generated — designed to look undesigned. Mechanically undefined. Sacrificing it does something unexpected.

---

## Expansion Model

The five elements are permanent and never change. New content comes as **factions** — new schools within an existing element, each with their own champion, summon roster, and passive flavor.

Examples:
- 🔥 **Volcanic** — eruption-based, area damage
- 🔥 **Ember** — swarm mechanics, death by a thousand cuts
- 💧 **Frost** — slowing, freezing creatures in place

Same element, different identity. Two Fire decks can play completely differently. Players learn the five elements once and that knowledge never expires.

### Seed Identity

A creature is identified by **element + seed**. Fire #1234 and Earth #1234 are different creatures — siblings, not duplicates.

- The seed drives structure: eye count, mouth shape, limb arrangement
- The element drives color palette and body style
- Same seed across elements produces visually related but distinct creatures
- No number ranges, no limits — any seed works for any element

This creates a natural collecting angle: own all five #1234s, one per element. The website shows all five variants side by side for any seed.

---

## Champions

One champion per deck — the identity card everything builds toward.

| Element | Champion | Power | Passive |
|---------|----------|-------|---------|
| 🔥 Fire | The Pyre Colossus | 10 | Deals 1 damage to every opponent creature at end of each turn |
| 💧 Water | The Abyssal Shell | 9 | Incoming power loss is halved, rounded up |
| 🌬️ Air | The Gale Phantom | 8 | Can attack twice per turn at half power each |
| 🌍 Earth | The Rootbound Titan | 11 | Cannot be destroyed by accumulated damage — must be killed in a single hit |
| ✨ Aether | The Unnamed | 12 | Once per game: copy any champion ability destroyed this match. Form is procedurally generated each summon. |

---

## Card Effects

One effect per summoned creature, maximum. No effects on basics — they are resources, not cards you read.

### Effect trigger types
- **On summon** — triggers when creature enters the board
- **On death** — triggers when destroyed
- **Passive** — always active while on board

Champions use passives only. Regular summons use on summon and on death.

### Summon Cost Formula

Yugioh-style tribute summoning. Sacrifice count gates which power tier you're allowed to summon from hand — it does not generate or randomize anything. Summon cards are fixed, printed, predetermined cards in your deck, identical every time, like any normal TCG card.

| Basics Sacrificed | Power Tier You May Summon |
|--------------------|---------------------------|
| 1 | 2–3 |
| 2 | 4–5 |
| 3 | 6–7 |
| 4 | 8–9 |
| 5 (champion-only) | 10–12 |

You sacrifice the required number of basics, then summon any card from your hand whose printed power falls in that tier. No randomness, no seed involvement. Seeds only apply to basic creatures' procedural visuals — summons and champions are static, designed cards.

---

## Monetization

**Buy it once, own it forever.**

- Base game: €12.99
- All factions free forever for owners as they release
- No DLC, no microtransactions, no battle passes, no sales, no discounts
- No pay to win, no cosmetic shops

This is a principle, not a strategy. Put it on the Steam page explicitly — there is an audience that will buy partly because of this.

### Physical Cards

Physical cards exist as **trophies only**, not a product.

- Tournament winners receive a physical version of the champion they used to win
- Holo foil, limited print run, optionally signed by the developer
- Proof you were there — people frame these
- Production via MakePlayingCards.com for small runs, no minimum order

### Revenue Reality

At €12.99:
- 800 sales → modest sustainable income
- 4000 sales → worth the years invested
- 10000 sales → genuine indie success

All achievable with a strong hook and the creature generator website doing marketing work before launch.

---

## Card Design

Full-bleed artwork with minimal UI overlay. No borders, no frames.

- Art fills the entire card
- Name and power in a semi-transparent bar at the bottom
- Effect text in a thin strip below that, small font
- Element icon in top-left corner, small
- Seed number in top-right corner on basics only
- Champion cards: no seed, larger name and power text

Basics are visually smaller than summons on the board, reinforcing hierarchy.

The Unnamed has no static art — procedural creature fills the card, regenerated each summon.

---

## Campaign & Progression

### Structure
1. Player picks one element at the start — this is their starting deck
2. Five chapters, one per enemy element
3. Beat a chapter → earn boosters of that element
4. Chapter 6: fight a corrupted version of your own champion
5. Chapter 7: The Unnamed — true final boss, unlocked after all others

### Deck Building During Campaign
- Start with a pure mono-element deck
- Boosters from defeated enemies add cards from that element
- By the final chapter the deck reflects the entire journey
- Mixed decks are valid — generic summons cost any basics, champions cost 5 matching basics

### Aether Basics
Count as any element for champion sacrifice requirements. The flexible glue of mixed decks.

### Boosters
Each booster from a defeated chapter contains:
- 5–8 basics of that element
- 1 guaranteed summon of that element
- Small chance of that element's champion card
- Very small chance of a corrupted or shiny variant

---

## Collection

Pokémon-style — collect everything, keep it forever between runs.

### Collecting Goals
- All five variants of a seed (Fire #1234 through Aether #1234)
- All five shiny variants
- All five corrupted variants
- All five corrupted shiny variants
- All five champions + their corrupted versions
- #000000

### Collection Screen
Grid view. Fog of war on uncollected cards. Variant indicators per card. Should feel good to look at — players spend time here between games.

### Shiny Sacrifice Rule
Sacrificing a shiny basic transfers shiny status to the summoned creature. The shiny basic is **permanently destroyed** — gone from the collection forever. The choice is real and irreversible.

---

## Open Questions

- [ ] AI opponent behavior and difficulty levels
- [ ] Sound and music direction
- [ ] UI/UX beyond the card layout mockup
- [ ] Tutorial structure (early idea: forced first combats teaching weaker/equal/stronger matchups)
- [ ] Full card roster — only 5 champions and example summons exist so far
- [ ] Starting deck basic ratio — exact number to tune in playtesting (~20-24 of 60 suggested)

---

## Developer Context

- **Developer**: solo, side project alongside web development work
- **Timeline**: 3-4 years realistic to a shippable game
- **Stack advantage**: web development background makes the creature generator website a fast first ship
- **Approach**: one card a day, consistent evenings and weekends

### Launch Strategy

No Kickstarter. Self-funded, release when ready.

1. Build the creature generator website first — web stack, fast to ship, starts building audience immediately
2. Build the Love2D prototype in parallel — proves the game loop works
3. Open Steam wishlist when both exist and look good together
4. Post dev updates on Reddit — r/indiegaming, r/tcg, r/lovelyframes
5. Release free factions post-launch to keep momentum

### Creature Generator Website

The single most important marketing tool. A page where anyone types a seed and watches their creature appear across all five elements.

- Big seed input, centered
- Creature renders instantly, all five element variants shown side by side
- Shareable URL with seed embedded: `yoursite.com/?seed=1234`
- Every shared link is free distribution
- Same pixel array algorithm as the game — seed #1234 looks identical everywhere

---

## Next Steps

1. Define 3–4 summonable creatures per element (name, power, sacrifice cost, ability)
2. Sketch card frame
3. Build seed → creature generator in Love2D
4. Paper prototype two decks and play one full match
5. Tune life total and power ranges from feel
