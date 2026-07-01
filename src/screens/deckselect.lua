-- Campaign deck selection: pick one of the four basic-element champions.

local sprite = require("src.core.sprite")
local card = require("src.core.card")
local cards = require("data.cards")

local deckselect = {}

local SCALE = 3
local GAP = 28
local BOB_SPEED = 2.2
local BOB_AMP = 10

local deckIds = { "002", "003", "004", "001" } -- fire, water, air, earth
local entries = {}
local selected = 1
local t = 0
local handlers = {}
local blockX, cellW, cellH = 0, 0, 0
local titleFont

function deckselect.load(h)
  handlers = h or {}
  selected = 1
  t = 0
  entries = {}
  cellW, cellH = 0, 0
  titleFont = titleFont or love.graphics.newFont("assets/fonts/Cinzel-Bold.ttf", 40)

  for _, id in ipairs(deckIds) do
    local spr = sprite.load("data/" .. id .. ".json")
    entries[#entries + 1] = { id = id, sprite = spr, meta = cards[id] }
    local cw, ch = card.size(spr, SCALE)
    cellW, cellH = math.max(cellW, cw), math.max(cellH, ch)
  end

  local blockW = #entries * cellW + (#entries - 1) * GAP
  blockX = (love.graphics.getWidth() - blockW) / 2
end

local function cellOrigin(i)
  local x = blockX + (i - 1) * (cellW + GAP)
  local y = (love.graphics.getHeight() - cellH) / 2 + 40
  return x, y
end

local function bob(i)
  if i ~= selected then return 0 end
  return math.sin(t * BOB_SPEED) * BOB_AMP
end

function deckselect.update(dt)
  t = t + dt
end

function deckselect.draw()
  local w, h = love.graphics.getDimensions()
  love.graphics.setColor(0.05, 0.05, 0.07)
  love.graphics.rectangle("fill", 0, 0, w, h)

  love.graphics.setFont(titleFont)
  love.graphics.setColor(0.9, 0.85, 0.7)
  love.graphics.printf("Choose Your Champion", 0, h * 0.10, w, "center")

  for i, e in ipairs(entries) do
    local x, y = cellOrigin(i)
    y = y + bob(i)
    if i == selected then
      local cw, ch = card.size(e.sprite, SCALE)
      love.graphics.setColor(1, 0.85, 0.4)
      love.graphics.setLineWidth(3)
      love.graphics.rectangle("line", x - 5, y - 5, cw + 10, ch + 10, card.RADIUS + 3)
    end
    card.draw(e.sprite, e.meta.element, x, y, SCALE,
      { name = e.meta.name, power = e.meta.power, champion = true, time = t })
  end
  love.graphics.setColor(1, 1, 1)
end

local function hit(mx, my)
  for i, e in ipairs(entries) do
    local x, y = cellOrigin(i)
    local cw, ch = card.size(e.sprite, SCALE)
    if mx >= x and mx <= x + cw and my >= y and my <= y + ch then
      return i
    end
  end
end

function deckselect.mousemoved(mx, my)
  local i = hit(mx, my)
  if i then selected = i end
end

local function choose()
  if handlers.choose then handlers.choose(entries[selected].meta.element) end
end

function deckselect.mousepressed(mx, my, button)
  if button ~= 1 then return end
  local i = hit(mx, my)
  if i then
    selected = i
    choose()
  end
end

function deckselect.keypressed(key)
  if key == "left" or key == "a" then
    selected = (selected - 2) % #entries + 1
  elseif key == "right" or key == "d" then
    selected = selected % #entries + 1
  elseif key == "return" or key == "kpenter" or key == "space" then
    choose()
  end
end

return deckselect
