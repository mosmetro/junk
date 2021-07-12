local Pool = require("m.pool")
local nc = require("m.notification_center")
local CONST = require("m.constants")
local groups = require("m.groups")
-- local colors = require("m.colors")
-- local game = require("pixelfrog.game.game")
-- local debug_draw = require("m.debug_draw")
-- local utils = require("m.utils")

local snd = require("sound.sound")

local runtime = runtime
local vector3_set_xy = fastmath.vector3_set_xy
local vector3_set_xyz = fastmath.vector3_set_xyz
local set_position = go.set_position
local vmath = vmath
local get_instance = runtime.get_instance
local set_instance = runtime.set_instance
local clamp01 = fastmath.clamp01
local lerp_unclamped = fastmath.lerp_unclamped
local abs = fastmath.abs
local sign = fastmath.sign
local is_equal = fastmath.is_equal
local add_update_callback = runtime.add_update_callback
local remove_update_callback = runtime.remove_update_callback
local raycast = physics.raycast
local ceil = math.ceil
local sqrt = math.sqrt

local SKIN_WIDTH = 0.001
local MIN_OBSTACLE_WIDTH = 12
local MIN_OBSTACLE_HEIGHT = 12
local TARGETS = {
   groups.ENTITY,
   groups.BOX,
}

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_MOTOR_PLATFORMS,
      dx = 0,
      dy = 0,
      can_jump_down = true,
      -- can_climb_up = true,
      is_ground = true,
      aabb = { 0, 0, 0, 0 },
   }
   local root
   local vector3_stub = vmath.vector3()
   local position_x
   local position_y
   local name
   local raycast_width
   local raycast_height
   local half_raycast_width
   local waypoint_x = {}
   local waypoint_y = {}
   local from_waypoint
   local next_move_time
   local interpolator
   local easing_factor
   local speed
   local wait_time
   local is_solid
   local is_active
   local vertical_rays_count
   local vertical_rays_spacing
   local horizontal_rays_count
   local horizontal_rays_spacing
   local ray_start = vmath.vector3()
   local ray_end = vmath.vector3()
   local debug_label

   -- local function update_aabb()
   --    local aabb = instance.aabb
   --    aabb[1] = position_x - 170 -- should be customizable
   --    aabb[2] = position_y - 32
   --    aabb[3] = position_x + 170
   --    aabb[4] = position_y + 32
   --    debug_draw.aabb(aabb)
   -- end -- update_aabb

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local post_init
   function post_init()
      nc.remove_observer(post_init, CONST.POST_INIT_NOTIFICATION)
      nc.post_notification(CONST.READY_NOTIFICATION, name, instance, root)
   end -- post_init

   local level_will_appear
   local update
   function level_will_appear()
      nc.remove_observer(level_will_appear, CONST.LEVEL_WILL_APPEAR_NOTIFICATION)
      position_x = waypoint_x[from_waypoint]
      position_y = waypoint_y[from_waypoint]
      vector3_set_xyz(vector3_stub, position_x, position_y, 0)
      set_position(vector3_stub, root)
      -- update_aabb()
      if is_active then
         add_update_callback(instance, update)
      end
      set_instance(root.path, instance)
   end -- level_will_appear

   local function calculate_delta_position(dt)
      local time = runtime.current_time
      if time < next_move_time then
         return 0, 0
      end
      from_waypoint = ((from_waypoint - 1) % #waypoint_x) + 1
      local to_waypoint = (from_waypoint % #waypoint_x) + 1
      local lx = waypoint_x[from_waypoint] - waypoint_x[to_waypoint]
      local ly = waypoint_y[from_waypoint] - waypoint_y[to_waypoint]
      local distance = sqrt(lx * lx + ly * ly)
      interpolator = clamp01(interpolator + dt * speed / distance)
      local new_x
      local new_y
      if easing_factor > 1 then
         local e_interpolator = fastmath.ease(interpolator, easing_factor)
         new_x = fastmath.lerp(waypoint_x[from_waypoint], waypoint_x[to_waypoint], e_interpolator)
         new_y = fastmath.lerp(waypoint_y[from_waypoint], waypoint_y[to_waypoint], e_interpolator)
      else
         new_x = lerp_unclamped(waypoint_x[from_waypoint], waypoint_x[to_waypoint], interpolator)
         new_y = lerp_unclamped(waypoint_y[from_waypoint], waypoint_y[to_waypoint], interpolator)
      end
      if interpolator == 1 then
         interpolator = 0
         from_waypoint = from_waypoint + 1
         next_move_time = time + wait_time
      end
      local dx = new_x - position_x
      local dy = new_y - position_y
      if abs(dx) < 0.01 then
         dx = 0.01 * sign(dx)
      end
      if abs(dy) < 0.01 then
         dy = 0.01 * sign(dy)
      end
      return dx, dy
   end -- calculate_delta_position

   local function cast_rays(dx, dy)
      if is_solid and not is_equal(dx, 0) then
         local direction = sign(dx)
         local start_x = position_x + direction * (half_raycast_width - SKIN_WIDTH)
         local end_x = start_x + direction * 30--(abs(dx) + SKIN_WIDTH)
         local y = position_y - SKIN_WIDTH + dy
         for _ = 1, horizontal_rays_count do
            vector3_set_xy(ray_start, start_x, y)
            vector3_set_xy(ray_end, end_x, y)
            -- msg.post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = colors.MAGENTA })
            local hit = raycast(ray_start, ray_end, TARGETS)
            if hit then
               local other_instance = get_instance(hit.id)
               if other_instance then
                  if direction > 0 then
                     other_instance.needs_left_pass = true
                  else
                     other_instance.needs_right_pass = true
                  end
               end
            end
            y = y - horizontal_rays_spacing
         end
      end
      if not is_equal(dy, 0) then
         local direction = sign(dy)
         if (direction < 0) and (not is_solid) then
            return
         end
         local x = position_x - (half_raycast_width - SKIN_WIDTH) + dx
         local start_y = (direction > 0) and (position_y - SKIN_WIDTH) or (position_y - raycast_height + SKIN_WIDTH)
         local end_y = start_y + direction * (abs(dy) + SKIN_WIDTH)
         for _ = 1, vertical_rays_count do
            vector3_set_xy(ray_start, x, start_y)
            vector3_set_xy(ray_end, x, end_y)
            -- msg.post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = colors.MAGENTA })
            local hit = raycast(ray_start, ray_end, TARGETS)
            if hit then
               local other_instance = get_instance(hit.id)
               if other_instance then
                  if direction > 0 then
                     other_instance.needs_down_pass = true--current_frame
                  else
                     other_instance.needs_up_pass = true--current_frame
                  end
               end
            end
            x = x + vertical_rays_spacing
         end
      end
   end -- cast_rays

   function update(dt)
      -- if not fastmath.aabb_overlap(game.view_aabb, instance.aabb) then return end

      local dx, dy = calculate_delta_position(dt)
      cast_rays(dx, dy)
      position_x = position_x + dx
      position_y = position_y + dy
      instance.dx = dx
      instance.dy = dy
      vector3_set_xyz(vector3_stub, position_x, position_y, 0)
      set_position(vector3_stub, root)
      -- update_aabb()
      -- debug_draw.aabb(instance.aabb)
   end -- update

   function instance.collect_damage()
      return nil
   end

   function instance.add_waypoint(index, x, y)
      waypoint_x[index] = x
      waypoint_y[index] = y
   end -- instance.add_waypoint

   function instance.on_collision_response(message)
      -- utils.log("on_collision")
      local other_instance = get_instance(message.other_id)
      if other_instance and other_instance.on_hit then
         other_instance.on_hit(snd.FATE_SLICE_FLESH_2, 100)
      end
   end -- instance.on_collision_response

   function instance.init(self)
      debug_label = msg.url("#debug_label")
      -- msg.post(debug_label, msg.DISABLE)
      name = self.name
      raycast_width = self.width
      raycast_height = self.height
      from_waypoint = self.start_waypoint
      speed = self.speed
      wait_time = self.wait_time
      is_solid = self.is_solid
      is_active = self.is_active
      easing_factor = fastmath.clamp(self.easing_factor, 1, 3)
      half_raycast_width = raycast_width * 0.5
      vertical_rays_count = ceil(raycast_width / MIN_OBSTACLE_WIDTH) + 1
      vertical_rays_spacing = (raycast_width - 2 * SKIN_WIDTH) / (vertical_rays_count - 1)
      horizontal_rays_count = ceil(raycast_height / MIN_OBSTACLE_HEIGHT) + 1
      horizontal_rays_spacing = (raycast_height - 2 * SKIN_WIDTH) / (horizontal_rays_count - 1)
      root = msg.url(".")
      next_move_time = runtime.current_time + wait_time
      interpolator = 0
      instance.dx = 0
      instance.dy = 0
      if is_solid then
         msg.post("#collisionobject_solid", msg.ENABLE)
         msg.post("#collisionobject_oneway", msg.DISABLE)
         instance.can_jump_down = false
      else
         msg.post("#collisionobject_solid", msg.DISABLE)
         msg.post("#collisionobject_oneway", msg.ENABLE)
         instance.can_jump_down = true
      end
      instance.aabb[1] = self.aabb_min_x
      instance.aabb[2] = self.aabb_min_y
      instance.aabb[3] = self.aabb_max_x
      instance.aabb[4] = self.aabb_max_y

      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.add_observer(level_will_appear, CONST.LEVEL_WILL_APPEAR_NOTIFICATION)
      nc.add_observer(post_init, CONST.POST_INIT_NOTIFICATION)
   end -- init

   function instance.deinit()
      remove_update_callback(instance)
      set_instance(root.path, nil)
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.remove_observer(level_will_appear, CONST.LEVEL_WILL_APPEAR_NOTIFICATION)
      nc.remove_observer(post_init, CONST.POST_INIT_NOTIFICATION)
      fastmath.clear_arrays(waypoint_x, waypoint_y)
   end -- deinit

   return instance
end -- make

local pool = Pool.new(make)

-- export
return {
   new = pool.new,
   free = pool.free,
}
