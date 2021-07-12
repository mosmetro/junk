local LabelBase = require("m.ui.label_base")
local colors = require("m.colors")

local Prototype = {}

function Prototype.new(control)
   LabelBase.new(control)
   local color = control.color or colors.CONTROL_COLOR
   gui.set_color(control.title_node, color)

   function control.set_text(text)
      gui.set_text(control.title_node, text)
   end -- control.set_text

   return control
end -- new

return Prototype
