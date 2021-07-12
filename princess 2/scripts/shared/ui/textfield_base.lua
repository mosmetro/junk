-- import
local Control = require("scripts.shared.ui.control")
local utils = require("scripts.shared.utils")
local nc = require("scripts.shared.notification_center")

-- localization
local hash = hash
local tostring = tostring
local trim_whitespaces = utils.trim_whitespaces
local clamp = utils.clamp
local next = next
local set_text = gui.set_text
local get_text = gui.get_text
local get_parent = gui.get_parent
local get_position = gui.get_position
-- local set_position = gui.set_position
local get_size = gui.get_size
local get_font = gui.get_font
local get_text_metrics = gui.get_text_metrics
local get_text_metrics_from_node = gui.get_text_metrics_from_node
local get_leading = gui.get_leading
local get_tracking = gui.get_tracking
local animate = gui.animate
local EASING_LINEAR = gui.EASING_LINEAR

local TEXTFIELD_DID_GET_FOCUS_NOTIFICATION = hash("TEXTFIELD_DID_GET_FOCUS_NOTIFICATION")
local TEXTFIELD_DID_LOST_FOCUS_NOTIFICATION = hash("TEXTFIELD_DID_LOST_FOCUS_NOTIFICATION")
-- local TEXTFIELD_TEXT_DID_CHANGE_NOTIFICATION = hash("TEXTFIELD_TEXT_DID_CHANGE_NOTIFICATION")
local KEYBOARD_WILL_APPEAR_NOTIFICATION = hash("KEYBOARD_WILL_APPEAR_NOTIFICATION")
local KEYBOARD_WILL_DISAPPEAR_NOTIFICATION = hash("KEYBOARD_WILL_DISAPPEAR_NOTIFICATION")

local POSITION_X = hash("position.x")

-- functions
local new

---------------------------------------

-- new

---------------------------------------

function new (self)
	Control.new(self)

	local text_node = self.text_node
	local cursor_node = self.cursor_node
	local clip_node = get_parent(text_node)
	self.node = clip_node

	local has_focus = false
	local input_group = self.input_group or {}
	if input_group then
		local index = #input_group + 1
		input_group[index] = self
		self.index = index
	end

	local cursor_index = 0

	---------------------------------------

	-- set_value

	---------------------------------------

	function self.set_value (value)
		set_text(text_node, trim_whitespaces(tostring(value)))
	end -- set_value

	---------------------------------------

	-- get_value

	---------------------------------------

	function self.get_value ()
		return get_text(text_node)
	end -- get_value

	---------------------------------------

	-- set_focus

	---------------------------------------

	function self.set_focus (focused)
		if has_focus == focused then return end
		has_focus = focused
		if has_focus then
			cursor_index = #get_text(text_node)
			self.move_cursor(true, false)
			nc.post_notification(TEXTFIELD_DID_GET_FOCUS_NOTIFICATION, self)
		else
			nc.post_notification(TEXTFIELD_DID_LOST_FOCUS_NOTIFICATION, self)
		end
		self.release(focused, true)
	end -- set_focus

	---------------------------------------

	-- switch_focus

	---------------------------------------

	function self.switch_focus (forward)
		if not input_group then return end

		local index = self.index + (forward and 1 or -1)
		if index > #input_group then
			index = 1
		elseif index < 1 then
			index = #input_group
		end
		local control = input_group[index]
		self.set_focus(false)
		control.set_focus(true)
	end -- switch_focus

	-- function self.pointer_down_entered ()
	-- end
	--
	-- function self.pointer_down_exited ()
	-- end

	---------------------------------------

	-- pointer_up_inside

	---------------------------------------

	function self.pointer_up_inside ()
		for _, textfield in next, input_group do
			textfield.set_focus(textfield == self)
		end
	end -- pointer_up_inside

	-- function self.pointer_up_outside ()
	-- end
	--
	-- function self.pointer_cancelled ()
	-- end

	---------------------------------------

	-- insert

	---------------------------------------

	function self.insert (char)
		local text = get_text(text_node)
		local prefix = text:sub(1, cursor_index)
		local suffix = text:sub(cursor_index + 1)
		set_text(text_node, prefix .. tostring(char) .. suffix)
		self.move_cursor(true, false)
		-- nc.post_notification(TEXTFIELD_TEXT_DID_CHANGE_NOTIFICATION, self, { previous_text = text })
	end -- insert

	---------------------------------------

	-- remove

	---------------------------------------

	function self.delete ()
		local text = get_text(text_node)
		local suffix = text:sub(cursor_index + 1)
		self.move_cursor(false, false)
		local prefix = text:sub(1, cursor_index)
		set_text(text_node, prefix .. suffix)
		-- nc.post_notification(TEXTFIELD_TEXT_DID_CHANGE_NOTIFICATION, self, { previous_text = text })
	end -- delete


	---------------------------------------

	-- move_cursor

	---------------------------------------

	function self.move_cursor (forward, animated)
		self.animate_cursor(false)
		local text = get_text(text_node)
		local font = get_font(text_node)
		local leading = get_leading(text_node)
		local tracking = get_tracking(text_node)
		local clip_width = get_size(clip_node).x
		local cursor_width = get_size(cursor_node).x
		local text_position = get_position(text_node)
		local move_duration = animated and 0.15 or 0

		local previous_prefix = text:sub(1, cursor_index)
		local previous_prefix_width = get_text_metrics(font, previous_prefix, nil, nil, leading, tracking).width

		cursor_index = clamp(cursor_index + (forward and 1 or -1), 0, #text)

		local prefix = text:sub(1, cursor_index)
		local prefix_width = get_text_metrics(font, prefix, nil, nil, leading, tracking).width

		if forward then
			if (previous_prefix_width + text_position.x) >= (clip_width * 0.66) then
				text_position.x = text_position.x + (previous_prefix_width - prefix_width)
				local text_width = get_text_metrics_from_node(text_node).width + cursor_width
				if text_position.x <= (clip_width - text_width) then
					text_position.x = clip_width - text_width
					if text_position.x > 0 then
						text_position.x = 0
					end
				end
				animate(text_node, POSITION_X, text_position.x, EASING_LINEAR, move_duration)
				-- set_position(text_node, text_position)
			end
		else
			if (previous_prefix_width + text_position.x) <= (clip_width * 0.33) then
				text_position.x = text_position.x + (previous_prefix_width - prefix_width)
				if text_position.x > 0 then
					text_position.x = 0
				end
				animate(text_node, POSITION_X, text_position.x, EASING_LINEAR, move_duration)
				-- set_position(text_node, text_position)
			end
		end

		local cursor_position = get_position(cursor_node)
		cursor_position.x = prefix_width
		animate(cursor_node, POSITION_X, cursor_position.x, EASING_LINEAR, move_duration)
		-- set_position(cursor_node, cursor_position)
		self.animate_cursor(true)
	end -- move_cursor

	return self
end -- new

-- export
return {
	new = new,
	TEXTFIELD_DID_GET_FOCUS_NOTIFICATION = TEXTFIELD_DID_GET_FOCUS_NOTIFICATION,
	TEXTFIELD_DID_LOST_FOCUS_NOTIFICATION = TEXTFIELD_DID_LOST_FOCUS_NOTIFICATION,
	KEYBOARD_WILL_APPEAR_NOTIFICATION = KEYBOARD_WILL_APPEAR_NOTIFICATION,
	KEYBOARD_WILL_DISAPPEAR_NOTIFICATION = KEYBOARD_WILL_DISAPPEAR_NOTIFICATION,
}
