local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local snd = require("sound.sound")

local DEPTH =  layers.get_depth(layers.PROJECTILES)

local runtime = runtime
local fastmath = fastmath
local set_position = go.set_position
local get_position = go.get_position
local delete = go.delete

local AMMO_BOMB_EXPLOSION = hash("ammo_bomb_explosion")

local function make()
   local instance = {}
   local root
   local anchor
   local damage_points

   local function destroy()
      delete(root, true)
   end -- destroy

   function instance.on_collision(other_instance)
      utils.log("on_collision", runtime.current_frame)
      if other_instance.on_hit then
         other_instance.on_hit(nil, damage_points)
      end
   end -- instance.on_collision

   function instance.init(self)
      damage_points = self.damage_points
      root = msg.url(".")
      anchor = msg.url("anchor")
      local pos = get_position(anchor)
      fastmath.vector3_set_z(pos, DEPTH)
      set_position(pos, anchor)
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      -- snd.play_sound(snd.SHANTAE_ENEMY_EXPLODE)
      snd.play_sound(snd.SHANTAE_EXPLOSION_POPCORN_2)
      sprite.play_flipbook("anchor#sprite", AMMO_BOMB_EXPLOSION, destroy)
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
