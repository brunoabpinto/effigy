-- Card preview: renders one card's base / shiny / corrupted variants.
-- Used by main.lua's dev preview mode (run: ./card <id>  e.g.  ./card 001).

local sprite = require("src.core.sprite")
local card = require("src.core.card")
local cards = require("data.cards")

local cardview = {}

local SCALE = 6
local base, shiny, corrupted, meta
local t = 0

function cardview.load(id)
  meta = cards[id]
  assert(meta, "unknown card id: " .. tostring(id))
  base = sprite.load("data/" .. id .. ".json")

  -- shiny: alternate palette (channel-rotated), indices unchanged
  local pal = {}
  for i, c in ipairs(base.palette) do pal[i] = { c[2], c[3], c[1] } end
  shiny = sprite.shiny(base, pal)

  corrupted = sprite.corrupted(base, 12345)
end

function cardview.update(dt)
  t = t + dt
end

function cardview.draw()
  local gap = 20
  local cw, ch = card.size(base, SCALE)
  local totalW = cw * 3 + gap * 2
  local x0 = (love.graphics.getWidth() - totalW) / 2
  local y0 = (love.graphics.getHeight() - ch) / 2
  local n, p, ch2, sv = meta.name, meta.power, meta.champion, meta.silver
  card.draw(base, meta.element, x0, y0, SCALE, { name = n, power = p, champion = ch2, silver = sv })
  card.draw(shiny, meta.element, x0 + cw + gap, y0, SCALE, { name = n, power = p, champion = ch2, silver = sv, holo = true, time = t })
  card.draw(corrupted, meta.element, x0 + (cw + gap) * 2, y0, SCALE, { name = n, power = p, champion = ch2, silver = sv, corrupt = true, time = t })
end

return cardview
