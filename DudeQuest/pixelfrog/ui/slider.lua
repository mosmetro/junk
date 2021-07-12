local SliderBase = require("m.ui.slider_base")
-- local utils = require("m.utils")

-- local snd = require("sound.sound")

-- local fastmath = fastmath
local gui = gui
local play_flipbook = gui.play_flipbook

local function new(control)

   function control.press()
      play_flipbook(control.thumb_node, control.pressed_animation)
   end -- control.press

   function control.release()
      play_flipbook(control.thumb_node, control.released_animation)
   end -- control.release

   play_flipbook(control.thumb_node, control.released_animation)
   return SliderBase.new(control)
end -- new

return {
   new = new,
}
