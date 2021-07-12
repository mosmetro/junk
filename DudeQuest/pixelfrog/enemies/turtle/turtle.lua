local Pool = require("m.pool")
local StateMachine = require("m.state_machine")
local const = require("m.constants")
local nc = require("m.notification_center")
local animation = require("m.animation")
local utils = require("m.utils")
local debug_draw = require("m.debug_draw")

local layers = require("pixelfrog.render.layers")
local game = require("pixelfrog.game.game")
local snd = require("sound.sound")

local DEPTH = layers.get_depth(layers.ENEMIES)

local runtime = runtime
local play_animation = animation.play
local vmath = vmath
local set_position = go.set_position
local abs = fastmath.abs
local sign = fastmath.sign
local clamp = fastmath.clamp
local vector3_set_xyz = fastmath.vector3_set_xyz

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

-- local idle_time_roll = fastmath.uniform_real(1, 2)
local dead_speed_roll = fastmath.uniform_real(0, MAX_AIR_SPEED)

local ANIMATION = {
   SPIKES = {
      { id = hash("turtle_spikes"), position = vmath.vector3(0, 13, 0), },
   },
   NO_SPIKES = {
      { id = hash("turtle_no_spikes"), position = vmath.vector3(0, 11, 0), },
   },
   SPIKES_IN = {
      { id = hash("turtle_spikes_in"), position = vmath.vector3(-1, 13, 0), },
   },
   SPIKES_OUT = {
      { id = hash("turtle_spikes_out"), position = vmath.vector3(-1, 13, 0), },
   },
   HIT = {
      { id = hash("turtle_hit"), position = vmath.vector3(0, 11, 0), },
   },
}

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_BEFORE_PLAYER,
      x = 0,
      y = 0,
      horizontal_look = 1,
   }

   local char = animation.new_target()
   local debug_label
   local move_direction
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
   local activator
   local aabb = { 0, 0, 0, 0 }

   local spikes = {}
   local spikes_in = {}
   local no_spikes = {}
   local spikes_out = {}
   local hit = {}
   local dead = {}

   local machine = StateMachine.new(nil)

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function move(dt, dir, acc, spd, grav)
      local target_speed_x = (dir or move_direction) * (spd or max_horizontal_speed)
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
      velocity_y = velocity_y + (grav or gravity) * dt
      velocity_y = clamp(velocity_y, MAX_FALL_SPEED, MAX_RISE_SPEED)
      local dy = (old_velocity_y + velocity_y) * 0.5 * dt
      return dx, dy
   end -- move

   local function turnaround(target, direction)
      if direction == instance.horizontal_look then return end
      instance.horizontal_look = direction
      go.set_rotation(direction >= 0 and const.QUAT_Y_0 or const.QUAT_Y_180, target.pivot)
   end -- turnaround

   local function update_aabb()
      aabb[1] = instance.x - 16
      aabb[2] = instance.y - 64
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
      runtime.remove_update_callback(instance)
   end -- deactivate

   ---------------------------------------
   -- spikes
   ---------------------------------------

   function spikes.on_enter()
      label.set_text(debug_label, "Spikes")
      play_animation(char, ANIMATION.SPIKES)
      spikes.in_time = runtime.current_time + 2.1
   end -- spikes.on_enter

   function spikes.update()
      if runtime.current_time > spikes.in_time then
         if spikes.keep_spikes then
            spikes.keep_spikes = false
            spikes.in_time = runtime.current_time + 2.1
         else
            machine.enter_state(spikes_in)
         end
      end
   end -- spikes.update

   ---------------------------------------
   -- spikes_in
   ---------------------------------------

   local function spikes_in_complete()
      machine.enter_state(no_spikes)
   end -- spikes_in_complete

   function spikes_in.on_enter()
      label.set_text(debug_label, "Spikes_in")
      play_animation(char, ANIMATION.SPIKES_IN, nil, spikes_in_complete)
   end -- spikes_in.on_enter

   ---------------------------------------
   -- no_spikes
   ---------------------------------------

   function no_spikes.on_enter()
      label.set_text(debug_label, "No_spikes")
      play_animation(char, ANIMATION.NO_SPIKES)
      msg.post(collisionobject_hurtbox, msg.DISABLE)
      no_spikes.out_time = runtime.current_time + 0.7
   end -- no_spikes.on_enter

   function no_spikes.update()
      if runtime.current_time > no_spikes.out_time then
         machine.enter_state(spikes_out)
      end
   end -- no_spikes.update

   ---------------------------------------
   -- spikes_out
   ---------------------------------------

   local function spikes_out_complete()
      machine.enter_state(spikes)
   end -- spikes_out_complete

   function spikes_out.on_enter()
      label.set_text(debug_label, "Spikes_out")
      play_animation(char, ANIMATION.SPIKES_OUT, nil, spikes_out_complete)
      msg.post(collisionobject_hurtbox, msg.ENABLE)
   end -- spikes_out.on_enter

   ---------------------------------------
   -- hit
   ---------------------------------------

   local function on_hit_complete()
      if machine.current_state() == hit then
         machine.enter_state(spikes_out)
      end
   end -- on_hit_complete

   function hit.on_enter()
      label.set_text(debug_label, "Hit")
      play_animation(char, ANIMATION.HIT, nil, on_hit_complete)
   end -- hit.on_enter

   ---------------------------------------
   -- dead
   ---------------------------------------

   function dead.on_enter()
      label.set_text(debug_label, "Dead")
      play_animation(char, ANIMATION.HIT, nil, animation.done_sink)
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

   function instance.on_collision(other_instance)
      if other_instance and other_instance.on_hit then
         other_instance.on_hit(snd.SHANTAE_GETHIT, damage_points, velocity_x)
      end
   end -- instance.on_collision

   function instance.on_hit(sfx, dp, speed)
      local player_instance = runtime.get_instance(game.player_id)
      if player_instance then
         local to_player = sign(player_instance.x - instance.x)
         turnaround(char, to_player)
      end
      spikes.keep_spikes = true
      if machine.current_state() ~= no_spikes then
         snd.play_sound(snd.SHIELD01)
         return
      end
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
      debug_label = msg.url("#debug_label")
      -- msg.post(debug_label, msg.DISABLE)
      root = msg.url(".")
      instance.x, instance.y = fastmath.vector3_get_xy(go.get_position(root))
      char.pivot = msg.url("pivot")
      char.anchor = msg.url("anchor")
      char.sprite = msg.url("anchor#sprite")
      char.current_animation_group = nil
      char.current_animation = nil
      char.on_complete = nil
      move_direction = 0
      collisionobject_hitbox = msg.url("#collisionobject_hitbox")
      collisionobject_hurtbox = msg.url("#collisionobject_hurtbox")
      vector3_set_xyz(vector3_stub, 0, 0, DEPTH)
      set_position(vector3_stub, char.pivot)
      acceleration = GROUND_ACCELERATION
      max_horizontal_speed = MAX_HORIZONTAL_SPEED
      gravity = NORMAL_GRAVITY
      velocity_x = 0
      velocity_y = 0
      instance.horizontal_look = 1
      turnaround(char, self.horizontal_look)
      runtime.set_instance(root.path, instance)
      if activator == const.EMPTY then
         runtime.add_update_callback(instance, update)
      else
         nc.add_observer(activate, const.ACTIVATE_NOTIFICATION, activator)
         nc.add_observer(deactivate, const.DEACTIVATE_NOTIFICATION, activator)
      end
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      machine.reset()
      machine.enter_state(spikes)
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      if activator ~= const.EMPTY then
         nc.remove_observer(activate, const.ACTIVATE_NOTIFICATION, activator)
         nc.remove_observer(deactivate, const.DEACTIVATE_NOTIFICATION, activator)
      end
   end -- instance.deinit

   return instance
end

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
