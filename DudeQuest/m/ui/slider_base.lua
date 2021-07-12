local Control = require("m.ui.control")
-- local utils = require("m.utils")

local get_size = gui.get_size
-- local set_size = gui.set_size
local get_position = gui.get_position
local set_position = gui.set_position
local floor = math.floor
local vector3_get_xy = fastmath.vector3_get_xy
local vector3_set_xyz = fastmath.vector3_set_xyz
local clamp = fastmath.clamp
local clamp01 = fastmath.clamp01
local ensure_zero = fastmath.ensure_zero
local vector3_stub = fastmath.vector3_stub

local function update_aabb(aabb, x, y, w, h)
   w = w * 0.5 + 4
   local h_up = h * 0.5 + 2
   local h_down = h * 0.5 + 10
   aabb[1] = x - w
   aabb[2] = y - h_down
   aabb[3] = x + w
   aabb[4] = y + h_up
end -- update_aabb

local function new(control)
   local min_value = control.min_value or 0
   local max_value = control.max_value or 1
   local range = max_value - min_value
   local is_continuous = (control.is_continuous == nil) and true or control.is_continuous
   local is_integral = control.is_integral or false
   local track_x, track_y = fastmath.get_absolute_node_position(control.node)
   local track_width, track_height = vector3_get_xy(get_size(control.node))
   local is_horizontal = (track_width > track_height)
   local thumb_origin_x, thumb_origin_y = vector3_get_xy(get_position(control.thumb_node))
   local thumb_x, thumb_y = thumb_origin_x, thumb_origin_y
   local track_length = is_horizontal and (-2 * thumb_origin_x) or (-2 * thumb_origin_y)
   local value = min_value

   control.aabb = { 0, 0, 0, 0 }

   local function set_thumb_position(animated, callback)
      if animated then
         vector3_set_xyz(vector3_stub, thumb_x, thumb_y, 0)
         gui.animate(control.thumb_node, gui.PROP_POSITION, vector3_stub, gui.EASING_INOUTQUAD, 0.3, 0, callback, gui.PLAYBACK_ONCE_FORWARD)
         vector3_set_xyz(vector3_stub, clamp(thumb_x + 50, 1, 99), 15, 0)
         gui.animate(control.highlight_node, gui.PROP_SIZE, vector3_stub, gui.EASING_INOUTQUAD, 0.3, 0, nil, gui.PLAYBACK_ONCE_FORWARD)
      else
         vector3_set_xyz(vector3_stub, thumb_x, thumb_y, 0)
         set_position(control.thumb_node, vector3_stub)
         vector3_set_xyz(vector3_stub, clamp(thumb_x + 50, 1, 99), 15, 0)
         gui.set_size(control.highlight_node, vector3_stub)
      end
      gui.set_text(control.value_node, control.get_value())
   end -- set_thumb_position

   function control.pointer_down_entered(event)
      control.press()
      if is_horizontal then
         thumb_x = clamp(event.x - track_x, thumb_origin_x, -thumb_origin_x)
         value = ensure_zero((thumb_x - thumb_origin_x) / track_length)
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
         thumb_x = clamp(event.x - track_x, thumb_origin_x, -thumb_origin_x)
         value = ensure_zero((thumb_x - thumb_origin_x) / track_length)
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
			thumb_x = value * track_length + thumb_origin_x
		end
		set_thumb_position(animated, callback)
      -- if control.callback then
      --    control:callback()
      -- end
	end -- control.set_value

   update_aabb(control.aabb, track_x, track_y, track_width, track_height)
   return Control.new(control)
end -- new

return {
   new = new,
}
