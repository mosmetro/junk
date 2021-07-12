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

   local to_safe
   local rotate_to_safe
   local to_unsafe
   local rotate_to_unsafe
   local turn_duration
   local idle_duration
   local start_delay
   local damage_points
   local is_safe

   local function destroy()
      if timer_handle then
         timer.cancel(timer_handle)
      end
      go.delete(root, true)
   end -- destroy

   function instance.on_collision(other_instance)
      if other_instance and other_instance.on_hit then
         other_instance.on_hit(snd.SHANTAE_GETHIT, damage_points, 0)
      end
   end -- instance.on_collision

   function to_safe()
      msg.post(collisionobject, msg.ENABLE)
      timer_handle = timer.delay(idle_duration, false, rotate_to_safe)
   end -- to_safe

   function rotate_to_safe()
      msg.post(collisionobject, msg.DISABLE)
      go.animate(root, const.EULER_Z, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_INOUTSINE, turn_duration, 0, to_unsafe)
   end -- rotate_to_safe

   function to_unsafe()
      msg.post(collisionobject, msg.ENABLE)
      timer_handle = timer.delay(idle_duration, false, rotate_to_unsafe)
   end -- to_unsafe

   function rotate_to_unsafe()
      msg.post(collisionobject, msg.DISABLE)
      go.animate(root, const.EULER_Z, go.PLAYBACK_ONCE_FORWARD, 180, go.EASING_INOUTSINE, turn_duration, 0, to_safe)
   end -- rotate_to_unsafe

   function instance.init(self)
      turn_duration = self.turn_duration
      idle_duration = self.idle_duration
      start_delay = self.start_delay
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
         timer_handle = timer.delay(start_delay, false, rotate_to_unsafe)
      else
         go.set(root, const.ROTATION, const.QUAT_Z_180)
         timer_handle = timer.delay(start_delay, false, rotate_to_safe)
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
