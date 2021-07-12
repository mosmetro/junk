local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
local animation = require("m.animation")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local factories = require("pixelfrog.game.factories")
local loot_distributor = require("pixelfrog.props.collectable.loot_distributor")
local gamestate = require("pixelfrog.game.gamestate")
local snd = require("sound.sound")

local DEPTH = layers.get_depth(layers.ENEMIES)
-- local coin_toss = fastmath.bernoulli(0.5)

local vector3_stub = fastmath.vector3_stub
local play_animation = animation.play
local runtime = runtime

local ANIMATION = {
   IDLE = {
      { id = hash("pink_star_idle"), position = vmath.vector3(0, 13, 0), },
      { id = hash("fierce_tooth_idle"), position = vmath.vector3(-1, 12, 0), },
      { id = hash("crabby_idle"), position = vmath.vector3(-1, 15, 0), },
   },
   CELEBRATE = {
      { id = hash("pink_star_celebrate"), position = vmath.vector3(1, 16, 0), },
      { id = hash("fierce_tooth_celebrate"), position = vmath.vector3(0, 15, 0), },
      { id = hash("crabby_celebrate"), position = vmath.vector3(0, 15, 0), },
   },
   DISAPPEAR = {
      { id = hash("disappearance"), position = vmath.vector3(0, 16, 0), },
   },
}

-- local gems = {
--    factories.GEM_RED,
--    factories.GEM_ORANGE,
--    factories.GEM_BLACK,
-- }

local hostages = {
   [gamestate.pink_star] = 1,
   [gamestate.fierce_tooth] = 2,
   [gamestate.crabby] = 3,
}

local pre = vmath.vector3(1.1, 0.9, 1)
local post = vmath.vector3(0.9, 1.2, 1)

local function make()
   local instance = {}
   local root
   local kind
   local name
   local door_name
   -- local drop_counter
   -- local drop_position
   local loot_count
   local root_position
   local char = animation.new_target()

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function drop_done()
      play_animation(char, ANIMATION.DISAPPEAR, nil, destroy)
   end -- drop_done

   local drop_loot

   local function on_complete()
      if loot_count > 0 then
         loot_count = loot_count - 1
         go.animate(char.pivot, const.SCALE, go.PLAYBACK_ONCE_FORWARD, post, go.EASING_LINEAR, 0.07, 0, drop_loot)
         loot_distributor.drop(fastmath.coin_toss() and factories.COIN_GOLD or fastmath.pick_any(factories.GEMS), root_position)
         snd.play_sound(snd.POP_SOUNDS_8)
      else
         go.animate(char.pivot, const.SCALE, go.PLAYBACK_ONCE_FORWARD, const.VECTOR3_ONE, go.EASING_LINEAR, 0.07, 0, drop_done)
      end
   end -- on_complete

   -- local function drop_loot()
   --    char.current_animation = nil
   --    if drop_counter > 0 then
   --       if coin_toss() then
   --          loot_distributor.drop(gems[drop_counter], drop_position)
   --       else
   --          loot_distributor.drop(factories.COIN_GOLD, drop_position)
   --       end
   --       drop_counter = drop_counter - 1
   --       play_animation(char, ANIMATION.CELEBRATE, kind, drop_loot)
   --    else
   --       play_animation(char, ANIMATION.DISAPPEAR, nil, destroy)
   --    end
   --    snd.play_sound(snd.SHANTAE_LAND)
   -- end -- drop_loot

   function drop_loot()
      go.animate(char.pivot, const.SCALE, go.PLAYBACK_ONCE_FORWARD, pre, go.EASING_LINEAR, 0.08, 0, on_complete)
   end -- drop_loot

   local function on_door_open()
      -- play_animation(char, ANIMATION.CELEBRATE, kind, drop_loot)
      go.animate(char.pivot, const.SCALE, go.PLAYBACK_ONCE_FORWARD, pre, go.EASING_LINEAR, 0.08, 0, on_complete)
      gamestate.set(gamestate.map, name, "freed", true)
   end -- on_door_open

   local function on_level_will_appear()
      nc.post_notification(gamestate.key_spawner, name, factories.KEY_IRON, 0, 110)
   end -- on_level_will_appear

   function instance.init(self)
      name = self.name
      root = msg.url(".")
      root_position = go.get_position(root)
      if gamestate.get(gamestate.map, name, "freed", false) then
         destroy()
         return
      end
      kind = hostages[name]
      door_name = self.door_name
      char.pivot = msg.url("pivot")
      char.anchor = msg.url("anchor")
      char.sprite = msg.url("anchor#sprite")
      char.current_animation_group = nil
      char.current_animation = nil
      char.on_complete = nil
      fastmath.vector3_set_xyz(vector3_stub, 0, 0, DEPTH)
      go.set_position(vector3_stub, char.pivot)
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      if self.direction < 0 then
         go.set(char.pivot, const.ROTATION, const.QUAT_Y_180)
      end
      if door_name ~= const.EMPTY then
         nc.add_observer(on_door_open, "opened", door_name)
      end
      nc.add_observer(on_level_will_appear, const.LEVEL_WILL_APPEAR_NOTIFICATION)
      play_animation(char, ANIMATION.IDLE, kind)
      loot_count = 5
      -- drop_counter = #gems
      -- drop_position = go.get_position(root)
   end -- instance.init

   function instance.deinit()
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.remove_observer(on_level_will_appear, const.LEVEL_WILL_APPEAR_NOTIFICATION)
      nc.remove_observer(on_door_open, "opened", door_name)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

-- export
return {
   new = pool.new,
   free = pool.free,
}
