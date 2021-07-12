local MSG = require("scripts.shared.messages")
local SND = require("scripts.platformer.sound")
-- local LAYER = require("scripts.shared.layers")
local StateMachine = require("scripts.shared.state_machine")
local game = require("scripts.platformer.game")
local utils = require("scripts.shared.utils")
local FX = require("scripts.platformer.fx")

-- localization
local pairs = pairs
local delete = go.delete
local create = factory.create
local distance = utils.distance
local sign = utils.sign
local abs = math.abs
local rad = math.rad
local deg = math.deg
local sin = math.sin
local cos = math.cos
local set = go.set
local post = msg.post
local vector3 = vmath.vector3
-- local get_position = go.get_position
local set_position = go.set_position
local set_text = label.set_text
local is_down = game.is_down
local is_up = game.is_up
local is_pressed = game.is_pressed
local animate = go.animate
local cancel_animations = go.cancel_animations
local PLAYBACK_ONCE_PINGPONG = go.PLAYBACK_ONCE_PINGPONG
local EASING_LINEAR = go.EASING_LINEAR
local LEFT = game.LEFT
local RIGHT = game.RIGHT
local A = game.A -- jump
local B = game.B -- slide, pogo-stick-style-attack
local X = game.X -- sword attack
local Y = game.Y -- magic attack

-- constants
local POSITION = hash("position")
local EULER_Y = hash("euler.y")
local ZERO = vector3()
local HOOK_THROW_DURATION = 0.20

-- functions
local play_animation
local make_machine
local check_directional_input
local throw_hook
local hide_hook
-- local rotate_player

-- player animations
local IDLE                  = { id = hash("princess_idle"),                  position = vector3(0, 16, 0) }
local BLINK                 = { id = hash("princess_blink"),                 position = vector3(0, 16, 0) }
local BORED                 = { id = hash("princess_bored"),                 position = vector3(0, 16, 0) }
local RUN                   = { id = hash("princess_run"),                   position = vector3(4, 20, 0) }
local PUSH                  = { id = hash("princess_push"),                  position = vector3(0, 16, 0) }
local LAND                  = { id = hash("princess_land"),                  position = vector3(0, 16, 0) }
local LAND_SIDE             = { id = hash("princess_land_side"),             position = vector3(0, 16, 0) }
local BOUNCE_UP             = { id = hash("princess_bounce_up"),             position = vector3(0, 16, 0) }
local BOUNCE_DOWN           = { id = hash("princess_bounce_down"),           position = vector3(0, 16, 0) }
local BOUNCE_LAND           = { id = hash("princess_bounce_land"),           position = vector3(0, 16, 0) }
local SMASH                 = { id = hash("princess_smash"),                 position = vector3(0, 16, 0) }
local JUMP_UP               = { id = hash("princess_jump_up"),               position = vector3(0, 27, 0) }
local JUMP_UP_APEX          = { id = hash("princess_jump_up_apex"),          position = vector3(0, 27, 0) }
local JUMP_SIDE             = { id = hash("princess_jump_side"),             position = vector3(0, 16, 0) }
local ROLL                  = { id = hash("princess_roll"),                  position = vector3(0, 16, 0) }
local FALL                  = { id = hash("princess_fall"),                  position = vector3(0, 16, 0) }
local FALL_SIDE             = { id = hash("princess_fall_side"),             position = vector3(0, 32, 0) }
local CRASH_FALL            = { id = hash("princess_crash_fall"),            position = vector3(0, 16, 0) }
-- local BASIC_MAGIC_ATTACK  = { id = hash("princess_basic_magic_attack"),      position = vector3(16, 16, 0) }
local SWORD_ATTACK_AIR      = { id = hash("princess_sword_attack_air"),      position = vector3(16, 16, 0) }
local SWORD_ATTACK_LAND     = { id = hash("princess_sword_attack_land"),     position = vector3(16, 16, 0) }
-- local SWORD_ATTACK_LAND_START     = { id = hash("princess_sword_attack_land_start"),   position = vector3(16, 16, 0) }
-- local SWORD_ATTACK_LAND_END       = { id = hash("princess_sword_attack_land_end"),     position = vector3(16, 16, 0) }
local SLIDE                 = { id = hash("princess_slide"),                 position = vector3(16, 16, 0) }
-- local CRAWL                 = { id = hash("princess_crawl"),                 position = vector3(0, 16, 0) } -- unused. Not good move for mobile
local BALANCE_START         = { id = hash("princess_balance_start"),         position = vector3(0, 16, 0) }
local BALANCE_MIDDLE        = { id = hash("princess_balance_middle"),        position = vector3(0, 16, 0) }
-- local BALANCE_END           = { id = hash("princess_balance_end"),           position = vector3(0, 16, 0) } -- unused now, because looks bad
local ATTACK_DOWN_START     = { id = hash("princess_attack_down_start"),     position = vector3(0, 16, 0) }
local ATTACK_DOWN_REPEAT    = { id = hash("princess_attack_down_repeat"),    position = vector3(0,  1, 0) }
local HOOK_THROW_LAND_START = { id = hash("princess_hook_throw_land_start"), position = vector3(0, 16, 0) }
local HOOK_THROW_LAND_END   = { id = hash("princess_hook_throw_land_end"),   position = vector3(0, 16, 0) }
local HOOK_THROW_AIR_START  = { id = hash("princess_hook_throw_air_start"),  position = vector3(0, 16, 0) }
local HOOK_THROW_AIR_END    = { id = hash("princess_hook_throw_air_end"),    position = vector3(0, 16, 0) }
local SWING_1               = { id = hash("princess_swing_1"),               position = vector3(-6,  12, 0) } -- 12
local SWING_2               = { id = hash("princess_swing_2"),               position = vector3(-8,  12, 0) }
local SWING_3               = { id = hash("princess_swing_3"),               position = vector3(-6,  12, 0) }
local SWING_4               = { id = hash("princess_swing_4"),               position = vector3(0,  12, 0) }
local SWING_5               = { id = hash("princess_swing_5"),               position = vector3(2,  12, 0) }
local SWING_6               = { id = hash("princess_swing_6"),               position = vector3(4,  12, 0) }



