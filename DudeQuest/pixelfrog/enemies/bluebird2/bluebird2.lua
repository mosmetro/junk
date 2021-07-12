local Pool = require("m.pool")
local StateMachine = require("m.state_machine")
local const = require("m.constants")
local nc = require("m.notification_center")
local animation = require("m.animation")
local utils = require("m.utils")
-- local debug_draw = require("m.debug_draw")
-- local colors = require("m.colors")

local layers = require("pixelfrog.render.layers")
local game = require("pixelfrog.game.game")
local snd = require("sound.sound")

local play_animation = animation.play
local vmath = vmath
local set_position = go.set_position
local get = go.get
local abs = fastmath.abs
local sign = fastmath.sign
local clamp = fastmath.clamp
local vector3_set_xyz = fastmath.vector3_set_xyz
local ceil = math.ceil
local cos = math.cos
local sin = math.sin

local DEPTH = layers.get_depth(layers.ENEMIES)

local MAX_HORIZONTAL_SPEED = 40
local MAX_FALL_SPEED = -500
local MAX_RISE_SPEED = 600
local GROUND_ACCELERATION = 2000
local MAX_AIR_SPEED = 100
local AIR_ACCELERATION = 2000
local JUMP_HEIGHT = 56--56
local JUMP_TIME_TO_APEX = 0.34--0.3--0.38
local NORMAL_GRAVITY = -(2 * JUMP_HEIGHT) / (JUMP_TIME_TO_APEX * JUMP_TIME_TO_APEX)
local JUMP_SPEED = abs(NORMAL_GRAVITY) * JUMP_TIME_TO_APEX
-- utils.log("gravity ", NORMAL_GRAVITY, "jump_speed ", JUMP_SPEED)
local vector3_stub = fastmath.vector3_stub

local dead_speed_roll = fastmath.uniform_real(0, MAX_AIR_SPEED)

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

local FLY = {
   { id = hash("bluebird_fly"), position = vmath.vector3(5, 0, 0), },
}
local HIT = {
   { id = hash("bluebird_hit"), position = vmath.vector3(5, 0, 0), },
}

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_MOTOR_PLATFORMS,
      x = 0,
      y = 0,
      dx = 0,
      dy = 0,
      horizontal_look = 0,
      horizontal_drag = 0,
      vertical_drag = 0,
   }
   local move_direction
   local max_horizontal_speed
   local debug_label
   local acceleration
   local gravity
   local velocity_x
   local velocity_y
   local root
   local collisionobject_hitbox
   local collisionobject_hurtbox
   local health_points
   local damage_points
   local effect
   local aabb = { 0, 0, 0, 0 }
   local fly_angle
   local fly_speed
   local fly_radius_x
   local fly_radius_y
   local fly_factor_x
   local fly_factor_y
   local pivot_x
   local pivot_y

   local fly = {}
   local hit = {}
   local dead = {}

   local char = animation.new_target()
   local machine = StateMachine.new(nil)

   local function destroy()
      go.delete(root, true)
   end -- destroy

   -- https://ru.wikipedia.org/wiki/Фигуры_Лиссажу
   local function curve(dt)
      fly_angle = fly_angle + fly_speed * dt
      local cs = cos(fly_factor_x * fly_angle)
      local sn = sin(fly_factor_y * fly_angle)
      local new_x = pivot_x + cs * fly_radius_x
      local new_y = pivot_y + sn * fly_radius_y
      return new_x - instance.x, new_y - instance.y
   end -- curve

   local function update(dt)
      machine.update(dt)
   end -- update

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

   local function update_aabb()
      aabb[1] = instance.x - 16
      aabb[2] = instance.y - 16
      aabb[3] = instance.x + 16
      aabb[4] = instance.y + 16
   end -- update_aabb

   local function turnaround(target, direction)
      if direction == instance.horizontal_look then return end
      instance.horizontal_look = direction
      -- utils.log(direction, instance.horizontal_look)
      go.set_rotation(direction >= 0 and const.QUAT_Y_0 or const.QUAT_Y_180, target.pivot)
      go.set_rotation(direction >= 0 and const.QUAT_Y_0 or const.QUAT_Y_180, target.pivotfx)
   end -- turnaround

   ---------------------------------------
   -- fly
   ---------------------------------------

   function fly.on_enter()
      label.set_text(debug_label, "Fly")
      play_animation(char, FLY)
   end -- fly.on_enter

   function fly.update(dt)
      local dx, dy = curve(dt)
      instance.x = instance.x + dx
      instance.y = instance.y + dy
      instance.dx = dx
      instance.dy = dy
      local dir = sign(dx)
      if dir ~= 0 then
         turnaround(char, dir)
      end
      vector3_set_xyz(vector3_stub, instance.x, instance.y, 0)
      set_position(vector3_stub, root)

      if char.current_animation_group == FLY then
         local cursor = get(char.sprite, const.CURSOR)
         -- frame count
         local frame = ceil(cursor * 9)
         if frame == 5 then
            if not fly.effect_fired then
               fly.effect_fired = true
               particlefx.play(effect)
            end
         else
            fly.effect_fired = false
         end
      end
   end -- fly.update

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
      nc.post_notification(const.CAMERA_SHAKE_REQUEST_NOTIFICATION, nil, 3, 0.15)
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
      local dx, dy = move(dt * 1.25, -instance.horizontal_look, AIR_ACCELERATION, dead_speed_roll(), NORMAL_GRAVITY)
      instance.x = instance.x + dx
      instance.y = instance.y + dy
      vector3_set_xyz(vector3_stub, instance.x, instance.y, 0)
      set_position(vector3_stub, root)
   end -- dead.update

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
      health_points = self.health_points
      damage_points = self.damage_points
      fly_radius_x = self.fly_radius_x
      fly_radius_y = self.fly_radius_y
      fly_factor_x = self.fly_factor_x
      fly_factor_y = self.fly_factor_y
      fly_speed = self.fly_speed
      fly_angle = self.fly_angle * fastmath.TO_RAD
      debug_label = msg.url("#debug_label")
      msg.post(debug_label, msg.DISABLE)
      root = msg.url(".")
      pivot_x, pivot_y = fastmath.vector3_get_xy(go.get_position(root))
      move_direction = 0
      instance.x = pivot_x
      instance.y = pivot_y
      instance.dx = 0
      instance.dy = 0
      acceleration = GROUND_ACCELERATION
      max_horizontal_speed = MAX_HORIZONTAL_SPEED
      gravity = NORMAL_GRAVITY
      velocity_x = 0
      velocity_y = 0
      char.pivot = msg.url("pivot")
      char.anchor = msg.url("anchor")
      char.sprite = msg.url("anchor#sprite")
      char.current_animation_group = nil
      char.current_animation = nil
      char.on_complete = nil
      char.pivotfx = msg.url("pivotfx")
      effect = msg.url("anchorfx#effect")
      collisionobject_hitbox = msg.url("#collisionobject_hitbox")
      collisionobject_hurtbox = msg.url("#collisionobject_hurtbox")
      vector3_set_xyz(vector3_stub, 0, 0, DEPTH)
      set_position(vector3_stub, char.pivot)
      vector3_set_xyz(vector3_stub, 0, 0, DEPTH - 0.001)
      set_position(vector3_stub, char.pivotfx)
      instance.horizontal_look = 0
      turnaround(char, self.horizontal_look)
      runtime.set_instance(root.path, instance)
      runtime.add_update_callback(instance, update)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      machine.reset()
      machine.enter_state(fly)
   end -- instance.init

   function instance.deinit()
      particlefx.stop(effect)
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
