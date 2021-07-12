local ui = require("m.ui.ui")
-- local utils = require("m.utils")

local runtime = runtime
-- local pairs = pairs
-- local sort = table.sort
local LEFT = ui.LEFT
local RIGHT = ui.RIGHT
local UP = ui.UP
local DOWN = ui.DOWN
local A = ui.A
local B = ui.B
local X = ui.X
local Y = ui.Y
local PAUSE = ui.PAUSE

local get_instance
local set_instance
local add_update_callback
local remove_update_callback
local on_input
local update
local is_down
local is_up
local is_pressed
local reset_input
local pause
-- local sorted_crates

local current_state = {
   [LEFT] = false,
   [RIGHT] = false,
   [UP] = false,
   [DOWN] = false,
   [A] = false,
   [B] = false,
   [X] = false,
   [Y] = false,
}
local previous_state = {
   [LEFT] = false,
   [RIGHT] = false,
   [UP] = false,
   [DOWN] = false,
   [A] = false,
   [B] = false,
   [X] = false,
   [Y] = false,
}

local new_callbacks = {
   {},
   {},
   {},
   {},
   {},
   {},
   {},
}

local callbacks = {
   {},
   {},
   {},
   {},
   {},
   {},
   {},
}

local instances = {}

function get_instance(gameobject)
   return instances[gameobject]
end -- get_instance

function set_instance(gameobject, instance)
   instances[gameobject] = instance
end -- set_instance

function add_update_callback(instance, callback)
   new_callbacks[instance.update_group][instance] = callback
end -- add_update_callback

function remove_update_callback(instance)
   new_callbacks[instance.update_group][instance] = nil
   -- callbacks[instance.update_group][instance] = nil
end -- remove_update_callback

function on_input(action_id, value)
   current_state[action_id] = value
end -- on_input

-- function sorted_crates(t)
--    local s = {}
--    for k in pairs(t) do
--       s[#s + 1] = k
--    end
--    sort(s, function (a, b)
--       return a.position_y < b.position_y
--    end)
--    local i = 0
--    return function ()
--       i = i + 1
--       return s[i], t[s[i]]
--    end
-- end

function update(_, dt)
   runtime.current_time = runtime.current_time + dt
   runtime.current_frame = runtime.current_frame + 1
   runtime.delta_time = dt

   if dt == 0 then
      return
   end

   -- for i = 1, 7 do
   --    local new = new_callbacks[i]
   --    local old = callbacks[i]
   --    for k in next, new do
   --       old[k] = new[k]
   --       new[k] = nil
   --    end
   -- end
   --
   -- for i = 1, 7 do
   --    local old = callbacks[i]
   --    for _, callback in next, old do
   --       callback(dt)
   --    end
   -- end

   for i = 1, 7 do
      local new = new_callbacks[i]
      local old = callbacks[i]
      for k, v in next, new do
         old[k] = v
      end
   end

   for i = 1, 7 do
      local old = callbacks[i]
      for k, callback in next, old do
         callback(dt)
         old[k] = nil
      end
   end

   if is_down(PAUSE) then
      pause()
   end

   for action_id, _ in next, current_state do
      previous_state[action_id] = current_state[action_id]
   end
end -- update

function pause()
   msg.post("main:/main#game", msg.SET_TIME_STEP, { factor = 0, mode = 1 })
   runtime.execute_in_context(ui.ingame_controls_context.disable, ui.ingame_controls_context)
   runtime.execute_in_context(ui.single_touch_controls_context.enable, ui.single_touch_controls_context)
   runtime.execute_in_context(ui.pause_context.enable, ui.pause_context)
   runtime.execute_in_context(ui.backdrop_context.enable, ui.backdrop_context, nil, 0.5)
   ui.first_responder = ui.pause_context
end -- pause

function reset_input()
   for action_id, _ in next, current_state do
      current_state[action_id] = false
   end
   for action_id, _ in next, previous_state do
      previous_state[action_id] = false
   end
end -- reset_input

function is_down(action_id)
   return current_state[action_id] and (previous_state[action_id] ~= current_state[action_id])
end -- is_down

function is_up(action_id)
   return (not current_state[action_id]) and (previous_state[action_id] ~= current_state[action_id])
end -- is_up

function is_pressed(action_id)
   return current_state[action_id] and (previous_state[action_id] == current_state[action_id])
end -- is_pressed

runtime.current_time = 0
runtime.current_frame = 0
runtime.delta_time = 0

runtime.reset_input = reset_input
runtime.pause = pause
runtime.on_input = on_input
runtime.update = update

runtime.UPDATE_GROUP_FIRST = 1
runtime.UPDATE_GROUP_MOTOR_PLATFORMS = 2
runtime.UPDATE_GROUP_MOVABLE_OBJECTS = 3
runtime.UPDATE_GROUP_BEFORE_PLAYER = 4
runtime.UPDATE_GROUP_PLAYER = 5
runtime.UPDATE_GROUP_AFTER_PLAYER = 6
runtime.UPDATE_GROUP_LAST = 7

runtime.get_instance = get_instance
runtime.set_instance = set_instance
runtime.add_update_callback = add_update_callback
runtime.remove_update_callback = remove_update_callback

runtime.is_down = is_down
runtime.is_up = is_up
runtime.is_pressed = is_pressed

runtime.inspect = function() pprint(instances) end
