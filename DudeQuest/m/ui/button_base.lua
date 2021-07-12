local Control = require("m.ui.control")

local function new(control)
   local is_on = false
   local radio_group = control.radio_group
   if radio_group then
      radio_group[#radio_group + 1] = control
   end

   function control.is_on()
      return is_on
   end -- is_on

   function control.set_on(on)
      is_on = on
      -- if control.is_active then
         control.release()
      -- end
   end -- set_on

   function control.pointer_down_entered()
      control.press()
   end

   function control.pointer_down_exited()
      control.release()
   end

   function control.pointer_up_inside()
      if radio_group then
         if not is_on then
            is_on = true
            for _, button in next, radio_group do
               if button ~= control then
                  button.set_on(false)
               end
            end
            -- if control.callback then control:callback() end
         end
      else
         is_on = not is_on
         -- if control.callback then control:callback() end
      end
      if control.callback then control:callback() end
      control.release(true)
   end -- pointer_up_inside

   function control.pointer_up_outside ()
      control.release()
   end -- pointer_up_outside

   function control.pointer_cancelled ()
      control.release()
   end -- pointer_cancelled

   return Control.new(control)
end -- new

return {
   new = new,
}
