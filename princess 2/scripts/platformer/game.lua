local defold = _G

-- import
local MSG = require("scripts.shared.messages")
local SND = require("scripts.platformer.sound")
local utils = require("scripts.shared.utils")
local ui = require("scripts.shared.ui.ui")

-- localization
local execute_in_context = utils.execute_in_context
local next = next
local vector3 = vmath.vector3
-- local gettime = socket.gettime
local post = msg.post
local url = msg.url
-- local pairs = pairs
-- local sort = table.sort

-- constants
local LEFT = hash("left")
local RIGHT = hash("right")
local A = hash("a")
local B = hash("b")
local X = hash("x")
local Y = hash("y")
local MAGIC1 = hash("magic1")
local MAGIC2 = hash("magic2")
local MAGIC3 = hash("magic3")
local MAGIC4 = hash("magic4")
local MAGIC5 = hash("magic5")
local MAGIC6 = hash("magic6")
local PAUSE = hash("pause")
local TOUCH = hash("touch")
local MULTI_TOUCH = hash("multi_touch")

-- functions
-- local view_store = view_store
-- local sorted_crates
-- local reset
local play_gated_sound
local get_shared_data
local remove_shared_data
local set_agent
local get_agent
local add_update_callback
local remove_update_callback
-- local set_input_target
-- local set_input_receivers
local set_delta_position
local get_delta_position
-- local get_camera_target
local get_time
local get_frame
local increment_frame
local get_delta_time
local on_input
-- local update_input
local update
local is_down
local is_up
local is_pressed
local reset_input
local pause

-- variables
local current_frame = {}
local previous_frame = {}

local window = {
	screen_size = vector3(),
	logic_size = vector3(),
	default_layout_size = vector3(),
	screen_position = vector3(),
	logic_position = vector3(),
}
--
local world = {
	time = 0,
	frame = 0,
	camera_position = vector3(),
	pointer_position = vector3(),
}
--
-- local input_target
-- local input_receiver
local delta_positions = {}
local ZERO = vector3()
--
local motor_platforms = {}
local crates = {}
local player = {}
local last_order = {}

-- local camera_target = {}

local agents = {}

local shared_store = {}

local sound_gate = {}
local sound_options = { gain = 1 }
local SOUND_GATE_TIME = 0.033

-- function reset()
-- 	for k, _ in next, delta_positions do
-- 		delta_positions[k] = nil
-- 	end
-- end

function play_gated_sound (sound_url, gain)
	if not sound_gate[sound_url.fragment] then
		sound_gate[sound_url.fragment] = SOUND_GATE_TIME
		sound_options.gain = gain or 1
		post(sound_url, MSG.PLAY_SOUND, sound_options)
	end
end

function increment_frame ()
	world.frame = world.frame + 1
end

function get_frame ()
	return world.frame
end

local current_time = 0

function get_time ()
	return current_time
	-- return world.time
end

function get_delta_time ()
	return world.dt
end

function get_shared_data (gameobject)
	local data = shared_store[gameobject]
	if not data then
		data = {}
		shared_store[gameobject] = data
	end
	return data
end

function remove_shared_data (gameobject)
	shared_store[gameobject] = nil
end

-- function view_store ()
-- 	pprint(shared_store)
-- end

function set_agent (agent, gameobject)
	agents[gameobject] = agent
end

function get_agent (gameobject)
	return agents[gameobject]
end

function set_delta_position (gameobject, value)
	delta_positions[gameobject] = value
end

function get_delta_position (platform)
	return delta_positions[platform] or ZERO
end

function add_update_callback (context, callback, group)
	group[context] = callback
end

function remove_update_callback (context, group)
	group[context] = nil
end

