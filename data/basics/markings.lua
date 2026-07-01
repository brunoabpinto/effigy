-- Marking parts (accent overlays on the body). Slots: 2 accent.
local g = require("src.core.parts")

return {
  spots = g({
    " *  * ",
    "*  *  ",
    " *  * ",
  }),

  stripe = g({
    "**",
    "**",
    "**",
  }),

  dots = g({
    "* *",
    " * ",
    "* *",
  }),

  cross = g({
    " * ",
    "***",
    " * ",
  }),
}
