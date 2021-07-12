local ButtonBase = require("m.ui.button_base")
-- local utils = require("m.utils")

local gui = gui

local ProfileButton = {}

local radio_group = {}

function ProfileButton.new(control)
   local title_node = control.title_node
   control.aabb = control.aabb or ProfileButton.aabb

   function control.press()
      gui.cancel_animation(title_node, gui.PROP_COLOR)
      gui.set_color(title_node, ProfileButton.selected_color)
   end -- control.press

   function control.release(inside)
      if control.is_on() then
         gui.cancel_animation(title_node, gui.PROP_COLOR)
         gui.set_color(title_node, ProfileButton.selected_color)
      else
         gui.animate(title_node, gui.PROP_COLOR, ProfileButton.color, gui.EASING_LINEAR, 0.2)
      end
   end -- control.release

   function control.set_text(text)
      gui.set_text(control.title_node, text)
   end -- control.set_text

   ButtonBase.new(control, radio_group)
   control.release(false)
   return control
end -- new

return ProfileButton
