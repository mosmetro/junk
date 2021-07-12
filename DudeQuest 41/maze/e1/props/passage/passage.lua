local Pool = require("m.pool")
local nc = require("m.notification_center")
local CONST = require("m.constants")
local utils = require("m.utils")

local function make()
   local instance = {
      x = 0,
      y = 0,
      is_passage = true,
   }

   local root
   local is_horizontal

   local function destroy()
      go.delete(root, true)
   end -- destroy

   function instance.transit(player_x, player_y)
      local shift = 0
      local elevation = 0
      if is_horizontal then
         elevation = player_y - instance.y
      else
         shift = player_x - instance.x
      end
      return shift, elevation
   end

   function instance.init(self)
      instance.map = self.destination_map
      instance.location = self.destination_passage
      is_horizontal = self.is_horizontal
      root = msg.url(".")
      instance.x, instance.y = fastmath.vector3_get_components(go.get_position())
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

-- export
return {
   new = pool.new,
   free = pool.free,
}