-- this animations played directly (outside play_animation finction)
local HOOK_ANIMATION        = { id = hash("princess_chain_hook") }
local CHAIN_A_ANIMATION     = { id = hash("princess_chain_a") }
local CHAIN_B_ANIMATION     = { id = hash("princess_chain_b") }


-- states
local idle = {}
local run = {}
local jump = {}
local fall = {}
local attack = {}
local slide = {}
local attack_down = {}
local crash = {}
local bounce = {}
local basic_magic_attack = {}
local advanced_magic_attack = {}
local swing = {}


local buffered_jump = false
local buffered_slide = false
local buffered_attack = false
local buffered_down_thrust = false
local buffered_magic_attack = false

---------------------------------------

-- idle

---------------------------------------
function idle.on_enter (machine)
	set_text(machine.owner.label, "IDLE")
	-- local owner = machine.owner
	buffered_slide = false
	idle.magic_frames = 0
	idle.should_check_edges = true
	idle.boring_countdown = 4
	if machine.previous_state == fall then
		play_animation(machine.owner, LAND)
	elseif machine.previous_state == bounce then
		play_animation(machine.owner, BOUNCE_LAND)
	else
		play_animation(machine.owner, IDLE)
	end
end -- idle.on_enter

function idle.execute (machine, dt)
	local owner = machine.owner
	local velocity = owner.velocity

	check_directional_input(owner)
	set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)

	if is_down(A) or buffered_jump then
		buffered_jump = false
		velocity.y = owner.jump_speed
	end

	if is_down(Y) then
		idle.magic_frames = 0
	elseif is_pressed(Y) then
		if idle.magic_frames > 20 then
			machine.enter_state(advanced_magic_attack)
		end
		idle.magic_frames = idle.magic_frames + 1
	elseif is_up(Y) then
		if idle.magic_frames < 20 then
			machine.enter_state(basic_magic_attack)
		end
	end

	if is_down(X) or buffered_attack then
		buffered_attack = false
		machine.enter_state(attack)
	elseif velocity.y > 0 then
		machine.enter_state(jump)
	elseif velocity.y < 0 then
		machine.enter_state(fall)
	elseif velocity.x ~= 0 then
		machine.enter_state(run)
	end


	owner:move(dt)
	if idle.should_check_edges then
		owner:check_edges()
		idle.should_check_edges = false
	end
	if owner.previous_ground ~= owner.ground then
		play_animation(machine.owner, IDLE)
		idle.should_check_edges = true
	end
