local ButtonBase = require("m.ui.button_base")
local colors = require("m.colors")
-- local utils = require("m.utils")

local gui = gui

local Prototype = {}

function Prototype.new(control)
   local title_node = control.title_node
   control.aabb = control.aabb or { -30, -14, 30, 8, }
   local color = control.color or colors.CONTROL_COLOR
   local selected_color = control.selected_color or colors.CONTROL_SELECTED_COLOR
   local disabled_color = control.disabled_color or colors.CONTROL_DISABLED_COLOR

   function control.press()
      gui.cancel_animation(title_node, gui.PROP_COLOR)
      gui.set_color(title_node, selected_color)
   end -- control.press

   function control.release(inside)
      gui.animate(title_node, gui.PROP_COLOR, color, gui.EASING_LINEAR, 0.2)
   end -- control.release

   function control.on_enable(animated)
      if animated then
         gui.animate(title_node, gui.PROP_COLOR, color, gui.EASING_LINEAR, 0.2)
      else
         gui.cancel_animation(title_node, gui.PROP_COLOR)
         gui.set_color(title_node, color)
      end
   end -- control.on_enable

   function control.on_disable(animated)
      if animated then
         gui.animate(title_node, gui.PROP_COLOR, disabled_color, gui.EASING_LINEAR, 0.2)
      else
         gui.cancel_animation(title_node, gui.PROP_COLOR)
         gui.set_color(title_node, disabled_color)
      end
   end -- control.on_disable

   function control.set_text(text)
      gui.set_text(control.title_node, text)
   end -- control.set_text

   ButtonBase.new(control)
   control.release(false)
   return control
end -- new

return Prototype
