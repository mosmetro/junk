
local Pool = require("m.pool")
local layers = require("m.layers")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")
-- local debug_draw = require("m.debug_draw")
-- local colors = require("m.colors")
local game = require("maze.game")
local global = require("game.global")

local DEPTH = layers.get_depth(layers.STATIC_GEOMETRY)

-- local hash = hash

local aabb_overlap = fastmath.aabb_overlap
local vector3_stub = vmath.vector3()


local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_MOTOR_PLATFORMS,
      x = 0,
      y = 0,
      aabb = { 0, 0, 0, 0 },
      can_jump_down = true,
      can_climb_up = true,
      is_static = true,
   }
   local root
   local id
   local anchor
   local enabled
   local aabb_min_x
   local aabb_min_y
   local aabb_max_x
   local aabb_max_y

   local function destroy()
      game.shadow_casters[id] = nil
      go.delete(root, true)
   end -- destroy


   local function update_aabb(box, x, y)
      box[1] = x + aabb_min_x
      box[2] = y + aabb_min_y
      box[3] = x + aabb_max_x
      box[4] = y + aabb_max_y
      -- debug_draw.aabb(box, colors.BLUE)
   end -- update_aabb

   local function update()
      update_aabb(instance.aabb, instance.x, instance.y)
      if aabb_overlap(global.view_aabb, instance.aabb) then
         if not enabled then
            enabled = true
            msg.post(anchor, msg.ENABLE)
            game.shadow_casters[id] = instance
         end
      elseif enabled then
         enabled = false
         msg.post(anchor, msg.DISABLE)
         game.shadow_casters[id] = nil
      end
   end -- update

   function instance.init(self)
      instance.shadow_edges = self.shadow_edges
      instance.can_jump_down = self.can_jump_down
      instance.can_climb_up = self.can_climb_up
      aabb_min_x, aabb_min_y, aabb_max_x, aabb_max_y = fastmath.vector4_get_components(self.aabb)
      root = msg.url("root")
      id = root.path
      anchor = msg.url("anchor")
      instance.x, instance.y = fastmath.vector3_get_xy(go.get_position(root))
      fastmath.vector3_set_xyz(vector3_stub, 0, 0, DEPTH)
      go.set_position(vector3_stub, "pivot")
      runtime.set_instance(id, instance)
      runtime.add_update_callback(instance, update)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      msg.post(anchor, msg.DISABLE)
      enabled = false
   end -- instance.init

   function instance.deinit()
      runtime.set_instance(id, nil)
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
