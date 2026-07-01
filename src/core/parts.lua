-- Parse ASCII rows into a part { w, h, pixels = {{x,y,slot}} }.
-- '#' = outline (0), '+' = base (1), '*' = accent (2), other = empty.

local slots = { ["#"] = 0, ["+"] = 1, ["*"] = 2 }

return function(rows)
  local px, w = {}, 0
  for y, row in ipairs(rows) do
    w = math.max(w, #row)
    for x = 1, #row do
      local s = slots[row:sub(x, x)]
      if s then px[#px + 1] = { x - 1, y - 1, s } end
    end
  end
  return { w = w, h = #rows, pixels = px }
end
