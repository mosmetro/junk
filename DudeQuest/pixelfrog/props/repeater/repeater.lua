local Pool = require("m.pool")
local const = require("m.constants")
local nc = require("m.notification_center")
-- local utils = require("m.utils")

-- local gamestate = require("pixelfrog.game.gamestate")
local game = require("pixelfrog.game.game")

local vector4_set_y = fastmath.vector4_set_y
local set_constant = sprite.set_constant
local offset = vmath.vector4()
local OFFSET = hash("offset")

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_LAST,
   }

   local root
   local repeating_sprite
   local offset_y

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function update(dt)
      vector4_set_y(offset, offset_y)
      set_constant(repeating_sprite, OFFSET, offset)
      offset_y = (offset_y > 1) and 0 or (offset_y + dt * 0.1)
   end -- update

   function instance.init()
      root = msg.url(".")
      repeating_sprite = msg.url("#sprite")
      local scale_x = game.view_width / 64
      local scale_y = game.view_height / 64
      fastmath.vector3_set_xyz(fastmath.vector3_stub, scale_x, scale_y, 1)
      go.set_scale(fastmath.vector3_stub, root)
      fastmath.vector4_set_xyzw(fastmath.vector4_stub, scale_x, scale_y, 1, 1)
      set_constant(repeating_sprite, "scale", fastmath.vector4_stub)
      offset_y = 0
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