end -- idle.execute

function idle.on_message (machine, message_id, message)
	local owner = machine.owner

	if message_id == MSG.ANIMATION_DONE then
		if message.id == LAND.id or message.id == BLINK.id or message.id == BOUNCE_LAND.id then
			play_animation(machine.owner, IDLE)

		elseif message.id == IDLE.id then
			idle.boring_countdown = idle.boring_countdown - 1
			play_animation(machine.owner, idle.boring_countdown < 0 and BORED or BLINK)
		elseif message.id == BALANCE_START.id then
			play_animation(machine.owner, BALANCE_MIDDLE)
		elseif message.id == BALANCE_MIDDLE.id then
			play_animation(machine.owner, BALANCE_START)
		-- elseif message.id == BALANCE_END.id then
		-- 	play_animation(machine.owner, BALANCE_START)
		end

	elseif message_id == MSG.ON_LEFT_EDGE or message_id == MSG.ON_RIGHT_EDGE then
		owner.look_direction = message_id == MSG.ON_LEFT_EDGE and 1 or -1
		play_animation(machine.owner, BALANCE_START)
	end
end -- idle.on_message

---------------------------------------

-- run

---------------------------------------
function run.on_enter (machine)
	set_text(machine.owner.label, "RUN")
	if machine.previous_state == fall then
		run.is_recovered = false
		play_animation(machine.owner, LAND_SIDE)
	else
		run.is_recovered = true
	end
end -- run.on_enter

function run.execute (machine, dt)
	local owner = machine.owner
	local velocity = owner.velocity

	if (owner.look_direction == 1 and owner.collision_right) or (owner.look_direction == -1 and owner.collision_left) then
		run.is_recovered = true
		play_animation(owner, PUSH)
	elseif run.is_recovered then
		play_animation(owner, RUN)
	end

	check_directional_input(owner)
	set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)

	if is_down(A) or buffered_jump then
		buffered_jump = false
		velocity.y = owner.jump_speed
	end

	if is_down(X) or buffered_attack then
		buffered_attack = false
		machine.enter_state(attack)
	elseif is_down(Y) then
		machine.enter_state(basic_magic_attack)
	elseif (is_down(B) or buffered_slide) then
		buffered_slide = false
		if owner.move_direction ~= 0 and not (owner.collision_right or owner.collision_left) then
			machine.enter_state(slide)
		end
	elseif velocity.y > 0 then
		machine.enter_state(jump)
	elseif velocity.y < 0 then
		machine.enter_state(fall)
	elseif velocity.x == 0 then
		machine.enter_state(idle)
	end


	owner:move(dt)
end -- run.execute

function run.on_message (_, message_id, message)
	if message_id == MSG.ANIMATION_DONE then
		if message.id == LAND_SIDE.id then
			run.is_recovered = true
		end
	end
end -- run.on_message

---------------------------------------

-- jump

---------------------------------------
function jump.on_enter (machine)
	set_text(machine.owner.label, "JUMP")
	SND.PLAYER_JUMP:create_instance():start()
	-- print(event.release)
	-- event:release()
end -- jump.on_enter

function jump.execute (machine, dt)
	local owner = machine.owner
	local velocity = owner.velocity

	if velocity.x == 0 then
		if velocity.y < 250 then
			play_animation(owner, JUMP_UP_APEX)
		else
			play_animation(owner, JUMP_UP)
		end
	else
		if velocity.y < 180 then
			play_animation(owner, ROLL)
		else
			play_animation(owner, JUMP_SIDE)
		end
	end

	check_directional_input(owner)
  set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)

	if is_up(A) then
		velocity.y = velocity.y * 0.33
	end

	if is_down(X) or buffered_attack then
		buffered_attack = false
		machine.enter_state(attack)
	elseif is_down(B) and abs(velocity.x) < owner.max_horizontal_speed then
		buffered_down_thrust = true
	elseif is_down(Y) then
		machine.enter_state(basic_magic_attack)
	elseif velocity.y <= 0 then
		machine.enter_state(fall)
	end


	owner:move(dt)
end -- jump.execute

---------------------------------------

-- fall

---------------------------------------
function fall.on_enter (machine)
	set_text(machine.owner.label, "FALL")

	if machine.previous_state == idle or machine.previous_state == run then
		fall.jump_frames = 6
	else
		fall.jump_frames = 0
	end
