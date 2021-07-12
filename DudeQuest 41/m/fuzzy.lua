--[[
set represented as:
local s = {
   [element1] = true,
   [element2] = true,
   ...
   etc.
}
]]

local function union(s1, s2, r)
   r = r or {}
   for e in next, s1 do r[e] = true end
   for e in next, s2 do r[e] = true end
   return r
end -- union

local function intersect(s1, s2, r)
   r = r or {}
   for e in next, s1 do
      r[e] = s2[e]
   end
   return r
end -- intersect

return {
   union = union,
   intersect = intersect,
}
