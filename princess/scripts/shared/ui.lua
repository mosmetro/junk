local MSG = require("scripts.shared.messages")
local GUI = require("scripts.platformer.gui")
-- local utils = require("scripts.modules.utils")

-- local clamp = utils.clamp
local pick_node = gui.pick_node
local set_enabled = gui.set_enabled
local is_enabled = gui.is_enabled
local set_text = gui.set_text
local get_parent = gui.get_parent
-- local get_node = gui.get_node
local play_flipbook = gui.play_flipbook
local setmetatable = setmetatable
local post = msg.post
-- local url = msg.url
local set_color = gui.set_color
-- local vector3 = vmath.vector3
local vector4 = vmath.vector4
local animate = gui.animate
local cancel_animation = gui.cancel_animation
local get_position = gui.get_position
local set_position = gui.set_position
local get_size = gui.get_size
local get_scale = gui.get_scale
local get_width = gui.get_width
local get_height = gui.get_height
local PROP_COLOR = gui.PROP_COLOR
local PROP_POSITION = gui.PROP_POSITION
local TRANSITION_ON_SCREEN = gui.EASING_OUTQUAD
local TRANSITION_OFF_SCREEN = gui.EASING_INQUAD
local EASING_OUTQUAD = gui.EASING_OUTQUAD
local EASING_INOUTQUAD = gui.EASING_INOUTQUAD
local abs = math.abs
local next = next

-- local TRANSITION_EASING = gui.EASING_INOUTQUAD
local PLAYBACK_LOOP_PINGPONG = gui.PLAYBACK_LOOP_PINGPONG
local HUGE = math.huge
local TRANSITION_DURATION = 0.3
local TRANSPARENT_WHITE = vector4(1, 1, 1, 0)
local OPAQUE_WHITE = vector4(1, 1, 1, 1)

local get_enabled


---------------------------------------

-- get_enabled

---------------------------------------

function get_enabled (node)
	local parent = get_parent(node)
	if parent then
		return get_enabled(parent) -- get_enabled
	end
	return is_enabled(node)
end

local control = { is_active = true }
control.__index = control

---------------------------------------

-- control:hit_test

---------------------------------------

function control:hit_test (x, y)
	return get_enabled(self.node) and pick_node(self.node, x, y) or false
end

---------------------------------------

-- control:on_message

---------------------------------------

function control:on_message (message_id, message)
	if message_id == MSG.ENABLE or message_id == MSG.DISABLE then return true end -- consume this messages
	if not self.is_active then return false end

	if message_id == MSG.MOUSE_DOWN then
		if self:hit_test(message.x, message.y) then
			self.tracking = true
			self.mouse_inside = true
			self:mouse_down_entered(message)
			return true
		end

	elseif message_id == MSG.MOUSE_DRAGGED then
		if self.tracking then
			if self:hit_test(message.x, message.y) then
				if not self.mouse_inside then
					self.mouse_inside = true
					self:mouse_down_entered(message)
				end
			else
				if self.mouse_inside then
					self.mouse_inside = false
					self:mouse_down_exited(message)
				end
			end

			self:mouse_dragged(message)
			return true
		end

	elseif message_id == MSG.MOUSE_UP then
		if self.tracking then
			if self.mouse_inside then
				self:mouse_up_inside(message)
			else
				self:mouse_up_outside(message)
			end
			self.tracking = false
			self.mouse_inside = false
			return true
		end

	elseif message_id == MSG.MOUSE_CANCELLED then
		self.tracking = false
		self.mouse_inside = false
		-- self:mouse_up_outside()
		self:mouse_cancelled()
	end
	return false
end

function control:mouse_down_entered () -- luacheck: no unused args
end

function control:mouse_down_exited () -- luacheck: no unused args
end

function control:mouse_up_inside () -- luacheck: no unused args
end

function control:mouse_up_outside () -- luacheck: no unused args
end

function control:mouse_dragged () -- luacheck: no unused args
end

function control:mouse_cancelled () -- luacheck: no unused args
end

---------------------------------------

-- new_button

---------------------------------------

local function new_button (button)
	setmetatable(button, control)

	function button:mouse_down_entered ()
		self:activate()
	end

	function button:mouse_down_exited ()
		self:deactivate()
	end

	function button:mouse_up_inside ()
		self:deactivate()
		if self.callback then self.callback() end
	end

	function button:mouse_up_outside ()
		self:deactivate()
	end

	function button:mouse_cancelled ()
		self:deactivate()
	end

	function button:activate ()
		play_flipbook(self.node, self.active)
	end

	function button:deactivate ()
		play_flipbook(self.node, self.normal)
	end

	function button:highlight ()
		set_color(self.glow, TRANSPARENT_WHITE)
		animate(self.glow, PROP_COLOR, OPAQUE_WHITE, EASING_INOUTQUAD, 1.2, 0, nil, PLAYBACK_LOOP_PINGPONG)
	end

	function button:unhighlight ()
		play_flipbook(self.node, self.normal)
	end

	function button:disable ()
		set_enabled(self.node, false)
	end

	function button:set_text (text)
		set_text(self.text_node, text)
	end

	return button
