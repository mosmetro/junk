-- import
local groups = require("m.groups")
-- local colors = require("m.colors")
local utils = require("m.utils")

-- localization
local runtime = runtime
local abs = fastmath.abs
local sign = fastmath.sign
local angle_between = fastmath.angle_between
local sincos = fastmath.sincos
-- local max = fastmath.max
local combined_is_equal = fastmath.combined_is_equal
local vector3_set_components = fastmath.vector3_set_components
-- local vector3_get_components = fastmath.vector3_get_components
local vector3_get_x = fastmath.vector3_get_x
-- local vector3_get_y = fastmath.vector3_get_y
-- local vector3_get_sign_x = fastmath.vector3_get_sign_x
local ensure_zero = fastmath.ensure_zero
-- local TO_DEG = fastmath.TO_DEG
local TO_RAD = fastmath.TO_RAD
local get_instance = runtime.get_instance
local ceil = math.ceil
local tan = math.tan
local atan2 = math.atan2
local vector3 = vmath.vector3
local raycast = physics.raycast

local ray_start = vector3()
local ray_end = vector3()

local INFINITY = 1 / 0
local MAX_ASCEND_ANGLE = 80 * TO_RAD
local UP = vector3(0, 1, 0)
local RAY_LENGTH = 15
local SKIN_THIN = 0.001
local SKIN_THICK = 1
local MIN_OBSTACLE_WIDTH = 12
local MIN_OBSTACLE_HEIGHT = 12

