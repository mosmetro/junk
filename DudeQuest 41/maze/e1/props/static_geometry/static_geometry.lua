local Pool = require("m.pool")
local nc = require("m.notification_center")
local CONST = require("m.constants")
-- local utils = require("m.utils")

local set_instance = runtime.set_instance

local function make()
   local instance = {
      can_jump_down = false,
      can_climb_up = true,
      is_static = true,
   }
   local root

   local function destroy()
      go.delete(root, true)
   end -- destroy

   function instance.collect_damage()
      return nil
   end

   function instance.init(self)
      root = msg.url(".")
      instance.can_jump_down = self.can_jump_down
      instance.can_climb_up = self.can_climb_up
      set_instance(root.path, instance)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      set_instance(root.path, nil)
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)



-- export
return {
   new = pool.new,
   free = pool.free,
   fill = pool.fill,
   purge = pool.purge,
   count = pool.count,
}
