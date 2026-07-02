-- Hotseat match screen: renders a match state and drives the engine.
-- The active player sits at the bottom (hand + board); the opponent's board is
-- on top with only a hand count. Controls always act on the active player, so
-- the view flips perspective each turn.
--
-- Interaction modes:
--   select    - click a hand basic to play it, a summon to start sacrificing,
--               or an eligible board creature to DECLARE an attack
--   sacrifice - toggle board basics, Enter to confirm the summon, Esc to cancel
--   block     - an attack is declared; the DEFENDER now chooses which creature
--               blocks (must block if able). With an empty board the attack hits
--               face. Esc cancels the declaration.

local sprite = require("src.core.sprite")
local basic = require("src.core.basic")
local card = require("src.core.card")
local match = require("src.core.match")

local board = {}

local W, H = 1280, 720
local SCALE = 2
local GAP = 14
local FOE_ROW_Y = 56
local MY_ROW_Y = 356
local HAND_Y = 536

local state, t
local mode = "select"
local pending          -- summon: { handIndex, need }; attack: { attackerIndex }
local sacrifice = {}   -- set of board indices chosen to sacrifice
local font, bigFont, smallFont
local spriteCache = {}
local rects = { hand = {}, myBoard = {}, foeBoard = {}, face = nil, endTurn = nil }

local function spriteFor(c)
  local key = c.id or ("b:" .. c.element .. ":" .. c.seed)
  local s = spriteCache[key]
  if not s then
    s = c.id and sprite.load("data/" .. c.id .. ".json") or basic.generate(c.seed, c.element)
    spriteCache[key] = s
  end
  return s
end

-- false = cached miss (basic, or id with no art/hires/<id>.png) -> pixel fallback.
local hiresCache = {}
local function hiresFor(c)
  if not c.id then return nil end
  local v = hiresCache[c.id]
  if v == nil then
    local path = "art/hires/" .. c.id .. ".png"
    v = love.filesystem.getInfo(path) and love.graphics.newImage(path) or false
    hiresCache[c.id] = v
  end
  return v or nil
end

function board.load(matchState)
  state = matchState
  t = 0
  mode = "select"
  pending, sacrifice = nil, {}
  rects = { hand = {}, myBoard = {}, foeBoard = {}, face = nil, endTurn = nil }
  font = font or love.graphics.newFont("assets/fonts/Cinzel-Bold.ttf", 20)
  bigFont = bigFont or love.graphics.newFont("assets/fonts/Cinzel-Bold.ttf", 40)
  smallFont = smallFont or love.graphics.newFont("assets/fonts/Cinzel-Bold.ttf", 14)
end

function board.update(dt) t = t + dt end

local CELL_W, CELL_H = card.size({ w = 40, h = 56 }, SCALE)

local function rowX(n, i)
  local total = n * CELL_W + (n - 1) * GAP
  return (W - total) / 2 + (i - 1) * (CELL_W + GAP)
end

local function drawCard(c, power, x, y, opts)
  opts = opts or {}
  opts.name, opts.power, opts.time = c.name, power, t
  opts.champion = c.kind == "champion"
  opts.holo, opts.corrupt = c.shiny, c.corrupted
  if opts.onBoard then
    card.drawStanding(spriteFor(c), hiresFor(c), c.element, x, y, SCALE, opts)
  else
    card.draw(spriteFor(c), c.element, x, y, SCALE, opts)
  end
end

local function outline(x, y, color)
  love.graphics.setColor(color)
  love.graphics.setLineWidth(3)
  love.graphics.rectangle("line", x - 4, y - 4, CELL_W + 8, CELL_H + 8, card.RADIUS + 3)
  love.graphics.setColor(1, 1, 1)
end

local HILITE = { 1, 0.85, 0.4 }       -- selectable / declared attacker
local BLOCKER = { 0.4, 0.7, 0.95 }    -- defender's blocker options
local SAC = { 0.5, 0.85, 0.4 }        -- chosen sacrifice

