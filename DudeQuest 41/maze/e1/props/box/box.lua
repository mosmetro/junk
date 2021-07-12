-- import
local Pool = require("m.pool")
local RaycastController = require("m.raycast_controller")
local groups = require("m.groups")
local utils = require("m.utils")
local nc = require("m.notification_center")
local CONST = require("m.constants")
local game = require("maze.game")
-- local debug_draw = require("m.debug_draw")

local global = require("game.global")

-- localization
local runtime = runtime
local vector3_set_components = fastmath.vector3_set_components
local set_position = go.set_position
local abs = fastmath.abs
local sign = fastmath.sign

local MAX_VERTICAL_SPEED = 800

local function make()
   local instance = {
      dx = 0,
      dy = 0,
      needs_down_pass = false,
      needs_up_pass = false,
      needs_left_pass = false,
      needs_right_pass = false,
      update_group = runtime.UPDATE_GROUP_MOVABLE_OBJECTS,
      can_push = true,
      is_box = true,
      GROUND = {
         groups.SOLID,
         groups.ONEWAY,
         groups.SLOPE,
         groups.BOX,
      },
      SOLIDS = {
         groups.SLOPE,
         groups.SOLID,
         groups.BOX,
         groups.ENTITY,
      },
      CEILING = {
         groups.SOLID,
         groups.BOX,
      },
      SLOPES = {
         groups.SLOPE,
      },
      SLOPE = groups.SLOPE,
   }
   local aabb = { 0, 0, 0, 0 }
   local name
   local root
   local vector3_stub
   local position_x
   local position_y
   local velocity_x
   local velocity_y
   local gravity
   local ground
   local max_horizontal_speed
   -- local last_push_target

   local raycast_controller = RaycastController.new(instance)

   local post_init
   function post_init()
      nc.remove_observer(post_init, CONST.POST_INIT_NOTIFICATION)
      nc.post_notification(CONST.PLATFORM_READY_NOTIFICATION, name, instance, root) -- for something parented with box
   end -- post_init

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function move(dt)
      local delta_velocity_y = gravity * dt
      local old_velocity_y = velocity_y
      velocity_y = velocity_y + delta_velocity_y
      if abs(velocity_y) > MAX_VERTICAL_SPEED then
         velocity_y = MAX_VERTICAL_SPEED * sign(velocity_y)
      end
      local dy = (old_velocity_y + velocity_y) * 0.5 * dt
      return 0, dy
   end -- move

   local function advance(dx, dy, my_ground)
      dx, dy, velocity_x, velocity_y, ground = raycast_controller.update(position_x, position_y, dx, dy, velocity_x, velocity_y, my_ground)
      position_x = position_x + dx
      position_y = position_y + dy
      vector3_set_components(vector3_stub, position_x, position_y, 0)
      set_position(vector3_stub, root)
      instance.dx = dx
      instance.dy = dy
      return dx, dy
   end -- advance

   local function update_aabb()
      aabb[1] = position_x - 32
      aabb[2] = position_y - 32
      aabb[3] = position_x + 32
      aabb[4] = position_y + 32
      -- debug_draw.aabb(aabb)
   end -- update_aabb

   local function update(dt)
      if not fastmath.aabb_overlap(global.view_aabb, aabb) then
         local inst = runtime.get_instance(ground)
         if inst and inst.aabb then
            if not fastmath.aabb_overlap(global.view_aabb, inst.aabb) then
               return
            end
         else
            return
         end
      end
      advance(move(dt))
      update_aabb()
   end -- update

   function instance.push(dx)
      local dt = runtime.delta_time
      local push_limit = max_horizontal_speed * dt
      dx = fastmath.clamp(dx, -push_limit, push_limit)
      local _, dy = move(dt)
      instance.dx, instance.dy = advance(dx, dy, ground)
      return instance.dx
   end -- push

   function instance.on_hit(amount)
      utils.log("received " .. tostring(amount) .. " damage points")
      destroy()
   end

   function instance.init(self)
      name = self.name
      gravity = self.gravity
      max_horizontal_speed = self.max_horizontal_speed
      root = msg.url(".")
      vector3_stub = go.get_position()
      position_x, position_y = fastmath.vector3_get_components(vector3_stub)
      velocity_x = 0
      velocity_y = 0
      instance.dx = 0
      instance.dy = 0
      instance.can_push = true
      raycast_controller.set_width(self.width)
      raycast_controller.set_height(self.height)
      ground = nil
      update_aabb()
      runtime.set_instance(root.path, instance)
      runtime.add_update_callback(instance, update)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.add_observer(post_init, CONST.POST_INIT_NOTIFICATION)
   end -- init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- deinit

   return instance
end -- make

local pool = Pool.new(make)

-- export
return {
   new = pool.new,
   free = pool.free,
   fill = pool.fill,
   purge = pool.purge,
}
