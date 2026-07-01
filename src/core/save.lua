-- Persistent save state, serialized to the LOVE save directory.
-- Everything is reconstructed from element + seed, so a card instance is just
-- { element, seed, shiny, corrupted }; the collection is a list of those, the
-- fog-of-war "seen" set is keyed by element:seed, and campaign holds run state.
-- No sprites or functions are ever stored — the caller passes plain data only.

local save = {}

local PATH = "save.lua"
local BAK = "save.bak.lua"
local VERSION = 1

local function default()
  return { version = VERSION, collection = {}, seen = {}, decks = {}, campaign = nil }
end

save.data = default()

-- Serialize a plain-data value (number/boolean/string/table) to a Lua literal.
local function encode(v)
  local t = type(v)
  if t == "number" then
    return tostring(v)
  elseif t == "boolean" then
    return v and "true" or "false"
  elseif t == "string" then
    return string.format("%q", v)
  elseif t == "table" then
    local parts, n = {}, #v
    for i = 1, n do
      parts[#parts + 1] = encode(v[i])
    end
    for k, val in pairs(v) do
      local isSeq = type(k) == "number" and k >= 1 and k <= n and k == math.floor(k)
      if not isSeq then
        local key = (type(k) == "string" and k:match("^[%a_][%w_]*$"))
          and k or "[" .. encode(k) .. "]"
        parts[#parts + 1] = key .. "=" .. encode(val)
      end
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  error("save: cannot serialize " .. t)
end

-- Read a save file back into a table, sandboxed so a tampered file can't run.
local function readTable(path)
  if not love.filesystem.getInfo(path) then return nil end
  local content = love.filesystem.read(path)
  if not content then return nil end
  local chunk = loadstring(content)
  if not chunk then return nil end
  setfenv(chunk, {})
  local ok, result = pcall(chunk)
  if ok and type(result) == "table" then return result end
  return nil
end

-- Load from disk into memory, falling back to the backup then a fresh save.
function save.load()
  save.data = readTable(PATH) or readTable(BAK) or default()
  return save.data
end

-- Write current state to disk, backing up the last good file first so a crash
-- mid-write never destroys the previous save.
function save.flush()
  if love.filesystem.getInfo(PATH) then
    local cur = love.filesystem.read(PATH)
    if cur then love.filesystem.write(BAK, cur) end
  end
  love.filesystem.write(PATH, "return " .. encode(save.data))
end

local function key(element, seed) return element .. ":" .. seed end

-- Collection ---------------------------------------------------------------

-- Add a card instance to the collection; opts = { shiny, corrupted }.
function save.own(element, seed, opts)
  opts = opts or {}
  local inst = {
    element = element,
    seed = seed,
    shiny = opts.shiny or false,
    corrupted = opts.corrupted or false,
  }
  local col = save.data.collection
  col[#col + 1] = inst
  save.markSeen(element, seed)
  return inst
end

-- Destroy a specific instance (shiny sacrifice). Irreversible, so it persists
-- immediately. Returns true if the instance was found and removed.
function save.destroy(inst)
  local col = save.data.collection
  for i = #col, 1, -1 do
    if col[i] == inst then
      table.remove(col, i)
      save.flush()
      return true
    end
  end
  return false
end

-- Fog of war ---------------------------------------------------------------

function save.markSeen(element, seed)
  save.data.seen[key(element, seed)] = true
end

function save.hasSeen(element, seed)
  return save.data.seen[key(element, seed)] == true
end

-- Decks --------------------------------------------------------------------

-- Stored deck records for an element (see deck.roll), or nil if never built.
function save.getDeck(element)
  return save.data.decks[element]
end

-- Persist an element's deck records so the same deck reappears next session.
function save.setDeck(element, records)
  save.data.decks[element] = records
  save.flush()
end

-- Campaign -----------------------------------------------------------------

function save.setCampaign(t)
  save.data.campaign = t
end

return save
