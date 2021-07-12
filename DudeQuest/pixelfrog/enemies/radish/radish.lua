local Pool = require("m.pool")
local RaycastController = require("m.raycast_controller")
local StateMachine = require("m.state_machine")
local groups = require("m.groups")
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
local abs = fastmath.abs
local sign = fastmath.sign
local clamp = fastmath.clamp
local min = fastmath.min
local cos = math.cos
local sin = math.sin
local vector3_set_xyz = fastmath.vector3_set_xyz
local vector3_set_xy = fastmath.vector3_set_xy
local ensure_zero = fastmath.ensure_zero
local get_instance = runtime.get_instance

local INFINITY = const.INFINITY
local DEPTH = layers.get_depth(layers.ENEMIES)
local CHARACTER_WIDTH = 16
local CHARACTER_HEIGHT = 22
local MAX_HORIZONTAL_SPEED = 80
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
local ray_start = fastmath.ray_start
local ray_end = fastmath.ray_end
local TARGET_GROUPS = {
   groups.SLOPE,
   groups.SOLID,
}
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

local LEAFS_FACTORY = msg.url("game:/enemies#radish_leafs")

local IDLE_SQUASH = vmath.vector3(1.15, 0.85, 1)
local JUMP_STRETCH = vmath.vector3(0.9, 1.15, 1)

-- local idle_time_roll = fastmath.uniform_real(1, 2)
local dead_speed_roll = fastmath.uniform_real(0, MAX_AIR_SPEED)

