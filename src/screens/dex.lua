-- Dex: shows every registered creature as a grid of cards.
-- Run: love . --dex

local sprite = require("src.core.sprite")
local card = require("src.core.card")
local cards = require("data.cards")

local dex = {}

local SCALE = 3
local PAD = 16
local entries = {}        -- { id, sprite, meta }
local cols, cellW, cellH = 1, 0, 0
local selected = 1

function dex.load()
  -- reset state so reopening the dex doesn't stack duplicates
  entries = {}
  cellW, cellH = 0, 0
  selected = 1

  -- collect ids in sorted order
  local ids = {}
  for id in pairs(cards) do ids[#ids + 1] = id end
  table.sort(ids)

  for _, id in ipairs(ids) do
    local ok, spr = pcall(sprite.load, "data/" .. id .. ".json")
    if ok then
      entries[#entries + 1] = { id = id, sprite = spr, meta = cards[id] }
      local cw, ch = card.size(spr, SCALE)
      cellW, cellH = math.max(cellW, cw), math.max(cellH, ch)
    end
  end

  -- size the window to a uniform grid (max 6 per row)
  cols = math.min(#entries, 6)
  cols = math.max(cols, 1)
  local rows = math.ceil(#entries / cols)
  local w = PAD + cols * (cellW + PAD)
  local h = PAD + rows * (cellH + PAD)
  love.window.setMode(w, h, { highdpi = true })
end

local function cellOrigin(i)
  local col = (i - 1) % cols
  local row = math.floor((i - 1) / cols)
  return PAD + col * (cellW + PAD), PAD + row * (cellH + PAD)
end

function dex.draw()
  for i, e in ipairs(entries) do
    local x, y = cellOrigin(i)
    card.draw(e.sprite, e.meta.element, x, y, SCALE,
      { name = e.meta.name, power = e.meta.power, champion = e.meta.champion, silver = e.meta.silver })
  end

  -- selection highlight
  local e = entries[selected]
  if e then
    local x, y = cellOrigin(selected)
    local cw, ch = card.size(e.sprite, SCALE)
    love.graphics.setColor(1, 0.85, 0.4)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", x - 4, y - 4, cw + 8, ch + 8, card.RADIUS + 2)
    love.graphics.setColor(1, 1, 1)
  end
end

-- Returns the id of the card under (mx, my), or nil.
function dex.hit(mx, my)
  for i, e in ipairs(entries) do
    local x, y = cellOrigin(i)
    local cw, ch = card.size(e.sprite, SCALE)
    if mx >= x and mx <= x + cw and my >= y and my <= y + ch then
      selected = i
      return e.id
    end
  end
end

-- Highlight the card under the cursor (mouse hover).
function dex.hover(mx, my)
  for i, e in ipairs(entries) do
    local x, y = cellOrigin(i)
    local cw, ch = card.size(e.sprite, SCALE)
    if mx >= x and mx <= x + cw and my >= y and my <= y + ch then
      selected = i
      return
    end
  end
end

-- Arrow/WASD navigation. Returns the selected id when confirmed (enter/space), else nil.
function dex.keypressed(key)
  local n = #entries
  if n == 0 then return end
  if key == "left" or key == "a" then
    selected = (selected - 2) % n + 1
  elseif key == "right" or key == "d" then
    selected = selected % n + 1
  elseif key == "up" or key == "w" then
    selected = ((selected - 1 - cols) % n) + 1
  elseif key == "down" or key == "s" then
    selected = ((selected - 1 + cols) % n) + 1
  elseif key == "return" or key == "kpenter" or key == "space" then
    return entries[selected].id
  end
end

return dex
