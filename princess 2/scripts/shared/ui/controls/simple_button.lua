-- import
local ButtonBase = require("scripts.shared.ui.button_base")
-- local MSG = require("scripts.shared.messages")
local SND = require("scripts.platformer.sound")
local COLOR = require("scripts.shared.colors")
-- local utils = require("scripts.shared.utils")

-- localization
-- local clamp = utils.clamp
-- local post = msg.post
local play_flipbook = gui.play_flipbook
local set_position = gui.set_position
local get_position = gui.get_position
local get_parent = gui.get_parent
local set_color = gui.set_color
-- local get_size = gui.get_size
-- local set_size = gui.set_size
-- local get_text_metrics_from_node = gui.get_text_metrics_from_node
local vector3 = vmath.vector3
-- local max = math.max

-- functions
local new

local RELEASED_IMAGE = hash("button_white_released")
local PRESSED_IMAGE = hash("button_white_pressed")

function new (self)

	self.node = get_parent(self.image_node)

	local released_position = get_position(self.text_node)
	local pressed_position = vector3(released_position)
	pressed_position.y = pressed_position.y - 6

	function self.press ()
		play_flipbook(self.image_node, self.pressed)
		set_position(self.text_node, pressed_position)
	end -- press

	function self.release (inside)
		play_flipbook(self.image_node, self.released)
		set_position(self.text_node, released_position)
		if inside then
			SND.BUTTON_CLICK:create_instance():start()
		end
	end -- release

	function self.enable (enable)
		set_color(self.text_node, enable and COLOR.GREY_600 or COLOR.GREY_400)
		self.is_active = enable
	end

	-- function self.resize ()
	-- 	local width = get_text_metrics_from_node(self.text_node).width
	-- 	local image_size = get_size(self.image_node)
	-- 	image_size.x = max(width + 100, 300)
	-- 	set_size(self.image_node, image_size)
	-- end

	ButtonBase.new(self)
	self.enable(true)
	return self
end -- new

-- export
return {
	new = new,
	RELEASED_IMAGE = RELEASED_IMAGE,
	PRESSED_IMAGE = PRESSED_IMAGE,
}
