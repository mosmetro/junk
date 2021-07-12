local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")

local DEPTH = layers.get_depth(layers.DEBRIS)

local set_instance = runtime.set_instance
local vector3_stub = fastmath.vector3_stub

local function make()
   local instance = {
      can_jump_down = true,
      can_climb_up = false,
      is_static = true,
      is_ground = true,
   }
   local root

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function destruct()
      go.delete(root, true)
   end

   function instance.init()
      root = msg.url(".")
      set_instance(root.path, instance)
      fastmath.vector3_set_xyz(vector3_stub, 0, 0, DEPTH)
      go.set_position(vector3_stub, "pivot")
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      timer.delay(6, false, destruct)
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
}