end -- fall.on_enter

function fall.execute (machine, dt)
	local owner = machine.owner
	local velocity = owner.velocity

	if velocity.x == 0 then
		play_animation(owner, FALL)
	else
		if machine.previous_state == jump and (velocity.y < 0 and velocity.y > -100) then
			play_animation(owner, ROLL)
		else
			play_animation(owner, FALL_SIDE)
		end
	end

	check_directional_input(owner)
	set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)

	if is_down(A) then
		buffered_jump = true
		buffered_slide = false
		if fall.jump_frames > 0 then
			fall.jump_frames = 0
			buffered_jump = false
			velocity.y = owner.jump_speed
		end
	end

	if is_down(B) or buffered_down_thrust then
		buffered_down_thrust = false
		if abs(velocity.x) < owner.max_horizontal_speed then
			machine.enter_state(attack_down)
		else
			buffered_slide = true
		end
		buffered_jump = false
	elseif is_down(X) or buffered_attack then
		buffered_attack = false
		machine.enter_state(attack)
	elseif is_down(Y) then
		machine.enter_state(basic_magic_attack)
	elseif velocity.y == 0 then
		if velocity.x == 0 then
			machine.enter_state(idle)
		else
			machine.enter_state(run)
		end
	elseif velocity.y > 0 then
		machine.enter_state(jump)
	elseif velocity.y < -owner.max_vertical_speed * 0.9 then
		machine.enter_state(crash)
	end
	fall.jump_frames = fall.jump_frames - 1


	owner:move(dt)
end -- fall.execute

---------------------------------------

-- attack

---------------------------------------
function attack.on_enter (machine)
	set_text(machine.owner.label, "ATTACK")
	local owner = machine.owner
	if owner.velocity.y == 0 then
		play_animation(owner, SWORD_ATTACK_LAND)
	else
		play_animation(owner, SWORD_ATTACK_AIR)
	end
	for k in pairs(owner.hits) do
		owner.hits[k] = nil
	end
end -- attack.on_enter

function attack.execute (machine, dt)
	local owner = machine.owner
	local velocity = owner.velocity

	if is_down(X) then
		buffered_attack = true
	elseif is_down(A) then
		buffered_jump = true -- better remove this?
	elseif is_down(B) then
		buffered_slide = true
	end

	if velocity.y == 0 then
		owner.move_direction = 0
	end

	owner:move(dt)
	owner:sword_attack()
end -- attack.execute

function attack.on_message (machine, message_id, message)
	if message_id == MSG.ANIMATION_DONE then
		local owner = machine.owner
		-- owner.animation = nil
		if message.id == SWORD_ATTACK_LAND.id or message.id == SWORD_ATTACK_AIR.id then
			local velocity = owner.velocity
			if velocity.y == 0 then
				if velocity.x == 0 then
					machine.enter_state(idle)
				else
					machine.enter_state(run)
				end
			elseif velocity.y > 0 then
				machine.enter_state(jump)
			else
				machine.enter_state(fall)
			end
		end
	end
end -- attack.on_message

---------------------------------------

-- attack_down

---------------------------------------

function attack_down.on_enter (machine)
	set_text(machine.owner.label, "ATTACK_DOWN")
	local owner = machine.owner
	play_animation(owner, ATTACK_DOWN_START)
	for k in pairs(owner.hits) do
		owner.hits[k] = nil
	end
	attack_down.is_started = false
end -- attack_down.on_enter

function attack_down.execute (machine, dt)
	local owner = machine.owner
	local velocity = owner.velocity

	if velocity.y < -owner.max_vertical_speed * 0.9 then
		machine.enter_state(crash)
	elseif velocity.y > 0 then
		machine.enter_state(jump)
	end

	owner:move(dt)
	if attack_down.is_started and not (machine.previous_state == attack_down) then
		owner:down_thrust_attack()
	end
end -- attack_down.execute

function attack_down.on_message (machine, message_id, message)
	if message_id == MSG.ANIMATION_DONE then
		if message.id == ATTACK_DOWN_START.id then
			play_animation(machine.owner, ATTACK_DOWN_REPEAT)
			attack_down.is_started = true
		end
	end
end -- attack_down.on_message

---------------------------------------

-- slide

