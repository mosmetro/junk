local Pool = require("m.pool")
local layers = require("m.layers")
local nc = require("m.notification_center")
local CONST = require("m.constants")
local utils = require("m.utils")
-- local debug_draw = require("m.debug_draw")
-- local colors = require("m.colors")
local game = require("maze.game")
local PointLight = require("lighting.point_light")

local global = require("game.global")

local DEPTH = layers.get_depth(layers.LIGHTS)

local hash = hash

local FIRE_ANIMATION = hash("candle_single_fire")
local offset_roll = fastmath.uniform_real(0, 1)
local properties = {
   offset = 0,
}

local vector3_stub = vmath.vector3()
local aabb_overlap = fastmath.aabb_overlap


local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_LAST,
   }
   local root
   local candle
   local light_sprite
   local fire_sprite
   local platform
   local aabb = { 0, 0, 0, 0 }
   local point_light
   local aabb_min_x
   local aabb_min_y
   local aabb_max_x
   local aabb_max_y
   local light_data

   local function destroy()
      -- runtime.remove_update_callback(instance
      point_light.disable()
      go.delete(root, true)
   end -- destroy

   local function platform_ready(_, _, parent)
      -- utils.log("setting parent")
      go.set_parent(root, parent, true)
   end -- platform_ready

   local function update_aabb(box, x, y)
      box[1] = x + aabb_min_x
      box[2] = y + aabb_min_y
      box[3] = x + aabb_max_x
      box[4] = y + aabb_max_y
      -- debug_draw.aabb(box, colors.GREEN)
   end -- update_aabb

   local function update()
      local x, y = fastmath.vector3_get_xy(go.get_world_position(root))
      y = y + 14
      update_aabb(aabb, x, y)
      if aabb_overlap(global.view_aabb, aabb) then
         if not light_data then
            light_data = point_light.enable(aabb)
            if light_data then
               go.set(light_sprite, "material", light_data.light_material)
               msg.post(candle, msg.ENABLE)
               point_light.update(aabb, x, y)
            end
         else
            point_light.update(aabb, x, y)
         end
      elseif light_data then
         -- utils.log("NOT aabb_overlap")
         point_light.disable()
         go.set(light_sprite, "material", light_data.nodraw_material)
         light_data = nil
         msg.post(candle, msg.DISABLE)
      end
   end -- update

   function instance.init(self)
      aabb_min_x = self.min_x
      aabb_min_y = self.min_y
      aabb_max_x = self.max_x
      aabb_max_y = self.max_y
      root = msg.url("root")
      candle = msg.url("candle")
      light_sprite = msg.url("candle#light")
      fire_sprite = msg.url("candle#fire")
      properties.offset = offset_roll()
      sprite.play_flipbook(fire_sprite, FIRE_ANIMATION, nil, properties)
      platform = self.platform
      vector3_stub = go.get_position(root)
      fastmath.vector3_set_z(vector3_stub, DEPTH)
      go.set_position(vector3_stub, root)
      runtime.add_update_callback(instance, update)
      nc.add_observer(platform_ready, CONST.PLATFORM_READY_NOTIFICATION, platform)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      point_light = PointLight.new()
      light_data = nil
      msg.post(candle, msg.DISABLE)
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
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
