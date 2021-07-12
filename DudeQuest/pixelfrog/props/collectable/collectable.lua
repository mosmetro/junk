local Pool = require("m.pool")
local groups = require("m.groups")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local snd = require("sound.sound")

local DEPTH = layers.get_depth(layers.COLLECTABLE)

local runtime = runtime
local fastmath = fastmath
-- local vector3_set_xyz = fastmath.vector3_set_xyz
local set_position = go.set_position
local get_position = go.get_position
local delete = go.delete


local function make()
   local instance = {
      needs_down_pass = false,
      needs_up_pass = false,
      needs_left_pass = false,
      needs_right_pass = false,
      update_group = runtime.UPDATE_GROUP_BEFORE_PLAYER,
      GROUND = {
         groups.SOLID,
         groups.ONEWAY,
         groups.SLOPE,
         groups.BOX,
      },
      SOLIDS = {
         groups.SLOPE,
         groups.SOLID,
         groups.BOX,
      },
      CEILING = {
         groups.SOLID,
         groups.BOX,
      },
      SLOPES = {
         groups.SLOPE,
      },
      SLOPE = groups.SLOPE,
   }

   local root
   -- local x
   -- local y
   -- local vector3_stub = fastmath.vector3_stub
   local kind
   local variant
   local collect_vfx
   local collect_sfx

   local function destroy()
      delete(root, true)
   end -- destroy

   function instance.on_collision(other_instance)
      if other_instance and other_instance.on_collect then
         if not other_instance.on_collect(kind, variant) then return end
      end
      local pos = get_position(root)
      -- vector3_set_xyz(vector3_stub, x, y + 8, 0)
      factory.create(collect_vfx, pos, const.QUAT_IDENTITY, nil, 1)
      snd.play_sound(collect_sfx)
      destroy()
   end -- instance.collect_currency

   function instance.init(self)
      kind = self.kind
      variant = self.variant
      collect_vfx = self.collect_vfx
      collect_sfx = self.collect_sfx
      root = msg.url(".")
      local pivot = msg.url("pivot")
      local pos = get_position(pivot)
      fastmath.vector3_set_z(pos, DEPTH)
      set_position(pos, pivot)
      -- x, y = fastmath.vector3_get_components(get_position(root))
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end

local pool = Pool.new(make)

return {
   -- cleanup = cleanup,
   new = pool.new,
   free = pool.free,
}
