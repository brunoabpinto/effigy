-- Sprite loading + variant generation.

local sprite = {}

-- Load an indexed sprite JSON produced by tools/convert.
function sprite.load(path)
  local raw = love.filesystem.read(path)
  -- expects {"w","h","palette":[[r,g,b],...],"pixels":[[x,y,i],...]}
  local data = { w = 0, h = 0, palette = {}, pixels = {} }
  data.w = tonumber(raw:match('"w":(%d+)'))
  data.h = tonumber(raw:match('"h":(%d+)'))

  -- Split the two arrays first so their identical [n,n,n] shape can't collide.
  local palStr = raw:match('"palette":%[(.-)%],"pixels"')
  local pixStr = raw:match('"pixels":%[(.-)%]}')
  for r, g, b in palStr:gmatch('%[(%d+),(%d+),(%d+)%]') do
    data.palette[#data.palette + 1] = { tonumber(r), tonumber(g), tonumber(b) }
  end
  for x, y, i in pixStr:gmatch('%[(%d+),(%d+),(%d+)%]') do
    data.pixels[#data.pixels + 1] = { tonumber(x), tonumber(y), tonumber(i) }
  end
  return data
end

-- Shiny: replace the palette, keep indices.
function sprite.shiny(data, newPalette)
  return { w = data.w, h = data.h, palette = newPalette, pixels = data.pixels }
end

-- Corrupted: seeded pixel displacement, same palette as the base.
function sprite.corrupted(data, seed)
  local gen = love.math.newRandomGenerator(seed)
  local function rng() return gen:random() end
  local palette = data.palette
  local pixels = {}
  for i, p in ipairs(data.pixels) do
    local dx = (rng() < 0.15) and (rng() < 0.5 and -1 or 1) or 0
    local dy = (rng() < 0.15) and (rng() < 0.5 and -1 or 1) or 0
    pixels[i] = { p[1] + dx, p[2] + dy, p[3] }
  end
  return { w = data.w, h = data.h, palette = palette, pixels = pixels }
end

return sprite
