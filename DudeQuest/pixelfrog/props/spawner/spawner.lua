local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local debug_draw = require("m.debug_draw")
-- local utils = require("m.utils")


local ROOT = const.ROOT
local params = {
   [ROOT] = {
      velocity_x = 0,
      velocity_y = 0,
   },
}

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_LAST,
   }
   local root
   local name
   local sender
   local position
   local default_factory

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function spawn(_, factory_url, vx, vy)
      params[ROOT].velocity_x = vx or 0
      params[ROOT].velocity_y = vy or 0.1
      collectionfactory.create(factory_url or default_factory, position, const.QUAT_IDENTITY, params, 1)
   end -- spawn

   function instance.init(self)
      name = self.name
      sender = (self.sender ~= const.EMPTY) and self.sender or nil
      default_factory = self.default_factory
      root = msg.url(".")
      position = go.get_position(root)
      nc.add_observer(spawn, name, sender)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      if self.spawn_on_init then
         spawn()
      end
   end -- instance.init

   function instance.deinit()
      -- remove_update_callback(instance)
      nc.remove_observer(spawn, name, sender)
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
