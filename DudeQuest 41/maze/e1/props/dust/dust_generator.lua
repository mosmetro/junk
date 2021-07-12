local Pool = require("m.pool")
local layers = require("m.layers")
local nc = require("m.notification_center")
local CONST = require("m.constants")
local game = require("maze.game")
-- local utils = require("m.utils")

local global = require("game.global")

local go = go
local fastmath = fastmath

local FOREGROUND = layers.get_depth(layers.DUST_FOREGROUND)

local vector3_stub = vmath.vector3()
local IDENTITY = vmath.quat()
local spawn_time_roll = fastmath.uniform_real(0.2, 2)

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_LAST,
   }
   local root
   local next_spawn_time
   local position_x_roll
   local position_y_roll
   local max_dust
   local dust_factory

   local function destroy()
      runtime.remove_update_callback(instance)
      go.delete(root, true)
   end -- destroy

   local function update()
      -- utils.log(game.dust_count)
      if game.dust_count < max_dust then
         next_spawn_time = 0
      else
         return
      end
      if runtime.current_time > next_spawn_time then
         local x = (global.view_x or 0) + position_x_roll()
         local y = (global.view_y or 0) + position_y_roll()
         local z = FOREGROUND
         fastmath.vector3_set_xyz(vector3_stub, x, y, z)
         factory.create(dust_factory, vector3_stub, IDENTITY, nil, 1)
         game.dust_count = game.dust_count + 1
         next_spawn_time = runtime.current_time + spawn_time_roll()
      end
   end -- update

   function instance.set_active(active)
      if active then
         runtime.add_update_callback(instance, update)
      else
         runtime.remove_update_callback(instance)
      end
   end -- instance.set_active

   function instance.init(self)
      root = msg.url(".")
      dust_factory = self.dust_factory
      max_dust = self.max_dust
      instance.set_active(self.is_active)
      game.dust_count = 0
      position_x_roll = fastmath.uniform_real(-game.view_half_width, game.view_half_width)
      position_y_roll = fastmath.uniform_real(-game.view_half_height, game.view_half_height)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
