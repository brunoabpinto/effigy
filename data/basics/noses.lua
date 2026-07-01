-- Nose parts. Slots: 0 outline, 1 base, 2 accent.
local g = require("src.core.parts")

return {
  button = g({
    "##",
    "##",
  }),

  snout = g({
    " ## ",
    "####",
  }),

  beak = g({
    "#",
    "##",
    "#",
  }),

  wide = g({
    "####",
    " ## ",
  }),
}
