local Pool = require("m.pool")
local RaycastController = require("m.raycast_controller")
local groups = require("m.groups")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")

local DEPTH = layers.get_depth(layers.DEBRIS)

local go = go
local runtime = runtime
local fastmath = fastmath
local vector3_set_xyz = fastmath.vector3_set_xyz
local set_position = go.set_position
local clamp = fastmath.clamp
local vector3_stub = fastmath.vector3_stub

local velocity_x_roll = fastmath.uniform_real(-120, 120)
local velocity_y_roll = fastmath.uniform_real(130, 260)

-- local params = {
--    parent_id = nil,
-- }

local TINT_W = const.TINT_W
local EULER_Z = const.EULER_Z
local MAX_FALL_SPEED = -400
local MAX_RISE_SPEED = 600
local NORMAL_GRAVITY = -500
local ENTITY_WIDTH = 4
local ENTITY_HEIGHT = 4

-- local live_objects = {}

local function make()
   local instance = {
      needs_down_pass = false,
      needs_up_pass = false,
      needs_left_pass = false,
      needs_right_pass = false,
      update_group = runtime.UPDATE_GROUP_BEFORE_PLAYER,
      vertical_drag = 0,
      GROUND = {
         groups.SOLID,
         groups.ONEWAY,
         groups.SLOPE,
         groups.BOX,
         groups.PROPS_HITBOX,
      },
      SOLIDS = {
         groups.SLOPE,
         groups.SOLID,
         groups.BOX,
         groups.PROPS_HITBOX,
      },
      CEILING = {
         groups.SOLID,
         groups.BOX,
         groups.PROPS_HITBOX,
      },
      SLOPES = {
         groups.SLOPE,
      },
      SLOPE = groups.SLOPE,
   }

   local root
   local anchor
   local velocity_x
   local velocity_y
   local x
   local y
   local ground
   local gravity
   local rotation_direction
   local raycast_controller = RaycastController.new(instance)

   local function move(dt)
      local dx = velocity_x * dt-- + instance.horizontal_drag
      local delta_velocity_y = gravity * dt
      local old_velocity_y = velocity_y
      velocity_y = velocity_y + delta_velocity_y + instance.vertical_drag
      velocity_y = clamp(velocity_y, MAX_FALL_SPEED, MAX_RISE_SPEED)
      local dy = (old_velocity_y + velocity_y) * 0.5 * dt
      return dx, dy
   end -- move

   local function advance(dx, dy)
      dx, dy, velocity_x, velocity_y, ground = raycast_controller.update(x, y, dx, dy, velocity_x, velocity_y)
      instance.ground = ground
      x = x + dx
      y = y + dy
      vector3_set_xyz(vector3_stub, x, y, 0)
      set_position(vector3_stub, root)
   end -- advance

   local function update(dt)
      velocity_x = velocity_x * 0.99
      if ground then
         if velocity_y > 0 then
            rotation_direction = -rotation_direction
            go.animate(anchor, EULER_Z, go.PLAYBACK_LOOP_FORWARD, 360 * rotation_direction, go.EASING_LINEAR, 1.2 - velocity_y/260)
         elseif velocity_y == 0 then
            go.cancel_animations(anchor, EULER_Z)
            runtime.remove_update_callback(instance)
            local ground_instance = runtime.get_instance(ground)
            -- can boxes be moved?
            if ground_instance and (not ground_instance.is_static) then
               -- utils.log("setting parent: ", ground)
               -- params.parent_id = ground
               -- msg.post(root, msg.SET_PARENT, params)
               go.set_parent(root, ground)
            end
         end
      end
      advance(move(dt))
      -- instance.horizontal_drag = 0
      instance.vertical_drag = 0
   end -- update

   local function destroy()
      go.delete(root, true)
   end -- destroy

   function instance.on_ground_contact(vy)
      if vy < -60 then
         return -vy * 0.5
      end
      return 0
   end -- instance.on_ground_contact

   function instance.on_slope_contact(vy)
      if vy < -60 then
         return -vy * 0.5
      end
      return 0
   end -- instance.on_slope_contact

   function instance.on_contact(_, _, vx)
      return -vx * 0.8
   end -- instance.on_contact

   function instance.init(self)
      root = msg.url(".")
      anchor = msg.url("anchor")
      local anchor_sprite = msg.url("anchor#sprite")
      local position = go.get_position(anchor)
      fastmath.vector3_set_z(position, DEPTH)
      set_position(position, anchor)
      gravity = NORMAL_GRAVITY
      -- instance.horizontal_drag = 0
      instance.vertical_drag = 0
      -- velocity_x = self.velocity_x
      -- velocity_y = self.velocity_y
      velocity_x = velocity_x_roll()
      velocity_y = velocity_y_roll()
      rotation_direction = (velocity_x > 0) and -1 or 1
      -- utils.log(1.2 - velocity_y/260, velocity_y)
      --go.animate(url, property, playback, to, easing, duration, delay, complete_function)
      go.animate(anchor, EULER_Z, go.PLAYBACK_LOOP_FORWARD, 360 * rotation_direction, go.EASING_LINEAR, 1.2 - velocity_y/260)
      go.animate(anchor_sprite, TINT_W, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, 1, self.lifetime, destroy)
      x, y = fastmath.vector3_get_components(go.get_position(root))
      raycast_controller.set_width(ENTITY_WIDTH)
      raycast_controller.set_height(ENTITY_HEIGHT)
      runtime.set_instance(root.path, instance)
      runtime.add_update_callback(instance, update)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      -- live_objects[root.path] = true
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      -- live_objects[root.path] = nil
   end -- instance.deinit

   return instance
end

-- local function cleanup()
--    for k, _ in next, live_objects do
--       go.delete(k, true)
--    end
-- end

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