local function new(owner)
   local controller = {}
   local vertical_rays_count
   local vertical_rays_spacing
   local horizontal_rays_count
   local horizontal_rays_spacing
   local raycast_height
   -- local raycast_width
   local half_raycast_width
   local slope_angle
   local distance_to_slope
   local ground_id
   local up_space
   local down_hits = {}
   local ascending_slope

   function controller.check_ledge(direction, pos_x, pos_y, dy, shift_y)
      local start_x = pos_x + direction * (half_raycast_width - SKIN_THIN)
      local end_x = start_x + direction * RAY_LENGTH
      local y = pos_y + raycast_height + (shift_y or 0) + SKIN_THIN
      vector3_set_components(ray_start, start_x, y)
      vector3_set_components(ray_end, end_x, y)
      -- msg.post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = colors.MAGENTA })
      local hit = raycast(ray_start, ray_end, owner.SOLIDS)
      if hit then
         local inst = get_instance(hit.id)
         local other_dx = inst and inst.dx or 0
         local hit_distance = ensure_zero(hit.fraction * RAY_LENGTH - SKIN_THIN)
         if abs(hit_distance * direction + other_dx) < SKIN_THIN then
            return nil, dy
         end
      end

      local x = pos_x + direction * (half_raycast_width + SKIN_THIN)
      local start_y = pos_y + raycast_height - SKIN_THIN
      local end_y = start_y + 1
      vector3_set_components(ray_start, x, start_y)
      vector3_set_components(ray_end, x, end_y)
      -- msg.post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = colors.WHITE })
      hit = raycast(ray_start, ray_end, owner.CEILING)
      if hit then
         return nil, dy
      end

      local ledge_id = nil
      x = pos_x + direction * (half_raycast_width + SKIN_THIN)
      start_y = pos_y + raycast_height + (shift_y or 0) + SKIN_THIN
      end_y = start_y - RAY_LENGTH
      vector3_set_components(ray_start, x, start_y)
      vector3_set_components(ray_end, x, end_y)
      -- msg.post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = colors.WHITE })
      hit = raycast(ray_start, ray_end, owner.GROUND)
      if hit then
         local inst = get_instance(hit.id)
         local other_dy = inst and inst.dy or 0
         local hit_distance = ensure_zero(hit.fraction * RAY_LENGTH - SKIN_THIN)
         if other_dy < 0 then
            if dy < 0 then
               if hit_distance < abs(dy + other_dy) then
                  if hit_distance == 0 then
                     dy = other_dy
                     ledge_id = hit.id
                  else
                     dy = -hit_distance + other_dy
                  end
               end
            end
         else -- other_dy >= 0 then
            if hit_distance + dy <= other_dy then -- should be "<" ??
               if hit_distance == 0 then -- if (hit_distance == 0) and (velocity_y < 0) then
               dy = other_dy
               ledge_id = hit.id
            else
               dy = -hit_distance + other_dy
            end
         end
      end
   end
   return ledge_id, dy
   end -- controller.check_ledge

   function controller.set_width(width)
      vertical_rays_count = ceil(width / MIN_OBSTACLE_WIDTH) + 1
      vertical_rays_spacing = (width - 2 * SKIN_THIN) / (vertical_rays_count - 1)
      -- raycast_width = width
      half_raycast_width = width * 0.5
   end -- set_width

   function controller.set_height(height)
      horizontal_rays_count = ceil(height / MIN_OBSTACLE_HEIGHT) + 1
      horizontal_rays_spacing = (height - 2 * SKIN_THIN) / (horizontal_rays_count - 1)
      raycast_height = height--max(raycast_height or 0, height)
   end -- set_height

   function controller.cast_ray(x1, y1, x2, y2, collision_groups)
      vector3_set_components(ray_start, x1, y1)
      vector3_set_components(ray_end, x2, y2)
      -- msg.post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = colors.MAGENTA })
      return raycast(ray_start, ray_end, collision_groups)
   end

   local function side_pass(direction, pos_x, pos_y, dx, vx)
      -- log("do side pass")
      local start_x = pos_x + direction * (half_raycast_width - SKIN_THICK)
      local end_x = start_x + direction * RAY_LENGTH
      local shared_y = pos_y + SKIN_THIN
      local last_push_target = nil
      for _ = 1, horizontal_rays_count do
         vector3_set_components(ray_start, start_x, shared_y)
         vector3_set_components(ray_end, end_x, shared_y)
         -- msg.post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = colors.MAGENTA })
         local hit = raycast(ray_start, ray_end, owner.SOLIDS)
         if hit and hit.group ~= owner.SLOPE then
            -- msg.post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = colors.WHITE })
            local other_instance = get_instance(hit.id)
            local other_dx = other_instance and other_instance.dx or 0
            local other_group = hit.group
            local hit_distance = ensure_zero(hit.fraction * RAY_LENGTH - SKIN_THICK)
            local delta = dx - other_dx
            if owner.wants_notify_target then
               if direction > 0 then
                  other_instance.needs_left_pass = true
               else
                  other_instance.needs_right_pass = true
               end
            end
            if hit_distance < abs(delta) then
               if (hit_distance == 0) and (owner.on_contact) then
                  vx = owner.on_contact(hit.id, direction, vx)
               end
               if delta * direction > 0 then
                  if owner.can_push and other_instance.push then
                     if other_instance ~= last_push_target then
                        last_push_target = other_instance
                        local push = delta - hit_distance * direction
                        local push_limit = other_instance.push(push)
                        dx = push_limit + hit_distance * direction + other_dx
                     end
                  elseif (other_group ~= groups.ENTITY) then
                     dx = hit_distance * direction + other_dx
                  end
               end
            end
         end
         shared_y = shared_y + horizontal_rays_spacing
      end
      return dx, vx
   end -- side_pass

   local function sub_down_pass(dy, vy, start, finish, step)
      for i = start, finish, step do
         local hit = down_hits[i]
         local other_dy = hit.dy
         local hit_distance = hit.hit_distance
         if other_dy < 0 then
            if dy < 0 then
               if hit_distance < abs(dy + other_dy) then
                  if hit.contact then
                     if owner.on_ground_contact then
                        vy = owner.on_ground_contact(vy, hit.nx)
                     else
                        vy = 0
                     end
                  end
                  dy = other_dy - hit_distance
               end
            end
         else -- other_dy >= 0 then
         if hit_distance + dy < other_dy then
            if hit.contact then
               if owner.on_ground_contact then
                  vy = owner.on_ground_contact(vy, hit.nx)
               else
                  vy = 0
               end
            end
            dy = other_dy - hit_distance
         end
      end
   end
   return dy, vy
   end -- down_pass

   local function down_pass(pos_x, pos_y, dx, dy, vy)
      local shared_x = pos_x - (half_raycast_width - SKIN_THIN) + dx
      local start_y = pos_y + SKIN_THICK
      local end_y = start_y - RAY_LENGTH
      local hit_id, hit_dx, hit_dy, hit_can_jump_down
      for ray = 1, vertical_rays_count do
         vector3_set_components(ray_start, shared_x, start_y)
         vector3_set_components(ray_end, shared_x, end_y)
         -- msg.post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = colors.MAGENTA })
         local hit = raycast(ray_start, ray_end, owner.GROUND)
         if hit then
            local nx = ensure_zero(vector3_get_x(hit.normal))
            -- utils.log(owner.bypass, nx, ray, hit.id)
            -- utils.log(ray, nx)
            if ((nx == 0) or (ray == 1 and nx > 0) or (ray == vertical_rays_count and nx < 0)) and (hit.id ~= owner.bypass) then
               -- msg.post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = colors.MAGENTA })
               if hit.id ~= hit_id then
                  hit_id = hit.id
                  local inst = get_instance(hit_id)
                  if inst then
                     hit_dx = inst.dx or 0
                     hit_dy = inst.dy or 0
                     hit_can_jump_down = inst.can_jump_down or false
                  else
                     hit_dx, hit_dy, hit_can_jump_down = 0, 0, false
                  end
               end
               local hit_distance = ensure_zero(hit.fraction * RAY_LENGTH - SKIN_THICK)
               hit.nx = nx
               hit.ray = ray
               hit.hit_distance = hit_distance
               hit.contact = (hit_distance == 0)
               hit.dx = hit_dx
               hit.dy = hit_dy
               hit.can_jump_down = hit_can_jump_down
               down_hits[#down_hits + 1] = hit
            end
         end
         shared_x = shared_x + vertical_rays_spacing
      end
      -- owner.bypass = nil

      local hit_count = #down_hits
      local ground_hit
      if hit_count > 1 then
         local d1, v1 = sub_down_pass(dy, vy, 1, hit_count, 1)
         local d2, v2 = sub_down_pass(dy, vy, hit_count, 1, -1)
         dy = d1 > d2 and d1 or d2
         vy = v1 > v2 and v1 or v2
         if vy == 0 then
            for i = 1, hit_count do
               local hit = down_hits[i]
               if hit.contact then
                  ground_hit = ground_hit or hit
                  if ground_hit ~= hit then
                     if (hit.dy > ground_hit.dy) then
                        ground_hit = hit
                     else
                        if hit.can_jump_down == ground_hit.can_jump_down then
                           if abs(hit.dx) < abs(ground_hit.dx) then
                              ground_hit = hit
                           end
                        elseif not hit.can_jump_down then
                           ground_hit = hit
                        end
                     end
                  end
               end
            end
         end
      elseif hit_count == 1 then
         dy, vy = sub_down_pass(dy, vy, 1, 1, 1)
         if vy == 0 then
            local hit = down_hits[1]
            ground_hit = hit.contact and hit
         end
      end

      ground_id = ground_hit and ground_hit.id or ground_id

      return dy, vy
   end -- down_pass

   local function up_pass(pos_x, pos_y, dx, dy, vy)
      -- log("do up pass")
      up_space = INFINITY
      local initial_dy = dy
      local shared_x = pos_x - (half_raycast_width - SKIN_THIN) + dx
      local start_y = pos_y + (raycast_height - SKIN_THICK)
      local end_y = start_y + RAY_LENGTH
      for _ = 1, vertical_rays_count do
         vector3_set_components(ray_start, shared_x, start_y)
         vector3_set_components(ray_end, shared_x, end_y)
         -- msg.post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = colors.MAGENTA })
         local hit = raycast(ray_start, ray_end, owner.CEILING)
         if hit then
            -- msg.post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = colors.WHITE })
            local inst = get_instance(hit.id)
            local other_dy = inst and inst.dy or 0
            local hit_distance = ensure_zero(hit.fraction * RAY_LENGTH - SKIN_THICK)
            if (hit_distance + other_dy) < up_space then
               up_space = hit_distance + other_dy
            end
            if hit_distance < (dy - other_dy) then
               dy = hit_distance + other_dy
               -- if hit_distance == 0 then
               if owner.on_contact_up then
                  owner.on_contact_up(hit.id, dy)
               end
               if vy > 0 then
                  vy = 0
               end
               -- end
            end
         end
         shared_x = shared_x + vertical_rays_spacing
      end
      if not ((slope_angle == 0) or combined_is_equal(initial_dy, dy)) then
         local proposed_dx = dy / tan(slope_angle) + distance_to_slope
         if abs(dx) > proposed_dx then
            dx = proposed_dx * sign(dx)
         end
      end
      return dx, dy, vy, up_space
   end -- up_pass

   local function ascend_slope(pos_x, pos_y, dx, dy, vy)
      local frame = runtime.current_frame
      local direction = sign(dx)
      local abs_dx = abs(dx)
      local start_x = pos_x + direction * (half_raycast_width - SKIN_THIN)
      local end_x = start_x + direction * RAY_LENGTH
      local y = pos_y + SKIN_THIN
      vector3_set_components(ray_start, start_x, y)
      vector3_set_components(ray_end, end_x, y)
      -- msg.post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = colors.WHITE })
      local hit = raycast(ray_start, ray_end, owner.SLOPES)
      if hit then
         local current_slope_angle = ensure_zero(angle_between(hit.normal, UP))
         if current_slope_angle < MAX_ASCEND_ANGLE then
            local hit_distance = ensure_zero(hit.fraction * RAY_LENGTH - SKIN_THIN)
            if hit_distance < abs_dx then
               slope_angle = current_slope_angle
               distance_to_slope = hit_distance
               local launch = atan2(dy, abs_dx)
               if launch > current_slope_angle then
                  return dx, dy, vy
               end
               local move_amount = abs_dx - hit_distance
               local sn, cs = sincos(current_slope_angle)
               dy = sn * move_amount
               dx = (cs * move_amount + hit_distance) * direction
               vy = 0
               ascending_slope  = true
               ground_id = hit.id
               y = y + dy
               -- end_x = start_x + direction * (abs(dx) + SKIN_THIN)
               vector3_set_components(ray_start, start_x, y)
               vector3_set_components(ray_end, end_x, y)
               hit = raycast(ray_start, ray_end, owner.SLOPES)
               if hit then
                  -- utils.log(frame, "hit")
                  local next_slope_angle = ensure_zero(angle_between(hit.normal, UP))
                  if (next_slope_angle < MAX_ASCEND_ANGLE) and (current_slope_angle ~= next_slope_angle) then
                     utils.log(frame, "hit different slope", next_slope_angle * fastmath.TO_DEG)
                     hit_distance = ensure_zero(hit.fraction * RAY_LENGTH - SKIN_THIN)
                     if hit_distance < abs(dx) then
                        dx = hit_distance * direction
                        ground_id = hit.id
                        -- log("correct dx shorter")
                     else
                        start_x = pos_x + direction * half_raycast_width + dx
                        vector3_set_components(ray_start, start_x, y)
                        vector3_set_components(ray_end, start_x, y - RAY_LENGTH)
                        hit = raycast(ray_start, ray_end, owner.GROUND)
                        if hit then
                           dy = dy - ensure_zero(hit.fraction * RAY_LENGTH)
                           ground_id = hit.id
                           -- log("correct dy shorter")
                           -- else
                           -- log("miss dy correction")
                        end
                     end
                     -- else
                     -- utils.log(frame, "hit same slope, do nothing", next_slope_angle * fastmath.TO_DEG)
                  end
               else
                  -- utils.log(frame, "miss")
                  start_x = pos_x + direction * half_raycast_width + dx
                  vector3_set_components(ray_start, start_x, y)
                  vector3_set_components(ray_end, start_x, y - RAY_LENGTH)
                  hit = raycast(ray_start, ray_end, owner.GROUND)
                  if hit then
                     -- local angle = angle_between(hit.normal, UP)
                     -- log(frame, "hit horizontal and correct dy", angle * fastmath.TO_DEG)
                     dy = dy - ensure_zero(hit.fraction * RAY_LENGTH - SKIN_THIN)
                     ground_id = hit.id
                     -- else
                     --    log(frame, "miss horizontal")
                  end
               end
            end
         end
      end
      return dx, dy, vy
   end -- ascend_slope

   local function descend_slope(pos_x, pos_y, dx, dy, vy)
      local direction = sign(dx)
      local abs_dx = abs(dx)
      local x = pos_x - direction * (half_raycast_width - SKIN_THIN)
      local start_y = pos_y + SKIN_THIN
      local end_y = start_y - RAY_LENGTH
      vector3_set_components(ray_start, x, start_y)
      vector3_set_components(ray_end, x, end_y)
      local hit = raycast(ray_start, ray_end, owner.GROUND)
      if hit then
         local nx = ensure_zero(vector3_get_x(hit.normal))
         if (nx == 0) or (sign(nx) == direction) then
            local hit_distance = ensure_zero(hit.fraction * RAY_LENGTH - SKIN_THIN)
            local current_slope_angle = ensure_zero(angle_between(hit.normal, UP))
            local proposed_dy = tan(current_slope_angle) * abs_dx
            if hit_distance <= proposed_dy then
               local launch = atan2(dy, abs_dx)
               if launch > current_slope_angle then
                  return dx, dy, vy
               end
               -- msg.post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = colors.WHITE })
               if current_slope_angle ~= 0 then
                  local sn, cs = sincos(current_slope_angle)
                  dy = -(sn * abs_dx + hit_distance)
                  dx = cs * dx
               end
               -- vy = 0
               ground_id = hit.id
               -- x = pos_x - direction * half_raycast_width + dx
               x = x + dx
               vector3_set_components(ray_start, x, start_y)
               vector3_set_components(ray_end, x, end_y)
               hit = raycast(ray_start, ray_end, owner.GROUND)
               if hit then
                  -- msg.post("@render:", "draw_line", { start_point = ray_start, end_point = ray_end, color = colors.RED })
                  local next_slope_angle = ensure_zero(angle_between(hit.normal, UP))
                  hit_distance = ensure_zero(hit.fraction * RAY_LENGTH - SKIN_THIN)
                  if current_slope_angle == 0 then
                     if next_slope_angle ~= 0 then
                        local tan_next_slope_angle = tan(next_slope_angle)
                        local threshold = tan_next_slope_angle * abs_dx
                        if (hit_distance < threshold) or combined_is_equal(hit_distance, threshold) then
                           local move_amount = hit_distance / tan_next_slope_angle
                           local sn, cs = sincos(next_slope_angle)
                           dy = -sn * move_amount
                           dx = (cs * move_amount + (abs_dx - move_amount)) * direction
                           ground_id = hit.id
                           vy = 0
                        end
                     end
                  else
                     -- log(hit_distance, dy)
                     if -hit_distance > dy or combined_is_equal(-hit_distance, dy) then -- hit_distance < abs(dy)
                     dy = -hit_distance
                     ground_id = hit.id
                     vy = 0
                        -- log("DY correction")
                     else
                        end_y = pos_y + dy
                        vector3_set_components(ray_start, x, end_y)
                        vector3_set_components(ray_end, x - dx, end_y)
                        hit = raycast(ray_start, ray_end, owner.GROUND)
                        if hit then
                           -- log("DX correction")
                           dx = dx - ensure_zero(hit.fraction * dx)
                           ground_id = hit.id
                           vy = 0
                        end
                     end
                  end
               end
            end
         end
      end
      return dx, dy, vy
   end -- descend_slope

   function controller.update(pos_x, pos_y, dx, dy, vx, vy, ledge_id)
      -- local current_frame = runtime.current_frame

      local ground_dx = 0
      if ledge_id ~= ground_id then
         local inst = get_instance(ground_id)
         ground_dx = inst and inst.dx or 0
         dx = dx + ground_dx
      end

      -- reset
      for i = 1, #down_hits do
         down_hits[i] = nil
      end
      ground_id = nil
      up_space = nil
      slope_angle = 0
      distance_to_slope = 0
      ascending_slope = false
      if owner.before_update then
         owner.before_update()
      end

      -- side
      if owner.needs_right_pass then
         dx, vx = side_pass(1, pos_x, pos_y, dx, vx)
         owner.needs_right_pass = dx ~= 0
      end
      if owner.needs_left_pass then
         dx, vx = side_pass(-1, pos_x, pos_y, dx, vx)
         -- if owner.needs_left_pass < current_frame then
         --    owner.needs_left_pass = false
         -- end
         -- if dx == 0 then
         owner.needs_left_pass = dx ~= 0 --not combined_is_equal(dx, 0)
         -- end
      end
      if dx > 0 then
         dx, vx = side_pass(1, pos_x, pos_y, dx, vx)
      end
      if dx < 0 then
         dx, vx = side_pass(-1, pos_x, pos_y, dx, vx)
      end

      -- slopes
      if not combined_is_equal(dx, 0) then
         dx, dy, vy = ascend_slope(pos_x, pos_y, dx, dy, vy)
         if not ascending_slope then
            dx, dy, vy = descend_slope(pos_x, pos_y, dx, dy, vy)
         end
      end

      --up
      if owner.needs_up_pass then
         -- log("needs_up_pass")
         dx, dy, vy, up_space = up_pass(pos_x, pos_y, dx, dy, vy)
         -- if owner.needs_up_pass < current_frame then
         --    owner.needs_up_pass = false
         -- end
         owner.needs_up_pass = dy > 0
      end
      if dy > 0 then
         -- log("dy > 0")
         dx, dy, vy = up_pass(pos_x, pos_y, dx, dy, vy)
      end

      -- down
      if owner.needs_down_pass then
         -- log("needs_down_pass")
         dy, vy = down_pass(pos_x, pos_y, dx - ground_dx, dy, vy)
         -- if owner.needs_down_pass < current_frame then
         --    owner.needs_down_pass = false
         -- end
         owner.needs_down_pass = dy ~= 0
      end
      if dy < 0 then
         -- log("dy < 0")
         dy, vy = down_pass(pos_x, pos_y, dx - ground_dx, dy, vy)
      end

      return dx, dy, vx, vy, ground_id, up_space
   end -- update

   return controller
end -- new

return {
   new = new,
}
