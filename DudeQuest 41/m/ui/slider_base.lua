local Control = require("m.ui.control")
-- local utils = require("m.utils")

local gui = gui
local get_size = gui.get_size
local set_size = gui.set_size
local set_position = gui.set_position
local get_scale = gui.get_scale
local floor = math.floor
local vector3_get_x = fastmath.vector3_get_x
local vector3_get_xy = fastmath.vector3_get_xy
local vector3_set_xyz = fastmath.vector3_set_xyz
local clamp = fastmath.clamp
local clamp01 = fastmath.clamp01
local ensure_zero = fastmath.ensure_zero
local vector3_stub = fastmath.vector3_stub
local get_absolute_node_position = fastmath.get_absolute_node_position

local ANIMATION_DURATION = 0.4

local function new(control)
   local min_value = control.min_value or 0
   local max_value = control.max_value or 1
   local range = max_value - min_value
   local is_continuous = (control.is_continuous == nil) and true or control.is_continuous
   local is_integral = control.is_integral or false
   local track_x, _ = get_absolute_node_position(control.track)
   local track_scale = vector3_get_x(get_scale(control.track))
   local track_width, track_height = vector3_get_xy(get_size(control.track) * track_scale)
   local is_horizontal = (track_width > track_height)
   local knob_x, knob_y = 0, 0
   local track_length = is_horizontal and track_width or track_height
   local value = min_value

   local function set_thumb_position(animated, callback)
      if animated then
         vector3_set_xyz(vector3_stub, knob_x, knob_y, 0)
         gui.animate(control.knob, gui.PROP_POSITION, vector3_stub, gui.EASING_INOUTQUAD, ANIMATION_DURATION, 0, callback, gui.PLAYBACK_ONCE_FORWARD)
         vector3_set_xyz(vector3_stub, clamp(knob_x, 0, track_length) / track_scale, track_height / track_scale, 0)
         gui.animate(control.track_highlight, gui.PROP_SIZE, vector3_stub, gui.EASING_INOUTQUAD, ANIMATION_DURATION, 0, nil, gui.PLAYBACK_ONCE_FORWARD)
      else
         vector3_set_xyz(vector3_stub, knob_x, knob_y, 0)
         set_position(control.knob, vector3_stub)
         vector3_set_xyz(vector3_stub, clamp(knob_x, 0, track_length) / track_scale, track_height / track_scale, 0)
         set_size(control.track_highlight, vector3_stub)
      end
   end -- set_thumb_position

   function control.pointer_down_entered(event)
      control.press()
      if is_horizontal then
         knob_x = clamp(event.x - track_x, 0, track_length)
         value = ensure_zero(knob_x / track_length)
         set_thumb_position()
      end
      if control.callback then
         control:callback()
      end
   end -- control.pointer_down_entered

   function control.pointer_up_inside()
      control.release()
   end

   function control.pointer_up_outside()
      control.release()
   end

   function control.pointer_cancelled()
      control.release()
   end

   function control.pointer_dragged(event)
      if is_horizontal then
         knob_x = clamp(event.x - track_x, 0, track_length)
         value = ensure_zero(knob_x / track_length)
         set_thumb_position()
      end
      if is_continuous and control.callback then
         control:callback()
      end
   end

   function control.get_value()
      local result = range * value + min_value
      return (is_integral and floor(result + 0.5) or result), value
   end -- control.get_value

   function control.set_value(new_value, animated, callback)
      value = ensure_zero(clamp01(((new_value - min_value) / range), 0, 1))
      if is_horizontal then
         knob_x = value * track_length
         set_thumb_position(animated, callback)
      end
      -- if control.callback then
      --    control:callback()
      -- end
   end -- control.set_value

   -- update_aabb(control.aabb, track_x, track_y, track_width, track_height)
   return Control.new(control)
end -- new

return {
   new = new,
}
