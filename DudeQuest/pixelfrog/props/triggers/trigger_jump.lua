local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")

local get_instance = runtime.get_instance

local function make()
   local instance = {
   }
   local root
   local jump_speed

   local function destroy()
      go.delete(root, true)
   end -- destroy

   function instance.on_trigger_response(message)
      if message.enter then
         local other_instance = get_instance(message.other_id)
         if other_instance and other_instance.command_jump then
            -- empirical value
            other_instance.command_jump(jump_speed)
         end
      end
   end -- instance.on_trigger_response

   function instance.init(self)
      jump_speed = self.jump_speed
      root = msg.url(".")
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

-- export
return {
   new = pool.new,
   free = pool.free,
}
