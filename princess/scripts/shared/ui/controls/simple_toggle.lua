-- import
local ToggleBase = require("scripts.shared.ui.toggle_base")
local COLOR = require("scripts.shared.colors")
-- local MSG = require("scripts.shared.messages")
local SND = require("scripts.platformer.sound")

-- localization
local set_color = gui.set_color
local play_sound = SND.play_sound
-- local post = msg.post

-- functions
local new

function new (self)

	function self.press ()
		set_color(self.dot_node, COLOR.WHITE)
	end -- press

	function self.release (inside)
		set_color(self.dot_node, self.is_on() and COLOR.YELLOW_500 or COLOR.TRANSPARENT_WHITE)
		if inside then
			play_sound(SND.BUTTON_CLICK)
		end
	end -- release

	ToggleBase.new(self)
	return self
end -- new

-- export
return {
	new = new,
}
