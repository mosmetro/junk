-- import
local Control = require("scripts.shared.ui.control")
local UI = require("scripts.shared.ui.ui")
local utils = require("scripts.shared.utils")

-- localization
local clamp = utils.clamp
local next = next
local get_size = gui.get_size
-- local get_scale = gui.get_scale
local get_parent = gui.get_parent
-- local get_screen_position = gui.get_screen_position
local get_width = gui.get_width
local get_height = gui.get_height
local get_position = gui.get_position
local set_position = gui.set_position
local animate = gui.animate
local cancel_animation = gui.cancel_animation
local abs = math.abs
local vector3 = vmath.vector3
local EASING_OUTQUAD = gui.EASING_OUTQUAD
local EASING_INOUTQUAD = gui.EASING_INOUTQUAD

-- functions
local new
local scroll_back_horizontal
local scroll_back_vertical
local get_absolute_position

-- const
local POSITION   = hash("position")
local POSITION_X = hash("position.x")
local POSITION_Y = hash("position.y")

---------------------------------------

-- new

---------------------------------------

function new (self)
	Control.new(self)
	local horizontal_scroll_enabled = (self.horizontal_scroll_enabled == nil) and true or self.horizontal_scroll_enabled
	local vertical_scroll_enabled = (self.vertical_scroll_enabled == nil) and true or self.vertical_scroll_enabled
	local deceleration = self.deceleration or 0.95
	local drag_slow_down = self.drag_slow_down or 0.20
	local min_velocity = self.min_velocity or 75
	local controls = self.controls or {}
	local content_size = get_size(self.content_node)
	local clip_size =  self.clip_node and get_size(self.clip_node) or vector3(get_width(), get_height(), 0)
	local margin_x = get_position(self.content_node).x
	local margin_y = get_position(self.content_node).y
	local min_scroll_x = (self.clip_node and clip_size.x or get_width()) - content_size.x - margin_x
	local min_scroll_y = -((self.clip_node and clip_size.y or get_height()) - content_size.y + margin_y)
	local dragging = false
	local vx = 0
	local vy = 0
	local hot_control = nil
	self.node = self.clip_node or self.content_node

	---------------------------------------
	-- get_absolute_position
	---------------------------------------

	function get_absolute_position(node)
		local position = get_position(node)
		local parent = get_parent(node)
		if parent then
			position = position + get_absolute_position(parent)
		end
		return position
	end -- get_absolute_position

	---------------------------------------

	-- adjust_to_keyboard_height

	---------------------------------------

	-- function self.adjust_to_keyboard_height (keyboard_height, control, duration, easing)
	-- 	local multiplier = UI.LAYOUT_MULTIPLIER_Y
	-- 	keyboard_height = keyboard_height / multiplier
	-- 	local clip_height = (self.clip_node and clip_size.y or get_height()) / multiplier
	-- 	local clip_position_y = self.clip_node and (get_absolute_position(self.clip_node).y / multiplier) or clip_height
	-- 	local clip_visible_height = clip_position_y - keyboard_height
	-- 	local content_correction_y = (clip_height - clip_visible_height) * multiplier
	-- 	if content_size.y < get_size(self.content_node).y + content_correction_y then
	-- 		content_size.y = content_size.y + content_correction_y
	-- 	end
	-- 	min_scroll_y = -((self.clip_node and clip_size.y or get_height()) - content_size.y + margin_y)
	-- 	local clip_baseline = -((clip_visible_height * multiplier) - 25)
	-- 	local clip_position = vector3(clip_size.x * 0.5, clip_baseline, 0)
	-- 	local target_position = control.get_reference_position()
	-- 	self.scroll_to(target_position, clip_position, duration, easing)
	-- end -- adjust_to_keyboard_height

	function self.adjust_to_keyboard_height (keyboard_height, control, duration, easing)
		local multiplier = UI.LAYOUT_MULTIPLIER_Y
		keyboard_height = keyboard_height / multiplier
		local clip_height = (self.clip_node and clip_size.y or get_height()) / multiplier
		local clip_position_y = self.clip_node and (get_absolute_position(self.clip_node).y / multiplier) or clip_height
		local clip_visible_height = clip_position_y - keyboard_height
		local content_correction_y = (clip_height - clip_visible_height) * multiplier
		if content_size.y < get_size(self.content_node).y + content_correction_y then
			content_size.y = content_size.y + content_correction_y
		end
		min_scroll_y = -((self.clip_node and clip_size.y or get_height()) - content_size.y + margin_y)
		local clip_baseline = -((clip_visible_height * multiplier) - 25)
		local clip_position = vector3(clip_size.x * 0.5, clip_baseline, 0)
		local target_position = control.get_reference_position()
		self.scroll_to(target_position, clip_position, duration, easing)
	end -- adjust_to_keyboard_height

	---------------------------------------

	-- revert_to_normal_height

	---------------------------------------

	function self.revert_to_normal_height (duration, easing)
		content_size.y = get_size(self.content_node).y
		min_scroll_y = -((self.clip_node and clip_size.y or get_height()) - content_size.y + margin_y)
		scroll_back_vertical(nil, duration, easing)
	end -- revert_to_normal_height

	---------------------------------------

	-- pointer_down_entered

	---------------------------------------

	function self.pointer_down_entered (event)
		cancel_animation(self.content_node, POSITION)
		dragging = false
		vx = 0
		vy = 0

		for  _, cntrl in next, controls do
			if cntrl.on_event(event) then
				hot_control = cntrl
				break
			end
		end
	end -- pointer_down_entered

	---------------------------------------

	-- pointer_dragged

	---------------------------------------

	function self.pointer_dragged (event)
		dragging = true
		local position = get_position(self.content_node)

		if horizontal_scroll_enabled then
			local new_x = position.x + event.dx
			if new_x > margin_x or new_x < min_scroll_x then
				new_x = position.x + event.dx * drag_slow_down
			end
			position.x = new_x
		end

		if vertical_scroll_enabled then
			local new_y = position.y + event.dy
			if new_y < margin_y or new_y > min_scroll_y then
				new_y = position.y + event.dy * drag_slow_down
			end
			position.y = new_y
		end

		set_position(self.content_node, position)

		if hot_control then
			hot_control.on_event( { type = UI.POINTER_CANCELLED })
			hot_control = nil
		end
	end -- pointer_dragged

	---------------------------------------

	-- pointer_up_inside

	---------------------------------------

	function self.pointer_up_inside (event)
		scroll_back_horizontal(event)
		scroll_back_vertical(event)
		dragging = false

		if hot_control then
			hot_control.on_event(event)
			hot_control = nil
		end
	end -- pointer_up_inside

	---------------------------------------

	-- pointer_up_outside

	---------------------------------------

	function self.pointer_up_outside (event)
		scroll_back_horizontal(event)
		scroll_back_vertical(event)
		dragging = false

		if hot_control then
			hot_control.on_event( { type = UI.POINTER_CANCELLED })
			hot_control = nil
		end
	end -- pointer_up_outside

	---------------------------------------

	-- pointer_cancelled

	---------------------------------------

	function self.pointer_cancelled ()
		cancel_animation(self.content_node, POSITION)
		dragging = false
		vx = 0
		vy = 0

		local position = get_position(self.content_node)

		if position.x > margin_x then
			position.x = margin_x
		elseif position.x < min_scroll_x then
			position.x = min_scroll_x
		end

		if position.y < margin_y then
			position.y = margin_y
		elseif position.y > min_scroll_y then
			position.y = min_scroll_y
		end

		set_position(self.content_node, position)

		if hot_control then
			hot_control.on_event( { type = UI.POINTER_CANCELLED })
			hot_control = nil
		end
	end -- pointer_cancelled

	---------------------------------------

	-- update

	---------------------------------------

	function self.update (dt)
		if dragging then return end

		local position = get_position(self.content_node)

		if abs(vx) > min_velocity then
			local old_vx = vx
			vx = vx * deceleration
			position.x = position.x + (old_vx + vx) * 0.5 * dt
			set_position(self.content_node, position)
			if position.x > margin_x or position.x < min_scroll_x then
				scroll_back_horizontal()
			end
		end

		if abs(vy) > min_velocity then
			local old_vy = vy
			vy = vy * deceleration
			position.y = position.y + (old_vy + vy) * 0.5 * dt
			set_position(self.content_node, position)
			if position.y < margin_y or position.y > min_scroll_y then
				scroll_back_vertical()
			end
		end

	end -- update

	---------------------------------------

	-- scroll_back_horizontal

	---------------------------------------

	function scroll_back_horizontal (event)
		if horizontal_scroll_enabled then
			local position = get_position(self.content_node)
			if position.x > margin_x then
				vx = 0
				animate(self.content_node, POSITION_X, margin_x, EASING_OUTQUAD, 0.5)
			elseif position.x < min_scroll_x then
				vx = 0
				animate(self.content_node, POSITION_X, min_scroll_x, EASING_OUTQUAD, 0.5)
			elseif dragging then
				vx = event and event.vx or 0
			end
		end
	end -- scroll_back_horizontal

	---------------------------------------

	-- scroll_back_vertical

	---------------------------------------

	function scroll_back_vertical (event, duration, easing)
		if not vertical_scroll_enabled then return end

		local position = get_position(self.content_node)
		if position.y < margin_y then
			vy = 0
			animate(self.content_node, POSITION_Y, margin_y, easing or EASING_OUTQUAD, duration or 0.5)
		elseif position.y > min_scroll_y then
			vy = 0
			animate(self.content_node, POSITION_Y, min_scroll_y, easing or EASING_OUTQUAD, duration or 0.5)
		elseif dragging then
			vy = event and event.vy or 0
		end
	end -- scroll_back_vertical

	---------------------------------------

	-- scroll_to_position

	---------------------------------------

	function self.scroll_to (target_position, clip_position, duration, easing)
		clip_position = clip_position or (clip_size * 0.5)
		target_position.x = clamp(target_position.x, -margin_x + clip_position.x, content_size.x + margin_x - clip_size.x + clip_position.x)
		target_position.y = clamp(target_position.y, clip_size.y + clip_position.y - content_size.y + margin_y, -margin_y + clip_position.y)
		animate(self.content_node, POSITION, clip_position - target_position, easing or EASING_INOUTQUAD, duration or 0)
	end -- scroll_to_position

	return self
end -- new

-- export
return {
	new = new,
}
