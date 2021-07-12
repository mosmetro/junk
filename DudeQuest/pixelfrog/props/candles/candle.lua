local Pool = require("m.pool")
local nc = require("m.notification_center")
local CONST = require("m.constants")

local layers = require("pixelfrog.render.layers")

local DEPTH = layers.get_depth(layers.PROPS)

local hash = hash

local FIRE_ANIMATION = hash("candle_single_fire")
local offset_roll = fastmath.uniform_real(0, 1)
local properties = {
   offset = 0,
}

local vector3_stub = vmath.vector3()


local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_LAST,
   }
   local root
   local fire_sprite
   local platform

   local function destroy()
      -- runtime.remove_update_callback(instance)
      go.delete(root, true)
   end -- destroy

   local function platform_ready(_, _, parent)
      -- utils.log("setting parent")
      go.set_parent(root, parent, true)
   end -- platform_ready

   -- local function update()
   -- end -- update

   function instance.init(self)
      root = msg.url("root")
      fire_sprite = msg.url("candle#fire")
      properties.offset = offset_roll()
      sprite.play_flipbook(fire_sprite, FIRE_ANIMATION, nil, properties)
      platform = self.platform
      vector3_stub = go.get_position(root)
      fastmath.vector3_set_z(vector3_stub, DEPTH)
      go.set_position(vector3_stub, root)
      -- runtime.add_update_callback(instance, update)
      nc.add_observer(platform_ready, CONST.PLATFORM_READY_NOTIFICATION, platform)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      -- runtime.remove_update_callback(instance)
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.remove_observer(platform_ready, CONST.PLATFORM_READY_NOTIFICATION, platform)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
