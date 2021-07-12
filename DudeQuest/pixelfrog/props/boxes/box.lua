local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local snd = require("sound.sound")
local factories = require("pixelfrog.game.factories")

local DEPTH = layers.get_depth(layers.PROPS)

local loot_velocity_x_roll = fastmath.uniform_int(-60, 60)
local loot_velocity_y_roll = fastmath.uniform_int(170, 200)

local vector3_stub = fastmath.vector3_stub
local ROOT = const.ROOT

local params = {
   [ROOT] = {
      velocity_x = 0,
      velocity_y = -1,
   },
}

local HIT_SOUNDS = {
   snd.FATE_WOOD_FLESH_1,
   snd.FATE_WOOD_FLESH_2,
   snd.FATE_WOOD_FLESH_3,
}

local function make()
   local instance = {}
   local root
   local anchor_sprite
   local collisionobject

   local IDLE
   local HIT
   local destroyed_collection
   local health_points
   local has_gold_coin
   local has_sword

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function on_complete()
      if health_points > 0 then
         sprite.play_flipbook(anchor_sprite, IDLE)
      else
         local position = go.get_world_position(root)
         collectionfactory.create(destroyed_collection, position, const.QUAT_IDENTITY, nil, 1)
         factory.create(factories.EFFECT_CIRCLE_PUFF, position, const.QUAT_IDENTITY, nil, 1)
         if has_gold_coin then
            params[ROOT].velocity_x = loot_velocity_x_roll()
            params[ROOT].velocity_y = loot_velocity_y_roll()
            collectionfactory.create(factories.COIN_GOLD, position, const.QUAT_IDENTITY, params, 1)
         end
         if has_sword then
            params[ROOT].velocity_x = loot_velocity_x_roll()
            params[ROOT].velocity_y = loot_velocity_y_roll()
            collectionfactory.create(factories.SWORD_PICKUP, position, const.QUAT_IDENTITY, params, 1)
         end
         destroy()
      end
   end -- on_complete

   function instance.on_hit(sfx, dp)
      health_points = health_points - (dp or 0)
      if health_points > 0 then
         if sfx then
            snd.play_sound(sfx)
         else
            snd.play_sound(fastmath.pick_any(HIT_SOUNDS, 2))
         end
      else
         msg.post(collisionobject, msg.DISABLE)
         snd.play_sound(snd.BARREL_BREAK)
         nc.post_notification(const.CAMERA_SHAKE_REQUEST_NOTIFICATION, nil, 3, 0.25)
      end
      sprite.play_flipbook(anchor_sprite, HIT, on_complete)
   end -- instance.on_hit

   function instance.on_jump(sfx, dp, speed)
      instance.on_hit(sfx, dp, speed)
      return 150 -- recoil velocity
   end -- instance.on_jump

   function instance.init(self)
      has_gold_coin = self.has_gold_coin
      has_sword = self.has_sword
      IDLE = self.idle_animation
      HIT = self.hit_animation
      destroyed_collection = self.destroyed_collection
      health_points = self.health_points
      root = msg.url(".")
      collisionobject = msg.url("#collisionobject")
      anchor_sprite = msg.url("anchor#sprite")
      vector3_stub = go.get_position("anchor")
      fastmath.vector3_set_z(vector3_stub, DEPTH)
      go.set_position(vector3_stub, "anchor")
      sprite.play_flipbook(anchor_sprite, IDLE)
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

-- export
return {
   new = pool.new,
   free = pool.free,
}