end

---------------------------------------

-- new_scroll_area

---------------------------------------

local function new_scroll_area (scroll_area)
	setmetatable(scroll_area,	control)
	scroll_area.deceleration = scroll_area.deceleration or 0.95
	scroll_area.drag_slow_down = scroll_area.drag_slow_down or 0.1
	scroll_area.min_velocity = scroll_area.min_velocity or 75
	scroll_area.controls = scroll_area.controls or {}

	scroll_area.vx = 0
	scroll_area.vy = 0
	scroll_area.content_size = get_size(scroll_area.node)
	local content_scale = get_scale(scroll_area.node)
	scroll_area.content_size.x = scroll_area.content_size.x * content_scale.x
	scroll_area.content_size.y = scroll_area.content_size.y * content_scale.y

	---------------------------------------

	-- scroll_area:hit_test

	---------------------------------------

	function scroll_area:hit_test (x, y)
		local node = self.clip_node and self.clip_node or self.node
		return get_enabled(self.node) and pick_node(node, x, y) or false
	end

	---------------------------------------

	-- scroll_area:scroll_to_position

	---------------------------------------

	function scroll_area:scroll_to_position (position, animated)
		if animated then
			animate(self.node, PROP_POSITION, position, EASING_INOUTQUAD, 1.5)
		else
			set_position(self.node, position)
		end
	end

	---------------------------------------

	-- scroll_area:min_scroll_x

	---------------------------------------

	function scroll_area:min_scroll_x ()
		return (self.clip_node and get_size(self.clip_node).x or get_width()) - self.content_size.x
	end

	---------------------------------------

	-- scroll_area:min_scroll_y

	---------------------------------------

	function scroll_area:min_scroll_y ()
		return (self.clip_node and get_size(self.clip_node).y or get_height()) - self.content_size.y
	end

	---------------------------------------

	-- scroll_area:mouse_down_entered

	---------------------------------------

	function scroll_area:mouse_down_entered (args)
		cancel_animation(self.node, PROP_POSITION)
		self.dragging = false
		self.vx = 0
		self.vy = 0

		for  _, cntrl in next, self.controls do
			if cntrl:on_message(MSG.MOUSE_DOWN, args) then
				self.active_control = cntrl
				break
			end
		end
	end

	---------------------------------------

	-- scroll_area:mouse_dragged

	---------------------------------------

	function scroll_area:mouse_dragged (args)
		self.dragging = true
		local position = get_position(self.node)

		if self.horizontal_scroll_enabled then
			local new_x = position.x + args.dx
			if new_x > 0 or new_x < self:min_scroll_x() then
				new_x = position.x + args.dx * self.drag_slow_down
			end
			position.x = new_x
		end

		if self.vertical_scroll_enabled then
			local new_y = position.y + args.dy
			if new_y > 0 or new_y < self:min_scroll_y() then
				new_y = position.y + args.dy * self.drag_slow_down
			end
			position.y = new_y
		end

		set_position(self.node, position)

		-- for  _, cntrl in next, self.controls do
		-- 	cntrl:on_message(MSG.MOUSE_CANCELLED)
		-- end
		if self.active_control then
			self.active_control:on_message(MSG.MOUSE_CANCELLED)
			self.active_control = nil
		end
	end

	---------------------------------------

	-- scroll_area:mouse_up_inside

	---------------------------------------

	function scroll_area:mouse_up_inside (args)
		local position = get_position(self.node)

		if self.horizontal_scroll_enabled then
			if position.x > 0 then
				self.vx = 0
				position.x = 0
				animate(self.node, "position.x", 0, EASING_OUTQUAD, 0.5)
			elseif position.x < self:min_scroll_x() then
				self.vx = 0
				position.x = self:min_scroll_x()
				animate(self.node, "position.x", self:min_scroll_x(), EASING_OUTQUAD, 0.5)
			elseif self.dragging then
				self.vx = args.vx
			end
		end

		if self.vertical_scroll_enabled then
			if position.y > 0 then
				self.vy = 0
				position.y = 0
				animate(self.node, "position.y", 0, EASING_OUTQUAD, 0.5)
			elseif position.y < self:min_scroll_y() then
				self.vy = 0
				position.y = self:min_scroll_y()
				animate(self.node, "position.y", self:min_scroll_y(), EASING_OUTQUAD, 0.5)
			elseif self.dragging then
				self.vy = args.vy
			end
		end

		self.dragging = false

		if self.active_control then
			self.active_control:on_message(MSG.MOUSE_UP, args)
			self.active_control = nil
		end
	end

	---------------------------------------

	-- scroll_area:mouse_up_outside

	---------------------------------------

	function scroll_area:mouse_up_outside (args)
		local position = get_position(self.node)

		if self.horizontal_scroll_enabled then
			if position.x > 0 then
				self.vx = 0
				position.x = 0
				animate(self.node, "position.x", 0, EASING_OUTQUAD, 0.5)
			elseif position.x < self:min_scroll_x() then
				self.vx = 0
				position.x = self:min_scroll_x()
				animate(self.node, "position.x", self:min_scroll_x(), EASING_OUTQUAD, 0.5)
			elseif self.dragging then
				self.vx = args.vx
			end
		end

		if self.vertical_scroll_enabled then
			if position.y > 0 then
				self.vy = 0
				position.y = 0
				animate(self.node, "position.y", 0, EASING_OUTQUAD, 0.5)
			elseif position.y < self:min_scroll_y() then
				self.vy = 0
				position.y = self:min_scroll_y()
				animate(self.node, "position.y", self:min_scroll_y(), EASING_OUTQUAD, 0.5)
			elseif self.dragging then
				self.vy = args.vy
			end
		end

		self.dragging = false

		if self.active_control then
			self.active_control:on_message(MSG.MOUSE_CANCELLED)
			self.active_control = nil
		end
	end

	---------------------------------------

	-- sscroll_area:mouse_cancelled

	---------------------------------------

	function scroll_area:mouse_cancelled ()
		cancel_animation(self.node, PROP_POSITION)
		self.dragging = false
		self.vx = 0
		self.vy = 0

		local position = get_position(self.node)

		if position.x > 0 then
			position.x = 0
		elseif position.x < self:min_scroll_x() then
			position.x = self:min_scroll_x()
		end

		if position.y > 0 then
			position.y = 0
		elseif position.y < self:min_scroll_y() then
			position.y = self:min_scroll_y()
		end

		set_position(self.node, position)

		if self.active_control then
			self.active_control:on_message(MSG.MOUSE_CANCELLED)
			self.active_control = nil
		end
	end

	---------------------------------------

	-- scroll_area:update

	---------------------------------------

	function scroll_area:update (dt)
		if self.dragging then
			return
		end

		local position = get_position(self.node)

		if abs(self.vx) > self.min_velocity then
			if position.x > 0 or position.x < self:min_scroll_x() then
				self:mouse_up_inside()
				return
			else
				self.vx = self.vx * self.deceleration
				position.x = position.x + self.vx * dt
				set_position(self.node, position)
			end
		end

		if abs(self.vy) > self.min_velocity then
			if position.y > 0 or position.y < self:min_scroll_y() then
				self:mouse_up_inside()
				return
			else
				self.vy = self.vy * self.deceleration
				position.y = position.y + self.vy * dt
				set_position(self.node, position)
			end
		end
	end

	return scroll_area
