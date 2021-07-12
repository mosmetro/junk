-- local vector4 = vmath.vector4
local table = table
-- local tostring = tostring

local lights = {
  {
    position = "light1_position",
    color = "light1_color",
    falloff = "light1_falloff",
  },

  {
    position = "light2_position",
    color = "light2_color",
    falloff = "light2_falloff",
  },

  {
    position = "light3_position",
    color = "light3_color",
    falloff = "light3_falloff",
  },

  {
    position = "light4_position",
    color = "light4_color",
    falloff = "light4_falloff",
  },

  {
    position = "light5_position",
    color = "light5_color",
    falloff = "light5_falloff",
  },
}

-- functions
-- local generate
local push
local pop

-- function generate()
--   for i = 0, 5 do -- 0 - player lamp light
--     local light = {
--       position = "light" .. tostring(i) .. "_position",
--       color    = "light" .. tostring(i) .. "_color",
--       falloff  = "light" .. tostring(i) .. "_falloff"
--     }
--     lights[i] = light
--   end
-- end

function push(light)
  if not light then return end
  lights[#lights + 1] = light
end

function pop()
  return table.remove(lights)
end


return {
  -- generate = generate,
  push = push,
  pop = pop,
}