-- function sorted_crates(t)
-- 	local s = {}
-- 	for k in pairs(t) do
-- 		s[#s + 1] = k
-- 	end
-- 	sort(s, function (a, b)
-- 		return a.position.y < b.position.y
-- 	end)
-- 	local i = 0
-- 	return function ()
-- 		i = i + 1
-- 		return s[i], t[s[i]]
-- 	end
-- end

---------------------------------------

-- update

---------------------------------------

function update (dt)
	current_time = current_time + dt
	-- current_time = gettime()
	world.dt = dt

	for snd, gate in next, sound_gate do
		gate = gate - dt
		if gate < 0 then
			sound_gate[snd] = nil
		else
			sound_gate[snd] = gate
		end
	end

	local script_instance = _G[3700146495]

	for context, callback in next, motor_platforms do
		_G[3700146495] = context
		callback(context, dt)
	end

	-- if next(crates) then
	-- 	for context, callback in sorted_crates(crates) do
	-- 		callback(context, dt)
	-- 	end
	-- end

	for context, callback in next, crates do
		_G[3700146495] = context
		callback(context, dt)
	end

	for context, callback in next, player do
		_G[3700146495] = context
		callback(context, dt)
	end

	for context, callback in next, last_order do
		_G[3700146495] = context
		callback(context, dt)
	end

	_G[3700146495] = script_instance

	if is_down(PAUSE) then
		pause()
	end

	for action_id, _ in next, current_frame do
		previous_frame[action_id] = current_frame[action_id]
	end
end

---------------------------------------
-- on_input
---------------------------------------

function on_input (action_id, value)
	current_frame[action_id] = value
end -- on_input

---------------------------------------
-- pause
---------------------------------------

function pause ()
	SND.BUTTON_CLICK:create_instance():start()
	post(url("main:/region1#level1_proxy"), MSG.SET_TIME_STEP, { factor = 0, mode = 1 })
	execute_in_context(ui.ingame_controls_context, function (context)
		context:disable()
	end)
	execute_in_context(ui.pause_context, function (context)
		context:enable()
	end)
	execute_in_context(ui.single_touch_controls_context, function (context)
		context:enable()
	end)
end -- pause

---------------------------------------
-- reset_input
---------------------------------------

function reset_input ()
	current_frame = {
		[LEFT] = false,
		[RIGHT] = false,
		[A] = false,
		[B] = false,
		[X] = false,
		[Y] = false,
	}
	previous_frame = {
		[LEFT] = false,
		[RIGHT] = false,
		[A] = false,
		[B] = false,
		[X] = false,
		[Y] = false,
	}
end -- reset_input

---------------------------------------
-- is_down
---------------------------------------

function is_down (action_id)
	return current_frame[action_id] and (previous_frame[action_id] ~= current_frame[action_id])
end -- is_down

---------------------------------------
-- is_up
---------------------------------------

function is_up (action_id)
	return not current_frame[action_id] and (previous_frame[action_id] ~= current_frame[action_id])
end -- is_up

---------------------------------------
-- is_pressed
---------------------------------------

function is_pressed (action_id)
	return current_frame[action_id]
end -- is_pressed

-- export
return {
	-- view_store = view_store,
	LEFT = LEFT,
	RIGHT = RIGHT,
	A = A,
	B = B,
	X = X,
	Y = Y,
	MAGIC1 = MAGIC1,
	MAGIC2 = MAGIC2,
	MAGIC3 = MAGIC3,
	MAGIC4 = MAGIC4,
	MAGIC5 = MAGIC5,
	MAGIC6 = MAGIC6,
	PAUSE = PAUSE,
	TOUCH = TOUCH,
	MULTI_TOUCH = MULTI_TOUCH,

	window = window,
	-- world = world,
	--
	-- reset = reset,
	reset_input = reset_input,
	pause = pause,
	on_input = on_input,
	update = update,
	-- update_input = update_input,

	motor_platforms = motor_platforms,
	crates = crates,
	player = player,
	last_order = last_order,

	get_shared_data = get_shared_data,
	remove_shared_data = remove_shared_data,
	set_agent = set_agent,
	get_agent = get_agent,
	add_update_callback = add_update_callback,
	remove_update_callback = remove_update_callback,
	-- set_input_target = set_input_target,
	-- set_input_receiver = set_input_receiver,
	set_delta_position = set_delta_position,
	get_delta_position = get_delta_position,
	get_time = get_time,
	get_frame = get_frame,
	increment_frame = increment_frame,
	get_delta_time = get_delta_time,

	is_down = is_down,
	is_up = is_up,
	is_pressed = is_pressed,

	play_gated_sound = play_gated_sound,
} -- export
