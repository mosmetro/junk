local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")


local function make()
   local instance = {}
   local root

   local function destroy()
      go.delete(root, true)
   end -- destroy

   function instance.on_collision(other_instance)
      if other_instance and other_instance.on_instant_death then
         other_instance.on_instant_death()
      end
   end -- instance.on_collision

   function instance.init()
      root = msg.url(".")
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      runtime.set_instance(root.path, nil)
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
