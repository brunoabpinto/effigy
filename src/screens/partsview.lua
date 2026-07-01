-- Dev preview of the basic-creature parts. Run: love . --parts
-- Slots are shown with placeholder colors: 0 outline, 1 base, 2 accent.

local basic = require("src.core.basic")

local partsview = {}

local categories = { "bodies", "eyes", "mouths", "noses", "limbs", "markings" }
local SCALE = 8
local PAD = 20
local GAP = 28
local W = 900

local slotColor = {
  [0] = { 0.15, 0.15, 0.18 },
  [1] = { 0.60, 0.60, 0.66 },
  [2] = { 0.90, 0.55, 0.30 },
}

local items = {}     -- { part, x, y, name, header }
local totalH = 0
local font, labelFont

function partsview.load()
  font = love.graphics.newFont("assets/fonts/Cinzel-Bold.ttf", 16)
  labelFont = love.graphics.newFont(12)
  local y = PAD

  for _, cat in ipairs(categories) do
    items[#items + 1] = { header = cat, x = PAD, y = y }
    y = y + 26

    local mod = require("data.basics." .. cat)
    local names = {}
    for name in pairs(mod) do names[#names + 1] = name end
    table.sort(names)

    local x = PAD
    local rowH = 0
    for _, name in ipairs(names) do
      local part = mod[name]
      local pw, ph = part.w * SCALE, part.h * SCALE
      if x + pw > W - PAD then
        x = PAD; y = y + rowH + 22; rowH = 0
      end
      items[#items + 1] = { part = part, x = x, y = y, name = name }
      rowH = math.max(rowH, ph)
      x = x + pw + GAP
    end
    y = y + rowH + 22 + GAP
  end

  items[#items + 1] = { header = "creatures", x = PAD, y = y }
  y = y + 26
  local x, rowH = PAD, 0
  for _ = 1, 3 do
    local seed = love.math.random(1, 99999)
    local cr = basic.generate(seed)
    local pw, ph = cr.w * SCALE, cr.h * SCALE
    if x + pw > W - PAD then x = PAD; y = y + rowH + 22; rowH = 0 end
    items[#items + 1] = { part = cr, x = x, y = y, name = "#" .. seed }
    rowH = math.max(rowH, ph)
    x = x + pw + GAP
  end
  y = y + rowH + 22

  totalH = y
  love.window.setMode(W, totalH, { highdpi = true })
end

local function drawPart(part, ox, oy)
  for _, p in ipairs(part.pixels) do
    love.graphics.setColor(slotColor[p[3]])
    love.graphics.rectangle("fill", ox + p[1] * SCALE, oy + p[2] * SCALE, SCALE, SCALE)
  end
end

function partsview.draw()
  love.graphics.clear(0.08, 0.08, 0.10)
  for _, it in ipairs(items) do
    if it.header then
      love.graphics.setFont(font)
      love.graphics.setColor(0.9, 0.85, 0.7)
      love.graphics.print(it.header, it.x, it.y)
    else
      local pw, ph = it.part.w * SCALE, it.part.h * SCALE
      love.graphics.setColor(0, 0, 0, 0.35)
      love.graphics.rectangle("fill", it.x - 4, it.y - 4, pw + 8, ph + 8)
      drawPart(it.part, it.x, it.y)
      love.graphics.setFont(labelFont)
      love.graphics.setColor(0.65, 0.65, 0.7)
      love.graphics.print(it.name, it.x, it.y + ph + 4)
    end
  end
  love.graphics.setColor(1, 1, 1)
end

return partsview
