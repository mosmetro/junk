local ButtonBase = require("m.ui.button_base")
-- local utils = require("m.utils")

local gui = gui

local Control = {}

function Control.new(control)
   local title_node = control.title_node
   control.aabb = control.aabb or Control.aabb

   function control.press()
      gui.cancel_animation(title_node, gui.PROP_COLOR)
      gui.set_color(title_node, Control.selected_color)
   end -- control.press

   function control.release(inside)
      gui.animate(title_node, gui.PROP_COLOR, Control.color, gui.EASING_LINEAR, 0.2)
   end -- control.release

   ButtonBase.new(control)
   control.release(false)
   return control
end -- new

return Control