---------------------------------------
function slide.on_enter (machine)
	set_text(machine.owner.label, "SLIDE")

	local owner = machine.owner
	owner:set_height_profile(owner.raycast_low_profile)
	slide.frames = 12
	play_animation(owner, SLIDE)
	-- game.play_gated_sound(SND.PLAYER_SLIDE)
end -- slide.on_enter

function slide.execute (machine, dt)
	local owner = machine.owner
	local velocity = owner.velocity

	if is_down(X) then
		buffered_attack = true
		buffered_jump = false
	elseif is_down(A) then
		buffered_jump = true
		buffered_attack = false
	end

	-- set_text(machine.owner.label, tostring(slide.frames))
	if (slide.frames < 0) or (owner.collision_right or owner.collision_left) or velocity.y ~= 0 then
		if owner.up_space > (owner.raycast_high_profile - owner.raycast_low_profile) then
			owner:set_height_profile(owner.raycast_high_profile)
			if buffered_attack then
				buffered_attack = false
				machine.enter_state(attack)
			elseif velocity.y == 0 then
				if velocity.x == 0 then
					machine.enter_state(idle)
				else
					machine.enter_state(run)
				end
			elseif velocity.y > 0 then
				machine.enter_state(jump)
			else
				machine.enter_state(fall)
			end
		end
	end
	slide.frames = slide.frames - 1

	owner:move(dt)
end -- slide.execute

---------------------------------------

-- crash

---------------------------------------

function crash.on_enter (machine)
	set_text(machine.owner.label, "CRASH")
	buffered_jump = false
	buffered_slide = false
	play_animation(machine.owner, CRASH_FALL)
end -- crash.on_enter

function crash.execute (machine, dt)
	local owner = machine.owner

	if owner.velocity.y == 0 then
		play_animation(owner, SMASH)
		machine.enter_state(bounce)
	end

	owner:move(dt)
end -- crash.execute

---------------------------------------

-- bounce

---------------------------------------

function bounce.on_enter (machine)
	set_text(machine.owner.label, "BOUNCE")
	bounce.jump_speed = machine.owner.jump_speed * 0.6
end -- bounce.on_enter

function bounce.execute (machine, dt)
	local owner = machine.owner
	local velocity = owner.velocity

	if velocity.y == 0 then
		velocity.y = bounce.jump_speed
		bounce.jump_speed = bounce.jump_speed * 0.4
	end
	velocity.x = velocity.x * 0.7

	play_animation(owner, velocity.y > 0 and BOUNCE_UP or BOUNCE_DOWN)

	if bounce.jump_speed < 50 then
		velocity.y = 0
		-- if velocity.x == 0 then
			machine.enter_state(idle)
		-- else
			-- machine.enter_state(run)
		-- end
	end

	owner:move(dt)
end -- bounce.execute

---------------------------------------

-- basic_magic_attack

---------------------------------------

function basic_magic_attack.on_enter (machine)
	set_text(machine.owner.label, "BASIC_MAGIC_ATTACK")
	local owner = machine.owner
	basic_magic_attack.is_ended = false
	if owner.velocity.y == 0 then
		play_animation(owner, HOOK_THROW_LAND_START)
	else
		play_animation(owner, HOOK_THROW_AIR_START)
	end
end -- basic_magic_attack.on_enter

function basic_magic_attack.execute (machine, dt)
	local owner = machine.owner
	local velocity = owner.velocity

	if is_down(Y) then
		buffered_magic_attack = true
	elseif is_down(A) then
		buffered_jump = true
	elseif is_down(B) then
		buffered_slide = true
	end

	if basic_magic_attack.is_ended then
		hide_hook(owner)
		if velocity.y == 0 then
			if velocity.x == 0 then
				machine.enter_state(idle)
			else
				machine.enter_state(run)
			end
		elseif velocity.y > 0 then
			machine.enter_state(jump)
		else
			machine.enter_state(fall)
		end
	end

	if velocity.y == 0 then
		owner.move_direction = 0
	end

	owner:move(dt)
end -- basic_magic_attack.execute

function basic_magic_attack.on_message (machine, message_id, message)
	if message_id == MSG.ANIMATION_DONE then
		local owner = machine.owner
		if message.id == HOOK_THROW_LAND_START.id then
			throw_hook(owner, HOOK_THROW_LAND_END)
		elseif message.id == HOOK_THROW_AIR_START.id then
			throw_hook(owner, HOOK_THROW_AIR_END)
		end

	elseif message_id == MSG.ON_HOOK then
		swing.pendulum_pivot = message.pivot_position
		machine.enter_state(swing)
	end
