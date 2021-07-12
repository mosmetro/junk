local utils = require("m.utils")

local hash = hash

local layers = {
   -- near
   "DEBUG",
   "COVER",
   "MUD",
   "SAND",
   "PROJECTILES",
   "PLAYER",
   "EFFECT_BACK",
   "COLLECTABLE",
   "ENEMIES",
   "PROPS",
   "STATIC_GEOMETRY",
   "DEBRIS",
   "PROPS_BACK",
   "BACKGROUND",
   "PARALLAX_1",
   "PARALLAX_2",
   "PARALLAX_3",
   "PARALLAX_4",
   "PARALLAX_5",
   "PARALLAX_6",
   "PARALLAX_7",
   "PARALLAX_8",
   "PARALLAX_9",
   -- far
}

local M = {}
for i = 1, #layers do
   local layer = layers[i]
   M[layer] = hash(layer)
end

local depths = {}

local function setup_depths(near, far)
   local last_index = #layers - 1
   local delta = (far - near) / last_index
   for i = 0, last_index do
      depths[M[layers[i + 1]]] = far - delta * i
   end
   for i =1, #layers do
      local layer = layers[i]
      utils.log(layer, depths[M[layer]])
   end
end

local function get_depth(layer)
   local result = depths[layer]
   if result then return result end
   utils.log("layer not found: " .. tostring(layer))
end

M.setup_depths = setup_depths
M.get_depth = get_depth

return M
