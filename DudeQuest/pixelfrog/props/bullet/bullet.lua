local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
local groups = require("m.groups")
-- local debug_draw = require("m.debug_draw")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local game = require("pixelfrog.game.game")

local DEPTH = layers.get_depth(layers.PROJECTILES)

local vector3_stub = fastmath.vector3_stub
local vector3_set_xy = fastmath.vector3_set_xy
local vector3_set_xyz = fastmath.vector3_set_xyz
local aabb_overlap = fastmath.aabb_overlap
local set_position = go.set_position
local raycast = physics.raycast
local get_instance = runtime.get_instance

local ray_start = fastmath.ray_start
local ray_end = fastmath.ray_end
local TARGET_GROUPS = {
   groups.PLAYER_HITBOX,
   groups.SOLID,
}

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_BEFORE_PLAYER,
   }
   local root
   local x
   local y
   -- local z
   local speed
   local damage_points
   local hit_soundfx
   local debris_factory
   local aabb = { 0, 0, 0, 0 }

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function update_aabb()
      aabb[1] = x - 40
      aabb[2] = y - 16
      aabb[3] = x + 40
      aabb[4] = y + 16
      -- debug_draw.aabb(aabb)
   end -- update_aabb

   local function update(dt)
      update_aabb()
      if not aabb_overlap(game.view_aabb, aabb) then
         destroy()
         return
      end
      -- local dx = speed * dt
      -- local ray_length = fastmath.abs(dx) + 1
      -- local direction = fastmath.sign(dx)
      -- local start_x = x + 4 * direction
      -- vector3_set_xy(ray_start, x + 4 * direction, y)
      -- vector3_set_xy(ray_end, start_x + ray_length * direction, y)
      -- local ray_hit = raycast(ray_start, ray_end, TARGET_GROUPS)
      local dx = speed * dt
      vector3_set_xy(ray_start, x, y)
      vector3_set_xy(ray_end, x + dx, y)
      local ray_hit = raycast(ray_start, ray_end, TARGET_GROUPS)
      -- debug_draw.line(ray_start.x, ray_start.y, ray_end.x, ray_end.y)
      if ray_hit then
         local other_instance = get_instance(ray_hit.id)
         instance.on_collision(other_instance)
         return
      end
      x = x + dx
      vector3_set_xyz(vector3_stub, x, y, 0)
      set_position(vector3_stub, root)
   end -- update

   function instance.on_collision(other_instance)
      if other_instance and other_instance.on_hit then
         other_instance.on_hit(hit_soundfx, damage_points, speed)
      end
      vector3_set_xy(vector3_stub, x, y, 0)
      -- collectionfactory.create(url, position, rotation, properties, scale)
      collectionfactory.create(debris_factory, vector3_stub, const.QUAT_IDENTITY, nil, 1)
      destroy()
   end -- instance.on_collision

   function instance.init(self)
      root = msg.url(".")
      speed = self.speed
      damage_points = self.damage_points
      hit_soundfx = self.hit_soundfx
      debris_factory = self.debris_factory
      x, y = fastmath.vector3_get_components(go.get_position(root))
      fastmath.vector3_set_xyz(vector3_stub, 0, 0, DEPTH)
      set_position(vector3_stub, "pivot")
      runtime.set_instance(root.path, instance)
      runtime.add_update_callback(instance, update)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      runtime.set_instance(root.path, nil)
      runtime.remove_update_callback(instance)
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
