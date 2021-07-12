local Pool = require("m.pool")
local StateMachine = require("m.state_machine")
local groups = require("m.groups")
local const = require("m.constants")
local nc = require("m.notification_center")
local animation = require("m.animation")
-- local utils = require("m.utils")
-- local debug_draw = require("m.debug_draw")

local layers = require("pixelfrog.render.layers")
local game = require("pixelfrog.game.game")
local snd = require("sound.sound")

local play_animation = animation.play
local vmath = vmath
local set_position = go.set_position
local abs = fastmath.abs
local sign = fastmath.sign
local clamp = fastmath.clamp
-- local min = fastmath.min
-- local max = fastmath.max
local vector3_set_xyz = fastmath.vector3_set_xyz
local vector3_set_xy = fastmath.vector3_set_xy
local vector3_get_x = fastmath.vector3_get_x
-- local get_instance = runtime.get_instance

-- local INFINITY = const.INFINITY
local DEPTH = layers.get_depth(layers.ENEMIES)
local MAX_HORIZONTAL_SPEED = 40
local MAX_FALL_SPEED = -500
local MAX_RISE_SPEED = 600
local GROUND_ACCELERATION = 2000
local MAX_AIR_SPEED = 80
local AIR_ACCELERATION = 2000
local JUMP_HEIGHT = 56--56
local JUMP_TIME_TO_APEX = 0.34--0.3--0.38
local NORMAL_GRAVITY = -(2 * JUMP_HEIGHT) / (JUMP_TIME_TO_APEX * JUMP_TIME_TO_APEX)
local JUMP_SPEED = abs(NORMAL_GRAVITY) * JUMP_TIME_TO_APEX
-- utils.log("gravity ", NORMAL_GRAVITY, "jump_speed ", JUMP_SPEED)
local vector3_stub = fastmath.vector3_stub
local ray_start = fastmath.ray_start
local ray_end = fastmath.ray_end
local HIT_SOUNDS = {
   snd.FATE_SLICE_FLESH_1,
   snd.FATE_SLICE_FLESH_2,
   snd.FATE_SLICE_FLESH_3,
}
local DIE_SOUNDS = {
   snd.FATE_DEMON_DIE1,
   snd.FATE_DEMON_DIE2,
   snd.FATE_DEMON_DIE3,
}
local TARGET_GROUPS = {
   groups.PLAYER_HITBOX,
   groups.SOLID,
}
local BULLET_FACTORY_R = msg.url("game:/enemies#plant_bullet_r")
local BULLET_FACTORY_L = msg.url("game:/enemies#plant_bullet_l")
local bullet_properties = {
   [const.ROOT] = {
      speed = 0,
      damage_points = 0,
      hit_soundfx = snd.FATE_WOOD_FLESH_1,
   }
}

local SHOT_TIME = (1 / 20) * 4

-- local idle_time_roll = fastmath.uniform_real(1, 2)
local dead_speed_roll = fastmath.uniform_real(0, MAX_AIR_SPEED)

