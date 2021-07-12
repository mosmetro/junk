local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
local animation = require("m.animation")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local snd = require("sound.sound")
local factories = require("pixelfrog.game.factories")

local DEPTH = layers.get_depth(layers.PROPS)
-- local FIRE_EFFECT_DEPTH = layers.get_depth(layers.PROJECTILES) + 0.001

local hash = hash
local play_animation = animation.play
local vector3_get_xy = fastmath.vector3_get_xy
local vector3_set_xyz = fastmath.vector3_set_xyz
local vector3_stub = fastmath.vector3_stub

local ANIMATION = {
   IDLE = {
      { id = hash("cannon_idle"), position = vmath.vector3(0, 9, 0), },
   },
   FIRE = {
      { id = hash("cannon_fire"), position = vmath.vector3(7, 11, 0), },
   },
}

local BLANK = hash("blank")
local CANNON_FIRE_EFFECT = hash("cannon_fire_effect")

local bullet_properties = {
   [const.ROOT] = {
      speed = 0,
      damage_points = 0,
      hit_soundfx = snd.SHANTAE_EXPLOSION_LARGE_FLANGE
   }
}

local function make()
   local instance = {}

   local root
   local name
   local char = animation.new_target()
   local fire_effect_sprite
   local bullet_damage_points
   local bullet_speed

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function fire_complete()
      play_animation(char, ANIMATION.IDLE)
      sprite.play_flipbook(fire_effect_sprite, BLANK)
   end -- fire_complete

   local function fire()
      play_animation(char, ANIMATION.FIRE, nil, fire_complete)
      sprite.play_flipbook(fire_effect_sprite, CANNON_FIRE_EFFECT)
      snd.play_sound(snd.SHANTAE_CANNON_SHOT)
      local x, y = vector3_get_xy(go.get_world_position(root))
      vector3_set_xyz(vector3_stub, x + instance.direction * 8, y + 11, 0)
      bullet_properties[const.ROOT].speed = bullet_speed * instance.direction
      bullet_properties[const.ROOT].damage_points = bullet_damage_points
      collectionfactory.create(factories.CANNON_BALL, vector3_stub, const.QUAT_IDENTITY, bullet_properties, 1)
   end -- fire

   local function on_command(_, command, other_instance)
      if command == 1 then
         other_instance.cannon = root.path
      elseif command == 2 then
         fire()
      end
   end -- on_command

   function instance.get_mount_point()
      local x, y = vector3_get_xy(go.get_world_position(root))
      return x - instance.direction * 24, y
   end -- instance.get_mount_point

   function instance.init(self)
      name = self.name
      bullet_damage_points = self.bullet_damage_points
      bullet_speed = self.bullet_speed
      instance.direction = self.direction
      root = msg.url(".")
      char.pivot = msg.url("pivot")
      char.anchor = msg.url("anchor")
      char.sprite = msg.url("anchor#sprite")
      char.current_animation_group = nil
      char.current_animation = nil
      char.on_complete = nil
      char.previous_horizontal_look = 0
      fire_effect_sprite = msg.url("pivot#fire_effect_sprite")
      vector3_set_xyz(fastmath.vector3_stub, 0, 0, DEPTH)
      go.set_position(fastmath.vector3_stub, char.pivot)
      go.set_rotation((instance.direction == 1) and const.QUAT_Y_0 or const.QUAT_Y_180, char.pivot)
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.add_observer(on_command, name)
   end -- instance.init

   function instance.deinit()
      runtime.set_instance(root.path, nil)
      nc.remove_observer(on_command, name)
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
