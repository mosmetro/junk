local Pool = require("m.pool")
local snd = require("sound.sound")
local nc = require("m.notification_center")
local CONST = require("m.constants")
local utils = require("m.utils")

local set_instance = runtime.set_instance
local get_id = go.get_id
local set_position = go.set_position
local get_world_position = go.get_world_position
local animate = go.animate
local vector3_get_components = fastmath.vector3_get_components
local vector3_set_components = fastmath.vector3_set_components
local PLAYBACK_ONCE_FORWARD = go.PLAYBACK_ONCE_FORWARD
local EASING_GATE_OPEN = go.EASING_LINEAR
local EASING_GATE_CLOSE = go.EASING_OUTBOUNCE
-- local play_sound = snd.play_sound

local POSITION_Y = hash("position.y")

local function make()
   local instance = {
      x = 0,
      y = 0,
      is_gate = true,
      map = 0,
      location = 0,
   }
   local vector3_stub = vmath.vector3()
   local root
   local portcullis

   local function destroy()
      go.delete(root, true)
   end -- destroy

   function instance.accepts_first_responder(other_instance)
      -- utils.log(root)
      return fastmath.combined_is_equal(instance.y, other_instance.y)
   end -- accepts_first_responder

   function instance.become_first_responder()
      -- utils.log(root)
   end -- become_first_responder

   function instance.resign_first_responder()
      -- utils.log(root)
   end -- resign_first_responder

   function instance.open(animated, delay)
      vector3_set_components(vector3_stub)
      set_position(vector3_stub, portcullis)
      animate(portcullis, POSITION_Y, PLAYBACK_ONCE_FORWARD, 40, EASING_GATE_OPEN, (animated and 1 or 0), delay or 0)
   end -- open

   function instance.close(animated, delay)
      vector3_set_components(vector3_stub, 0, 40)
      set_position(vector3_stub, portcullis)
      animate(portcullis, POSITION_Y, PLAYBACK_ONCE_FORWARD, 0, EASING_GATE_CLOSE, (animated and 1.6 or 0), delay or 0)
      -- local source_attr = fmod._3D_ATTRIBUTES()
      -- source_attr.position = get_world_position(root)
      -- source_attr.velocity = vmath.vector3(0.0)
      -- source_attr.forward = vmath.vector3(1, 0, 0)
      -- source_attr.up = vmath.vector3(0, 1, 0)
      -- play_sound(snd.PORTCULLIS_CLOSE)
   end -- close

   function instance.init(self)
      instance.map = self.destination_map
      instance.location = self.destination_gate
      root = msg.url(".")
      portcullis = msg.url("portcullis")
      instance.x, instance.y = vector3_get_components(get_world_position())
      set_instance(root.path, instance)
      instance.close(true, 0.25)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      set_instance(root.path, nil)
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

-- export
return {
   new = pool.new,
   free = pool.free,
   fill = pool.fill,
   purge = pool.purge,
   count = pool.count,
}
