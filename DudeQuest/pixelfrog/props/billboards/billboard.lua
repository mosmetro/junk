local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local debug_draw = require("m.debug_draw")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
-- local game = require("pixelfrog.game.game")

local DEPTH = layers.get_depth(layers.PROPS_BACK)

local get_position = go.get_position
local set_position = go.set_position
-- local vector3_get_xy = fastmath.vector3_get_xy
local vector3_set_z = fastmath.vector3_set_z
-- local aabb_overlap = fastmath.aabb_overlap
-- local add_update_callback = runtime.add_update_callback
-- local remove_update_callback = runtime.remove_update_callback

-- local controls_scale = vmath.vector3(0.12, 0.12, 1)
-- local pic_scale = vmath.vector3(0.1509, 0.1509, 1)

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_LAST,
   }
   local root
   -- local aabb = { 0, 0, 0, 0 }
   -- local enabled

   local function destroy()
      go.delete(root, true)
   end -- destroy

   -- local function update()
   --    if aabb_overlap(game.view_aabb, aabb) and (not enabled) then
   --
   --    else
   --    end
   --    debug_draw.aabb(aabb)
   -- end -- update

   function instance.init()
      root = msg.url(".")
      local pos = get_position(root)
      vector3_set_z(pos, DEPTH)
      set_position(pos, root)
      -- add_update_callback(instance, update)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      -- local x, y = vector3_get_xy(pos)
      -- aabb[1] = x - 65 - 16
      -- aabb[2] = y - 16
      -- aabb[3] = x + 65 + 16
      -- aabb[4] = y + 88 + 16
   end -- instance.init

   function instance.deinit()
      -- remove_update_callback(instance)
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
