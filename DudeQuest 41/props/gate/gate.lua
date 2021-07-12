local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
local utils = require("m.utils")

local layers = require("m.layers")
local gamestate = require("game.gamestate")
local DEPTH = layers.get_depth(layers.PROPS_BACK)

local go = go
local set_instance = runtime.set_instance
local set_position = go.set_position
local get_position = go.get_position
local animate = go.animate
local vector3_get_xy = fastmath.vector3_get_xy
local vector3_set_xyz = fastmath.vector3_set_xyz


local function make()
   local instance = {
      x = 0,
      y = 0,
      is_gate = true,
      map = 0,
      location = 0,
   }
   local vector3_stub = fastmath.vector3_stub
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
      vector3_set_xyz(vector3_stub, 0, 0, 0.0001)
      set_position(vector3_stub, portcullis)
      animate(portcullis, const.POSITION_Y, go.PLAYBACK_ONCE_FORWARD, 40, go.EASING_INOUTQUAD, (animated and 1.4 or 0), delay or 0)
   end -- open

   function instance.close(animated, delay)
      vector3_set_xyz(vector3_stub, 0, 40, 0.0001)
      set_position(vector3_stub, portcullis)
      animate(portcullis, const.POSITION_Y, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_OUTBOUNCE, (animated and 1.6 or 0), delay or 0)
   end -- close

   function instance.init(self)
      instance.map = gamestate[self.destination]
      instance.location = gamestate[self.passage]
      root = msg.url(".")
      portcullis = msg.url("portcullis")
      instance.x, instance.y = vector3_get_xy(get_position())
      vector3_set_xyz(vector3_stub, 0, 0, DEPTH)
      set_position(vector3_stub, "doorway")
      set_instance(root.path, instance)
      instance.open(true, 0.25)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      set_instance(root.path, nil)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
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
