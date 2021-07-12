local game = require("scripts.platformer.game")
local utils = require("scripts.shared.utils")
local Queue = require("scripts.shared.queue")
local LAYER = require("scripts.shared.layers")
local TAG = require("scripts.shared.tags")
local MSG = require("scripts.shared.messages")
local GROUP = require("scripts.shared.groups")

local vector3 = vmath.vector3
local go = go
local msg = msg
local ray_cast = physics.ray_cast

local BORDER = GROUP.BORDER
local STATIC = GROUP.STATIC
local ONE_WAY_STATIC = GROUP.ONE_WAY_STATIC
local PLATFORM = GROUP.PLATFORM
local ONE_WAY_PLATFORM = GROUP.ONE_WAY_PLATFORM
local CRATE = GROUP.CRATE

local UPDATE_GROUP = game.update_group_after_player
local RAY_LENGTH = 5000
local EULER_Z = hash("euler.z")
local ROTATION_DURATION = 1.5
local PLAYBACK_LOOP_FORWARD = go.PLAYBACK_LOOP_FORWARD
local PLAYBACK_ONCE_FORWARD = go.PLAYBACK_ONCE_FORWARD
local EASING_LINEAR = go.EASING_LINEAR
local TINT_W = hash("tint.w")

local GROUND = {
   STATIC,
   ONE_WAY_STATIC,
   PLATFORM,
   ONE_WAY_PLATFORM,
   CRATE,
   BORDER,
}

local SOLIDS = {
   STATIC,
   PLATFORM,
   CRATE,
   BORDER,
}

