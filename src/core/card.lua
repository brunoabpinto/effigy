-- Reusable card renderer. Full-bleed sprite art + element-colored border.

local card = {}

card.FOG_OF_WAR = false

card.FRAME = 5         -- thickness of the element-colored band
card.PADDING = 6       -- gap between the creature and the frame
card.PADDING_BOTTOM = 32 -- extra space below the creature (under the name bar)
card.RADIUS = 10

-- Outer card size for a sprite at a given scale.
function card.size(sprite, scale)
  local edge = (card.FRAME + card.PADDING) * 2
  return sprite.w * scale + edge, sprite.h * scale + edge + card.PADDING_BOTTOM
end

local function scale3(c, f, a)
  return { math.min(c[1] * f, 1), math.min(c[2] * f, 1), math.min(c[3] * f, 1), a or 1 }
end

-- Holographic foil shader (Balatro-style): flowing rainbow sheen + light streaks.
local holoCode = [[
  extern number time;
  extern vec2 resolution;

  vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
  }

  vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec2 uv = sc / resolution;
    float hue = fract((uv.x + uv.y) * 0.6 + time * 0.08);
    vec3 rainbow = hsv2rgb(vec3(hue, 0.55, 1.0));
    float streak = sin((uv.x - uv.y) * 8.0 + time * 2.5) * 0.5 + 0.5;
    float intensity = mix(0.08, 0.45, pow(streak, 2.0));
    return vec4(rainbow * intensity, intensity) * color;
  }
]]
local holoShader
local function getHolo()
  holoShader = holoShader or love.graphics.newShader(holoCode)
  return holoShader
end

-- Gold foil shader (champions / rare cards): moving gold light streaks.
local goldCode = [[
  extern number time;
  extern vec2 resolution;

  vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec2 uv = sc / resolution;
    float band = sin((uv.x + uv.y) * 4.0 - time * 2.0) * 0.5 + 0.5;
    float streak = pow(band, 3.0);
    vec3 gold = vec3(1.0, 0.80, 0.32);
    float intensity = mix(0.06, 0.5, streak);
    return vec4(gold * intensity, intensity) * color;
  }
]]
local goldShader
local function getGold()
  goldShader = goldShader or love.graphics.newShader(goldCode)
  return goldShader
end

-- Silver foil shader (#000): same sweep, silver tint.
local silverCode = [[
  extern number time;
  extern vec2 resolution;

  vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec2 uv = sc / resolution;
    float band = sin((uv.x + uv.y) * 4.0 - time * 2.0) * 0.5 + 0.5;
    float streak = pow(band, 3.0);
    vec3 silver = vec3(0.82, 0.86, 0.95);
    float intensity = mix(0.06, 0.5, streak);
    return vec4(silver * intensity, intensity) * color;
  }
]]
local silverShader
local function getSilver()
  silverShader = silverShader or love.graphics.newShader(silverCode)
  return silverShader
end

-- Draw an animated foil overlay (shader) over the whole card, masked to its shape.
local function drawFoil(shader, time, x, y, cw, ch, R)
  shader:send("time", time)
  shader:send("resolution", { love.graphics.getWidth(), love.graphics.getHeight() })
  love.graphics.stencil(function()
    love.graphics.rectangle("fill", x, y, cw, ch, R)
  end, "replace", 1)
  love.graphics.setStencilTest("greater", 0)
  love.graphics.setShader(shader)
  love.graphics.setBlendMode("add")
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("fill", x, y, cw, ch, R)
  love.graphics.setBlendMode("alpha")
  love.graphics.setShader()
  love.graphics.setStencilTest()
end

-- Public: animated foil overlay over an arbitrary rect (reused by the menu).
-- kind = "holo" | "gold" | "silver".
function card.foil(kind, time, x, y, w, h, R)
  local get = ({ holo = getHolo, gold = getGold, silver = getSilver })[kind]
  if not get then return end
  drawFoil(get(), time or love.timer.getTime(), x, y, w, h, R or 0)
end

-- Vertical gradient quad: light at top, dark at bottom.
local function gradientMesh(w, h, top, bot)
  return love.graphics.newMesh({
    { 0, 0, 0, 0, top[1], top[2], top[3], 1 },
    { w, 0, 1, 0, top[1], top[2], top[3], 1 },
    { w, h, 1, 1, bot[1], bot[2], bot[3], 1 },
    { 0, h, 0, 1, bot[1], bot[2], bot[3], 1 },
  }, "fan", "static")
end

