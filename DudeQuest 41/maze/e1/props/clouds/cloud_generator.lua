local Pool = require("m.pool")
local layers = require("m.layers")
local nc = require("m.notification_center")
local CONST = require("m.constants")
-- local snd = require("sound.sound")
local game = require("maze.game")
local utils = require("m.utils")
local debug_draw = require("m.debug_draw")

local global = require("game.global")

local go = go
local fastmath = fastmath

local FOREGROUND = layers.get_depth(layers.CLOUDS_FOREGROUND)

-- local vector3_stub
-- local TINT_W = hash("tint.w")
local IDENTITY = vmath.quat()

local spawn_time_roll = fastmath.uniform_real(2, 7)
local z_shift_roll = fastmath.uniform_real(-0.005, 0.005)
local y_shift_roll = fastmath.uniform_real(-2, 16)


local cloud_factory = msg.url("game:/entities#cloud_factory")

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_BEFORE_PLAYER,
   }
   local aabb = { 0, 0, 0, 0 }
   local root
   local length
   local direction
   local start_x
   local start_y
   local vector3_stub
   local next_spawn_time
   local position_x_roll
   local cloud_count_roll
   local cloud_properties = {
      start_x = 0,
      direction = 0,
   }

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function update()
      if not fastmath.aabb_overlap(global.view_aabb, aabb) then return end

      if runtime.current_time > next_spawn_time then
         local count = cloud_count_roll()
         for _ = 1, count do
            local x = position_x_roll()
            local y = start_y + y_shift_roll()
            local z = FOREGROUND-- + z_shift_roll()
            fastmath.vector3_set_xyz(vector3_stub, x, y, z)
            cloud_properties.start_x = x
            cloud_properties.direction = direction
            factory.create(cloud_factory, vector3_stub, IDENTITY, cloud_properties, 1)
         end
         next_spawn_time = runtime.current_time + spawn_time_roll()
      end
      -- debug_draw.aabb(aabb)
   end -- update

   function instance.set_active(active)
      if active then
         next_spawn_time = 0--runtime.current_time + spawn_time_roll()
         runtime.add_update_callback(instance, update)
      else
         runtime.remove_update_callback(instance)
      end
   end -- instance.set_active

   function instance.init(self)
      length = self.length
      root = msg.url(".")
      direction = fastmath.sign(length)
      vector3_stub = go.get_position()
      start_x, start_y = fastmath.vector3_get_components(vector3_stub)
      local end_x = start_x + length
      local max_clouds = self.max_clouds
      if max_clouds == 0 then
         max_clouds = math.ceil(fastmath.abs(length) / 100)
      end
      cloud_count_roll = fastmath.uniform_int(1, max_clouds)
      if start_x < end_x then
         position_x_roll = fastmath.uniform_real(start_x, end_x)
      else
         position_x_roll = fastmath.uniform_real(end_x, start_x)
      end
      -- utils.log(start_x, end_x, direction, max_clouds)

      aabb[1] = end_x - 16
      aabb[2] = start_y - 16
      aabb[3] = start_x + 16
      aabb[4] = start_y + 16

      instance.set_active(self.is_active)
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
