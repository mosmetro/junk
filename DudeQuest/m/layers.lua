local utils = require("m.utils")

local hash = hash

local layers = {
   -- near
   "DEBUG",
   "CLOUDS_FOREGROUND",
   "DUST_FOREGROUND",
   "FOREGROUND",
   "PLAYER",
   "ENEMIES",
   "COLLECTABLE",
   "POTS",
   "DEFAULT",
   "LIGHTS",
   "PROPS_FOREGROUND",
   "STATIC_GEOMETRY",
   "DUST_BACKGROUND",
   "DEBRIS",
   "CLOUDS_BACKGROUND",
   "CHECKPOINT",
   "PARALLAX0",
   "PARALLAX1",
   "PARALLAX2",
   "PARALLAX3",
   "PARALLAX4",
   "BACKGROUND",
   "PARALLAX5",
   "PARALLAX6",
   "PARALLAX7",
   "PARALLAX8",
   "PARALLAX9",
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
