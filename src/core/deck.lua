-- Builds a 60-card deck for an element: registered cards of that element
-- (champion + summons) plus deterministic generated basics to fill to 60.
--
-- A deck is stored as plain records (see deck.roll) so it survives across
-- sessions; deck.hydrate turns those records into renderable entries. Variants
-- are rolled once at roll time and persisted, never re-rolled on load.

local sprite = require("src.core.sprite")
local basic = require("src.core.basic")
local cards = require("data.cards")

local deck = {}

local DECK_SIZE = 60
local SHINY_CHANCE = 1 / 4096
local CORRUPT_CHANCE = 1 / 10000

-- Roll a fresh deck for an element, returned as serializable records:
--   registered card -> { id = "001" }
--   generated basic -> { seed = n, shiny = bool, corrupted = bool }
-- The registered ids are deterministic; the basics' seeds and variant flags are
-- rolled here once, so the caller persists these records to reproduce the deck.
function deck.roll(element)
  local records = {}

  local ids, champId = {}, nil
  for id, meta in pairs(cards) do
    if meta.element == element then
      ids[#ids + 1] = id
      if meta.champion then champId = id end
    end
  end
  table.sort(ids, function(a, b) return cards[a].power > cards[b].power end)

  for _, id in ipairs(ids) do
    records[#records + 1] = { id = id }
  end

  local champNum = tonumber(champId) or 0
  local base = love.math.random(0, 999)
  for i = 1, DECK_SIZE - #ids do
    local seed = champNum * 1000 + ((i + base) * 2654435761 % 1000)
    records[#records + 1] = {
      seed = seed,
      shiny = love.math.random() < SHINY_CHANCE,
      corrupted = love.math.random() < CORRUPT_CHANCE,
    }
  end

  return records
end

-- Turn stored records into renderable entries: sprite + element + meta.
-- Registered cards load their shipped sprite and registry metadata; basics are
-- generated from their seed, with variant flags carried through to meta.
function deck.hydrate(element, records)
  local entries = {}
  for _, r in ipairs(records) do
    if r.id then
      entries[#entries + 1] = {
        sprite = sprite.load("data/" .. r.id .. ".json"),
        element = element,
        meta = cards[r.id],
      }
    else
      entries[#entries + 1] = {
        sprite = basic.generate(r.seed, element),
        element = element,
        meta = {
          name = "#" .. r.seed,
          power = 1,
          shiny = r.shiny,
          corrupted = r.corrupted,
        },
      }
    end
  end
  return entries
end

-- Convenience: roll a new deck and hydrate it in one step (no persistence).
function deck.build(element)
  return deck.hydrate(element, deck.roll(element))
end

return deck
