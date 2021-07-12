local utils = require("scripts.shared.utils")
-- local COLOR = require("scripts.shared.colors")
-- local GROUP = require("scripts.shared.groups")
-- local MSG = require("scripts.shared.messages")
-- local game = require("scripts.platformer.game")

-- local normalize = vmath.normalize
-- local reflect = utils.reflect
-- local next = next
-- local perp = utils.perp
-- local inversed = utils.inversed
local random_range = utils.random_range
local safe_normalize = utils.safe_normalize
-- local safe_normalized = utils.safe_normalized
local truncate = utils.truncate
local try_normalized = utils.try_normalized
-- local length_sqr = vmath.length_sqr
local length = vmath.length
local dot = vmath.dot
local vector3 = vmath.vector3
local min = math.min
local atan2 = math.atan2
local sin = math.sin
local cos = math.cos
-- local rad = math.rad
-- local post = msg.post
-- local ray_cast = physics.ray_cast

-- local draw_circle

-- local RAY_LENGTH = 1000

---------------------------------------

-- new_agent

---------------------------------------

local function new_agent(agent)
	agent = agent or {}
	agent.mass = agent.mass or 0.2
	agent.mass_reciprocal = 1 / agent.mass
	agent.max_force = agent.max_force or 40
	agent.max_speed = agent.max_speed or 100
	agent.velocity = agent.velocity or vector3()
	agent.heading = safe_normalize(agent.velocity)
	agent.position = agent.position or vector3()
	agent.wander_theta = 0

	---------------------------------------

	-- seek

	---------------------------------------

	function agent:seek(target_position)
		local to_target = target_position - self.position
		local desired_velocity = safe_normalize(to_target) * self.max_speed
		return desired_velocity - self.velocity -- desired = self.velocity + steering
	end -- seek

	---------------------------------------

	-- arrive

	---------------------------------------

	function agent:arrive(target_position, deceleration)
		deceleration = deceleration or 1
		local desired_velocity = target_position - self.position
		local distance = length(desired_velocity)
		if distance > 0 then
			local speed = distance / deceleration
			speed = min(speed, self.max_speed)
			desired_velocity.x = desired_velocity.x / distance * speed
			desired_velocity.y = desired_velocity.y / distance * speed
			return desired_velocity - self.velocity
		end
		return vector3()
	end -- arrive

	---------------------------------------

	-- pursuit

	---------------------------------------

	function agent:pursuit(evader)
		local to_evader = evader.position - self.position
		-- If the target is ahead...
		if dot(to_evader, self.heading) > 0 then
			-- and facing us...
			if dot(self.heading, evader.heading) < -0.94 then -- ~20 degress (acos)
				-- ...then we can just seek for the evader's current position.
				return self:seek(evader.position)
			end
		end
		-- Not considered ahead so we predict where the evader will be.
		-- The lookahead time is propotional to the distance between the evader and the pursuer,
    -- and is inversely proportional to the sum of the agent's velocities.
		local look_ahead_time = length(to_evader) / (self.max_speed + length(evader.velocity))
		-- Now seek to the predicted future position of the target.
		return self:seek(evader.position + evader.velocity * look_ahead_time)
	end -- pursuit

	---------------------------------------

	-- wander

	---------------------------------------

	function agent:wander()
		local wander_radius = 8
		local wander_distance = 16
		local theta_change = 0.3

		self.wander_theta = self.wander_theta + random_range(-theta_change, theta_change)

		local circle_location = self.position + self.heading * wander_distance

		-- draw_circle(circle_location, wander_radius, 20)

		local h = atan2(self.heading.y, self.heading.x)
		local circle_offset = vector3(wander_radius * cos(self.wander_theta + h), wander_radius * sin(self.wander_theta + h), 0)
		local target = circle_location + circle_offset

		-- draw_circle(target, 2, 8)

		return self:seek(target)
	end -- wander

	---------------------------------------

	-- wall_avoidance

	---------------------------------------

	function agent:wall_avoidance()


		local position = self.position
		local limits = self.limits

		local desired = vector3()

		local left = limits.left
		if left and position.x < left then
				desired.x = self.max_speed
		end
		local right = limits.right
		if right and position.x > right then
			desired.x = -self.max_speed
		end
		local bottom = limits.bottom
		if bottom and position.y < bottom then
			desired.y = self.max_speed
		end
		local top = limits.top
		if top and position.y > top then
			desired.y = -self.max_speed
		end

		return desired
	end -- wall_avoidance

	---------------------------------------

	-- on_message

	---------------------------------------

	-- function agent:on_message(message_id, message)
	--
	-- end -- on_message

	---------------------------------------

	-- update

	---------------------------------------

	function agent:update(dt)
		local steering_force = nil
		if not steering_force then return end

		truncate(steering_force, self.max_force)
		-- apply force
		local acceleration = steering_force * self.mass_reciprocal
		-- integrate
		local old_velocity = self.velocity
		self.velocity = self.velocity + acceleration * dt
		truncate(self.velocity, self.max_speed)
		self.position = self.position + (old_velocity + self.velocity) * 0.5 * dt
		-- update heading
		local result, success = try_normalized(self.velocity)
		if success then
			self.heading = result
		end
	end

	---------------------------------------

	-- support

	---------------------------------------

	-- function draw_circle (position, radius, segment_count)
	-- 	local step = rad(360) / segment_count
	-- 	local point_a = vector3(position.x + radius, position.y, 0)
	-- 	for i = 1, segment_count do
	-- 		local angle = i * step
	-- 		local point_b = vector3(position.x + radius * cos(angle), position.y + radius * sin(angle), 0)
	-- 		post("@render:", "draw_line", { start_point = point_a, end_point = point_b, color = COLOR.WHITE } )
	-- 		point_a = point_b
	-- 	end
	-- end -- draw_circle

	return agent
end -- new_agent

return {
	new_agent = new_agent,
}
