-- import
local MSG = require("scripts.shared.messages")
local SND = require("scripts.platformer.sound")
local utils = require("scripts.shared.utils")
local ui = require("scripts.shared.ui.ui")
local player_data = require("scripts.platformer.player_data")

-- localization
local defold = _G
local execute_in_context = utils.execute_in_context
local next = next
local vector3 = vmath.vector3
local vector4 = vmath.vector4
-- local gettime = socket.gettime
local post = msg.post
-- local url = msg.url
-- local pairs = pairs
-- local sort = table.sort
-- local tostring = tostring
local play_sound = SND.play_sound

-- constants
local LEFT = ui.LEFT
local RIGHT = ui.RIGHT
local UP = ui.UP
local DOWN = ui.DOWN
local DOWN_LEFT = ui.DOWN_LEFT
local DOWN_RIGHT = ui.DOWN_RIGHT
local A = ui.A
local B = ui.B
local X = ui.X
local Y = ui.Y
local L = ui.L
local R = ui.R
local NO_ACTION = ui.NO_ACTION

-- functions
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
local set_down
local set_up
local set_pressed
local reset_input
local pause
local set_context
local get_context
local set_pause_allowed

-- variables
local current_frame = {}
local previous_frame = {}

local window = {
   screen_size = vector4(),
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

local pause_allowed = true
--
-- local input_target
-- local input_receiver
local delta_positions = {}
local ZERO = vector3()
--
local update_group_motor_platforms = {}
local update_group_crates = {}
local update_group_before_player = {}
local update_group_player = {}
local update_group_after_player = {}
local update_group_cameras = {}
local update_group_lights = {}

local agents = {}
local context_store = {}

-- function reset()
-- 	for k, _ in next, delta_positions do
-- 		delta_positions[k] = nil
-- 	end
-- end

function set_pause_allowed(allowed)
   pause_allowed = allowed
end

function set_context(gameobject, context)
   context_store[gameobject] = context
end

function get_context(gameobject)
   return context_store[gameobject]
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

function update(ctx, dt)
   if dt == 0 then
      return
   end

   current_time = current_time + dt
   -- current_time = gettime()
   world.dt = dt
   -- for snd, gate in next, sound_gate do
   -- 	gate = gate - dt
   -- 	if gate < 0 then
   -- 		sound_gate[snd] = nil
   -- 	else
   -- 		sound_gate[snd] = gate
   -- 	end
   -- end

   -- local script_instance = defold.__dm_script_instance__

   for context, callback in next, update_group_motor_platforms do
      _G[3700146495] = context
      callback(context, dt)
   end

   -- if next(crates) then
   -- 	for context, callback in sorted_crates(crates) do
   -- 		callback(context, dt)
   -- 	end
   -- end

   for context, callback in next, update_group_crates do
      _G[3700146495] = context
      callback(context, dt)
   end

   for context, callback in next, update_group_before_player do
      _G[3700146495] = context
      callback(context, dt)
   end

   for context, callback in next, update_group_player do
      _G[3700146495] = context
      callback(context, dt)
   end

   for context, callback in next, update_group_after_player do
      _G[3700146495] = context
      callback(context, dt)
   end

   for context, callback in next, update_group_cameras do
      _G[3700146495] = context
      callback(context, dt)
   end

   for context, callback in next, update_group_lights do
      _G[3700146495] = context
      callback(context, dt)
   end

   _G[3700146495] = ctx

   if is_down(L) and pause_allowed then
      pause()
   end

   for action_id, _ in next, current_frame do
      previous_frame[action_id] = current_frame[action_id]
   end
end -- update

---------------------------------------
-- on_input
---------------------------------------

function on_input (action_id, value)
   current_frame[action_id] = value
end -- on_input

---------------------------------------
-- pause
---------------------------------------

function pause()
   play_sound(SND.BUTTON_CLICK)
   post(player_data.get_current_sector_url(), MSG.SET_TIME_STEP, { factor = 0, mode = 1 })
   execute_in_context(ui.ingame_controls_context, ui.ingame_controls_context.disable)
   execute_in_context(ui.pause_context, ui.pause_context.enable)
   execute_in_context(ui.single_touch_controls_context, ui.single_touch_controls_context.enable)
end -- pause

---------------------------------------
-- reset_input
---------------------------------------

function reset_input()
   utils.log("in game reset input")
   current_frame = {
      [LEFT] = false,
      [RIGHT] = false,
      [UP] = false,
      [DOWN] = false,
      [DOWN_LEFT] = false,
      [DOWN_RIGHT] = false,
      [A] = false,
      [B] = false,
      [X] = false,
      [Y] = false,
      [L] = false,
      [R] = false,
   }
   previous_frame = {
      [LEFT] = false,
      [RIGHT] = false,
      [UP] = false,
      [DOWN] = false,
      [DOWN_LEFT] = false,
      [DOWN_RIGHT] = false,
      [A] = false,
      [B] = false,
      [X] = false,
      [Y] = false,
      [L] = false,
      [R] = false,
   }
end -- reset_input

function set_down(action_id)
   if (not action_id) or (action_id == NO_ACTION) then return end
   previous_frame[action_id] = false
   current_frame[action_id] = true
end

function set_up(action_id)
   if (not action_id) or (action_id == NO_ACTION) then
      reset_input()
   else
      previous_frame[action_id] = true
      current_frame[action_id] = false
   end
end

function set_pressed(action_id)
   if (not action_id) or (action_id == NO_ACTION) then return end
   previous_frame[action_id] = true
   current_frame[action_id] = true
end

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
   -- utils.log("is_up", action_id)
   return (not current_frame[action_id]) and (previous_frame[action_id] ~= current_frame[action_id])
end -- is_up

---------------------------------------
-- is_pressed
---------------------------------------

function is_pressed (action_id)
   -- utils.log("is_pressed", action_id)
   return current_frame[action_id] and (previous_frame[action_id] == current_frame[action_id])
end -- is_pressed

-- export
return {
   window = window,
   reset_input = reset_input,
   pause = pause,
   on_input = on_input,
   update = update,

   update_group_motor_platforms = update_group_motor_platforms,
   update_group_crates = update_group_crates,
   update_group_before_player = update_group_before_player,
   update_group_player = update_group_player,
   update_group_after_player = update_group_after_player,
   update_group_cameras = update_group_cameras,
   update_group_lights = update_group_lights,

   set_context = set_context,
   get_context = get_context,
   set_agent = set_agent,
   get_agent = get_agent,
   add_update_callback = add_update_callback,
   remove_update_callback = remove_update_callback,
   set_delta_position = set_delta_position,
   get_delta_position = get_delta_position,
   get_time = get_time,
   get_frame = get_frame,
   increment_frame = increment_frame,
   get_delta_time = get_delta_time,

   is_down = is_down,
   is_up = is_up,
   is_pressed = is_pressed,

   set_down = set_down,
   set_up = set_up,
   set_pressed = set_pressed,

   set_pause_allowed = set_pause_allowed,
} -- export
