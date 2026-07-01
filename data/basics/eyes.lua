-- Eye parts. One eye tile each; the generator mirrors it for the second eye.
-- Slots: 0 outline, 1 sclera, 2 pupil.
local g = require("src.core.parts")

return {
  round = g({
    " #### ",
    "#++++#",
    "#+**+#",
    "#+**+#",
    "#++++#",
    " #### ",
  }),

  dot = g({
    " ## ",
    "#**#",
    "#**#",
    " ## ",
  }),

  angry = g({
    "###    ",
    " #++**#",
    "  #####",
  }),

  sleepy = g({
    "#######",
    " ** ** ",
  }),

  wide = g({
    " ##### ",
    "#+++++#",
    "#+***+#",
    "#+***+#",
    "#+++++#",
    " ##### ",
  }),
}
