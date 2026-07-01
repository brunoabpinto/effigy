-- Limb parts (arms / legs / wings). Slots: 0 outline, 1 base, 2 accent.
local g = require("src.core.parts")

return {
  stubs = g({
    "##   ##",
    "##   ##",
    "##   ##",
  }),

  legs = g({
    "##  ##",
    "##  ##",
    "##  ##",
    "##  ##",
  }),

  arms = g({
    "##        ##",
    "###      ###",
    " ##      ## ",
  }),

  wings = g({
    "##      ##",
    "###    ###",
    "####  ####",
    "### ## ###",
  }),
}
