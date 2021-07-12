local Pool = require("m.pool")
local layers = require("m.layers")
local nc = require("m.notification_center")
local CONST = require("m.constants")
-- local utils = require("m.utils")

local go = go
local fastmath = fastmath

local DEPTH = layers.get_depth(layers.DEBUG)

local vector3_stub

local function make()
   local instance = {}
   local root
   local platform
   local index
   local x
   local y

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function platform_ready(_, sender_instance)
      sender_instance.add_waypoint(index, x, y)
      destroy()
   end -- platform_ready

   function instance.init(self)
      platform = self.platform
      index = self.index
      root = msg.url(".")
      vector3_stub = go.get_position(root)
      x, y = fastmath.vector3_get_components(vector3_stub)
      fastmath.vector3_set_z(vector3_stub, DEPTH)
      go.set_position(vector3_stub, root)
      nc.add_observer(platform_ready, CONST.PLATFORM_READY_NOTIFICATION, platform)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.remove_observer(platform_ready, CONST.PLATFORM_READY_NOTIFICATION, platform)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
