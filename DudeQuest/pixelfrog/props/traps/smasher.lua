local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local snd = require("sound.sound")

local DEPTH = layers.get_depth(layers.PROPS)

local vector3_stub = fastmath.vector3_stub

local function make()
   local instance = {}
   local root
   local anchor
   local damage_points

   local function destroy()
      go.delete(root, true)
   end -- destroy

   function instance.on_collision(other_instance)
      if other_instance and other_instance.on_hit then
         other_instance.on_hit(snd.SHANTAE_GETHIT, damage_points)
      end
   end -- instance.on_collision

   function instance.init(self)
      damage_points = self.damage_points
      root = msg.url(".")
      anchor = msg.url("anchor")
      vector3_stub = go.get_position(anchor)
      fastmath.vector3_set_z(vector3_stub, DEPTH)
      go.set_position(vector3_stub, anchor)
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      go.set(root, const.EULER_Z, self.swing_start)
      if self.is_pendulum then
         go.animate(root, const.EULER_Z, go.PLAYBACK_LOOP_PINGPONG, self.swing_end, go.EASING_INOUTQUAD, self.swing_duration, self.start_delay)
      else
         go.animate(root, const.EULER_Z, go.PLAYBACK_LOOP_FORWARD, self.swing_end, go.EASING_LINEAR, self.swing_duration, self.start_delay)
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
