local Control = require("scripts.shared.ui.control")
local utils = require("scripts.shared.utils")

-- localization
local clamp = utils.clamp
local set_enabled = gui.set_enabled
local get_size = gui.get_size
local get_position = gui.get_position
local set_position = gui.set_position
local set_scale = gui.set_scale
local get_parent = gui.get_parent
local vector3 = vmath.vector3
local floor = math.floor

-- functions
local new

---------------------------------------

-- new

---------------------------------------

function new (self)

	local min_value = self.min_value or 0
	local max_value = self.max_value or 1
	local is_integral = self.is_integral or false
	local is_continuous = (self.is_continuous == nil) and true or self.is_continuous
	local track_size = get_size(self.track_node)
	local track_length = (track_size.x > track_size.y) and track_size.x or track_size.y
	local is_horizontal = track_length == track_size.x
	local sensor_node = get_parent(self.thumb_node)
	local position = get_position(sensor_node)
	local scale = vector3(1)
	local value
	local previous_value
	self.node = sensor_node

	---------------------------------------

	-- pointer_down_entered

	---------------------------------------

	function self.pointer_down_entered ()
		self.press()
	end

	function self.pointer_up_inside ()
		self.release()
		if (not is_continuous) and self.callback then	self:callback() end
	end

	function self.pointer_up_outside ()
		self.release()
		if (not is_continuous) and self.callback then	self:callback() end
	end

	function self.pointer_cancelled ()
		self.release()
	end

	---------------------------------------

	-- pointer_dragged

	---------------------------------------

	function self.pointer_dragged (event)
		previous_value = value
		if is_horizontal then
			position.x = clamp(position.x + event.dx, 0, track_length)
			value = position.x / track_length
			scale.x = value
		else
			position.y = clamp(position.y + event.dy, 0, track_length)
			value = position.y / track_length
			scale.y = value
		end
		set_position(sensor_node, position)
		set_scale(self.value_node, scale)
		if is_continuous and (previous_value ~= value) and self.callback then	self:callback() end
	end -- pointer_dragged

	---------------------------------------

	-- set_value

	---------------------------------------

	function self.set_value (new_value)
		previous_value = value
		new_value = clamp(new_value, min_value, max_value)
		value = (new_value - min_value) / (max_value - min_value)
		if is_horizontal then
			position.x = value * track_length
			scale.x = value
		else
			position.y = value * track_length
			scale.y = value
		end
		set_position(sensor_node, position)
		set_scale(self.value_node, scale)
	end -- set_value

	---------------------------------------

	-- get_value

	---------------------------------------

	function self.get_value ()
		local result = (max_value - min_value) * value + min_value
		return (is_integral and floor(result + 0.5) or result), value
	end -- get_value

	---------------------------------------

	-- disable

	---------------------------------------

	function self.disable ()
		set_enabled(get_parent(sensor_node), false)
	end -- disable

	---------------------------------------

	-- enable

	---------------------------------------

	function self.enable ()
		set_enabled(get_parent(sensor_node), true)
	end -- enable

	Control.new(self)
	self.set_value(max_value)
	return self
end -- new

-- export
return {
	new = new,
}
