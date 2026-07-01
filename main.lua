-- Effigy game loop.
-- `love .`        -> main menu (game entry point)
-- `love . <id>`   -> dev card preview (e.g. love . 001)
-- `love . --dex`  -> dex: all creatures in a grid (click a card for its variants)

local menu = require("src.screens.menu")
local cardview = require("src.screens.cardview")
local dex = require("src.screens.dex")
local deckselect = require("src.screens.deckselect")
local deck = require("src.core.deck")
local deckview = require("src.screens.deckview")
local partsview = require("src.screens.partsview")
local mode = "menu"
local cameFromDex = false

local function openDex()
  dex.load()
  mode = "dex"
end

local campaignDeck = nil

local function openDeckSelect()
  deckselect.load({
    choose = function(el)
      if not campaignDeck or campaignDeck.element ~= el then
        campaignDeck = { element = el, entries = deck.build(el) }
      end
      deckview.load(el, campaignDeck.entries)
      mode = "deckview"
    end,
  })
  mode = "deckselect"
end

local function toMenu()
  menu.load({
    campaign = openDeckSelect,
    dex = openDex,
    options = function() end,   -- TODO: options screen
    quit = function() love.event.quit() end,
  })
  mode = "menu"
end

function love.load(arg)
  local a = arg[1]
  if a == "--dex" then
    openDex()
  elseif a == "--parts" then
    partsview.load()
    mode = "parts"
  elseif a then
    cardview.load(a)
    mode = "card"
  else
    toMenu()
  end
end

function love.update(dt)
  if mode == "card" then cardview.update(dt)
  elseif mode == "deckselect" then deckselect.update(dt) end
end

function love.draw()
  if mode == "menu" then
    menu.draw()
  elseif mode == "card" then
    cardview.draw()
  elseif mode == "dex" then
    dex.draw()
  elseif mode == "deckselect" then
    deckselect.draw()
  elseif mode == "deckview" then
    deckview.draw()
  elseif mode == "parts" then
    partsview.draw()
  end
end

local function back()
  if mode == "card" and cameFromDex then
    mode = "dex"
    cameFromDex = false
  elseif mode == "card" or mode == "dex" then
    toMenu()
  elseif mode == "deckview" then
    openDeckSelect()
  elseif mode == "deckselect" then
    toMenu()
  end
end

function love.mousemoved(x, y)
  if mode == "menu" then
    menu.mousemoved(x, y)
  elseif mode == "dex" then
    dex.hover(x, y)
  elseif mode == "deckselect" then
    deckselect.mousemoved(x, y)
  end
end

function love.wheelmoved(dx, dy)
  if mode == "deckview" then deckview.wheelmoved(dx, dy) end
end

function love.mousepressed(x, y, button)
  if button ~= 1 then return end
  if mode == "menu" then
    menu.mousepressed(x, y, button)
  elseif mode == "dex" then
    local id = dex.hit(x, y)
    if id then
      cardview.load(id)
      mode = "card"
      cameFromDex = true
    end
  elseif mode == "deckselect" then
    deckselect.mousepressed(x, y, button)
  elseif mode == "card" then
    back()
  end
end

function love.keypressed(key)
  if mode == "menu" then
    menu.keypressed(key)
  elseif mode == "dex" then
    if key == "escape" then
      back()
    else
      local id = dex.keypressed(key)
      if id then
        cardview.load(id)
        mode = "card"
        cameFromDex = true
      end
    end
  elseif mode == "deckselect" then
    if key == "escape" then back() else deckselect.keypressed(key) end
  elseif mode == "deckview" then
    if key == "escape" then back() else deckview.keypressed(key) end
  elseif mode == "parts" then
    if key == "escape" then love.event.quit() end
  elseif key == "escape" then
    back()
  end
end
