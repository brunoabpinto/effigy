-- Procedural basic creatures: composite parts from a seed into one sprite.
-- Output pixels use slots (0 outline, 1 base, 2 accent); an element palette is
-- applied later. Same seed always yields the same creature.

local card = require("src.core.card")

local basic = {}

local parts = {
  body    = require("data.basics.bodies"),
  eyes    = require("data.basics.eyes"),
  mouth   = require("data.basics.mouths"),
  nose    = require("data.basics.noses"),
  limb    = require("data.basics.limbs"),
  marking = require("data.basics.markings"),
}

local function pick(gen, mod)
  local names = {}
  for name in pairs(mod) do names[#names + 1] = name end
  table.sort(names)
  return mod[names[gen:random(#names)]]
end

local function blit(acc, part, ox, oy, mirror)
  for _, p in ipairs(part.pixels) do
    local px = mirror and (part.w - 1 - p[1]) or p[1]
    acc[#acc + 1] = { math.floor(ox + px), math.floor(oy + p[2]), p[3] }
  end
end

-- Slot palette (0 outline, 1 base, 2 accent) derived from the element color.
local function paletteFor(element)
  local c = card.elementColor[element] or { 0.7, 0.7, 0.7 }
  local outline = { c[1] * 70, c[2] * 70, c[3] * 70 }
  local base = { c[1] * 255, c[2] * 255, c[3] * 255 }
  local accent = {
    math.min(c[1] * 255 + 80, 255),
    math.min(c[2] * 255 + 80, 255),
    math.min(c[3] * 255 + 80, 255),
  }
  return { outline, base, accent }
end

function basic.generate(seed, element)
  local gen = love.math.newRandomGenerator(seed)
  local body = pick(gen, parts.body)
  local eye = pick(gen, parts.eyes)
  local mouth = pick(gen, parts.mouth)
  local nose = pick(gen, parts.nose)
  local limb = pick(gen, parts.limb)
  local marking = pick(gen, parts.marking)

  local bw, bh = body.w, body.h
  local acc = {}
  blit(acc, body, 0, 0)
  blit(acc, marking, bw / 2 - marking.w / 2, bh * 0.4 - marking.h / 2)

  local ly = bh - limb.h
  blit(acc, limb, bw * 0.18 - limb.w / 2, ly)
  blit(acc, limb, bw * 0.82 - limb.w / 2, ly, true)

  local ey = bh * 0.30
  blit(acc, eye, bw * 0.30 - eye.w / 2, ey)
  blit(acc, eye, bw * 0.70 - eye.w / 2, ey, true)

  blit(acc, nose, bw / 2 - nose.w / 2, bh * 0.48 - nose.h / 2)
  blit(acc, mouth, bw / 2 - mouth.w / 2, bh * 0.66 - mouth.h / 2)

  local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge
  for _, p in ipairs(acc) do
    minx, miny = math.min(minx, p[1]), math.min(miny, p[2])
    maxx, maxy = math.max(maxx, p[1]), math.max(maxy, p[2])
  end

  local crW, crH = maxx - minx + 1, maxy - miny + 1

  -- Deck basics render on the same 40x56 card canvas as authored cards. A fixed
  -- scale keeps pixels uniform across every basic; centered on the canvas.
  local w, h, ox, oy, sc = crW, crH, 0, 0, 1
  if element then
    w, h, sc = 40, 56, 1
    ox = math.floor((w - crW * sc) / 2)
    oy = math.floor((h - crH * sc) / 2)
  end

  local pixels = {}
  for _, p in ipairs(acc) do
    local bx, by = (p[1] - minx) * sc + ox, (p[2] - miny) * sc + oy
    for dx = 0, sc - 1 do
      for dy = 0, sc - 1 do
        pixels[#pixels + 1] = { bx + dx, by + dy, p[3] }
      end
    end
  end
  return {
    w = w,
    h = h,
    palette = element and paletteFor(element) or nil,
    pixels = pixels,
  }
end

return basic
