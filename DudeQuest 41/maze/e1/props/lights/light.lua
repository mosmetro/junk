local Pool = require("m.pool")
-- local layers = require("m.layers")
local nc = require("m.notification_center")
local CONST = require("m.constants")
-- local utils = require("m.utils")
-- local debug_draw = require("m.debug_draw")
-- local COLOR = require("m.colors")
-- local game = require("maze.game")

local hash = hash

-- local POSITION_X = hash("position.x")
-- local TINT_W = hash("tint.w")
local SCALE = hash("scale")

-- local next_scale = fastmath.normal(1, 0.1) -- best but slower
local next_scale = fastmath.uniform_real(0.8, 1.1)


local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_LAST,
   }
   local root
   local scale_blend = 0.1
   local scale = 1
   -- local glow

   local function destroy()
      runtime.remove_update_callback(instance)
      go.delete(root)
   end -- destroy

   local function update()
      scale = scale + (next_scale() - scale) * scale_blend
      go.set(root, SCALE, scale)
   end -- update

   function instance.init()
      root = msg.url(".")
      runtime.add_update_callback(instance, update)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