end -- basic_magic_attack.on_message

---------------------------------------

-- advanced_magic_attack

---------------------------------------

function advanced_magic_attack.on_enter(machine)
	set_text(machine.owner.label, "ADVANCED_MAGIC_ATTACK")
end -- advanced_magic_attack.on_enter

function advanced_magic_attack.execute(machine, dt)
	local owner = machine.owner
	machine.revert_to_previous_state()
	owner:move(dt)
end -- advanced_magic_attack.execute

---------------------------------------

-- swing

---------------------------------------

function swing.on_enter (machine)
	set_text(machine.owner.label, "SWING")
	local owner = machine.owner

	cancel_animations(owner.link_b, POSITION)
	cancel_animations(owner.link_c, POSITION)
	cancel_animations(owner.hook, POSITION)
	hide_hook(owner)

	swing.hook   = create(FX.FACTORY, swing.pendulum_pivot, nil, FX.PRINCESS_HOOK)
	swing.link_a = create(FX.FACTORY, swing.pendulum_pivot, nil, FX.PRINCESS_CHAIN_B)
	swing.link_b = create(FX.FACTORY, swing.pendulum_pivot, nil, FX.PRINCESS_CHAIN_A)
	swing.link_c = create(FX.FACTORY, swing.pendulum_pivot, nil, FX.PRINCESS_CHAIN_B)

	local pos = owner.position + vector3(0, 32, 0)
	swing.radius = distance(swing.pendulum_pivot, pos)
	swing.pendulum_angle = pos.x < swing.pendulum_pivot.x and rad(-60) or rad(60)
	swing.angular_acceleration = 0
	swing.angular_velocity = 0

	-- swing.dt = 0
end -- swing.on_enter

function swing.execute (machine, dt)
	local owner = machine.owner
	local r = swing.radius

	if r >= owner.hook_length then
		r = owner.hook_length
	end

	swing.angular_acceleration = -sin(swing.pendulum_angle) * 0.008
	swing.angular_velocity = swing.angular_velocity + swing.angular_acceleration
	swing.pendulum_angle = swing.pendulum_angle + swing.angular_velocity

	local a = swing.pendulum_angle + rad(-90)

	local cos_a_r = cos(a) * r
	local sin_a_r = sin(a) * r

	local pos = vector3(cos_a_r + swing.pendulum_pivot.x, sin_a_r + swing.pendulum_pivot.y, 0)

	local look_direction = sign(swing.angular_velocity)
	owner.position.x = pos.x
	owner.position.y = pos.y - 32
	set_position(owner.position, owner.gameobject)
	set(owner.pivot, EULER_Y, look_direction == 1 and 0 or 180)

	if r >= owner.hook_length then
		local angle = deg(swing.pendulum_angle)
		if angle >= -60 and angle < -45 then
			play_animation(owner, look_direction == 1 and SWING_1 or SWING_6)
		elseif angle > -45 and angle < -10 then
			play_animation(owner, look_direction == 1 and SWING_2 or SWING_5)
		elseif angle > -10 and angle < 0 then
			play_animation(owner, look_direction == 1 and SWING_3 or SWING_4)
		elseif angle > 0 and angle < 10 then
			play_animation(owner, look_direction == 1 and SWING_4 or SWING_3)
		elseif angle > 10 and angle < 45 then
			play_animation(owner, look_direction == 1 and SWING_5 or SWING_2)
		elseif angle > 45 and angle < 60 then
			play_animation(owner, look_direction == 1 and SWING_6 or SWING_1)
		end
	end

	set_position(pos, swing.link_a)

	pos.x = cos_a_r * 0.66 + swing.pendulum_pivot.x
	pos.y = sin_a_r * 0.66 + swing.pendulum_pivot.y
	set_position(pos, swing.link_b)

	pos.x = cos_a_r * 0.33 + swing.pendulum_pivot.x
	pos.y = sin_a_r * 0.33 + swing.pendulum_pivot.y
	set_position(pos, swing.link_c)

	swing.radius = r + 100 * dt

	if is_down(A) then
		owner.velocity.y = owner.jump_speed
		owner.velocity.x = owner.max_horizontal_speed * look_direction
		owner.move_direction = look_direction
		machine.enter_state(jump)
	end