local FLY = {
   { id = hash("radish_fly"), position = vmath.vector3(0, 19, 0), },
}
local IDLE = {
   { id = hash("radish_idle"), position = vmath.vector3(0, 19, 0), },
}
local RUN = {
   { id = hash("radish_run"), position = vmath.vector3(0, 19, 0), },
}
local HIT = {
   { id = hash("radish_hit"), position = vmath.vector3(0, 19, 0), },
}

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_BEFORE_PLAYER,
      x = 0,
      y = 0,
      dx = 0,
      dy = 0,
      horizontal_look = 1,
      needs_down_pass = false,
      needs_up_pass = false,
      needs_left_pass = false,
      needs_right_pass = false,
      GROUND = {
         groups.SOLID,
         groups.ONEWAY,
         groups.SLOPE,
         groups.BOX,
      },
      SOLIDS = {
         groups.SOLID,
         groups.SLOPE,
         groups.BOX,
         groups.PROPS_HITBOX,
      },
      CEILING = {
         groups.SOLID,
         groups.BOX,
         groups.PROPS_HITBOX,
      },
      SLOPES = {
         groups.SLOPE,
      },
      SLOPE = groups.SLOPE,
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
   local ground
   local root
   local collisionobject_hitbox
   local collisionobject_hurtbox
   local collisionobject_raycast
   local health_points
   local damage_points
   local next_run_time
   local contact_left
   local contact_right
   local activator
   local pivot_x
   local pivot_y
   local fly_angle
   local fly_speed
   local fly_radius_x
   local fly_radius_y
   local fly_factor_x
   local fly_factor_y
   local aabb = { 0, 0, 0, 0 }
   local probe_length

   local fly = {}
   local idle = {}
   local run = {}
   local fall = {}
   local jump = {}
   local turn = {}
   local hit = {}
   local dead = {}

   local raycast_controller = RaycastController.new(instance)
   local machine = StateMachine.new(nil)

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function turnaround(target)
      if instance.horizontal_look == previous_horizontal_look then return end
      previous_horizontal_look = instance.horizontal_look
      go.set_rotation(instance.horizontal_look > 0 and const.QUAT_Y_0 or const.QUAT_Y_180, target.pivot)
   end -- turnaround

   -- https://ru.wikipedia.org/wiki/Фигуры_Лиссажу
   local function curve(dt)
      fly_angle = fly_angle + fly_speed * dt
      local cs = cos(fly_factor_x * fly_angle)
      local sn = sin(fly_factor_y * fly_angle)
      local new_x = pivot_x + cs * fly_radius_x
      local new_y = pivot_y + sn * fly_radius_y
      return new_x - instance.x, new_y - instance.y
   end -- curve

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

   local function advance(dx, dy, id)
      dx, dy, velocity_x, velocity_y, ground = raycast_controller.update(instance.x, instance.y, dx, dy, velocity_x, velocity_y, id)
      instance.ground = ground
      instance.x = instance.x + dx
      instance.y = instance.y + dy
      vector3_set_xyz(vector3_stub, instance.x, instance.y, 0)
      set_position(vector3_stub, root)
      instance.dx = dx
      instance.dy = dy
      return dx, dy
   end -- advance

   local function update_aabb()
      aabb[1] = instance.x - 16
      aabb[2] = instance.y
      aabb[3] = instance.x + 16
      aabb[4] = instance.y + 32
   end -- update_aabb

   local function update(dt)
      -- factory.create("game:/game#dot", vmath.vector3(instance.x, instance.y, 0))
      -- every ground must have instance!
      local ground_instance = get_instance(ground)
      if ground_instance and ground_instance.is_ground then
         -- utils.log(ground)
         acceleration = ground_instance.acceleration or GROUND_ACCELERATION
         max_horizontal_speed = min(ground_instance.max_speed or INFINITY, MAX_HORIZONTAL_SPEED)
      else
         if move_direction ~= 0 then
            acceleration = AIR_ACCELERATION
            max_horizontal_speed = MAX_AIR_SPEED
         end
      end
      contact_left = false
      contact_right = false
      machine.update(dt)
   end -- update

   local function activate()
      runtime.add_update_callback(instance, update)
   end -- activate

   local function deactivate()
      runtime.remove_update_callback(instance)
   end -- deactivate

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
      instance.horizontal_look = sign(dx)
      turnaround(char)
      vector3_set_xyz(vector3_stub, instance.x, instance.y, 0)
      set_position(vector3_stub, root)
   end -- fly.update

   ---------------------------------------
   -- idle
   ---------------------------------------

   local function on_scale_complete()
      go.set_scale(1, char.pivot)
   end -- on_scale_complete

   function idle.on_enter(previous_state)
      label.set_text(debug_label, "Idle")
      play_animation(char, IDLE)
      if previous_state == fall then
         go.animate(char.pivot, const.SCALE, go.PLAYBACK_ONCE_PINGPONG, IDLE_SQUASH, go.EASING_INOUTQUAD, 0.15, 0, on_scale_complete)
      end
      next_run_time = runtime.current_time + 0.66
   end -- idle.on_enter

   function idle.update(dt)
      advance(move(dt, 0))
      if velocity_y < 0 then
         machine.enter_state(fall)
      elseif runtime.current_time > next_run_time then
         move_direction = fastmath.coin_toss() and 1 or -1
         instance.horizontal_look = move_direction
         turnaround(char)
         machine.enter_state(run)
      end
   end -- idle.update

   ---------------------------------------
   -- run
   ---------------------------------------

   function run.on_enter(previous_state)
      label.set_text(debug_label, "Run")
      play_animation(char, RUN)
      if previous_state == fall then
         go.animate(char.pivot, const.SCALE, go.PLAYBACK_ONCE_PINGPONG, IDLE_SQUASH, go.EASING_INOUTQUAD, 0.15, 0, on_scale_complete)
      end
   end -- run.on_enter

   function run.update(dt)
      local dx, dy = move(dt)
      local start_x = instance.x + (CHARACTER_WIDTH * 0.5 - 1) * instance.horizontal_look + dx
      local start_y = instance.y + 1
      vector3_set_xy(ray_start, start_x, start_y)
      vector3_set_xy(ray_end, start_x, start_y - probe_length)
      local ray_hit = physics.raycast(ray_start, ray_end, TARGET_GROUPS)
      -- debug_draw.line(ray_start.x, ray_start.y, ray_end.x, ray_end.y, colors.MAGENTA)
      if not ray_hit then
         velocity_x = 0
         advance(0, dy)
         machine.enter_state(turn)
         return
      elseif (ensure_zero(ray_hit.fraction * probe_length - 1)) >= 16 then
         advance(dx, dy)
         velocity_y = 105
         machine.enter_state(jump)
         return
      end
      advance(dx, dy)
      if contact_left or contact_right then
         machine.enter_state(turn)
      end
   end -- run.update

   ---------------------------------------
   -- fall
   ---------------------------------------

   function fall.on_enter()
      label.set_text(debug_label, "Fall")
   end -- fall.on_enter

   function fall.update(dt)
      advance(move(dt))
      if ground then
         if velocity_x == 0 then
            machine.enter_state(idle)
         else
            machine.enter_state(run)
         end
      end
   end -- fall.update

   ---------------------------------------
   -- jump
   ---------------------------------------

   function jump.on_enter()
      label.set_text(debug_label, "Jump")
      go.animate(char.pivot, const.SCALE, go.PLAYBACK_ONCE_PINGPONG, JUMP_STRETCH, go.EASING_INOUTQUAD, JUMP_TIME_TO_APEX, 0, on_scale_complete)
   end -- jump.on_enter

   function jump.update(dt)
      advance(move(dt))
      if velocity_y < 0 then
         machine.enter_state(fall)
      elseif ground then
         if velocity_x == 0 then
            machine.enter_state(idle)
         else
            machine.enter_state(run)
         end
      end
   end -- jump.update

   ---------------------------------------
   -- turn
   ---------------------------------------

   function turn.on_enter()
      label.set_text(debug_label, "Turn")
      play_animation(char, IDLE)
      -- (1) turn duration
      next_run_time = runtime.current_time + 0.5
   end -- turn.on_enter

   function turn.update(dt)
      advance(move(dt, 0))
      if runtime.current_time > next_run_time then
         move_direction = -move_direction
         instance.horizontal_look = move_direction
         turnaround(char)
         machine.enter_state(run)
      end
   end -- turn.update

   ---------------------------------------
   -- hit
   ---------------------------------------

   local function on_hit_complete()
      if health_points == 1 then
         machine.enter_state(fall)
      elseif machine.previous_state() ~= hit then
         machine.revert_to_previous_state()
      end
   end -- on_hit_complete

   function hit.on_enter()
      label.set_text(debug_label, "Hit")
      play_animation(char, HIT, nil, on_hit_complete)
   end -- hit.on_enter

   function hit.update(dt, previous_state)
      if previous_state ~= fly then
         advance(move(dt, 0))
      end
   end -- hit.update

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
      msg.post(collisionobject_raycast, msg.DISABLE)
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
      local dx, dy = move(dt * 1.25, -instance.horizontal_look, AIR_ACCELERATION, dead_speed_roll(), NORMAL_GRAVITY)
      instance.x = instance.x + dx
      instance.y = instance.y + dy
      vector3_set_xyz(vector3_stub, instance.x, instance.y, 0)
      set_position(vector3_stub, root)
   end -- dead.update

   function instance.command_jump(speed)
      if machine.current_state() == run then
         velocity_y = speed
         machine.enter_state(jump)
      end
   end

   function instance.on_collision(other_instance)
      if other_instance and other_instance.on_hit then
         other_instance.on_hit(snd.SHANTAE_GETHIT, damage_points, 0)
      end
   end -- instance.on_collision

   function instance.on_hit(sfx, dp, speed)
      health_points = health_points - (dp or 0)
      if sfx then
         snd.play_sound(sfx)
      else
         snd.play_sound(fastmath.pick_any(HIT_SOUNDS, 2))
      end
      if health_points > 0 then
         if health_points == 1 then
            vector3_set_xyz(vector3_stub, instance.x, instance.y + 24, 0)
            collectionfactory.create(LEAFS_FACTORY, vector3_stub, const.QUAT_IDENTITY, nil, 1)
         end
         machine.enter_state(hit)
      else
         velocity_x = clamp(velocity_x + (speed or 0), -200, 200)
         machine.enter_state(dead)
      end
   end -- instance.on_hit

   function instance.on_jump(sfx, dp, speed)
      instance.on_hit(sfx, dp, speed)
      return 150 -- recoil velocity
   end -- instance.on_jump

   function instance.on_contact(_, direction, vx)
      if direction == 1 then
         contact_right = true
      else
         contact_left = true
      end
      return vx
   end -- instance.on_contact

   function instance.init(self)
      probe_length = self.probe_length
      activator = self.activator
      health_points = self.health_points
      damage_points = self.damage_points
      instance.horizontal_look = self.horizontal_look
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
      instance.x = 0
      instance.y = 0
      char.pivot = msg.url("pivot")
      char.anchor = msg.url("anchor")
      char.sprite = msg.url("anchor#sprite")
      char.current_animation_group = nil
      char.current_animation = nil
      char.on_complete = nil
      collisionobject_hitbox = msg.url("#collisionobject_hitbox")
      collisionobject_hurtbox = msg.url("#collisionobject_hurtbox")
      collisionobject_raycast = msg.url("#collisionobject_raycast")
      vector3_set_xyz(vector3_stub, 0, 0, DEPTH)
      set_position(vector3_stub, char.pivot)
      acceleration = GROUND_ACCELERATION
      max_horizontal_speed = MAX_HORIZONTAL_SPEED
      gravity = NORMAL_GRAVITY
      velocity_x = 0
      velocity_y = 0
      move_direction = 0
      previous_horizontal_look = 0
      ground = nil
      contact_left = false
      contact_right = false
      turnaround(char)
      raycast_controller.set_width(CHARACTER_WIDTH)
      raycast_controller.set_height(CHARACTER_HEIGHT)
      runtime.set_instance(root.path, instance)
      runtime.add_update_callback(instance, update)
      if activator ~= const.EMPTY then
         nc.add_observer(activate, const.ACTIVATE_NOTIFICATION, activator)
         nc.add_observer(deactivate, const.DEACTIVATE_NOTIFICATION, activator)
      end
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      machine.reset()
      machine.enter_state(fly)
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
