local Pool = require("m.pool")
-- local layers = require("m.layers")
local nc = require("m.notification_center")
local CONST = require("m.constants")
-- local utils = require("m.utils")
-- local debug_draw = require("m.debug_draw")
-- local COLOR = require("m.colors")
local game = require("maze.game")
-- local m2d = require("m.m2d")

local global = require("game.global")

local hash = hash
local safe_normalize = fastmath.safe_normalize

-- local POSITION_X = hash("position.x")
-- local TINT_W = hash("tint.w")
local SCALE = hash("scale")

local starting_angle_roll = fastmath.uniform_real(0, math.pi * 2)
-- local wander_radius_roll = fastmath.uniform_real(8, 16)
local minus_one_one_roll = fastmath.uniform_real(-1, 1)
-- local wander_distance_roll = fastmath.uniform_real(10, 30)
-- local delay_roll = fastmath.uniform_real(0.25, 0.75)
local life_time_roll = fastmath.uniform_real(2, 8)
local max_speed_roll = fastmath.uniform_real(6, 20)
local mass_roll = fastmath.uniform_real(0.25, 2)

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_LAST,
   }
   local vector3_stub
   local root
   local x
   local y
   local velocity_x
   local velocity_y
   local mass
   local reciprocal_mass
   local max_speed
   local aabb = { 0, 0, 0, 0 }

   local wander_target_x
   local wander_target_y
   local wander_radius
   local wander_distance
   local wander_jitter -- per second

   -- local transform = m2d.new()

   local function destroy()
      go.delete(root)
      game.dust_count = game.dust_count - 1
   end -- destroy

   local function update_aabb()
      aabb[1] = x - 16
      aabb[2] = y - 16
      aabb[3] = x + 16
      aabb[4] = y + 16
      -- debug_draw.aabb(aabb)
   end -- update_aabb

   local function update(dt)
      update_aabb()
      if not fastmath.aabb_overlap(global.view_aabb, aabb) then
         destroy()
         return
      end
      local jitter = wander_jitter * dt
      wander_target_x = wander_target_x + minus_one_one_roll() * jitter
      wander_target_y = wander_target_y + minus_one_one_roll() * jitter
      -- wander_radius = wander_radius_roll()
      -- wander_distance = wander_distance_roll()
      wander_target_x, wander_target_y = safe_normalize(wander_target_x, wander_target_y)
      wander_target_x = wander_target_x * wander_radius
      wander_target_y = wander_target_y * wander_radius
      local target_x = wander_target_x + wander_distance
      local target_y = wander_target_y
      -- project the target into world space
      local heading_x, heading_y = safe_normalize(velocity_x, velocity_y)
      -- utils.log(heading_x, heading_y)
      -- transform.set_rotation(heading_x, heading_y)
      -- transform.set_translation(x, y)
      -- transform.translate(x, y)
      -- target_x, target_y = transform.transform_point(target_x, target_y)


      -- target_x = heading_x * target_x - heading_y * target_y + x
      -- target_y = heading_y * target_x + heading_x * target_y + y -- wrong! target_x already modified
      -- must be in one line!
      target_x, target_y = heading_x * target_x - heading_y * target_y + x, heading_y * target_x + heading_x * target_y + y


      -- transform.set_rotation(heading_x, heading_y)
      -- transform.set_translation(x, y)
      -- local xx, yy = transform.transform_point(wander_distance, 0)
      -- debug_draw.circle(xx, yy, wander_radius, 16)
      -- debug_draw.circle(target_x, target_y, 2, 8, COLOR.RED)
      -- debug_draw.line(x, y, target_x, target_y)
      --
      -- debug_draw.circle(target_x, target_y, wander_radius, 16)
      -- debug_draw.circle(x + heading_x * wander_distance, y + heading_y * wander_distance, wander_radius, 16)

      local steering_x = target_x - x
      local steering_y = target_y - y
      local acceleration_x = steering_x * reciprocal_mass
      local acceleration_y = steering_y * reciprocal_mass
      local old_velocity_x = velocity_x
      local old_velocity_y = velocity_y
      velocity_x = velocity_x + acceleration_x * dt
      velocity_y = velocity_y + acceleration_y * dt
      velocity_x, velocity_y = fastmath.truncate(velocity_x, velocity_y, max_speed)
      local dx = (old_velocity_x + velocity_x) * 0.5 * dt
      local dy = (old_velocity_y + velocity_y) * 0.5 * dt
      x = x + dx
      y = y + dy
      fastmath.vector3_set_xy(vector3_stub, x, y)
      go.set_position(vector3_stub, root)

      -- go.set(root, "euler.z", math.deg(math.atan2(heading_y, heading_x)))
      -- utils.log(fastmath.length(velocity_x, velocity_y))
   end -- update

   function instance.init()
      root = msg.url(".")
      go.set(root, SCALE, 0)
      go.animate(root, SCALE, go.PLAYBACK_ONCE_PINGPONG, 0.4, go.EASING_INOUTSINE, life_time_roll(), 0, destroy)
      vector3_stub = go.get_position()
      x, y = fastmath.vector3_get_components(vector3_stub)
      -- velocity_x = 0
      -- velocity_y = 0
      local angle = starting_angle_roll()
      -- utils.log(math.deg(angle), fastmath.cosnsin(angle))
      local cs, sn = fastmath.cosnsin(angle)
      -- randomize initial direction a little
      velocity_x = cs
      velocity_y = -sn
      max_speed = max_speed_roll()
      wander_radius = 6 --wander_radius_roll()
      -- target position on the wander circle
      wander_target_x = wander_radius * cs
      wander_target_y = wander_radius * sn
      -- utils.log(wander_target_x, wander_target_y)
      wander_distance = 20
      wander_jitter = 125 -- per second
      mass = mass_roll()
      reciprocal_mass = 1 / mass
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
