local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local snd = require("sound.sound")
local factories = require("pixelfrog.game.factories")

local DEPTH = layers.get_depth(layers.PROPS)

local vector3_stub = fastmath.vector3_stub

local function make()
   local instance = {
      is_ground = true,
      is_static = true,
      can_jump_down = false,
   }
   local root
   local anchor
   local collisionobject
   local anchor_sprite
   local is_broken
   local timer_handle
   local idle_animation
   local break_animation
   local away_time
   local destroyed_collection

   local function destroy()
      if timer_handle then
         timer.cancel(timer_handle)
      end
      go.delete(root, true)
   end -- destroy

   local function restore_complete()
      is_broken = false
      msg.post(collisionobject, msg.ENABLE)
   end -- restore_complete

   local function restore()
      sprite.play_flipbook(anchor_sprite, idle_animation)
      fastmath.vector3_set_xyz(vector3_stub, 0, -10, DEPTH)
      go.set_position(vector3_stub, anchor)
      go.animate(anchor, const.POSITION_Y, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_OUTBACK, 0.5)
      go.animate(anchor_sprite, const.TINT_W, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_LINEAR, 0.3, 0, restore_complete)
   end -- restore

   local function break_complete()
      msg.post(collisionobject, msg.DISABLE)
      go.set(anchor_sprite, const.TINT_W, 0)
      snd.play_sound(snd.BLOCK_BREAK)
      local position = go.get_world_position(root)
      collectionfactory.create(destroyed_collection, position, const.QUAT_IDENTITY, nil, 1)
      factory.create(factories.EFFECT_CIRCLE_PUFF, position, const.QUAT_IDENTITY, nil, 1)
      timer_handle = timer.delay(away_time, false, restore)
   end -- break_complete

   function instance.on_step()
      if is_broken then return end
      is_broken = true
      -- utils.log("on_step", root, runtime.current_frame)
      sprite.play_flipbook(anchor_sprite, break_animation, break_complete)
   end -- instance.on_step

   function instance.init(self)
      idle_animation = self.idle_animation
      break_animation = self.break_animation
      away_time = self.away_time
      destroyed_collection = self.destroyed_collection
      root = msg.url(".")
      anchor = msg.url("anchor")
      collisionobject = msg.url("#collisionobject")
      anchor_sprite = msg.url("anchor#sprite")
      vector3_stub = go.get_position(anchor)
      fastmath.vector3_set_z(vector3_stub, DEPTH)
      go.set_position(vector3_stub, anchor)
      is_broken = false
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