local IDLE = {
   { id = hash("plant_idle"), position = vmath.vector3(0, 18, 0), },
}
local HIT = {
   { id = hash("plant_hit"), position = vmath.vector3(1, 18, 0), },
}
local ATTACK = {
   { id = hash("plant_attack"), position = vmath.vector3(4, 21, 0), },
}

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_BEFORE_PLAYER,
      x = 0,
      y = 0,
      dx = 0,
      dy = 0,
      horizontal_look = 1,
   }

   local char = animation.new_target()

   local debug_label
   local move_direction
   local previous_horizontal_look
   local max_horizontal_speed
   local velocity_x
   local velocity_y
   local acceleration
   local gravity
   local root
   local collisionobject_hitbox
   local collisionobject_hurtbox
   local health_points
   local damage_points
   local bullet_damage_points
   local next_attack_time
   local activator
   local shots_per_attack
   local shots_fired
   local bullet_speed
   local reloading
   local next_shot_time
   local aabb = { 0, 0, 0, 0 }

   local idle = {}
   local hit = {}
   local dead = {}
   local attack = {}

   local machine = StateMachine.new(nil)

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function turnaround(target)
      if instance.horizontal_look == previous_horizontal_look then return end
      previous_horizontal_look = instance.horizontal_look
      go.set_rotation(instance.horizontal_look > 0 and const.QUAT_Y_0 or const.QUAT_Y_180, target.pivot)
   end -- turnaround

   local function move(dt, dir, acc, spd, grav)
      local target_speed_x = (dir or move_direction) * (spd or max_horizontal_speed) + instance.horizontal_drag
      local speed_diff_x = target_speed_x - velocity_x
      local acceleration_x = (acc or acceleration) * sign(speed_diff_x)
      local delta_velocity_x = acceleration_x * dt
      if abs(delta_velocity_x) > abs(speed_diff_x) then
         delta_velocity_x = speed_diff_x
      end
      local old_velocity_x = velocity_x
      velocity_x = velocity_x + delta_velocity_x
      local dx = (old_velocity_x + velocity_x) * 0.5 * dt
      local old_velocity_y = velocity_y
      velocity_y = velocity_y + (grav or gravity) * dt + instance.vertical_drag
      velocity_y = clamp(velocity_y, MAX_FALL_SPEED, MAX_RISE_SPEED)
      local dy = (old_velocity_y + velocity_y) * 0.5 * dt
      return dx, dy
   end -- move

   local function check_target()
      vector3_set_xy(ray_start, instance.x, instance.y + 16)
      vector3_set_xy(ray_end, instance.x + game.view_width * 0.5 * instance.horizontal_look, instance.y + 16)
      local ray_hit = physics.raycast(ray_start, ray_end, TARGET_GROUPS)
      -- debug_draw.line(ray_start.x, ray_start.y, ray_end.x, ray_end.y)
      if ray_hit and (ray_hit.group ~= groups.SOLID) then
         return vector3_get_x(ray_hit.position)
      end
      return nil
   end -- check_target

   local function update_aabb()
      aabb[1] = instance.x - 16
      aabb[2] = instance.y
      aabb[3] = instance.x + 16
      aabb[4] = instance.y + 32
   end -- update_aabb

   local function update(dt)
      machine.update(dt)
   end -- update

   local function activate()
      runtime.add_update_callback(instance, update)
   end -- activate

   local function deactivate()
      shots_fired = 0
      reloading = false
      machine.enter_state(idle)
      runtime.remove_update_callback(instance)
   end -- deactivate

   ---------------------------------------
   -- idle
   ---------------------------------------

   function idle.on_enter()
      label.set_text(debug_label, "Idle")
      play_animation(char, IDLE)
      next_attack_time = runtime.current_time + 1
   end -- idle.on_enter

   function idle.update()
      if runtime.current_time > next_attack_time then
         if check_target() then
            machine.enter_state(attack)
         end
      end
   end -- idle.update

   ---------------------------------------
   -- hit
   ---------------------------------------

   local function on_hit_complete()
      if machine.previous_state() ~= hit then
         machine.revert_to_previous_state()
      end
   end -- on_hit_complete

   function hit.on_enter()
      label.set_text(debug_label, "Hit")
      play_animation(char, HIT, nil, on_hit_complete)
   end -- hit.on_enter

   ---------------------------------------
   -- dead
   ---------------------------------------

   function dead.on_enter()
      label.set_text(debug_label, "Dead")
      play_animation(char, HIT, nil, animation.done_sink)
      snd.play_sound(fastmath.pick_any(DIE_SOUNDS))
      go.animate(char.anchor, const.EULER_Z, go.PLAYBACK_LOOP_FORWARD, 360, go.EASING_LINEAR, 2)
      msg.post(collisionobject_hitbox, msg.DISABLE)
      msg.post(collisionobject_hurtbox, msg.DISABLE)
      nc.remove_observer(deactivate, const.DEACTIVATE_NOTIFICATION, activator)
      velocity_x = 0
      velocity_y = JUMP_SPEED * 0.8
      nc.post_notification(const.CAMERA_SHAKE_REQUEST_NOTIFICATION, nil, 6, 0.15)
   end -- dead.on_enter

   function dead.update(dt)
      update_aabb()
      -- debug_draw.aabb(aabb)
      if not fastmath.aabb_overlap(game.view_aabb, aabb) then
         destroy()
         return
      end
      local dx, dy = move(dt * 1.2, -instance.horizontal_look, AIR_ACCELERATION, dead_speed_roll(), NORMAL_GRAVITY)
      instance.x = instance.x + dx
      instance.y = instance.y + dy
      vector3_set_xyz(vector3_stub, instance.x, instance.y, 0)
      set_position(vector3_stub, root)
   end -- dead.update

   ---------------------------------------
   -- attack
   ---------------------------------------

   local function on_shot_complete()
      if shots_fired < shots_per_attack then
         char.current_animation = nil
         play_animation(char, ATTACK, nil, on_shot_complete)
         reloading = false
         next_shot_time = runtime.current_time + SHOT_TIME
      else
         machine.enter_state(idle)
      end
   end -- on_shot_complete

   function attack.on_enter(previous_state)
      label.set_text(debug_label, "Attack")
      play_animation(char, ATTACK, nil, on_shot_complete)
      if previous_state ~= hit then
         shots_fired = 0
      end
      reloading = false
      next_shot_time = runtime.current_time + SHOT_TIME
   end -- attack.on_enter

   function attack.update()
      if (not reloading) and (runtime.current_time > next_shot_time) then
         shots_fired = shots_fired + 1
         reloading = true
         local direction = instance.horizontal_look
         vector3_set_xyz(vector3_stub, instance.x + direction * 8, instance.y + 23, 0)
         bullet_properties[const.ROOT].speed = bullet_speed * direction
         bullet_properties[const.ROOT].damage_points = bullet_damage_points
         collectionfactory.create((direction > 0) and BULLET_FACTORY_R or BULLET_FACTORY_L, vector3_stub, const.QUAT_IDENTITY, bullet_properties, 1)
         snd.play_sound(snd.FATE_BOWMISS)
         -- utils.log("fire!", shots_fired, runtime.current_frame)
      end
      -- end
   end -- attack.update

   function instance.on_collision(other_instance)
      if other_instance and other_instance.on_hit then
         other_instance.on_hit(snd.SHANTAE_GETHIT, damage_points, 0)
      end
   end -- instance.on_collision

   function instance.on_hit(sfx, dp, speed)
      health_points = health_points - (dp or 0)
      velocity_x = clamp(velocity_x + (speed or 0), -200, 200)
      if sfx then
         snd.play_sound(sfx)
      else
         snd.play_sound(fastmath.pick_any(HIT_SOUNDS, 2))
      end
      if health_points > 0 then
         machine.enter_state(hit)
      else
         machine.enter_state(dead)
      end
   end -- instance.on_hit

   function instance.on_jump(sfx, dp, speed)
      instance.on_hit(sfx, dp, speed)
      return 150 -- recoil velocity
   end -- instance.on_jump

   function instance.init(self)
      activator = self.activator
      health_points = self.health_points
      damage_points = self.damage_points
      bullet_damage_points = self.bullet_damage_points
      shots_per_attack = self.shots_per_attack
      bullet_speed = self.bullet_speed
      instance.horizontal_look = self.horizontal_look
      move_direction = 0
      debug_label = msg.url("#debug_label")
      msg.post(debug_label, msg.DISABLE)
      root = msg.url(".")
      instance.x, instance.y = fastmath.vector3_get_components(go.get_position(root))
      char.pivot = msg.url("pivot")
      char.anchor = msg.url("anchor")
      char.sprite = msg.url("anchor#sprite")
      char.current_animation_group = nil
      char.current_animation = nil
      char.on_complete = nil
      collisionobject_hitbox = msg.url("#collisionobject_hitbox")
      collisionobject_hurtbox = msg.url("#collisionobject_hurtbox")
      vector3_set_xyz(vector3_stub, 0, 0, DEPTH)
      set_position(vector3_stub, char.pivot)
      acceleration = GROUND_ACCELERATION
      max_horizontal_speed = MAX_HORIZONTAL_SPEED
      gravity = NORMAL_GRAVITY
      velocity_x = 0
      velocity_y = 0
      instance.horizontal_drag = 0
      instance.vertical_drag = 0
      previous_horizontal_look = 0
      next_attack_time = 0
      turnaround(char)
      runtime.set_instance(root.path, instance)
      if activator == const.EMPTY then
         runtime.add_update_callback(instance, update)
      else
         nc.add_observer(activate, const.ACTIVATE_NOTIFICATION, activator)
         nc.add_observer(deactivate, const.DEACTIVATE_NOTIFICATION, activator)
      end
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      machine.reset()
      machine.enter_state(idle)
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.remove_observer(activate, const.ACTIVATE_NOTIFICATION, activator)
      nc.remove_observer(deactivate, const.DEACTIVATE_NOTIFICATION, activator)
   end -- instance.deinit

   return instance
end

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
