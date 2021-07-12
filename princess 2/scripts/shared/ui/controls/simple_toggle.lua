-- import
local ToggleBase = require("scripts.shared.ui.toggle_base")
local COLOR = require("scripts.shared.colors")
-- local MSG = require("scripts.shared.messages")
local SND = require("scripts.platformer.sound")

-- localization
local set_color = gui.set_color
-- local post = msg.post

-- functions
local new

function new (self)

	function self.press ()
		set_color(self.dot_node, COLOR.GREY)
	end -- press

	function self.release (inside)
		set_color(self.dot_node, self.is_on() and COLOR.BLUE_500 or COLOR.GREY_200)
		if inside then
			SND.BUTTON_CLICK:create_instance():start()
		end
	end -- release

	ToggleBase.new(self)
	return self
end -- new

-- export
return {
	new = new,
}
