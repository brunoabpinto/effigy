-- Mouth parts. Slots: 0 outline, 1 base, 2 accent (teeth).
local g = require("src.core.parts")

return {
  smile = g({
    "#      #",
    "#      #",
    " #    # ",
    "  ####  ",
  }),

  grin = g({
    "########",
    "#*#*#*#*",
    "########",
  }),

  frown = g({
    "  ####  ",
    " #    # ",
    "#      #",
    "#      #",
  }),

  open = g({
    " #### ",
    "#****#",
    "#****#",
    "#****#",
    " #### ",
  }),

  line = g({
    "######",
    "######",
  }),
}
