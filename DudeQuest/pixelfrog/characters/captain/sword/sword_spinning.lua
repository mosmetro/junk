local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
local groups = require("m.groups")
-- local debug_draw = require("m.debug_draw")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local game = require("pixelfrog.game.game")
-- local snd = require("sound.sound")
local factories = require("pixelfrog.game.factories")

local DEPTH = layers.get_depth(layers.EFFECT_BACK)

local vector3_stub = fastmath.vector3_stub
local vector3_set_xy = fastmath.vector3_set_xy
local vector3_set_xyz = fastmath.vector3_set_xyz
local aabb_overlap = fastmath.aabb_overlap
local sign = fastmath.sign
local abs = fastmath.abs
local set_position = go.set_position
local raycast = physics.raycast
local get_instance = runtime.get_instance

local ray_start = fastmath.ray_start
local ray_end = fastmath.ray_end
local TARGET_GROUPS = {
   groups.ENEMY_HITBOX,
   groups.SOLID,
   groups.SLOPE,
}

local SWORD_EMBEDDED_R_FACTORY = msg.url("game:/characters#sword_embedded_r")
local SWORD_EMBEDDED_L_FACTORY = msg.url("game:/characters#sword_embedded_l")

-- local HIT_ENEMY_SOUNDS = {
--    snd.FATE_METAL_FLESH_1,
--    snd.FATE_METAL_FLESH_2,
--    snd.FATE_METAL_FLESH_3,
-- }

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
   local aabb = { 0, 0, 0, 0 }

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function update_aabb()
      aabb[1] = x - 16
      aabb[2] = y - 16
      aabb[3] = x + 16
      aabb[4] = y + 16
   end -- update_aabb

   local function update(dt)
      update_aabb()
      -- debug_draw.aabb(aabb)
      if not aabb_overlap(game.view_aabb, aabb) then
         destroy()
         return
      end
      local dx = speed * dt
      vector3_set_xy(ray_start, x, y)
      vector3_set_xy(ray_end, x + sign(speed) * 16, y)
      -- debug_draw.line(ray_start.x, ray_start.y, ray_end.x, ray_end.y)
      local ray_hit = raycast(ray_start, ray_end, TARGET_GROUPS)
      if ray_hit then
         local target_instance = get_instance(ray_hit.id)
         if target_instance and target_instance.on_hit then
            local target_dx = target_instance.dx or 0
            if (ray_hit.fraction * 16) <= abs(dx - target_dx) then
               collectionfactory.create(factories.EFFECT_SWORD_HIT, ray_hit.position, const.QUAT_IDENTITY, nil, 1)
               if target_instance.on_hit(nil, damage_points, 0) then
                  -- snd.play_sound(snd.FATE_WOOD_FLESH_1)
                  collectionfactory.create(speed > 0 and SWORD_EMBEDDED_R_FACTORY or SWORD_EMBEDDED_L_FACTORY, ray_hit.position, const.QUAT_IDENTITY, nil, 1)
                  nc.post_notification(const.CAMERA_SHAKE_REQUEST_NOTIFICATION, nil, 3, 0.15)
               end
               destroy()
               return
            end
         end
      end
      x = x + dx
      vector3_set_xyz(vector3_stub, x, y, 0)
      set_position(vector3_stub, root)
   end -- update

   function instance.init(self)
      root = msg.url(".")
      speed = self.speed
      damage_points = self.damage_points
      sprite.set_hflip("pivot#sprite", speed < 0)
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
