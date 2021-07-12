-- import
local utils = require("scripts.shared.utils")

-- localization
local select_next = utils.select_next
local hash = hash
local vector3 = vmath.vector3

-- functions
local get_drop

local drops = {
  [hash("gold_coin")] = {
    animations = {
      hash("gold_coin_1"),
      hash("gold_coin_2"),
      hash("gold_coin_3"),
      hash("gold_coin_4"),
    },
    value = 3,
  },

  [hash("silver_coin")] = {
    animations = {
      hash("silver_coin_1"),
      hash("silver_coin_2"),
      hash("silver_coin_3"),
      hash("silver_coin_4"),
    },
    value = 2,
  },

  [hash("bronze_coin")] = {
    animations = {
      hash("bronze_coin_1"),
      hash("bronze_coin_2"),
      hash("bronze_coin_3"),
      hash("bronze_coin_4"),
    },
    value = 1,
  },
}

function get_drop(id) -- hash
  local drop = drops[id]
  return {
    velocity = vector3(22, 175, 0),
    animation = select_next(drop.animations),
    value = drop.value,
  }
end

-- export
return {
  get_drop = get_drop,
}