end

---------------------------------------

-- show

---------------------------------------

local function show (node, on_complete, duration, delay)
	duration = duration or TRANSITION_DURATION
	delay = delay or 0
	set_color(node, TRANSPARENT_WHITE)
	animate(node, PROP_COLOR, OPAQUE_WHITE, TRANSITION_ON_SCREEN, duration, delay, function()
		if on_complete then on_complete() end
	end)
	-- end
end

---------------------------------------

-- hide

---------------------------------------

local function hide (node, on_complete, duration, delay)
	duration = duration or TRANSITION_DURATION
	delay = delay or 0
	animate(node, PROP_COLOR, TRANSPARENT_WHITE, TRANSITION_OFF_SCREEN, duration, delay, on_complete)
end

-- local popup_message
-- local function register_url (url)
-- 	popup_message = url
-- end

local function show_popup (target_to_return_input)
	post(GUI.POPUP_MESSAGE, MSG.ENABLE)
	post(GUI.POPUP_MESSAGE, MSG.SHOW, { target = target_to_return_input })
end

---------------------------------------

-- new_key

---------------------------------------

local function new_key (key)
	key.is_active = key.is_active == nil or false
	key.repeat_interval = key.repeat_interval or HUGE
	key.time_elapsed = 0

	function key:on_message (message_id, message)
		if self.is_active then

			if message.key and message.key == self.id then
				if message_id == MSG.KEY_DOWN and self.key_down then
					self:key_down()
					self.time_elapsed = 0
				elseif message_id == MSG.KEY_UP and self.key_up then
					self:key_up()
				elseif message_id == MSG.KEY_PRESSED and self.key_pressed then
					if self.time_elapsed > self.repeat_interval then
						self.time_elapsed = 0
						self:key_pressed()
					end
					self.time_elapsed = self.time_elapsed + message.dt
				end
				return true
			end
		end
		return false
	end

	return key
end

---------------------------------------

-- export

---------------------------------------

return {
	new_key = new_key,
	-- register_url = register_url,
	TRANSITION_DURATION = TRANSITION_DURATION,
	new_button = new_button,
	new_scroll_area = new_scroll_area,
	show = show,
	hide = hide,
	show_popup = show_popup,
}
