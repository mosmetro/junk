local Pool = require("m.pool")
local const = require("m.constants")
local nc = require("m.notification_center")
-- local utils = require("m.utils")

-- local gamestate = require("pixelfrog.game.gamestate")
local game = require("pixelfrog.game.game")
local layers = require("pixelfrog.render.layers")

local vector3_set_xyz = fastmath.vector3_set_xyz
-- local vector3_set_z = fastmath.vector3_set_z
local vector3_stub = fastmath.vector3_stub
local set_position = go.set_position


local PARALLAX_1 = layers.get_depth(layers.PARALLAX_1)
-- local PARALLAX_2 = layers.get_depth(layers.PARALLAX_2)
local PARALLAX_3 = layers.get_depth(layers.PARALLAX_3)
-- local PARALLAX_4 = layers.get_depth(layers.PARALLAX_4)
local PARALLAX_5 = layers.get_depth(layers.PARALLAX_5)
-- local PARALLAX_6 = layers.get_depth(layers.PARALLAX_6)
local PARALLAX_7 = layers.get_depth(layers.PARALLAX_7)
-- local PARALLAX_8 = layers.get_depth(layers.PARALLAX_8)
local PARALLAX_9 = layers.get_depth(layers.PARALLAX_9)


local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_LAST,
   }

   local root
   local windows
   local bridge
   local arch
   local shadow
   local fog

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function update()
      local x = game.view_x
      local y = game.view_y
      local top = game.view_top

      vector3_set_xyz(vector3_stub, x * 0.9, y, PARALLAX_9)
      set_position(vector3_stub, windows)

      vector3_set_xyz(vector3_stub, x * 0.8, y * 0.98, PARALLAX_7)
      set_position(vector3_stub, bridge)

      vector3_set_xyz(vector3_stub, x * 0.75, y + top + 4, PARALLAX_5)
      set_position(vector3_stub, arch)

      vector3_set_xyz(vector3_stub, x, y - top - 10, PARALLAX_3)
      set_position(vector3_stub, shadow)

      vector3_set_xyz(vector3_stub, x, y + top + 40, PARALLAX_1)
      set_position(vector3_stub, fog)

   end -- update

   function instance.init()
      root = msg.url(".")
      windows = msg.url("windows")
      bridge = msg.url("bridge")
      arch = msg.url("arch")
      shadow = msg.url("shadow")
      fog = msg.url("fog")
      vector3_set_xyz(vector3_stub, 0, 0, 0)
      set_position(vector3_stub, root)
      runtime.set_instance(root.path, instance)
      runtime.add_update_callback(instance, update)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      runtime.set_instance(root.path, nil)
      runtime.remove_update_callback(instance)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
