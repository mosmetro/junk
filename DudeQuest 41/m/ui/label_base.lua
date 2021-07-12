local Control = require("m.ui.control")

local function new(control)
   Control.new(control)

   function control.hit_test()
      return false
   end

   function control.enable()
   end

   function control.disable()
   end

   return control
end -- new

return {
   new = new,
}
