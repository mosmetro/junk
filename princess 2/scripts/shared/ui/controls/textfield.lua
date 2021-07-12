-- import
local Textfield_base = require("scripts.shared.ui.textfield_base")
-- local utils = require("scripts.shared.utils")

-- localization
-- local trim_whitespaces = utils.trim_whitespaces
local hash = hash
-- local set_position = gui.set_position
local get_parent = gui.get_parent
-- local vector3 = vmath.vector3
local vector4 = vmath.vector4
local vector = vmath.vector
local set_color = gui.set_color
local get_color = gui.get_color
local get_text = gui.get_text
local set_enabled = gui.set_enabled
-- local set_scale = gui.set_scale
-- local set_position = gui.set_position
local get_position = gui.get_position
local get_size = gui.get_size
local get_text_metrics_from_node = gui.get_text_metrics_from_node
local animate = gui.animate
local cancel_animation = gui.cancel_animation
local PLAYBACK_LOOP_FORWARD = gui.PLAYBACK_LOOP_FORWARD
local EASING_LINEAR = gui.EASING_LINEAR

-- functions
local new

local CUSTOM_EASING = vector {
	0, 0, 0, 0, 0, 0, 0, 0,
	1, 1, 1, 1,
}
local COLOR = hash("color")
local POSITION_Y = hash("position.y")
local POSITION_X = hash("position.x")
local SCALE = hash("scale")
local SCALE_X = hash("scale.x")
local LABEL_POSITION_Y = 70
local LABEL_SCALE = 0.6

---------------------------------------

-- new

---------------------------------------

function new (self)
	Textfield_base.new(self)

	local text_node = self.text_node
	local label_node = self.label_node
	local cursor_node = self.cursor_node
	local underline_node = self.underline_node
	local cursor_color = get_color(cursor_node)
	local transparent_cursor_color = vector4(cursor_color)
	transparent_cursor_color.w = 0
	local label_color = get_color(label_node)
	local clip_width = get_size(get_parent(text_node)).x
	local text_color = get_color(text_node)

	---------------------------------------

	-- get_reference_position

	---------------------------------------

	function self.get_reference_position ()
		local clip_node = get_parent(text_node)
		local clip_size = get_size(clip_node)
		local position = get_position(get_parent(clip_node))
		position.x = position.x + clip_size.x * 0.5
		return position
	end -- get_reference_position

	---------------------------------------

	-- animate_cursor

	---------------------------------------

	function self.animate_cursor (start)
		if start then
			set_color(cursor_node, cursor_color)
			-- animate(node, property, to, easing, duration, delay, complete_function, playback)
			animate(cursor_node, COLOR, transparent_cursor_color, CUSTOM_EASING, 1, 0.1, nil, PLAYBACK_LOOP_FORWARD)
		else
			cancel_animation(cursor_node, COLOR)
			set_color(cursor_node, cursor_color)
		end
	end

	---------------------------------------

	-- release

	---------------------------------------

	function self.release (focused, animated)
		local duration = animated and 0.2 or 0
		if focused then
			set_enabled(cursor_node, true)
			animate(label_node, POSITION_Y, LABEL_POSITION_Y, EASING_LINEAR, duration)
			animate(label_node, SCALE, LABEL_SCALE, EASING_LINEAR, duration)
			animate(label_node, COLOR, label_color, EASING_LINEAR, duration)
			animate(underline_node, SCALE_X, 1, EASING_LINEAR, duration)
			local pos = gui.get_position(cursor_node)
			pos.x = get_text_metrics_from_node(text_node).width
			gui.set_position(cursor_node, pos)
			local text_width = get_text_metrics_from_node(text_node).width + get_size(cursor_node).x
			local text_position = get_position(text_node)
			text_position.x = (text_width > clip_width) and (clip_width - text_width) or 0
			animate(text_node, POSITION_X, text_position.x, EASING_LINEAR, duration)
		else
			local text = get_text(text_node)
			if text == "" then
				animate(label_node, POSITION_Y, 0, EASING_LINEAR, duration)
				animate(label_node, SCALE, 1, EASING_LINEAR, duration)
			else
				animate(label_node, POSITION_Y, LABEL_POSITION_Y, EASING_LINEAR, duration)
				animate(label_node, SCALE, LABEL_SCALE, EASING_LINEAR, duration)
			end
			animate(text_node, POSITION_X, 0, EASING_LINEAR, duration)
			animate(underline_node, SCALE_X, 0, EASING_LINEAR, duration)
			animate(label_node, COLOR, text_color, EASING_LINEAR, duration)
			-- self.animate_cursor(false)
			set_enabled(cursor_node, false)
		end
	end -- release

	self.release(false)
	return self
end -- new

-- export
return {
	new = new,
}
