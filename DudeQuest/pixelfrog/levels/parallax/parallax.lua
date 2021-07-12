local Pool = require("m.pool")
local const = require("m.constants")
local nc = require("m.notification_center")
-- local utils = require("m.utils")

-- local gamestate = require("pixelfrog.game.gamestate")
local game = require("pixelfrog.game.game")
local layers = require("pixelfrog.render.layers")

local vector3_set_xyz = fastmath.vector3_set_xyz
local vector3_set_z = fastmath.vector3_set_z
local vector3_stub = fastmath.vector3_stub
local set_position = go.set_position
local vector4_set_x = fastmath.vector4_set_x
local set_constant = sprite.set_constant

local PARALLAX_1 = layers.get_depth(layers.PARALLAX_1)
-- local PARALLAX_2 = layers.get_depth(layers.PARALLAX_2)
-- local PARALLAX_3 = layers.get_depth(layers.PARALLAX_3)
local PARALLAX_4 = layers.get_depth(layers.PARALLAX_4)
-- local PARALLAX_5 = layers.get_depth(layers.PARALLAX_5)
-- local PARALLAX_6 = layers.get_depth(layers.PARALLAX_6)
local PARALLAX_7 = layers.get_depth(layers.PARALLAX_7)
local PARALLAX_8 = layers.get_depth(layers.PARALLAX_8)
local PARALLAX_9 = layers.get_depth(layers.PARALLAX_9)

local offset = vmath.vector4()
local OFFSET = hash("offset")

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_LAST,
   }

   local root
   local layer_1
   -- local layer_2
   -- local layer_3
   local layer_4
   local cloud_near
   local cloud_far
   local sun
   local cloud_near_sprite
   local cloud_far_sprite

   local cloud_near_offset_x
   local cloud_far_offset_x

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function update(dt)
      local x = game.view_x
      local y = game.view_y
      vector3_set_xyz(vector3_stub, x * 0.7, y * 0.9, PARALLAX_1)
      set_position(vector3_stub, layer_1)

      -- vector3_set_xyz(vector3_stub, x * 0.7, y * 0.85, PARALLAX_2)
      -- set_position(vector3_stub, layer_2)

      -- vector3_set_xyz(vector3_stub, x * 0.8, y * 0.95, PARALLAX_3)
      -- set_position(vector3_stub, layer_3)

      vector3_set_xyz(vector3_stub, x * 0.9, y * 0.95, PARALLAX_4)
      set_position(vector3_stub, layer_4)

      vector4_set_x(offset, cloud_near_offset_x)
      set_constant(cloud_near_sprite, OFFSET, offset)
      cloud_near_offset_x = (cloud_near_offset_x > 1) and 0 or (cloud_near_offset_x + dt * 0.025)

      vector4_set_x(offset, cloud_far_offset_x)
      set_constant(cloud_far_sprite, OFFSET, offset)
      cloud_far_offset_x = (cloud_far_offset_x > 1) and 0 or (cloud_far_offset_x + dt * 0.01)
   end -- update

   function instance.init()
      root = msg.url(".")
      layer_1 = msg.url("layer_1")
      -- layer_2 = msg.url("layer_2")
      -- layer_3 = msg.url("layer_3")
      layer_4 = msg.url("layer_4")
      cloud_near = msg.url("cloud_near")
      cloud_far = msg.url("cloud_far")
      sun = msg.url("sun")
      vector3_set_xyz(vector3_stub, 0, 0, 0)
      set_position(vector3_stub, root)
      vector3_set_z(vector3_stub, PARALLAX_7)
      set_position(vector3_stub, cloud_near)
      vector3_set_z(vector3_stub, PARALLAX_8)
      set_position(vector3_stub, cloud_far)
      vector3_set_xyz(vector3_stub, game.view_right - 70, game.view_top - 30, PARALLAX_9)
      set_position(vector3_stub, sun)
      local scale = game.view_width / 1024
      vector3_set_xyz(vector3_stub, scale, scale, 1)
      go.animate(sun, const.SCALE, go.PLAYBACK_LOOP_PINGPONG, scale * 1.1, go.EASING_INOUTSINE, 3)
      -- go.set_scale(vector3_stub, root)
      go.set_scale(vector3_stub, layer_1)
      -- go.set_scale(vector3_stub, layer_2)
      -- go.set_scale(vector3_stub, layer_3)
      go.set_scale(vector3_stub, layer_4)
      go.set_scale(vector3_stub, cloud_near)
      go.set_scale(vector3_stub, cloud_far)
      go.set_scale(vector3_stub, sun)
      cloud_near_offset_x = 0
      cloud_far_offset_x = 0
      cloud_near_sprite = msg.url("cloud_near#sprite")
      cloud_far_sprite = msg.url("cloud_far#sprite")
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

return {
   new = pool.new,
   free = pool.free,
}
