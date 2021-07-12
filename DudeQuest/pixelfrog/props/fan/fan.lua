local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
local groups = require("m.groups")
-- local utils = require("m.utils")
-- local debug_draw = require("m.debug_draw")

local game = require("pixelfrog.game.game")
local layers = require("pixelfrog.render.layers")
local snd = require("sound.sound")

local DEPTH = layers.get_depth(layers.PROPS)

local vector3_set_xy = fastmath.vector3_set_xy
local raycast = physics.raycast
local get_instance = runtime.get_instance
local SOLID = groups.SOLID

local vector3_stub = vmath.vector3()
local ray_start = vmath.vector3()
local ray_end = vmath.vector3()

local PROPELLER_WIDTH = 24
local MIN_ENTITY_WIDTH = 12
local MIN_ENTITY_HEIGHT = 22
local TARGET_GROUPS = {
   groups.ENTITY,
   groups.SOLID,
}

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_BEFORE_PLAYER,
   }

   local root
   local airflow_fx
   local fan_sprite
   local max_airflow_strength
   local airflow_length
   local rays_count
   local rays_spacing
   local x
   local y
   local aabb = { 0, 0, 0, 0 }

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function horizontal_update()
      if not fastmath.aabb_overlap(game.view_aabb, aabb) then return end

      local end_x = x + airflow_length
      local shared_y = y
      for _ = 1, rays_count do
         vector3_set_xy(ray_start, x, shared_y)
         vector3_set_xy(ray_end, end_x, shared_y)
         -- debug_draw.line(ray_start.x, ray_start.y, ray_end.x, ray_end.y)
         local hit = raycast(ray_start, ray_end, TARGET_GROUPS)
         if hit and (hit.group ~= SOLID) then
            local other_instance = get_instance(hit.id)
            if other_instance then
               other_instance.horizontal_drag = max_airflow_strength * (1 - hit.fraction)
            end
            -- break
         end
         shared_y = shared_y + rays_spacing
      end
      -- debug_draw.aabb(aabb)
   end -- horizontal_update

   local function vertical_update()
      if not fastmath.aabb_overlap(game.view_aabb, aabb) then return end

      local end_y = y + airflow_length
      local shared_x = x
      for _ = 1, rays_count do
         vector3_set_xy(ray_start, shared_x, y)
         vector3_set_xy(ray_end, shared_x, end_y)
         -- debug_draw.line(ray_start.x, ray_start.y, ray_end.x, ray_end.y)
         local hit = raycast(ray_start, ray_end, TARGET_GROUPS)
         if hit and (hit.group ~= SOLID) then
            local other_instance = get_instance(hit.id)
            if other_instance then
               other_instance.vertical_drag = max_airflow_strength
               if hit.id == game.player_id then
                  snd.play_sound(snd.VERTICAL_WIND)
               end
            end
            -- break
         end
         shared_x = shared_x + rays_spacing
      end
      -- debug_draw.aabb(aabb)
   end -- vertical_update

   function instance.init(self)
      root = msg.url(".")
      vector3_stub = go.get_position(root)
      x, y = fastmath.vector3_get_components(vector3_stub)
      max_airflow_strength = self.airflow_strength
      airflow_length = self.airflow_length
      local rotation_z = go.get(root, const.EULER_Z)
      if (rotation_z == 0) or (rotation_z == 180) then
         -- horizontal fan
         x = x - fastmath.sign(max_airflow_strength)
         y = y - PROPELLER_WIDTH * 0.5
         rays_count = math.ceil(PROPELLER_WIDTH / MIN_ENTITY_HEIGHT) + 1
         rays_spacing = PROPELLER_WIDTH / (rays_count - 1)
         runtime.add_update_callback(instance, horizontal_update)
      else
         -- vertical fan
         x = x - PROPELLER_WIDTH * 0.5
         y = y - fastmath.sign(max_airflow_strength)
         rays_count = math.ceil(PROPELLER_WIDTH / MIN_ENTITY_WIDTH) + 1
         rays_spacing = PROPELLER_WIDTH / (rays_count - 1)
         runtime.add_update_callback(instance, vertical_update)
      end
      airflow_fx = msg.url("airflow#airflow")
      particlefx.play(airflow_fx)
      fan_sprite = msg.url("fan#sprite")
      sprite.play_flipbook(fan_sprite, "fan_on")
      vector3_stub = go.get_position("fan")
      fastmath.vector3_set_z(vector3_stub, DEPTH)
      go.set_position(vector3_stub, "fan")
      aabb[1] = self.aabb_min_x
      aabb[2] = self.aabb_min_y
      aabb[3] = self.aabb_max_x
      aabb[4] = self.aabb_max_y
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
