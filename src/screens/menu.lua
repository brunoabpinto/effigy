-- Main menu: the game's entry point.
-- Options: Campaign, Dex, Options, Quit.
-- Wire actions via menu.load(handlers) where handlers = { campaign, dex, options, quit }.

local card = require("src.core.card")

local menu = {}

local items = { "Campaign", "Dex", "Options", "Quit" }
local keys = { "campaign", "dex", "options", "quit" }

local titleFont, itemFont
local selected = 1
local handlers = {}

function menu.load(h)
  handlers = h or {}
  selected = 1
  titleFont = love.graphics.newFont("assets/fonts/Cinzel-Bold.ttf", 72)
  itemFont = love.graphics.newFont("assets/fonts/Cinzel-Bold.ttf", 28)
end

-- Vertical origin of item i (centered block), plus its height.
local function itemY(i)
  local h = itemFont:getHeight()
  local gap = 32
  local blockH = #items * h + (#items - 1) * gap
  local top = love.graphics.getHeight() * 0.62 - blockH / 2
  return top + (i - 1) * (h + gap), h
end

local function activate(i)
  local fn = handlers[keys[i]]
  if fn then fn() end
end

function menu.draw()
  local w, h = love.graphics.getDimensions()

  love.graphics.setColor(0.05, 0.05, 0.07)
  love.graphics.rectangle("fill", 0, 0, w, h)

  love.graphics.setFont(titleFont)
  love.graphics.setColor(0.9, 0.85, 0.7)
  love.graphics.printf("Effigy", 0, h * 0.10, w, "center")

  love.graphics.setFont(itemFont)
  for i, label in ipairs(items) do
    local y = itemY(i)
    if i == selected then
      love.graphics.setColor(1, 0.85, 0.4)
    else
      love.graphics.setColor(0.6, 0.6, 0.65)
    end
    love.graphics.printf(label, 0, y, w, "center")
  end

  card.foil("gold", love.timer.getTime(), 0, 0, w, h)
end

function menu.keypressed(key)
  if key == "up" or key == "w" then
    selected = (selected - 2) % #items + 1
  elseif key == "down" or key == "s" then
    selected = selected % #items + 1
  elseif key == "return" or key == "kpenter" or key == "space" then
    activate(selected)
  end
end

-- Highlight the item under the cursor.
function menu.mousemoved(mx, my)
  for i = 1, #items do
    local y, h = itemY(i)
    if my >= y and my <= y + h then selected = i end
  end
end

function menu.mousepressed(mx, my, button)
  if button ~= 1 then return end
  for i = 1, #items do
    local y, h = itemY(i)
    if my >= y and my <= y + h then
      selected = i
      activate(i)
      return
    end
  end
end

return menu
