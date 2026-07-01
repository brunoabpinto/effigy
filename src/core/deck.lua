-- Builds a 60-card deck for an element: registered cards of that element
-- (champion + summons) plus deterministic generated basics to fill to 60.

local sprite = require("src.core.sprite")
local basic = require("src.core.basic")
local cards = require("data.cards")

local deck = {}

local DECK_SIZE = 60
local SHINY_CHANCE = 1 / 4096
local CORRUPT_CHANCE = 1 / 10000

function deck.build(element)
  local entries = {}

  local ids, champId = {}, nil
  for id, meta in pairs(cards) do
    if meta.element == element then
      ids[#ids + 1] = id
      if meta.champion then champId = id end
    end
  end
  table.sort(ids, function(a, b) return cards[a].power > cards[b].power end)

  for _, id in ipairs(ids) do
    entries[#entries + 1] = {
      sprite = sprite.load("data/" .. id .. ".json"),
      element = element,
      meta = cards[id],
    }
  end

  -- Per-game random base: a new campaign rolls different basics; the built deck
  -- is stored, so reopening it shows the same cards.
  local champNum = tonumber(champId) or 0
  local base = love.math.random(0, 999)
  for i = 1, DECK_SIZE - #ids do
    local seed = champNum * 1000 + ((i + base) * 2654435761 % 1000)
    entries[#entries + 1] = {
      sprite = basic.generate(seed, element),
      element = element,
      meta = {
        name = "#" .. seed,
        power = 1,
        shiny = love.math.random() < SHINY_CHANCE,
        corrupted = love.math.random() < CORRUPT_CHANCE,
      },
    }
  end

  return entries
end

return deck