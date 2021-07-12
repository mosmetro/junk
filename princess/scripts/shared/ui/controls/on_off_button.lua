-- import
local ButtonBase = require("scripts.shared.ui.button_base")
local COLOR = require("scripts.shared.colors")

-- localization
local play_flipbook = gui.play_flipbook
local set_position = gui.set_position
local get_position = gui.get_position
local get_parent = gui.get_parent
local vector3 = vmath.vector3
local set_color = gui.set_color

-- functions
local new

function new (self)

	self.node = get_parent(self.image_node)

	local released_position = get_position(self.text_node)
	local pressed_position = vector3(released_position)
	pressed_position.y = pressed_position.y - 6

	self.is_on = false

	function self.press ()
		play_flipbook(self.image_node, self.pressed)
		set_position(self.text_node, pressed_position)
	end -- press

	function self.release (inside)
		play_flipbook(self.image_node, self.released)
		set_position(self.text_node, released_position)
		if inside then
			self.is_on = not self.is_on
			set_color(self.text_node, self.is_on and COLOR.BLUE_500 or COLOR.GREY)
		end
	end -- release

	ButtonBase.new(self)
	return self
end -- new

-- export
return {
	new = new,
}
