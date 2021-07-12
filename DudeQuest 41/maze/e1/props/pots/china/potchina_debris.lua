local Pool = require("m.pool")
local RaycastController = require("m.raycast_controller")
local layers = require("m.layers")
local groups = require("m.groups")
local nc = require("m.notification_center")
local CONST = require("m.constants")
-- local utils = require("m.utils")
local game = require("maze.game")

local DEPTH = layers.get_depth(layers.DEBRIS)

local hash = hash
local go = go
local runtime = runtime
local fastmath = fastmath
local vector3_set_xyz = fastmath.vector3_set_xyz
local set_position = go.set_position
local abs = fastmath.abs
local sign = fastmath.sign

local velocity_x_roll = fastmath.uniform_real(-120, 120)
local velocity_y_roll = fastmath.uniform_real(130, 260)

local params = {
   parent_id = nil,
}

local TINT_W = hash("tint.w")
local EULER_Z = hash("euler.z")
local MAX_VERTICAL_SPEED = 800
local NORMAL_GRAVITY = -500 -- ~player gravity
local ENTITY_WIDTH = 6
local ENTITY_HEIGHT = 6

-- local live_objects = {}

local function make()
   local instance = {
      x = 0,
      y = 0,
      needs_down_pass = false,
      needs_up_pass = false,
      needs_left_pass = false,
      needs_right_pass = false,
      update_group = runtime.UPDATE_GROUP_BEFORE_PLAYER,
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

   local root
   local debris
   local velocity_x
   local velocity_y
   -- local x
   -- local y
   local ground
   local vector3_stub = vmath.vector3()
   local gravity
   local rotation_direction
   local raycast_controller = RaycastController.new(instance)

   local function move(dt)
      local dx = velocity_x * dt
      local delta_velocity_y = gravity * dt
      local old_velocity_y = velocity_y
      velocity_y = velocity_y + delta_velocity_y
      if abs(velocity_y) > MAX_VERTICAL_SPEED then
         velocity_y = MAX_VERTICAL_SPEED * sign(velocity_y)
      end
      local dy = (old_velocity_y + velocity_y) * 0.5 * dt
      return dx, dy
   end -- move

   local function advance(dx, dy)
      dx, dy, velocity_x, velocity_y, ground = raycast_controller.update(instance.x, instance.y, dx, dy, velocity_x, velocity_y)
      instance.ground = ground
      instance.x = instance.x + dx
      instance.y = instance.y + dy
      vector3_set_xyz(vector3_stub, instance.x, instance.y, 0)
      set_position(vector3_stub, root)
   end -- advance

   local function update(dt)
      velocity_x = velocity_x * 0.99
      if ground then
         if velocity_y > 0 then
            rotation_direction = -rotation_direction
            go.animate(debris, EULER_Z, go.PLAYBACK_LOOP_FORWARD, 360 * rotation_direction, go.EASING_LINEAR, 1.2 - velocity_y/260)
         elseif velocity_y == 0 then
            go.cancel_animations(debris, EULER_Z)
            runtime.remove_update_callback(instance)
            local ground_instance = runtime.get_instance(ground)
            if ground_instance and (not ground_instance.is_static) then
               params.parent_id = ground
               msg.post(root, msg.SET_PARENT, params)
            end
         end
      end
      advance(move(dt))
   end -- update

   local function destroy()
      game.shadow_casters[root.path] = nil
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
      instance.shadow_edges = self.shadow_edges
      root = msg.url(".")
      debris = msg.url("debris")
      local debris_sprite = msg.url("debris#sprite")
      vector3_stub = go.get_position(debris)
      fastmath.vector3_set_z(vector3_stub, DEPTH)
      set_position(vector3_stub, debris)
      gravity = NORMAL_GRAVITY
      -- velocity_x = self.velocity_x
      -- velocity_y = self.velocity_y
      velocity_x = velocity_x_roll()
      velocity_y = velocity_y_roll()
      rotation_direction = (velocity_x > 0) and -1 or 1
      -- utils.log(1.2 - velocity_y/260, velocity_y)
      go.animate(debris, EULER_Z, go.PLAYBACK_LOOP_FORWARD, 360 * rotation_direction, go.EASING_LINEAR, 1.2 - velocity_y/260)
      go.animate(debris_sprite, TINT_W, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, 1, 4, destroy)
      instance.x, instance.y = fastmath.vector3_get_components(go.get_position(root))
      raycast_controller.set_width(ENTITY_WIDTH)
      raycast_controller.set_height(ENTITY_HEIGHT)
      runtime.set_instance(root.path, instance)
      runtime.add_update_callback(instance, update)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      -- live_objects[root.path] = true
      game.shadow_casters[root.path] = instance
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
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
   -- cleanup = cleanup,
   new = pool.new,
   free = pool.free,
}
