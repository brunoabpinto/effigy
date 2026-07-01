-- Headless match engine: game state + rules, no rendering, no `love`.
-- Actions mutate the passed state and return `ok, err`; queries never mutate.
--
-- Combat: attacker declares; if the defender has creatures they MUST assign one
-- as blocker (defender's choice, supplied by the caller), one per attacker. An
-- empty defender board means the attack hits life directly.
--
-- Elemental passives and card effects are not implemented -- this is vanilla
-- combat. Future hook points are marked `-- PASSIVE:`.

local cards = require("data.cards")

local match = {}

local START_LIFE = 20
local HAND_SIZE = 7
local BOARD_LIMIT = 5

local function defaultRng()
  if love and love.math then return function(n) return love.math.random(n) end end
  return function(n) return math.random(n) end
end

-- Summon cost: power / 2 rounded down. Champions ignore this and always cost 5
-- matching-element basics regardless of their printed power.
local function tributeCount(power)
  return math.floor(power / 2)
end

local function toCard(record, deckElement)
  if record.id then
    local m = cards[record.id]
    return {
      kind = m.champion and "champion" or "summon",
      id = record.id, name = m.name, element = m.element, power = m.power,
    }
  end
  return {
    kind = "basic", name = "#" .. record.seed, element = deckElement, power = 1,
    seed = record.seed, shiny = record.shiny, corrupted = record.corrupted,
  }
end

local function shuffle(list, rng)
  for i = #list, 2, -1 do
    local j = rng(i)
    list[i], list[j] = list[j], list[i]
  end
end

local function newPlayer(deck, rng)
  local pile = {}
  for _, record in ipairs(deck.records) do
    pile[#pile + 1] = toCard(record, deck.element)
  end
  shuffle(pile, rng)
  local hand = {}
  for _ = 1, HAND_SIZE do
    if #pile > 0 then hand[#hand + 1] = table.remove(pile) end
  end
  return { life = START_LIFE, element = deck.element, deck = pile, hand = hand, board = {} }
end

local function log(state, msg) state.log[#state.log + 1] = msg end

local function checkWin(state)
  if state.winner then return end
  if state.players[1].life <= 0 then state.winner = 2
  elseif state.players[2].life <= 0 then state.winner = 1 end
end

-- Empty deck is a silent no-op; deck-out consequence is still an open question.
function match.draw(state)
  local p = match.currentPlayer(state)
  if #p.deck == 0 then return false, "empty deck" end
  p.hand[#p.hand + 1] = table.remove(p.deck)
  return true
end

local function beginTurn(state)
  local p = match.currentPlayer(state)
  for _, c in ipairs(p.board) do c.attacked = false end
  match.draw(state)
end

function match.new(decks, opts)
  opts = opts or {}
  local rng = opts.rng or defaultRng()
  local state = {
    players = { newPlayer(decks[1], rng), newPlayer(decks[2], rng) },
    turnNumber = 1,
    turn = rng(2),
    phase = "main",
    winner = nil,
    log = {},
  }
  beginTurn(state)
  return state
end

function match.currentPlayer(state) return state.players[state.turn] end
function match.opponent(state) return state.players[3 - state.turn] end

function match.playBasic(state, handIndex)
  if state.winner then return false, "game over" end
  if state.phase ~= "main" then return false, "not main phase" end
  local p = match.currentPlayer(state)
  local card = p.hand[handIndex]
  if not card then return false, "no such card" end
  if card.kind ~= "basic" then return false, "not a basic" end
  if #p.board >= BOARD_LIMIT then return false, "board full" end
  table.remove(p.hand, handIndex)
  p.board[#p.board + 1] = {
    card = card, element = card.element, power = 1,
    kind = "basic", summonedTurn = state.turnNumber, attacked = false,
  }
  log(state, "P" .. state.turn .. " plays " .. card.name)
  return true
end

function match.summon(state, handIndex, sacrificeIndices)
  if state.winner then return false, "game over" end
  if state.phase ~= "main" then return false, "not main phase" end
  local p = match.currentPlayer(state)
  local card = p.hand[handIndex]
  if not card then return false, "no such card" end
  if card.kind ~= "summon" and card.kind ~= "champion" then
    return false, "not summonable"
  end

  local need = card.kind == "champion" and 5 or tributeCount(card.power)
  if #sacrificeIndices ~= need then
    return false, ("need %d basics, got %d"):format(need, #sacrificeIndices)
  end

  local seen = {}
  for _, idx in ipairs(sacrificeIndices) do
    local c = p.board[idx]
    if not c then return false, "no such creature" end
    if seen[idx] then return false, "duplicate sacrifice" end
    if c.kind ~= "basic" then return false, "can only sacrifice basics" end
    if card.kind == "champion"
      and c.element ~= card.element and c.element ~= "aether" then
      return false, "champion needs matching-element basics"
    end
    seen[idx] = true
  end

  -- PASSIVE: fire +1/sac, water shield, air attack bonus, earth half, aether
  -- inherits strongest basic's trait, shiny-transfer.

  local kept = {}
  for i, c in ipairs(p.board) do
    if not seen[i] then kept[#kept + 1] = c end
  end
  kept[#kept + 1] = {
    card = card, element = card.element, power = card.power,
    kind = card.kind, summonedTurn = state.turnNumber, attacked = false,
  }
  p.board = kept
  table.remove(p.hand, handIndex)
  log(state, "P" .. state.turn .. " summons " .. card.name)
  return true
end

local function canAttack(creature, turnNumber)
  if creature.attacked then return false end
  if creature.summonedTurn < turnNumber then return true end
  return creature.element == "air"   -- PASSIVE: air attacks on summon
end

function match.legalAttackers(state)
  local out = {}
  if state.winner then return out end
  for i, c in ipairs(match.currentPlayer(state).board) do
    if canAttack(c, state.turnNumber) then out[#out + 1] = i end
  end
  return out
end

-- Lower power dies; equal powers both die. Damage never persists, so a survivor
-- is unchanged. Returns attackerDies, blockerDies.
local function resolveCombat(attacker, blocker)
  -- PASSIVE: fire residual, earth +1 while blocking, water damage halving.
  if attacker.power > blocker.power then return false, true
  elseif attacker.power == blocker.power then return true, true
  else return true, false end
end

local function removeCreature(board, creature)
  for i, c in ipairs(board) do
    if c == creature then table.remove(board, i) return end
  end
end

function match.attack(state, attackerIndex, blockerIndex)
  if state.winner then return false, "game over" end
  local me, foe = match.currentPlayer(state), match.opponent(state)
  local attacker = me.board[attackerIndex]
  if not attacker then return false, "no attacker" end
  if not canAttack(attacker, state.turnNumber) then return false, "can't attack" end

  if #foe.board > 0 then
    if blockerIndex == nil then return false, "must assign a blocker" end
    local blocker = foe.board[blockerIndex]
    if not blocker then return false, "no such blocker" end
    attacker.attacked = true
    state.phase = "combat"
    local aDies, bDies = resolveCombat(attacker, blocker)
    if bDies then removeCreature(foe.board, blocker) end
    if aDies then removeCreature(me.board, attacker) end
    log(state, ("P%d %s attacks %s -> a:%s b:%s"):format(
      state.turn, attacker.card.name, blocker.card.name,
      aDies and "dead" or "ok", bDies and "dead" or "ok"))
  else
    if blockerIndex ~= nil then return false, "no creature to block" end
    attacker.attacked = true
    state.phase = "combat"
    foe.life = foe.life - attacker.power
    log(state, ("P%d %s hits face for %d (foe life %d)"):format(
      state.turn, attacker.card.name, attacker.power, foe.life))
    checkWin(state)
  end
  return true
end

function match.endTurn(state)
  if state.winner then return false, "game over" end
  state.turn = 3 - state.turn
  state.turnNumber = state.turnNumber + 1
  state.phase = "main"
  beginTurn(state)
  return true
end

return match
