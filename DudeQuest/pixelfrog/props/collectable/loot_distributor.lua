local const = require("m.constants")

local factories = require("pixelfrog.game.factories")
local gamestate = require("pixelfrog.game.gamestate")

local ROOT = const.ROOT
local QUAT_IDENTITY = const.QUAT_IDENTITY
local create = collectionfactory.create

local velocity_x_roll = fastmath.uniform_int(-70, 70)
local velocity_y_roll = fastmath.uniform_int(220, 270)
local chance_roll = fastmath.uniform_real(0, 1)

local bernoulli_1 = fastmath.bernoulli(0.1)
local bernoulli_2 = fastmath.bernoulli(0.2)
local bernoulli_3 = fastmath.bernoulli(0.3)
-- local bernoulli_4 = fastmath.bernoulli(0.4)
local bernoulli_5 = fastmath.bernoulli(0.5)
local bernoulli_6 = fastmath.bernoulli(0.6)
-- local bernoulli_7 = fastmath.bernoulli(0.7)
-- local bernoulli_8 = fastmath.bernoulli(0.8)
-- local bernoulli_9 = fastmath.bernoulli(0.9)

local loot_distributor = {
   amount = {
      [gamestate.coin_silver] = 1,
      [gamestate.coin_gold] = 3,
      [gamestate.gem_blue] = 5,
      [gamestate.gem_green] = 6,
      [gamestate.gem_red] = 7,
      [gamestate.gem_orange] = 9,
      [gamestate.gem_black] = 10,

      [gamestate.sword] = 1,

      [gamestate.heart] = 1,
   }
}

local params = {
   [ROOT] = {
      velocity_x = 0,
      velocity_y = 0,
   },
}

local COIN_SILVER = factories.COIN_SILVER
local COIN_GOLD = factories.COIN_GOLD
local GEM_BLUE = factories.GEM_BLUE
local GEM_GREEN = factories.GEM_GREEN
local GEM_RED = factories.GEM_RED
-- local GEM_ORANGE = factories.GEM_ORANGE
-- local GEM_BLACK = factories.GEM_BLACK
local HEART = factories.HEART

local function drop_loot(loot, position)
   if loot.drop_silver_coin then
      params[ROOT].velocity_x = velocity_x_roll()
      params[ROOT].velocity_y = velocity_y_roll()
      create(COIN_SILVER, position, QUAT_IDENTITY, params, 1)
   end
   if loot.drop_gold_coin and bernoulli_6() then
      params[ROOT].velocity_x = velocity_x_roll()
      params[ROOT].velocity_y = velocity_y_roll()
      create(COIN_GOLD, position, QUAT_IDENTITY, params, 1)
   end
   if loot.drop_blue_gem and bernoulli_5() then
      params[ROOT].velocity_x = velocity_x_roll()
      params[ROOT].velocity_y = velocity_y_roll()
      create(GEM_BLUE, position, QUAT_IDENTITY, params, 1)
   end
   if loot.drop_green_gem and bernoulli_3() then
      params[ROOT].velocity_x = velocity_x_roll()
      params[ROOT].velocity_y = velocity_y_roll()
      create(GEM_GREEN, position, QUAT_IDENTITY, params, 1)
   end
   if loot.drop_red_gem and bernoulli_2() then
      params[ROOT].velocity_x = velocity_x_roll()
      params[ROOT].velocity_y = velocity_y_roll()
      create(GEM_RED, position, QUAT_IDENTITY, params, 1)
   end
   if loot.drop_heart and bernoulli_1() then
      params[ROOT].velocity_x = velocity_x_roll()
      params[ROOT].velocity_y = velocity_y_roll()
      create(HEART, position, QUAT_IDENTITY, params, 1)
   end
end

local function drop(loot, position, chance)
   params[ROOT].velocity_x = velocity_x_roll()
   params[ROOT].velocity_y = velocity_y_roll()
   if chance and (chance_roll() < chance) then
      create(loot, position, QUAT_IDENTITY, params, 1)
   else
      create(loot, position, QUAT_IDENTITY, params, 1)
   end
end -- drop

loot_distributor.drop = drop
loot_distributor.drop_loot = drop_loot

return loot_distributor

-- return {
--    drop_loot = drop_loot,
-- }
