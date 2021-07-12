local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
local utils = require("m.utils")

local gamestate = require("pixelfrog.game.gamestate")

local function make()
   local instance = {
      x = 0,
      y = 0,
      is_teleport = true,
   }

   local root

   local function destroy()
      go.delete(root, true)
   end -- destroy

   function instance.init(self)
      -- instance.map = self.map
      -- instance.location = self.location
      instance.map = gamestate[self.map]
      instance.location = gamestate[self.location]
      -- utils.log(self.map, "->", instance.map)
      -- utils.log(self.location, "->", instance.location)
      root = msg.url(".")
      msg.post("#collisionobject", msg.DISABLE)
      msg.post("anchor#sprite", msg.DISABLE)
      instance.x, instance.y = fastmath.vector3_get_components(go.get_position(root))
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      -- gamestate.set(nil, gamestate.player, "last_checkpoint", { map = gamestate[instance.map], location = gamestate[instance.location] })
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