-- Border color per element.
card.elementColor = {
  fire   = { 0.55, 0.10, 0.06 }, -- dark red
  water  = { 0.20, 0.50, 0.85 }, -- blue
  air    = { 1, 1, 1 }, -- white
  earth  = { 0.50, 0.80, 0.40 }, -- green
  aether = { 0.70, 0.40, 0.85 }, -- purple
}

-- Deterministic 0..1 noise from a pixel index and time frame.
local function flickerNoise(i, frame)
  local r = math.sin(i * 12.9898 + frame * 78.233) * 43758.5453
  return r - math.floor(r)
end

-- Occasionally swap characters for a corrupted, glitching label.
local glitchChars = "!@#$%&*/\\?01234567890"
local function glitchName(name, frame)
  local out = {}
  for i = 1, #name do
    if flickerNoise(i * 13, frame) < 0.15 then
      local g = math.floor(flickerNoise(i * 7 + 1, frame) * #glitchChars) + 1
      out[i] = glitchChars:sub(g, g)
    else
      out[i] = name:sub(i, i)
    end
  end
  return table.concat(out)
end

-- Horizontal slice shift for a given sprite row (glitch scanline bars):
-- rows are grouped into bands; some bands jump sideways each frame.
local function barShift(spriteY, frame, scale)
  local band = math.floor(spriteY / 3)
  if flickerNoise(band * 7 + 1, frame) < 0.25 then           -- ~25% of bands active
    return math.floor((flickerNoise(band, frame) - 0.5) * 6) * scale
  end
  return 0
end

-- Draw sprite pixels. When `flicker` is set, corrupted glitch: a shifting subset
-- of pixels blinks off each frame, the R/B channels split horizontally
-- (chromatic aberration), and horizontal bands jump sideways (scanline bars).
-- flicker = { frame = n, amount = 0..1, split = px }.
local function drawSprite(s, ox, oy, scale, flicker, sil)
  if sil then
    love.graphics.setColor(sil)
    for _, p in ipairs(s.pixels) do
      if s.palette[p[3] + 1] then
        love.graphics.rectangle("fill", ox + p[1] * scale, oy + p[2] * scale, scale, scale)
      end
    end
    return
  end
  local split = flicker and flicker.split
  if split then love.graphics.setBlendMode("add") end
  for i, p in ipairs(s.pixels) do
    local c = s.palette[p[3] + 1]
    if c and not (flicker and flickerNoise(i, flicker.frame) < flicker.amount) then
      local bar = flicker and barShift(p[2], flicker.frame, scale) or 0
      local px, py = ox + p[1] * scale + bar, oy + p[2] * scale
      local r, g, b = c[1] / 255, c[2] / 255, c[3] / 255
      if split then
        love.graphics.setColor(r, 0, 0); love.graphics.rectangle("fill", px - split, py, scale, scale)
        love.graphics.setColor(0, g, 0); love.graphics.rectangle("fill", px, py, scale, scale)
        love.graphics.setColor(0, 0, b); love.graphics.rectangle("fill", px + split, py, scale, scale)
      else
        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill", px, py, scale, scale)
      end
    end
  end
  if split then love.graphics.setBlendMode("alpha") end
end

-- Draw one card: framed sprite art with a textured, element-colored border.
-- opts (optional): { holo = true, time = <seconds> } for the Balatro-style foil.
function card.draw(sprite, element, x, y, scale, opts)
  opts = opts or {}
  local color = card.elementColor[element] or { 1, 1, 1 }
  local F, P, R = card.FRAME, card.PADDING, card.RADIUS
  local artW, artH = sprite.w * scale, sprite.h * scale
  local wellW, wellH = artW + P * 2, artH + P * 2 + card.PADDING_BOTTOM
  local cw, ch = wellW + F * 2, wellH + F * 2

  -- gradient element frame, masked to the rounded card shape
  love.graphics.stencil(function()
    love.graphics.rectangle("fill", x, y, cw, ch, R)
  end, "replace", 1)
  love.graphics.setStencilTest("greater", 0)
  local mesh = gradientMesh(cw, ch, scale3(color, 0.1), scale3(color, 0.40))
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(mesh, x, y)
  love.graphics.setStencilTest()

  -- dark gradient well, inset by the frame, with its own rounded corners
  local wx, wy = x + F, y + F
  local Rw = math.max(R - F, 2)
  love.graphics.stencil(function()
    love.graphics.rectangle("fill", wx, wy, wellW, wellH, Rw)
  end, "replace", 1)
  love.graphics.setStencilTest("greater", 0)
  local wellTop, wellBot = { 0.16, 0.16, 0.18 }, { 0.04, 0.04, 0.05 }
  if opts.champion then
    wellTop, wellBot = { 0.55, 0.43, 0.12 }, { 0.22, 0.16, 0.04 } -- gold
  end
  local well = gradientMesh(wellW, wellH, wellTop, wellBot)
  love.graphics.draw(well, wx, wy)
  love.graphics.setStencilTest()

  -- thin dark groove at the well edge for definition
  love.graphics.setLineWidth(1)
  love.graphics.setColor(0.10, 0.10, 0.12)
  love.graphics.rectangle("line", wx, wy, wellW, wellH, Rw)

  local ax, ay = x + F + P, y + F + P

  if card.FOG_OF_WAR then
    love.graphics.setScissor(wx, wy, wellW, wellH)
    drawSprite(sprite, ax, ay, scale, nil, { 0.10, 0.10, 0.12 })
    love.graphics.setScissor()
  else
  -- creature, clipped to the well so corruption can't bleed into the frame
  local flicker
  if opts.corrupt then
    local t = opts.time or love.timer.getTime()
    local frame = math.floor(t * 5)
    -- jittered horizontal channel split, ~1px of the sprite scale
    local split = scale * (0.6 + 0.4 * flickerNoise(0, frame))
    flicker = { frame = frame, amount = 0.10, split = split } -- ~10% blink + RGB split at 5fps
  end
  love.graphics.setScissor(wx, wy, wellW, wellH)
  drawSprite(sprite, ax, ay, scale, flicker)
  love.graphics.setScissor()

  -- name plate + power badge, clipped to the rounded well
  if opts.name or opts.power then
    card._font = card._font or love.graphics.newFont("assets/fonts/Cinzel-Bold.ttf",16)
    card._powerFont = card._powerFont or love.graphics.newFont("assets/fonts/Cinzel-Bold.ttf",20)
    local f, pf = card._font, card._powerFont
    local pad = 8
    local barH = f:getHeight() + 10
    local by = wy + wellH - barH

    love.graphics.stencil(function()
      love.graphics.rectangle("fill", wx, wy, wellW, wellH, Rw)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    -- bottom bar
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", wx, by, wellW, barH)
    -- power badge (fixed zone, bottom-right) — the only stat, gets a constant anchor
    local nameRight = wx + wellW - pad
    if opts.power then
      local ro = barH * 0.72       -- outer radius
      local fr = card.FRAME        -- badge frame thickness (matches the card border)
      local ri = ro - fr           -- inner radius
      local cx, cy = wx + wellW - pad - ro, wy + wellH - pad - ro

      -- outer frame ring: same dark gradient as the card frame
      love.graphics.stencil(function()
        love.graphics.circle("fill", cx, cy, ro)
      end, "replace", 1)
      love.graphics.setStencilTest("greater", 0)
      local frame = gradientMesh(ro * 2, ro * 2, { 0.08, 0.08, 0.09 }, { 0.02, 0.02, 0.03 })
      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(frame, cx - ro, cy - ro)
      love.graphics.setStencilTest()

      -- inner: dark element-colored gradient
      love.graphics.stencil(function()
        love.graphics.circle("fill", cx, cy, ri)
      end, "replace", 1)
      love.graphics.setStencilTest("greater", 0)
      local bg = gradientMesh(ri * 2, ri * 2, scale3(color, 0.60), scale3(color, 0.10))
      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(bg, cx - ri, cy - ri)
      love.graphics.setStencilTest()

      -- groove at the inner edge for depth
      love.graphics.setLineWidth(1)
      love.graphics.setColor(0.10, 0.10, 0.12)
      love.graphics.circle("line", cx, cy, ri)

      local s = tostring(opts.power)
      love.graphics.setFont(pf)
      love.graphics.setColor(1, 1, 1, 0.6)
      love.graphics.print(s, cx - pf:getWidth(s) / 2, cy - pf:getHeight() / 2)
      nameRight = cx - ro - 6
    end

    -- name, auto-shrunk to fit the width left of the badge
    if opts.name then
      local avail = nameRight - (wx + pad)
      local sc = math.min(1, avail / f:getWidth(opts.name))
      local nx, ny = wx + pad, by + (barH - f:getHeight() * sc) / 2
      love.graphics.setFont(f)
      if opts.corrupt then
        local frame = math.floor((opts.time or love.timer.getTime()) * 5)
        local name = glitchName(opts.name, frame)
        love.graphics.setBlendMode("add")
        love.graphics.setColor(1, 0, 0); love.graphics.print(name, nx - 1.2, ny, 0, sc, sc)
        love.graphics.setColor(0, 1, 0); love.graphics.print(name, nx, ny, 0, sc, sc)
        love.graphics.setColor(0, 0, 1); love.graphics.print(name, nx + 1.2, ny, 0, sc, sc)
        love.graphics.setBlendMode("alpha")
      else
        if opts.champion then
          love.graphics.setColor(0.80, 0.60, 0.20, 0.95) -- deeper gold for champions
        else
          love.graphics.setColor(0.95, 0.95, 0.95, 0.8)
        end
        love.graphics.print(opts.name, nx, ny, 0, sc, sc)
      end
    end

    love.graphics.setStencilTest()
  end
  end

  -- animated foil overlays, masked to the rounded card shape
  local time = opts.time or love.timer.getTime()
  if opts.champion then drawFoil(getGold(), time, x, y, cw, ch, R) end -- gold rare foil
  if opts.silver then drawFoil(getSilver(), time, x, y, cw, ch, R) end  -- silver (#000)
  if opts.holo then drawFoil(getHolo(), time, x, y, cw, ch, R) end     -- holographic

  love.graphics.setColor(1, 1, 1)
end

-- The card lies flat (rendered to a canvas, then warped to a receding trapezoid)
-- with the hires art standing upright on it. Composition stays within the slot
-- rect [x,y .. x+cw,y+ch] so existing hitboxes/outlines still line up.
card.STAND_FAR   = 0.62   -- far-edge width as a fraction of the near (front) edge
card.STAND_DEPTH = 0.5    -- flat-card height on screen (foreshortening)
card.STAND_LIFT  = 0.5    -- feet plant along the flat depth (0 far..1 near)
card.STAND_BOB   = 5      -- idle float amplitude in px

local standCanvas, standMesh, standW, standH
function card.drawStanding(sprite, hires, element, x, y, scale, opts)
  opts = opts or {}
  local cw, ch = card.size(sprite, scale)

  if not standCanvas or standW ~= cw or standH ~= ch then
    standCanvas = love.graphics.newCanvas(cw, ch)
    standW, standH = cw, ch
  end
  local prev = love.graphics.getCanvas()
  love.graphics.setCanvas({ standCanvas, stencil = true })
  love.graphics.clear(0, 0, 0, 0)
  card.draw(sprite, element, 0, 0, scale, opts)
  love.graphics.setCanvas(prev)

  local flatH = ch * card.STAND_DEPTH
  local farW  = cw * card.STAND_FAR
  local yNear = y + ch
  local yFar  = yNear - flatH
  local fx0, fx1 = x + (cw - farW) / 2, x + (cw + farW) / 2
  standMesh = standMesh or love.graphics.newMesh(4, "fan", "stream")
  standMesh:setVertices({
    { fx0, yFar, 0, 0, 1, 1, 1, 1 },
    { fx1, yFar, 1, 0, 1, 1, 1, 1 },
    { x + cw, yNear, 1, 1, 1, 1, 1, 1 },
    { x, yNear, 0, 1, 1, 1, 1, 1 },
  })
  standMesh:setTexture(standCanvas)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(standMesh)

  local footX = x + cw / 2
  local footY = yFar + flatH * card.STAND_LIFT
  local targetH = footY - (y + 2)
  local iw, ih
  if hires then iw, ih = hires:getDimensions() else iw, ih = sprite.w, sprite.h end
  local s = math.min(targetH / ih, cw * 1.05 / iw)
  local dw, dh = iw * s, ih * s

  local time = opts.time or love.timer.getTime()
  local lift = math.sin(time * 2 + x * 0.05) * card.STAND_BOB
  local frac = lift / card.STAND_BOB * 0.5 + 0.5   -- 0 low .. 1 high
  love.graphics.setColor(0, 0, 0, 0.33 * (1 - 0.3 * frac))
  love.graphics.ellipse("fill", footX, footY, dw * 0.34 * (1 - 0.15 * frac), flatH * 0.16 * (1 - 0.15 * frac))
  love.graphics.setColor(1, 1, 1)
  local cy = footY - dh - lift
  if hires then
    love.graphics.draw(hires, footX - dw / 2, cy, 0, s, s)
  else
    drawSprite(sprite, footX - dw / 2, cy, s)
  end
end

return card
