local Pool = require("m.pool")
local RaycastController = require("m.raycast_controller")
local groups = require("m.groups")
local nc = require("m.notification_center")
local const = require("m.constants")
local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local snd = require("sound.sound")
local factories = require("pixelfrog.game.factories")

local DEPTH =  layers.get_depth(layers.PROJECTILES)

local runtime = runtime
local fastmath = fastmath
local vector3_set_xyz = fastmath.vector3_set_xyz
local clamp = fastmath.clamp
local set_position = go.set_position
local get_position = go.get_position
local delete = go.delete

local MAX_VERTICAL_SPEED = 600

local function make()
   local instance = {
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
   local pivot
   local velocity_x
   local velocity_y
   local x
   local y
   local ground
   local vector3_stub = fastmath.vector3_stub
   local gravity
   local damage_points
   local is_destroyed
   local raycast_controller = RaycastController.new(instance)

   local function destroy()
      is_destroyed = true
      -- utils.log("destroy", runtime.current_frame)
      delete(root, true)
   end -- destroy

   local function move(dt)
      local dx = velocity_x * dt
      local old_velocity_y = velocity_y
      velocity_y = clamp(velocity_y + gravity * dt, -MAX_VERTICAL_SPEED, MAX_VERTICAL_SPEED)
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
      -- factory.create("game:/game#dot", vmath.vector3(x, y, 1))
      advance(move(dt))
   end -- update

   local function breakdown()
      vector3_set_xyz(vector3_stub, x, y, 0)
      collectionfactory.create(factories.AMMO_BOX_DESTROYED, vector3_stub, const.QUAT_IDENTITY, nil, 1)
      -- factory.create(factories.EFFECT_CIRCLE_PUFF, vector3_stub, const.QUAT_IDENTITY, nil, 1)
      snd.play_sound(snd.BARREL_BREAK)
      destroy()
   end -- breakdown

   function instance.on_contact()
      if not is_destroyed then breakdown() end
      return 0
   end -- instance.on_contact

   function instance.on_ground_contact()
      if not is_destroyed then breakdown() end
      return 0
   end -- instance.on_ground_contact

   function instance.on_slope_contact()
      if not is_destroyed then breakdown() end
      return 0
   end -- instance.on_slope_contact

   function instance.on_collision(other_instance)
      -- utils.log("on_collision", runtime.current_frame)
      if other_instance.on_hit then
         breakdown()
         other_instance.on_hit(nil, damage_points)
      end
   end -- instance.on_collision

   function instance.init(self)
      damage_points = self.damage_points
      velocity_x = self.velocity_x
      velocity_y = self.velocity_y
      gravity = self.gravity
      root = msg.url(".")
      pivot = msg.url("pivot")
      local pos = get_position(pivot)
      fastmath.vector3_set_z(pos, DEPTH)
      set_position(pos, pivot)
      go.set_rotation(self.direction > 0 and const.QUAT_Y_0 or const.QUAT_Y_180, pivot)
      ground = nil
      is_destroyed = false
      x, y = fastmath.vector3_get_components(get_position(root))
      raycast_controller.set_width(22)
      raycast_controller.set_height(16)
      runtime.set_instance(root.path, instance)
      runtime.add_update_callback(instance, update)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end

local pool = Pool.new(make)

return {
   -- cleanup = cleanup,
   new = pool.new,
   free = pool.free,
}