local function make()
   local instance = {}
   local context = nil
   local gameobject = nil

   local responses = {}
   local contacts = {}

   local min_obstacle_height = 16
   local min_obstacle_width = 16
   local skin_width = 0.01
   local raycast_width = 8
   local vertical_ray_count = math.ceil(raycast_width / min_obstacle_width) + 1
   local vertical_ray_spacing = (raycast_width - 2 * skin_width) / (vertical_ray_count - 1)
   -- utils.log("vertical_ray_count", self.vertical_ray_count)
   -- utils.log("vertical_ray_spacing", self.vertical_ray_spacing)
   local raycast_height = 8
   local horizontal_ray_count = math.ceil(raycast_height / min_obstacle_height) + 1
   local horizontal_ray_spacing = (raycast_height -  2 * skin_width) / (horizontal_ray_count - 1)
   -- utils.log("horizontal_ray_count", self.horizontal_ray_count)
   -- utils.log("horizontal_ray_spacing", self.horizontal_ray_spacing)
   local total_ray_count = horizontal_ray_count * 2 + vertical_ray_count * 2
   -- utils.log("total_ray_count", self.total_ray_count)

   local first_right_ray = 1
   local last_right_ray = first_right_ray + horizontal_ray_count - 1

   local first_left_ray = last_right_ray + 1
   local last_left_ray = first_left_ray + horizontal_ray_count - 1

   local first_down_ray = last_left_ray + 1
   local last_down_ray = first_down_ray + vertical_ray_count - 1

   local first_up_ray = last_down_ray + 1
   local last_up_ray = first_up_ray + vertical_ray_count - 1

   -- self.acceleration = vector3(0, -434.78, 0)
   local acceleration = vector3(0, -850, 0)
   local max_vertical_speed = 800

   local delta_position = vector3()

   local depth_x = raycast_width * 0.5
   -- local depth_y = skin_width

   local collision_right = false
   local collision_left = false

   local ray_start = vector3()
   local ray_end = vector3()

   -- local previous_ground = nil
   local ground = nil

   local rotation_direction = 1
   local position = nil
   local velocity = nil

   local function calculate_delta_position (dt)
      local dv = acceleration * dt
      local old_velocity = velocity
      velocity = velocity + dv
      if math.abs(velocity.y) > max_vertical_speed then
         velocity.y = max_vertical_speed * utils.sign(velocity.y)
      end
      -- calculate the translation this frame (delta position) by integrating the velocity
      -- http://lolengine.net/blog/2011/12/14/understanding-motion-in-games
      return (old_velocity + velocity) * 0.5 * dt
   end -- calculate_delta_position

   -- local function update(_, dt)
   --    position = position + delta_position
   --    go.set_position(position)
   --    delta_position = calculate_delta_position(dt)
   --    -- body...
   -- end

   local function raycast_request()
      -- reset flags
      collision_right = false
      collision_left = false

      -- update ray origins
      local half_width = raycast_width * 0.5

      -- right rays (horizontal)
      ray_start.x = position.x + half_width - depth_x
      ray_start.y = position.y + skin_width
      ray_end.x = ray_start.x + RAY_LENGTH
      ray_end.y = ray_start.y
      for ray = first_right_ray, last_right_ray do
         ray_cast(ray_start, ray_end, SOLIDS, ray)
         -- post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = COLOR.MAGENTA } )
         ray_start.y = ray_start.y + horizontal_ray_spacing
         ray_end.y = ray_start.y
      end

      -- left rays (horizontal)
      ray_start.x = position.x - half_width + depth_x
      ray_start.y = position.y + skin_width
      ray_end.x = ray_start.x - RAY_LENGTH
      ray_end.y = ray_start.y
      for ray = first_left_ray, last_left_ray do
         ray_cast(ray_start, ray_end, SOLIDS, ray)
         -- post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = COLOR.MAGENTA } )
         ray_start.y = ray_start.y + horizontal_ray_spacing
         ray_end.y = ray_start.y
      end

      -- down rays (vertical)
      ray_start.x = position.x - half_width + skin_width
      ray_start.y = position.y + skin_width
      ray_end.x = ray_start.x
      ray_end.y = ray_start.y - RAY_LENGTH
      for ray = first_down_ray, last_down_ray do
         ray_cast(ray_start, ray_end, GROUND, ray)
         -- post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = COLOR.MAGENTA } )
         ray_start.x = ray_start.x + vertical_ray_spacing
         ray_end.x = ray_start.x
      end

      -- up rays (vertical)
      ray_start.x = position.x - half_width + skin_width
      ray_start.y = position.y + raycast_height - skin_width
      ray_end.x = ray_start.x
      ray_end.y = ray_start.y + RAY_LENGTH
      for ray = first_up_ray, last_up_ray do
         ray_cast(ray_start, ray_end, SOLIDS, ray)
         -- post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = COLOR.MAGENTA } )
         ray_start.x = ray_start.x + vertical_ray_spacing
         ray_end.x = ray_start.x
      end
   end -- raycast_request

   local function fade_out_complete()
      go.delete()
   end -- fade_out_complete

   local function update(self, dt)
      if ground and (velocity.y > 100) then
         rotation_direction = rotation_direction * -1
         go.animate(gameobject, EULER_Z, PLAYBACK_LOOP_FORWARD, 360 * rotation_direction, EASING_LINEAR, ROTATION_DURATION)
      end

      position = position + delta_position
      go.set_position(position)

      if ground and velocity.y == 0 then
         go.cancel_animations(gameobject, EULER_Z)
         game.remove_update_callback(context, UPDATE_GROUP)
         local ctx = game.get_context(ground)
         if ctx.tag ~= TAG.STATIC then
            msg.post(gameobject, MSG.SET_PARENT, { parent_id = ground })
         end
         go.animate("#sprite", TINT_W, PLAYBACK_ONCE_FORWARD, 0, EASING_LINEAR, 1, 1, fade_out_complete)
      end

      delta_position = calculate_delta_position(dt)
      raycast_request(self)
   end

   local function down_pass (delta_y, velocity_y, start, finish, step)
      for i = start, finish, step do
         local response = responses[i]
         local target_delta_y = game.get_delta_position(response.id).y
         local hit_distance = response.fraction * RAY_LENGTH - skin_width
         if math.abs(hit_distance) < 0.001 then
            hit_distance = 0
         end

         if delta_y < 0 or target_delta_y ~= 0 then
            if target_delta_y < 0 then
               if delta_y < 0 then
                  if hit_distance < math.abs(delta_y + target_delta_y) then
                     delta_y = -hit_distance + target_delta_y
                     if velocity_y < -60 then
                        velocity_y = -velocity_y * 0.66
                     end
                  end
               end
            else -- target_delta_y >= 0 then
               if hit_distance + delta_y < target_delta_y then
                  delta_y = -hit_distance + target_delta_y
                  if velocity_y < -60 then
                     velocity_y = -velocity_y * 0.66
                  else
                     velocity_y = 0
                  end
               end
            end
         end
         contacts[response.request_id] = (hit_distance == 0) and response.id or nil
      end -- end for

      return delta_y, velocity_y
   end -- down_pass

   local function up_pass(delta_y, velocity_y, start, finish, step)
      -- local up_space = HUGE
      for i = start, finish, step do
         local response = responses[i]
         local target_delta_y = game.get_delta_position(response.id).y

         local hit_distance = response.fraction * RAY_LENGTH - skin_width
         -- if hit_distance < up_space then
         -- 	up_space = hit_distance
         -- end

         if delta_y > 0 or target_delta_y ~= 0 then
            if math.abs(hit_distance) < 0.001 then
               hit_distance = 0
            end

            local delta_position_y = delta_y - target_delta_y
            if hit_distance < delta_position_y then
               delta_y = hit_distance + target_delta_y
               if velocity_y > 0 then
                  velocity_y = 0
               end
            end
         end
      end -- end for

      return delta_y, velocity_y--, up_space
   end -- up_pass

   local function horizontal_pass (direction, dx, first_ray, last_ray)
      for ray = first_ray, last_ray do
         local response = responses[ray]
         local hit_distance = RAY_LENGTH * response.fraction - depth_x
         if math.abs(hit_distance) < 0.001 then
            hit_distance = 0
         end
         local target_dx = game.get_delta_position(response.id).x
         local delta = dx - target_dx
         if math.abs(delta) < 0.001 then
            delta = 0
         end

         if hit_distance <= math.abs(delta) then
            if direction == 1 then
               collision_right = true
            end
            if direction == -1 then
               collision_left = true
            end

            if delta * direction > 0 then
               dx = hit_distance * direction + target_dx
            end
         end
      end
      return dx
   end -- horizontal_pass

   local function raycast_response (message)
      responses[message.request_id] = message
      if message.request_id < total_ray_count then
         return
      end
      -- all responses now collected

      local dx = delta_position.x
      local dy = delta_position.y

      local d1, v1 = down_pass(dy, velocity.y, first_down_ray, last_down_ray, 1)
      local d2, v2 = down_pass(dy, velocity.y, last_down_ray,  first_down_ray, -1)

      local d = d1 > d2 and d1 or d2
      local v = v1 > v2 and v1 or v2
      dy, velocity.y = up_pass(d, v, first_up_ray, last_up_ray, 1)

      -- previous_ground = ground
      ground = nil
      for _, g in next, contacts do
         if not ground then
            ground = g
         end
         if ground ~= g then
            local g_delta = game.get_delta_position(g)
            local ground_delta = game.get_delta_position(ground)
            if g_delta.y > ground_delta.y then
               ground = g
            elseif g_delta.x == 0 then
               ground = g
            end
         end
      end

      local ground_dx = game.get_delta_position(ground).x
      dx = dx + ground_dx

      if dx > 0 then
         dx = horizontal_pass(-1, dx, first_left_ray, last_left_ray)
         dx = horizontal_pass(1, dx, first_right_ray, last_right_ray)
      else
         dx = horizontal_pass(1, dx, first_right_ray, last_right_ray)
         dx = horizontal_pass(-1, dx, first_left_ray, last_left_ray)
      end

      if collision_left and velocity.x < 0 then
         velocity.x = -velocity.x * 0.8
      elseif collision_right and velocity.x > 0 then
         velocity.x = -velocity.x * 0.8
      else
         velocity.x = velocity.x * 0.99
      end

      delta_position.x = dx
      delta_position.y = dy
   end -- raycast_response

   function instance.on_message(message_id, message)
      if message_id == MSG.RAY_CAST_RESPONSE then
         raycast_response(message)
      end
   end

   function instance.init(self)
      context = self
      gameobject = go.get_id()
      position = go.get_position()
      position.z = LAYER.DEBRIS_2 - math.random() * 0.001
      go.set_position(position)
      delta_position.x = 0
      delta_position.y = 0
      delta_position.z = 0
      velocity = self.velocity
      rotation_direction = velocity.x > 0 and -1 or 1
      go.animate(gameobject, EULER_Z, PLAYBACK_LOOP_FORWARD, 360 * rotation_direction, EASING_LINEAR, ROTATION_DURATION)

      game.add_update_callback(self, update, UPDATE_GROUP)
      game.set_context(gameobject, context)
   end

   function instance.deinit()
      game.remove_update_callback(context, UPDATE_GROUP)
      game.set_context(gameobject, nil)
      context = nil
   end

   return instance
end

local pool
local function make_pool(count)
   utils.log("making debris pool of size " .. count)
   pool = Queue.new()
   for _ = 1, count do
      local instance = make {}
      pool.push_right(instance)
   end
end

local function new(context)
   local instance = pool.pop_right()
   if not instance then
      utils.log("clay_jug_debris.lua: Insufficient pool size")
      instance = make {}
   end
   instance.init(context)
   return instance
end

local function free(instance)
   instance.deinit()
   pool.push_right(instance)
   utils.log("debris pool size " .. pool.length())
end

make_pool(800)

return {
   make_pool = make_pool,
   new = new,
   free = free,
}
