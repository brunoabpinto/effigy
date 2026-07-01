-- Scrollable grid of a chosen element's full 60-card deck.

local card = require("src.core.card")

local deckview = {}

local W, H = 1280, 720
local SCALE = 4
local PAD = 16
local COLS = 6
local TITLE_H = 52

local entries = {}
local cellW, cellH = 0, 0
local marginX = PAD
local scrollY, maxScroll = 0, 0
local titleFont
local title = ""

function deckview.load(element, deckEntries)
  love.window.setMode(W, H, { highdpi = true })
  titleFont = titleFont or love.graphics.newFont("assets/fonts/Cinzel-Bold.ttf", 26)

  entries = deckEntries
  cellW, cellH = 0, 0
  for _, e in ipairs(entries) do
    local cw, ch = card.size(e.sprite, SCALE)
    cellW, cellH = math.max(cellW, cw), math.max(cellH, ch)
  end

  local gridW = COLS * cellW + (COLS - 1) * PAD
  marginX = math.max(PAD, (W - gridW) / 2)

  local rows = math.ceil(#entries / COLS)
  local contentH = rows * (cellH + PAD) + PAD
  maxScroll = math.max(0, contentH - (H - TITLE_H))
  scrollY = 0

  local label = element:sub(1, 1):upper() .. element:sub(2)
  title = label
end

local function cellOrigin(i)
  local col = (i - 1) % COLS
  local row = math.floor((i - 1) / COLS)
  return marginX + col * (cellW + PAD), TITLE_H + PAD + row * (cellH + PAD)
end

function deckview.draw()
  love.graphics.setColor(0.05, 0.05, 0.07)
  love.graphics.rectangle("fill", 0, 0, W, H)

  for i, e in ipairs(entries) do
    local x, y = cellOrigin(i)
    y = y - scrollY
    if y + cellH >= TITLE_H and y <= H then
      card.draw(e.sprite, e.element, x, y, SCALE,
        { name = e.meta.name, power = e.meta.power, champion = e.meta.champion,
          silver = e.meta.silver, holo = e.meta.shiny, corrupt = e.meta.corrupted })
    end
  end

  love.graphics.setColor(0.05, 0.05, 0.07)
  love.graphics.rectangle("fill", 0, 0, W, TITLE_H)
  love.graphics.setFont(titleFont)
  love.graphics.setColor(0.9, 0.85, 0.7)
  love.graphics.printf(title, 0, 14, W, "center")
  love.graphics.setColor(1, 1, 1)
end

local function scroll(dy)
  scrollY = math.max(0, math.min(maxScroll, scrollY + dy))
end

function deckview.wheelmoved(_, dy)
  scroll(-dy * 40)
end

function deckview.keypressed(key)
  if key == "down" or key == "s" then
    scroll(40)
  elseif key == "up" or key == "w" then
    scroll(-40)
  elseif key == "pagedown" then
    scroll(H - TITLE_H)
  elseif key == "pageup" then
    scroll(-(H - TITLE_H))
  end
end

return deckview
