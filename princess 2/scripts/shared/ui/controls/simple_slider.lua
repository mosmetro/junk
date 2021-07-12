-- import
local Slider_base = require("scripts.shared.ui.slider_base")

-- localization
local play_flipbook = gui.play_flipbook

-- functions
local new

local RELEASED_IMAGE = hash("slider_up_grey")
local PRESSED_IMAGE = hash("slider_up_grey_active_blue")

---------------------------------------

-- new

---------------------------------------

function new (self)

	---------------------------------------

	-- press

	---------------------------------------

	function self.press ()
		play_flipbook(self.thumb_node, self.pressed)
	end -- press

	---------------------------------------

	-- release

	---------------------------------------

	function self.release ()
		play_flipbook(self.thumb_node, self.released)
	end -- release

	Slider_base.new(self)
	if self.init then self:init() end
	return self
end -- new

-- export
return {
	new = new,
	RELEASED_IMAGE = RELEASED_IMAGE,
	PRESSED_IMAGE = PRESSED_IMAGE,
}
