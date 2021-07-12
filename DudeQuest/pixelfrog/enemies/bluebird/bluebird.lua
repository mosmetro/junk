local Pool = require("m.pool")
local StateMachine = require("m.state_machine")
local const = require("m.constants")
local nc = require("m.notification_center")
local animation = require("m.animation")
local utils = require("m.utils")
local debug_draw = require("m.debug_draw")
-- local colors = require("m.colors")

local layers = require("pixelfrog.render.layers")
local game = require("pixelfrog.game.game")
local snd = require("sound.sound")

local play_animation = animation.play
local vmath = vmath
local set_position = go.set_position
local get = go.get
local clamp01 = fastmath.clamp01
local abs = fastmath.abs
local sign = fastmath.sign
local clamp = fastmath.clamp
local lerp = fastmath.lerp
local lerp_unclamped = fastmath.lerp_unclamped
local ease = fastmath.ease
local ensure_zero = fastmath.ensure_zero
local vector3_set_xyz = fastmath.vector3_set_xyz
local sqrt = math.sqrt
local ceil = math.ceil

local INFINITY = const.INFINITY
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
utils.log("gravity ", NORMAL_GRAVITY, "jump_speed ", JUMP_SPEED)
local vector3_stub = fastmath.vector3_stub

local dead_speed_roll = fastmath.uniform_real(0, MAX_AIR_SPEED)

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
      horizontal_look = 1,
      horizontal_drag = 0,
      vertical_drag = 0,
   }
   local move_direction
   local previous_horizontal_look
   local max_horizontal_speed
   local debug_label
   local acceleration
   local gravity
   local velocity_x
   local velocity_y
   local waypoint_x = {}
   local waypoint_y = {}
   local from_waypoint
   local next_move_time
   local interpolator
   local easing_factor
   local speed
   local wait_time
   local root
   local collisionobject_hitbox
   local collisionobject_hurtbox
   local health_points
   local damage_points
   local effect
   local name
   local activator
   local aabb = { 0, 0, 0, 0 }

   local idle = {}
   local hit = {}
   local dead = {}

   local char = animation.new_target()
   local machine = StateMachine.new(nil)

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function update(dt)
      machine.update(dt)
   end -- update

   local function activate()
      runtime.add_update_callback(instance, update)
   end -- activate

   local function deactivate()
      runtime.remove_update_callback(instance)
   end -- deactivate

   local post_init
   function post_init()
      nc.remove_observer(post_init, const.POST_INIT_NOTIFICATION)
      nc.post_notification(const.READY_NOTIFICATION, name, instance, root)
   end -- post_init

   local level_will_appear
   function level_will_appear()
      nc.remove_observer(level_will_appear, const.LEVEL_WILL_APPEAR_NOTIFICATION)
      instance.x = waypoint_x[from_waypoint]
      instance.y = waypoint_y[from_waypoint]
      vector3_set_xyz(vector3_stub, instance.x, instance.y, 0)
      set_position(vector3_stub, root)
      if activator == const.EMPTY then
         runtime.add_update_callback(instance, update)
      else
         nc.add_observer(activate, const.ACTIVATE_NOTIFICATION, activator)
         nc.add_observer(deactivate, const.DEACTIVATE_NOTIFICATION, activator)
      end
   end -- level_will_appear

   local function fly(dt)
      local time = runtime.current_time
      if time < next_move_time then
         return 0, 0
      end
      from_waypoint = ((from_waypoint - 1) % #waypoint_x) + 1
      local to_waypoint = (from_waypoint % #waypoint_x) + 1
      local lx = waypoint_x[to_waypoint] - waypoint_x[from_waypoint]
      move_direction = sign(lx)
      instance.horizontal_look = move_direction
      local ly = waypoint_y[to_waypoint] - waypoint_y[from_waypoint]
      local distance = sqrt(lx * lx + ly * ly)
      interpolator = clamp01(interpolator + dt * speed / distance)
      local new_x
      local new_y
      if easing_factor > 1 then
         local e_interpolator = ease(interpolator, easing_factor)
         new_x = lerp(waypoint_x[from_waypoint], waypoint_x[to_waypoint], e_interpolator)
         new_y = lerp(waypoint_y[from_waypoint], waypoint_y[to_waypoint], e_interpolator)
      else
         new_x = lerp_unclamped(waypoint_x[from_waypoint], waypoint_x[to_waypoint], interpolator)
         new_y = lerp_unclamped(waypoint_y[from_waypoint], waypoint_y[to_waypoint], interpolator)
      end
      if interpolator == 1 then
         interpolator = 0
         from_waypoint = from_waypoint + 1
         next_move_time = time + wait_time
      end
      local dx = ensure_zero(new_x - instance.x)
      local dy = ensure_zero(new_y - instance.y)
      return dx, dy
   end -- fly

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

   local function turnaround(target)
      if instance.horizontal_look == previous_horizontal_look then return end
      previous_horizontal_look = instance.horizontal_look
      go.set_rotation(move_direction > 0 and const.QUAT_Y_0 or const.QUAT_Y_180, target.pivot)
      go.set_rotation(move_direction > 0 and const.QUAT_Y_0 or const.QUAT_Y_180, target.pivotfx)
   end -- turnaround

   ---------------------------------------
   -- idle
   ---------------------------------------

   function idle.on_enter()
      label.set_text(debug_label, "Idle")
      play_animation(char, FLY)
   end -- idle.on_enter

   function idle.update(dt)
      local dx, dy = fly(dt)
      instance.x = instance.x + dx
      instance.y = instance.y + dy
      instance.dx = dx
      instance.dy = dy
      vector3_set_xyz(vector3_stub, instance.x, instance.y, 0)
      set_position(vector3_stub, root)
      turnaround(char)
      velocity_x = instance.dx / dt
      velocity_y = instance.dy / dt

      if char.current_animation_group == FLY then
         local cursor = get(char.sprite, const.CURSOR)
         -- frame count
         local frame = ceil(cursor * 9)
         if frame == 5 then
            if not idle.effect_fired then
               idle.effect_fired = true
               particlefx.play(effect)
            end
         else
            idle.effect_fired = false
         end
      end
   end -- idle.update

   ---------------------------------------
   -- hit
   ---------------------------------------

   local function on_hit_complete()
      next_move_time = runtime.current_time + 0.5
      if machine.previous_state() ~= hit then
         machine.revert_to_previous_state()
      end
   end -- on_hit_complete

   function hit.on_enter()
      label.set_text(debug_label, "Hit")
      play_animation(char, HIT, nil, on_hit_complete)
      next_move_time = INFINITY
   end -- hit.on_enter

   ---------------------------------------
   -- dead
   ---------------------------------------

   function dead.on_enter()
      next_move_time = INFINITY
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
      debug_draw.aabb(aabb)
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

   function instance.add_waypoint(index, wx, wy)
      waypoint_x[index] = wx
      waypoint_y[index] = wy
   end -- instance.add_waypoint

   function instance.on_collision(other_instance)
      if other_instance and other_instance.on_hit then
         other_instance.on_hit(snd.FATE_SLICE_FLESH_2, damage_points)
      end
   end -- instance.on_collision

   function instance.on_hit(sfx, dp, spd)
      health_points = health_points - (dp or 0)
      if sfx then
         snd.play_sound(sfx)
      end
      velocity_x = clamp(velocity_x + (spd or 0), -200, 200)
      if health_points > 0 then
         machine.enter_state(hit)
      else
         machine.enter_state(dead)
      end
      -- TODO: this needs to be adjusted
      return 250
   end -- instance.on_hit

   function instance.init(self)
      debug_label = msg.url("#debug_label")
      -- msg.post(debug_label, msg.DISABLE)
      name = self.name
      activator = self.activator
      health_points = self.health_points
      damage_points = self.damage_points
      from_waypoint = self.start_waypoint
      speed = self.speed
      wait_time = self.wait_time
      easing_factor = fastmath.clamp(self.easing_factor, 1, 3)
      root = msg.url(".")
      move_direction = 0
      next_move_time = 0
      interpolator = 0
      instance.dx = 0
      instance.dy = 0
      acceleration = GROUND_ACCELERATION
      max_horizontal_speed = MAX_HORIZONTAL_SPEED
      gravity = NORMAL_GRAVITY
      previous_horizontal_look = 0
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
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.add_observer(level_will_appear, const.LEVEL_WILL_APPEAR_NOTIFICATION)
      nc.add_observer(post_init, const.POST_INIT_NOTIFICATION)
      machine.reset()
      machine.enter_state(idle)
   end -- instance.init

   function instance.deinit()
      particlefx.stop(effect)
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.remove_observer(level_will_appear, const.LEVEL_WILL_APPEAR_NOTIFICATION)
      nc.remove_observer(post_init, const.POST_INIT_NOTIFICATION)
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
