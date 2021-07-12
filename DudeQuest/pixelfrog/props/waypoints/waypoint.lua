local Pool = require("m.pool")
local nc = require("m.notification_center")
local CONST = require("m.constants")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")

local go = go
local fastmath = fastmath

local DEPTH = layers.get_depth(layers.DEBUG)

local vector3_stub

local function make()
   local instance = {}
   local root
   local entity
   local index
   local x
   local y

   local function on_ready(_, sender_instance)
      sender_instance.add_waypoint(index, x, y)
   end -- entity_ready

   local function destroy()
      go.delete(root, true)
   end -- destroy

   function instance.init(self)
      entity = self.entity
      index = self.index
      root = msg.url(".")
      vector3_stub = go.get_position(root)
      x, y = fastmath.vector3_get_components(vector3_stub)
      fastmath.vector3_set_z(vector3_stub, DEPTH)
      go.set_position(vector3_stub, root)
      nc.add_observer(on_ready, CONST.READY_NOTIFICATION, entity)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      nc.remove_observer(on_ready, CONST.READY_NOTIFICATION, entity)
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
