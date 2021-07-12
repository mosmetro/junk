local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local snd = require("sound.sound")

local DEPTH = layers.get_depth(layers.PROPS)

local vector3_stub = fastmath.vector3_stub

local function make()
   local instance = {
      is_ground = true,
      can_jump_down = false,
   }
   local root
   local anchor
   local collisionobject
   local timer_handle
   local rotate_to_safe
   local rotate_to_unsafe
   local turn_duration
   local auto_return
   local return_delay
   local damage_points
   local is_safe

   local function destroy()
      if timer_handle then timer.cancel(timer_handle) end
      go.delete(root, true)
   end -- destroy

   local function rotation_complete()
      msg.post(collisionobject, msg.ENABLE)
      if auto_return and is_safe then
         timer_handle = timer.delay(return_delay, false, rotate_to_unsafe)
      end
   end -- rotation_complete

   function rotate_to_safe()
      is_safe = true
      msg.post(collisionobject, msg.DISABLE)
      go.animate(root, const.EULER_Z, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_INOUTSINE, turn_duration, 0, rotation_complete)
   end -- rotate_to_safe

   function rotate_to_unsafe()
      is_safe = false
      msg.post(collisionobject, msg.DISABLE)
      go.animate(root, const.EULER_Z, go.PLAYBACK_ONCE_FORWARD, 180, go.EASING_INOUTSINE, turn_duration, 0, rotation_complete)
   end -- rotate_to_unsafe

   function instance.on_collision(other_instance)
      if other_instance and other_instance.on_hit then
         other_instance.on_hit(snd.SHANTAE_GETHIT, damage_points, 0)
      end
   end -- instance.on_collision

   function instance.on_hit()
      snd.play_sound(snd.FATE_WOOD_FLESH_1)
      nc.post_notification(const.CAMERA_SHAKE_REQUEST_NOTIFICATION, nil, 3, 0.15)
      if timer_handle then timer.cancel(timer_handle) end
      if is_safe then
         rotate_to_unsafe()
      else
         rotate_to_safe()
      end
   end -- instance.on_hit

   function instance.init(self)
      turn_duration = self.turn_duration
      auto_return = self.auto_return
      return_delay = self.return_delay
      damage_points = self.damage_points
      is_safe = self.is_safe
      root = msg.url(".")
      anchor = msg.url("anchor")
      collisionobject = msg.url("#collisionobject")
      vector3_stub = go.get_position(anchor)
      fastmath.vector3_set_z(vector3_stub, DEPTH)
      go.set_position(vector3_stub, anchor)
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      if is_safe then
         go.set(root, const.ROTATION, const.QUAT_IDENTITY)
      else
         go.set(root, const.ROTATION, const.QUAT_Z_180)
      end
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