-- Recompute every clickable rect for the current frame.
local function layout()
  rects.hand, rects.myBoard, rects.foeBoard = {}, {}, {}
  local me, foe = match.currentPlayer(state), match.opponent(state)
  for i = 1, #foe.board do
    rects.foeBoard[i] = { x = rowX(#foe.board, i), y = FOE_ROW_Y, i = i }
  end
  for i = 1, #me.board do
    rects.myBoard[i] = { x = rowX(#me.board, i), y = MY_ROW_Y, i = i }
  end
  for i = 1, #me.hand do
    rects.hand[i] = { x = rowX(#me.hand, i), y = HAND_Y, i = i }
  end
  rects.face = { x = W - 150, y = 8, w = 140, h = 40 }
  rects.endTurn = { x = W - 150, y = H - 48, w = 140, h = 40 }
end

local function inRect(r, mx, my)
  return mx >= r.x and mx <= r.x + (r.w or CELL_W)
    and my >= r.y and my <= r.y + (r.h or CELL_H)
end

local function legalAttackerSet()
  local set = {}
  for _, i in ipairs(match.legalAttackers(state)) do set[i] = true end
  return set
end

function board.draw()
  layout()
  local me, foe = match.currentPlayer(state), match.opponent(state)

  love.graphics.setColor(0.06, 0.06, 0.08)
  love.graphics.rectangle("fill", 0, 0, W, H)

  -- life + hand info
  love.graphics.setFont(font)
  love.graphics.setColor(0.85, 0.4, 0.4)
  love.graphics.print("Foe  " .. foe.life .. " HP", 16, 12)
  love.graphics.setColor(0.7, 0.7, 0.75)
  love.graphics.print(#foe.hand .. " in hand", 16, 34)
  love.graphics.setColor(0.5, 0.85, 0.5)
  love.graphics.print("You  " .. me.life .. " HP", 16, H - 40)

  love.graphics.setColor(0.9, 0.85, 0.7)
  love.graphics.printf("Player " .. state.turn .. " — turn " .. state.turnNumber,
    0, 12, W, "center")

  -- foe board (in block mode these are the defender's blocker choices)
  for i, c in ipairs(foe.board) do
    local r = rects.foeBoard[i]
    drawCard(c.card, c.power, r.x, r.y, { onBoard = true })
    if mode == "block" and #foe.board > 0 then outline(r.x, r.y, BLOCKER) end
  end

  -- face hit is only possible when the defender has nothing to block with
  if mode == "block" and #foe.board == 0 then
    love.graphics.setColor(BLOCKER)
    love.graphics.rectangle("line", rects.face.x, rects.face.y, rects.face.w, rects.face.h, 6)
    love.graphics.printf("Hit face", rects.face.x, rects.face.y + 10, rects.face.w, "center")
    love.graphics.setColor(1, 1, 1)
  end

  -- my board
  local attackers = legalAttackerSet()
  for i, c in ipairs(me.board) do
    local r = rects.myBoard[i]
    drawCard(c.card, c.power, r.x, r.y, { onBoard = true })
    if mode == "sacrifice" and c.kind == "basic" then
      if sacrifice[i] then outline(r.x, r.y, SAC) else outline(r.x, r.y, HILITE) end
    elseif mode == "block" and pending.attackerIndex == i then
      outline(r.x, r.y, HILITE)
    elseif mode == "select" and attackers[i] then
      outline(r.x, r.y, HILITE)
    end
  end

  -- my hand
  for i, c in ipairs(me.hand) do
    local r = rects.hand[i]
    drawCard(c, c.power, r.x, r.y)
    if mode == "select" and (c.kind == "basic" or c.kind == "summon" or c.kind == "champion") then
      -- subtle: hint that hand cards are actionable in select mode
    elseif mode == "sacrifice" and pending.handIndex == i then
      outline(r.x, r.y, HILITE)
    end
  end

  -- end turn button
  local et = rects.endTurn
  love.graphics.setColor(0.2, 0.2, 0.24)
  love.graphics.rectangle("fill", et.x, et.y, et.w, et.h, 6)
  love.graphics.setColor(0.9, 0.85, 0.7)
  love.graphics.printf("End Turn", et.x, et.y + 10, et.w, "center")

  -- mode hint
  love.graphics.setFont(smallFont)
  love.graphics.setColor(0.7, 0.7, 0.75)
  local hint = "click a hand card to play/summon · click a lit creature to declare an attack · Space ends turn"
  if mode == "sacrifice" then
    hint = ("select %d basics to sacrifice (%d chosen) · Enter to summon · Esc cancels")
      :format(pending.need, #sacrifice)
  elseif mode == "block" then
    hint = #foe.board > 0 and "defender: choose which creature blocks (must block) · Esc cancels"
      or "no blockers available — click Hit Face · Esc cancels"
  end
  love.graphics.printf(hint, 0, H - 66, W, "center")

  -- recent log
  love.graphics.setColor(0.5, 0.5, 0.55)
  for k = 0, 3 do
    local line = state.log[#state.log - k]
    if line then love.graphics.print(line, 16, H - 90 - k * 16) end
  end

  if state.winner then
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, W, H)
    love.graphics.setFont(bigFont)
    love.graphics.setColor(1, 0.85, 0.4)
    love.graphics.printf("Player " .. state.winner .. " wins", 0, H / 2 - 20, W, "center")
  end
  love.graphics.setColor(1, 1, 1)
end

local function countBasics(tbl)
  local n = 0
  for _ in pairs(tbl) do n = n + 1 end
  return n
end

local function confirmSummon()
  local idx = {}
  for i in pairs(sacrifice) do idx[#idx + 1] = i end
  local ok = match.summon(state, pending.handIndex, idx)
  if ok then
    mode, pending, sacrifice = "select", nil, {}
  end
  return ok
end

local function cancel()
  mode, pending, sacrifice = "select", nil, {}
end

function board.mousepressed(mx, my, button)
  if button ~= 1 or state.winner then return end
  layout()
  local me, foe = match.currentPlayer(state), match.opponent(state)

  if inRect(rects.endTurn, mx, my) then
    match.endTurn(state)
    cancel()
    return
  end

  if mode == "select" then
    for i, r in ipairs(rects.hand) do
      if inRect(r, mx, my) then
        local c = me.hand[i]
        if c.kind == "basic" then
          match.playBasic(state, i)
        else
          local need = c.kind == "champion" and 5 or math.floor(c.power / 2)
          mode, pending, sacrifice = "sacrifice", { handIndex = i, need = need }, {}
        end
        return
      end
    end
    local attackers = legalAttackerSet()
    for i, r in ipairs(rects.myBoard) do
      if inRect(r, mx, my) and attackers[i] then
        mode, pending = "block", { attackerIndex = i }   -- declare; defender blocks next
        return
      end
    end

  elseif mode == "sacrifice" then
    for i, r in ipairs(rects.myBoard) do
      if inRect(r, mx, my) and me.board[i].kind == "basic" then
        sacrifice[i] = not sacrifice[i] or nil
        return
      end
    end

  elseif mode == "block" then
    if #foe.board > 0 then
      for i, r in ipairs(rects.foeBoard) do
        if inRect(r, mx, my) then
          match.attack(state, pending.attackerIndex, i)
          cancel()
          return
        end
      end
    elseif inRect(rects.face, mx, my) then
      match.attack(state, pending.attackerIndex, nil)
      cancel()
      return
    end
  end
end

function board.keypressed(key)
  if state.winner then return end
  if key == "space" or key == "return" or key == "kpenter" then
    if mode == "sacrifice" then
      confirmSummon()
    elseif mode == "select" then
      match.endTurn(state)
      cancel()
    end
  end
end

-- Returns true if Esc was consumed (cancelling a sub-mode) rather than exiting.
function board.escape()
  if mode ~= "select" then
    cancel()
    return true
  end
  return false
end

return board
