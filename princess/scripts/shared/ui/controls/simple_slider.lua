-- import
local Slider_base = require("scripts.shared.ui.slider_base")
local COLOR = require("scripts.shared.colors")

-- localization
local play_flipbook = gui.play_flipbook
local set_color = gui.set_color
-- functions
local new

-- local RELEASED_IMAGE = hash("slider_up_grey")
-- local PRESSED_IMAGE = hash("slider_up_grey_active_blue")

local RELEASED_IMAGE = hash("shantae_thumb")
local PRESSED_IMAGE = hash("shantae_thumb")

---------------------------------------
-- new
---------------------------------------

function new (self)
	set_color(self.track_node, self.released_color)
	set_color(self.value_node, self.pressed_color)
	set_color(self.track_start_node, self.pressed_color)
	set_color(self.track_end_node, self.released_color)
	set_color(self.thumb_background_node, self.pressed_color)
	---------------------------------------
	-- press
	---------------------------------------

	function self.press ()
		play_flipbook(self.thumb_node, self.pressed)
		set_color(self.thumb_node, self.pressed_color or COLOR.WHITE)
	end -- press

	---------------------------------------
	-- release
	---------------------------------------

	function self.release ()
		play_flipbook(self.thumb_node, self.released)
		set_color(self.thumb_node, self.released_color or COLOR.WHITE)
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