end -- swing.execute

function swing.on_exit ()
	delete(swing.hook)
	delete(swing.link_a)
	delete(swing.link_b)
	delete(swing.link_c)
end -- swing.on_exit

---------------------------------------

-- throw_hook

---------------------------------------
function throw_hook (owner, character_animation)
	play_animation(owner, character_animation)
	set_position(ZERO, owner.hook)
	set_position(ZERO, owner.link_b)
	set_position(ZERO, owner.link_c)
	post(owner.hook_collisionobject, MSG.ENABLE)
	post(owner.hook_sprite, MSG.ENABLE)
	post(owner.link_a_sprite, MSG.ENABLE)
	post(owner.link_b_sprite, MSG.ENABLE)
	post(owner.link_c_sprite, MSG.ENABLE)
	post(owner.hook_sprite, MSG.PLAY_ANIMATION, HOOK_ANIMATION)
	post(owner.link_a_sprite, MSG.PLAY_ANIMATION, CHAIN_A_ANIMATION)
	post(owner.link_b_sprite, MSG.PLAY_ANIMATION, CHAIN_B_ANIMATION)
	post(owner.link_c_sprite, MSG.PLAY_ANIMATION, CHAIN_A_ANIMATION)
	animate(owner.link_b, POSITION, PLAYBACK_ONCE_PINGPONG, owner.link_b_position, EASING_LINEAR, HOOK_THROW_DURATION)
	animate(owner.link_c, POSITION, PLAYBACK_ONCE_PINGPONG, owner.link_c_position, EASING_LINEAR, HOOK_THROW_DURATION)
	animate(owner.hook, POSITION, PLAYBACK_ONCE_PINGPONG, owner.hook_position, EASING_LINEAR, HOOK_THROW_DURATION, 0, function ()
		-- hide_hook(owner)
		basic_magic_attack.is_ended = true
	end)
end -- throw_hook

---------------------------------------

-- hide_hook

---------------------------------------

function hide_hook (owner)
	post(owner.hook_collisionobject, MSG.DISABLE)
	post(owner.hook_sprite, MSG.DISABLE)
	post(owner.link_a_sprite, MSG.DISABLE)
	post(owner.link_b_sprite, MSG.DISABLE)
	post(owner.link_c_sprite, MSG.DISABLE)
end -- hide_hook

---------------------------------------

-- check_directional_input

---------------------------------------
function check_directional_input (owner)
	if is_down(LEFT) or
	(is_up(RIGHT) and is_pressed(LEFT)) or
	(is_pressed(LEFT) and not is_pressed(RIGHT)) then
		owner.move_direction = -1
		owner.look_direction = -1
	elseif is_down(RIGHT) or
	(is_up(LEFT) and is_pressed(RIGHT)) or
	(is_pressed(RIGHT) and not is_pressed(LEFT)) then
		owner.move_direction = 1
		owner.look_direction = 1
	elseif ((is_up(LEFT) or is_up(RIGHT)) and not (is_pressed(LEFT) or is_pressed(RIGHT))) or
	(not is_pressed(LEFT) and not is_pressed(RIGHT)) then
		owner.move_direction = 0
	end
end -- check_directional_input

---------------------------------------
-- play_animation
---------------------------------------

function play_animation (owner, animation)
	if owner.animation ~= animation then
		set_position(animation.position, owner.body)
		post(owner.body_sprite, MSG.PLAY_ANIMATION, animation)
		owner.animation = animation
	end
end -- play_animation

---------------------------------------
-- rotate_player
---------------------------------------

-- function rotate_player (owner)
-- 	if owner.look_direction == 1 then
-- 		set(owner.gameobject, EULER_Y, 0)
-- 		local p = get_position(owner.body)
-- 		p.z = 0
-- 		set_position(p, owner.body)
-- 	else
-- 		set(owner.gameobject, EULER_Y, 180)
-- 		local p = get_position(owner.body)
-- 		p.z = -0
-- 		set_position(p, owner.body)
-- 	end
-- end

---------------------------------------
-- make_machine
---------------------------------------
function make_machine (owner)
	return StateMachine.new(owner, idle)
end -- make_machine

-- export
return {
	make_machine = make_machine,
}
