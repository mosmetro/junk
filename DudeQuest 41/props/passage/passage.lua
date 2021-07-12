local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")

local gamestate = require("game.gamestate")

local function make()
   local instance = {
      x = 0,
      y = 0,
      is_horizontal = true
   }

   local root
   local collisionobject
   local exit_point
   local spawn_point

   local function destroy()
      go.delete(root, true)
   end -- destroy

   function instance.on_enter(other_instance)
      if other_instance.on_passage then
         msg.post(collisionobject, msg.DISABLE)
         other_instance.on_passage(instance)
      end
   end -- instance.on_enter

   function instance.get_exit_position()
      return fastmath.vector3_get_xy(go.get_world_position(exit_point))
   end -- instance.get_exit_position

   function instance.get_spawn_position()
      return fastmath.vector3_get_xy(go.get_world_position(spawn_point))
   end -- instance.get_spawn_position

   function instance.init(self)
      instance.map = gamestate[self.destination]
      instance.location = gamestate[self.passage]
      instance.is_horizontal = self.is_horizontal
      root = msg.url(".")
      exit_point = msg.url("exit_point")
      spawn_point = msg.url("spawn_point")
      collisionobject = msg.url("#collisionobject")
      instance.x, instance.y = fastmath.vector3_get_xy(go.get_position())
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
