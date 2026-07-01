-- Card registry: metadata not stored in the sprite JSON.
-- Sprite pixels come from data/<id>.json; this maps id -> name/element/power.
return {
  ["000"] = { name = "#000", element = "", power = 0, silver = true },
  ["001"] = { name = "Rootbound Colossus", element = "earth", power = 11, champion = true },
  ["002"] = { name = "Fire Colossus", element = "fire", power = 10, champion = true },
  ["003"] = { name = "The Abyssal Shell", element = "water", power = 9, champion = true },
  ["004"] = { name = "The Gale Phantom", element = "air", power = 8, champion = true },
  ["005"] = { name = "The Unnamed", element = "aether", power = 12, champion = true },
  ["006"] = { name = "Emberling", element = "fire", power = 2 },
  ["007"] = { name = "Cinder Hound", element = "fire", power = 4 },
  ["008"] = { name = "Magma Warden", element = "fire", power = 6 },
  ["009"] = { name = "Inferno Drake", element = "fire", power = 8 },
}
