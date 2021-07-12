local Pool = require("m.pool")
local RaycastController = require("m.raycast_controller")
local groups = require("m.groups")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")
-- local debug_draw = require("m.debug_draw")

local layers = require("pixelfrog.render.layers")
local game = require("pixelfrog.game.game")
local snd = require("sound.sound")

local DEPTH = layers.get_depth(layers.PROPS)

local runtime = runtime
local set_position = go.set_position
local abs = fastmath.abs
local sign = fastmath.sign
local vector3_stub = fastmath.vector3_stub
local vector3_set_xyz = fastmath.vector3_set_xyz

local MAX_VERTICAL_SPEED = 800

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_MOVABLE_OBJECTS,
      can_jump_down = false,
      can_climb_up = true,
      is_ground = true,
      dx = 0,
      dy = 0,
      needs_down_pass = false,
      needs_up_pass = false,
      needs_left_pass = false,
      needs_right_pass = false,
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
   local root
   local position_x
   local position_y
   local velocity_x
   local velocity_y
   local gravity
   local ground
   local max_horizontal_speed
   -- local use_aabb

   local raycast_controller = RaycastController.new(instance)

   local function destroy()
      go.delete(root, true)
   end -- destroy

   -- local function level_will_appear()
   -- end -- level_will_appear

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
      vector3_set_xyz(vector3_stub, position_x, position_y, 0)
      set_position(vector3_stub, root)
      instance.dx = dx
      instance.dy = dy
      return dx, dy
   end -- advance

   local function update_aabb()
      aabb[1] = position_x - 32
      aabb[2] = position_y - 32
      aabb[3] = position_x + 32
      aabb[4] = position_y + 48
      -- debug_draw.aabb(aabb)
   end -- update_aabb

   local function update(dt)
      local ground_instance = runtime.get_instance(ground)
      if ground_instance and ground_instance.on_step then
         ground_instance.on_step()
      end

      update_aabb()
      if not fastmath.aabb_overlap(game.view_aabb, aabb) then
         if ground_instance and ground_instance.aabb then
            if not fastmath.aabb_overlap(game.view_aabb, ground_instance.aabb) then
               return
            end
         else
            return
         end
      end

      advance(move(dt))
   end -- update

   function instance.push(dx)
      local dt = runtime.delta_time
      local push_limit = max_horizontal_speed * dt
      dx = fastmath.clamp(dx, -push_limit, push_limit)
      local _, dy = move(dt)
      instance.dx, instance.dy = advance(dx, dy, ground)
      return instance.dx
   end -- push

   function instance.on_hit()
      snd.play_sound(snd.FATE_WOOD_FLESH_1)
      nc.post_notification(const.CAMERA_SHAKE_REQUEST_NOTIFICATION, nil, 3, 0.15)
   end -- instance.on_hit

   function instance.init(self)
      gravity = self.gravity
      max_horizontal_speed = self.max_horizontal_speed
      -- use_aabb = self.use_aabb
      root = msg.url(".")
      vector3_set_xyz(vector3_stub, 0, 0, DEPTH)
      go.set_position(vector3_stub, "pivot")
      position_x, position_y = fastmath.vector3_get_xy(go.get_position())
      velocity_x = 0
      velocity_y = 0
      instance.dx = 0
      instance.dy = 0
      instance.can_push = true
      raycast_controller.set_width(self.width)
      raycast_controller.set_height(self.height)
      ground = nil
      runtime.set_instance(root.path, instance)
      runtime.add_update_callback(instance, update)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      update_aabb()
   end -- init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
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
