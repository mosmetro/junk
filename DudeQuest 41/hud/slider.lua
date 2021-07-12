local SliderBase = require("m.ui.slider_base")
local colors = require("m.colors")
-- local utils = require("m.utils")

local Prototype = {}

local aabb = { -4, -11, 64, 5, }

function Prototype.new(control)
   control.aabb = control.aabb or aabb
   gui.set_color(control.track, control.track_color or colors.CONTROL_DISABLED_COLOR)
   gui.set_color(control.track_highlight, control.highlight_color or colors.LABEL_COLOR)
   gui.set_color(control.knob, control.knob_color or colors.LABEL_COLOR)

   function control.press()
   end -- control.press

   function control.release()
   end -- control.release

   return SliderBase.new(control)
end -- new

return Prototype
