local Pool = require("m.pool")
local RaycastController = require("m.raycast_controller")
local StateMachine = require("m.state_machine")
local CONST = require("m.constants")
-- local game = require("maze.game")
local nc = require("m.notification_center")
local ui = require("m.ui.ui")
local snd = require("sound.sound")
local groups = require("m.groups")
local layers = require("m.layers")
-- local debug_draw = require("m.debug_draw")
local colors = require("m.colors")
local DAMAGE_TYPE = require("maze.damage_type")
local utils = require("m.utils")
local PointLight = require("lighting.point_light")

local global = require("game.global")
local gamestate = require("game.gamestate")

local PLAYER_DEPTH = layers.get_depth(layers.PLAYER)

-- local hash = hash
-- local msg = msg
-- local vmath = vmath
local LEFT_BTN = ui.LEFT
local RIGHT_BTN = ui.RIGHT
local UP_BTN = ui.UP
local DOWN_BTN = ui.DOWN
local JUMP_BTN = ui.B
local ACTION_BTN = ui.X
local ATTACK_BTN = ui.A
local USE_BTN = ui.Y

-- local runtime = runtime
local is_down = runtime.is_down
-- local is_up = runtime.is_up
local is_pressed = runtime.is_pressed
local ceil = math.ceil
-- local sin = math.sin
local abs = fastmath.abs
local sign = fastmath.sign
-- local max = fastmath.max
-- local vector3_get_components = fastmath.vector3_get_components
local vector3_set_xyz = fastmath.vector3_set_xyz
-- local vector3_set_components = fastmath.vector3_set_components
local lerp = fastmath.lerp
local get_instance = runtime.get_instance
local get = go.get
local set = go.set
-- local sprite_set_hflip = sprite.set_hflip
local physics_set_hflip = physics.set_hflip
local set_position = go.set_position
local play_flipbook = sprite.play_flipbook
local play_sound = snd.play_sound

-- constants
local IDENTITY = fastmath.IDENTITY
local INFINITY = 1 / 0
local CHARACTER_WIDTH = 10
local CHARACTER_HEIGHT = 22
local MAX_HORIZONTAL_SPEED = 110--110
local MAX_VERTICAL_SPEED = 300
local GROUND_ACCELERATION = 2000
local MAX_JUMPS = 2--300
local JUMP_HEIGHT = 36
local JUMP_TIME_TO_APEX = 0.38
local NORMAL_GRAVITY = -(2 * JUMP_HEIGHT) / (JUMP_TIME_TO_APEX * JUMP_TIME_TO_APEX)
local JUMP_SPEED = abs(NORMAL_GRAVITY) * JUMP_TIME_TO_APEX
local AIR_JUMP_SPEED = JUMP_SPEED-- * 0.8
-- local AIR_DASH_DURATION = ((1 / 18) * 8) * 0.1 -- 18 fps roll, 8 frames
-- utils.log("gravity ", NORMAL_GRAVITY, "jump_speed ", JUMP_SPEED)
local JUMP_GRACE_TIME = (1 / 60) * 10
local JUMP_BUFFER_TIME = (1 / 60) * 8
local INVULNERABILITY_BASE_DURATION = 0.6
-- local CAPE_POSITION_X = 0
-- local CAPE_POSITION_Y_HIGH = 21
-- local CAPE_POSITION_Y_LOW = 16
local PLAYBACK_RATE = CONST.PLAYBACK_RATE
local CURSOR = CONST.CURSOR
local EULER_Y = CONST.EULER_Y
local HIT_FLASH_EASING = vmath.vector({ 0, 1, 1, 1, 0, 1, 1, 1, 0 })
local HIT_BLINK_EASING = vmath.vector({ 1, 1, 0, 0, 0, 0, 1, 1, })

local MELEE_HIT_FACTORY = msg.url("game:/entities#melee_hit")

local PLAYER = {
   pivot = nil,
   object = nil,
   sprite = nil,
   current_animation_group = nil,
   current_animation = nil,
   on_complete = nil,

   IDLE = {
      { id = hash("rita_idle"), position = vmath.vector3(-1, 9, 0), },
   },
   ROLL = {
      { id = hash("rita_roll"), position = vmath.vector3(1, 10, 0), },
   },
   RUN = {
      { id = hash("rita_run"), position = vmath.vector3(0, 11, 0), },
   },
   STOP = {
      { id = hash("rita_stop"), position = vmath.vector3(1, 10, 0), },
   },
   JUMP = {
      { id = hash("rita_jump"), position = vmath.vector3(0, 10, 0), },
   },
   FALL = {
      { id = hash("rita_fall"), position = vmath.vector3(0, 13, 0), },
   },
   LAND = {
      { id = hash("rita_land"), position = vmath.vector3(-1, 9, 0), },
   },
   DASH = {
      { id = hash("rita_dash"), position = vmath.vector3(0, 10, 0), },
   },
   ATTACK1 = {
      { id = hash("rita_attack1"), position = vmath.vector3(6, 14, 0), },
   },
   ATTACK2 = {
      { id = hash("rita_attack2"), position = vmath.vector3(6, 14, 0), },
   },
   ATTACK3 = {
      { id = hash("rita_attack3"), position = vmath.vector3(6, 14, 0), },
   },
   LEDGE_GRAB = {
      { id = hash("rita_ledge_grab"), position = vmath.vector3(-1, 11, 0), },
   },
   HIT = {
      { id = hash("rita_hit"), position = vmath.vector3(2, 10, 0), },
   },
   DEATH = {
      { id = hash("rita_death"), position = vmath.vector3(2, 8, 0), },
   },
   TURN = {
      { id = hash("rita_turn"), position = vmath.vector3(-2, 9, 0), },
   },
}

local BASE_SOLIDS = {
   groups.SLOPE,
   groups.SOLID,
}
local SOLIDS_WITH_BOX = {
   groups.SLOPE,
   groups.SOLID,
   groups.BOX,
}

local function make()
   local instance = {
      health = 0,
      x = 0,
      y = 0,
      dx = 0,
      dy = 0,
      horizontal_look = 1,
      vertical_look = 1,
      needs_down_pass = false,
      needs_up_pass = false,
      needs_left_pass = false,
      needs_right_pass = false,
      update_group = runtime.UPDATE_GROUP_PLAYER,
      can_push = true,
      GROUND = {
         groups.SOLID,
         groups.ONEWAY,
         groups.SLOPE,
         groups.BOX,
      },
      SOLIDS = BASE_SOLIDS,
      CEILING = {
         groups.SOLID,
      },
      SLOPES = {
         groups.SLOPE,
      },
      SLOPE = groups.SLOPE,
   }

   local collisionobject = {}
   -- local safe_to_save
   -- local safe_position_x
   -- local safe_position_y
   local damage_type
   local player_lamp
   local ledge_id
   local attack_followup
   local attack_stop_frame
   local scheduled_attack
   local scheduled_roll
   local scheduled_jump
   -- local current_stamina
   -- local max_stamina
   -- local stamina_per_second
   -- local cape_anchor
   -- local cape_position_local_x
   -- local cape_position_local_y
   -- local cape_segments = {}
   -- local cape_pos_x = {}
   -- local cape_pos_y = {}
   local contact_right
   local contact_left
   local first_responder
   local responders = {}
   local previous_horizontal_look
   local move_direction
   local attack_direction
   local velocity_x
   local velocity_y
   -- local previous_velocity_y
   local acceleration
   local max_horizontal_speed
   local gravity
   local jump_count
   local max_jumps
   local jump_grace_time
   local jump_buffer_time
   -- local slide_buffer_time
   local ground
   -- local up_space
   local root
   local vector3_stub = vmath.vector3()
   local invulnerable
   local invulnerability_end
   local invulnerability_duration
   local melee_hit_frame
   local debug_label
   local point_light
   local light_data
   local aabb = { 0, 0, 0, 0 }
   local aabb_half_size
   local passage = {}

   -- states
   local undefined = {}
   local idle = {}
   local roll = {}
   local run = {}
   local jump = {}
   local fall = {}
   local attack1 = {}
   local attack2 = {}
   local attack3 = {}
   local air_attack = {}
   local ledge_grab = {}
   local hit = {}
   local death = {}
   local air_dash = {}
   local approach = {}
   local map_change = {}
   local state_checkpoint = {}

   local raycast_controller = RaycastController.new(instance)
   local machine = StateMachine.new()

   local attack_targets = {}

   local function check_directional_input()
      local is_pressed_left = is_pressed(LEFT_BTN)
      local is_pressed_right = is_pressed(RIGHT_BTN)

      if is_down(LEFT_BTN) then
         move_direction = -1
         instance.horizontal_look = -1
      elseif is_down(RIGHT_BTN) then
         move_direction = 1
         instance.horizontal_look = 1
      elseif is_pressed_left and (not is_pressed_right) then
         move_direction = -1
         instance.horizontal_look = -1
      elseif is_pressed_right and (not is_pressed_left) then
         move_direction = 1
         instance.horizontal_look = 1
      elseif not(is_pressed_left or is_pressed_right) then
         move_direction = 0
      end
   end -- check_directional_input

   local play_properties = { offset = 0, playback_rate = 1 }

   local function play_animation(target, animation_group, index, on_complete, cursor, rate, direction)
      local animation = animation_group[index or 1]
      if target.current_animation == animation then return end
      play_properties.offset = cursor or 0
      play_properties.playback_rate = rate or 1
      if direction then instance.horizontal_look = direction end
      set_position(animation.position, target.object)
      play_flipbook(target.sprite, animation.id, on_complete, play_properties)
      target.on_complete = on_complete
      target.current_animation_group = animation_group
      target.current_animation = animation
   end -- play_animation

   local function turnaround(target)
      if instance.horizontal_look == previous_horizontal_look then return end
      previous_horizontal_look = instance.horizontal_look
      set(target.pivot, EULER_Y, instance.horizontal_look == 1 and 0 or 180)
   end -- turnaround

   local function move(dt, dir, acc, spd)
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
      local delta_velocity_y = gravity * dt
      local old_velocity_y = velocity_y
      velocity_y = velocity_y + delta_velocity_y
      if abs(velocity_y) > MAX_VERTICAL_SPEED then
         velocity_y = MAX_VERTICAL_SPEED * sign(velocity_y)
      end
      local dy = (old_velocity_y + velocity_y) * 0.5 * dt
      return dx, dy
   end -- move

   local function advance(dx, dy)
      dx, dy, velocity_x, velocity_y, ground = raycast_controller.update(instance.x, instance.y, dx, dy, velocity_x, velocity_y)
      instance.ground = ground
      instance.x = instance.x + dx
      instance.y = instance.y + dy
      vector3_set_xyz(vector3_stub, instance.x, instance.y, 0)
      set_position(vector3_stub, root)
      instance.vertical_look = 1
      instance.dx = dx
      instance.dy = dy
      return dx, dy
   end -- advance

   local function apply_damage(amount)
      utils.log("received " .. tostring(amount) .. " damage points")
   end

   -- local function restore_stamina(dt)
   --    current_stamina = current_stamina + stamina_per_second * dt
   --    if current_stamina > max_stamina then current_stamina = max_stamina end
   -- end

   local function resign_first_responder()
      local inst = get_instance(first_responder)
      if inst then
         inst.resign_first_responder()
      end
      first_responder = nil
   end -- resign_first_responder

   local function discard_responder(responder, enter)
      if not responder then return end
      if responder == first_responder then
         resign_first_responder()
      end
      if not enter then
         responders[responder] = nil
      end
   end -- discard_responder

   ---------------------------------------
   -- undefined
   ---------------------------------------

   function undefined.update(dt)
      advance(move(dt))
      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      else
         machine.enter_state(idle)
      end
   end -- undefined.update

   ---------------------------------------
   -- idle
   ---------------------------------------

   local function play_idle()
      play_animation(PLAYER, PLAYER.IDLE)
   end -- play_idle

   function idle.on_enter(previous_state)
      label.set_text(debug_label, "Idle")
      if (previous_state) == fall or (previous_state == hit) or (previous_state == jump) then
         play_animation(PLAYER, PLAYER.LAND, nil, play_idle)
      elseif (previous_state == run) or (previous_state == roll) or (previous_state == approach) then
         play_animation(PLAYER, PLAYER.STOP, nil, play_idle)
      elseif previous_state == attack1 or (previous_state == attack2) or (previous_state == attack3) or (previous_state == air_attack) then
         play_animation(PLAYER, PLAYER.STOP, nil, play_idle, 4 / 10)
      else
         play_animation(PLAYER, PLAYER.IDLE)
      end
   end -- idle.on_enter

   function idle.update(dt)
      check_directional_input()
      turnaround(PLAYER)

      local is_pressed_down_btn = is_pressed(DOWN_BTN)

      if is_down(JUMP_BTN) then
         velocity_y = JUMP_SPEED
      end

      advance(move(dt))

      if is_pressed_down_btn then
         instance.vertical_look = -1
      end

      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif is_down(ATTACK_BTN) then
         machine.enter_state(attack1)
      elseif is_down(ACTION_BTN) then
         machine.enter_state(roll)
      elseif move_direction ~= 0 then
         machine.enter_state(run)
      elseif is_down(UP_BTN) or is_pressed(UP_BTN) then
         local inst = get_instance(first_responder)
         if inst then
            machine.enter_state(approach)
         end
      end
   end -- idle.update

   ---------------------------------------
   -- roll
   ---------------------------------------

   local function on_roll_end()
      check_directional_input()
      turnaround(PLAYER)
      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < -50 then
         machine.enter_state(fall)
      elseif scheduled_attack then
         machine.enter_state(attack1)
      elseif move_direction == 0 then
         machine.enter_state(idle)
      else
         machine.enter_state(run)
      end
   end -- on_roll_end

   function roll.on_enter(previous_state)
      label.set_text(debug_label, "Roll")
      if previous_state == run then
         play_animation(PLAYER, PLAYER.ROLL, nil, on_roll_end, 1/8)
      else
         play_animation(PLAYER, PLAYER.ROLL, nil, on_roll_end)
      end
      snd.play_sound(snd.KAHO_DASH)
      msg.post(collisionobject.hitbox, msg.DISABLE)
      msg.post(collisionobject.rollbox, msg.ENABLE)
      scheduled_attack = false
      scheduled_roll = false
   end -- roll.on_enter

   function roll.update(dt)
      advance(move(dt, instance.horizontal_look, nil, 160))

      if is_down(ATTACK_BTN) then
         scheduled_attack = true
      end
   end -- roll.update

   function roll.on_exit()
      msg.post(collisionobject.hitbox, msg.ENABLE)
      msg.post(collisionobject.rollbox, msg.DISABLE)
   end -- roll.on_exit

   ---------------------------------------
   -- run
   ---------------------------------------

   function run.on_enter()
      label.set_text(debug_label, "Run")
      play_animation(PLAYER, PLAYER.RUN)
      run.loud_frame = 6 -- and 1
   end -- run.on_enter

   function run.update(dt)
      -- local ground_instance = get_instance(ground)
      -- if ground_instance and ground_instance.is_static then
      --    safe_position_x = instance.x
      --    safe_position_y = instance.y
      -- end

      check_directional_input()
      turnaround(PLAYER)
      -- move_cape()

      if PLAYER.current_animation_group == PLAYER.RUN then
         local cursor = get(PLAYER.sprite, CURSOR)
         local frame = ceil(cursor * 10) -- frame count
         if frame == run.loud_frame then
            -- play_sound(snd.KAHO_STONE_FOOTSTEP)
            play_sound(snd.ROGUE_FOOTSTEP)
            run.loud_frame = run.loud_frame == 1 and 6 or 1
         end
      end

      if is_down(JUMP_BTN) and (jump_count < max_jumps) and (velocity_y < JUMP_SPEED) then
         velocity_y = JUMP_SPEED
      end

      advance(move(dt))

      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < -50 then
         machine.enter_state(fall)
      elseif is_down(ATTACK_BTN) then
         machine.enter_state(attack1)
      elseif is_down(ACTION_BTN) then
         machine.enter_state(roll)
         -- machine.enter_state(attack)
      elseif move_direction == 0 and velocity_x == 0 then
         machine.enter_state(idle)
      elseif is_down(UP_BTN) or is_pressed(UP_BTN) then
         local inst = get_instance(first_responder)
         if inst then
            machine.enter_state(approach)
         end
      end
   end -- run.update

   ---------------------------------------
   -- jump
   ---------------------------------------

   function jump.on_enter()
      label.set_text(debug_label, "Jump")
      jump_count = jump_count + 1
      instance.can_push = false
      -- if move_direction == 0 then
      --    play_animation(PLAYER, PLAYER.JUMP)
      -- else
      --    play_animation(PLAYER, PLAYER.JUMP_SIDE)
      -- end
      play_animation(PLAYER, PLAYER.JUMP)
      snd.play_sound(snd.SHANTAE_JUMP2)
      ledge_id = nil
   end -- jump.on_enter

   function jump.update(dt)
      check_directional_input()
      turnaround(PLAYER)
      if is_down(JUMP_BTN) and (jump_count < max_jumps) then
         jump_count = jump_count + 1
         velocity_y = AIR_JUMP_SPEED
         snd.play_sound(snd.SHANTAE_JUMP2)
      end

      local dx, dy = move(dt)

      if (velocity_y < 0) and ((move_direction == instance.horizontal_look) or is_down(UP_BTN) or is_pressed(UP_BTN)) and not (is_down(DOWN_BTN) or is_pressed(DOWN_BTN)) then
         ledge_id, dy = raycast_controller.check_ledge(instance.horizontal_look, instance.x, instance.y, dy)
      end

      advance(dx, dy)

      -- advance(move(dt))
      instance.vertical_look = 0
      if ledge_id then
         machine.enter_state(ledge_grab)
      elseif is_down(ATTACK_BTN) then
         machine.enter_state(air_attack)
      elseif is_down(ACTION_BTN) and not (ground or contact_left or contact_right) then
         machine.enter_state(air_dash)
      elseif velocity_y < -30 then
         machine.enter_state(fall)
      elseif ground and (velocity_y == 0) then
         if move_direction == 0 then
            machine.enter_state(idle)
         else
            machine.enter_state(run)
         end
      end
   end -- jump.update

   ---------------------------------------
   -- fall
   ---------------------------------------

   function fall.on_enter(previous_state)
      label.set_text(debug_label, "Fall")
      if (previous_state == jump) or (previous_state == air_attack) then
         jump_grace_time = INFINITY
      else
         jump_grace_time = JUMP_GRACE_TIME
      end
      play_animation(PLAYER, PLAYER.FALL)
      ledge_id = nil
   end -- fall.on_enter

   function fall.update(dt)
      check_directional_input()
      turnaround(PLAYER)
      if is_down(JUMP_BTN) then
         if (jump_count == 0) and (jump_grace_time <= 0) then
            jump_count = jump_count + 1 -- too late, consume one jump
         end
         if jump_count < max_jumps then
            velocity_y = AIR_JUMP_SPEED
         else
            jump_buffer_time = JUMP_BUFFER_TIME
         end
      end

      jump_grace_time = jump_grace_time - dt

      local dx, dy = move(dt)

      if ((move_direction == instance.horizontal_look) or is_down(UP_BTN) or is_pressed(UP_BTN)) and not (is_down(DOWN_BTN) or is_pressed(DOWN_BTN)) then
         ledge_id, dy = raycast_controller.check_ledge(instance.horizontal_look, instance.x, instance.y, dy)
      end

      advance(dx, dy)
      instance.vertical_look = 0

      if ledge_id then
         machine.enter_state(ledge_grab)
      elseif is_down(ATTACK_BTN) then
         machine.enter_state(air_attack)
      elseif is_down(ACTION_BTN) and not (ground or contact_left or contact_right) then
         machine.enter_state(air_dash)
      elseif velocity_y > 0 then
         machine.enter_state(jump)
      elseif ground then
         if scheduled_roll then
            machine.enter_state(roll)
         elseif jump_buffer_time > 0 then
            velocity_y = JUMP_SPEED
            machine.enter_state(jump)
         elseif move_direction == 0 then
            machine.enter_state(idle)
         else
            machine.enter_state(run)
         end
      end

      jump_buffer_time = jump_buffer_time - dt
   end -- fall.update

   function fall.on_exit()
      instance.bypass = nil
   end -- fall.on_exit

   ---------------------------------------
   -- attack1
   ---------------------------------------

   local function on_attack1_complete()
      turnaround(PLAYER)
      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif attack_followup then
         machine.enter_state(attack2)
      elseif scheduled_roll then
         machine.enter_state(roll)
      elseif move_direction == 0 then
         machine.enter_state(idle)
      else
         machine.enter_state(run)
      end
   end -- on_attack1_complete

   function attack1.on_enter()
      aabb_half_size = 84
      label.set_text(debug_label, "Attack1")
      play_animation(PLAYER, PLAYER.ATTACK1, nil, on_attack1_complete)
      snd.play_sound(snd.SWING_SWORD_01)
      -- snd.play_sound(snd.ALICE_VORPAL_SLASH_01)
      velocity_x = 0
      attack_followup = false
      scheduled_roll = false
      attack_direction = instance.horizontal_look
      attack_stop_frame = runtime.current_frame + 1
      physics_set_hflip(collisionobject.hurtbox1, attack_direction ~= 1)
      msg.post(collisionobject.hurtbox1, msg.ENABLE)
      for k, _ in next, attack_targets do
         attack_targets[k] = nil
      end
      -- pprint(attack_targets)
   end -- attack1.on_enter

   function attack1.update(dt)
      check_directional_input()

      if runtime.current_frame > attack_stop_frame then
         msg.post(collisionobject.hurtbox1, msg.DISABLE)
         attack_stop_frame = INFINITY
      end

      if is_down(ATTACK_BTN) then
         attack_followup = true
      elseif is_down(ACTION_BTN) then
         scheduled_roll = true
      end

      local t = get(PLAYER.sprite, CURSOR)
      local stop = 3 / 10
      if t < stop then
         advance(move(dt, attack_direction, nil, 60))
      else
         if is_down(JUMP_BTN) and (jump_count < max_jumps)then
            velocity_y = JUMP_SPEED
         end
         advance(move(dt, 0))
         if velocity_y > 0 then
            machine.enter_state(jump)
         elseif velocity_y < 0 then
            machine.enter_state(fall)
         end
      end
   end -- attack1.update

   function attack1.on_exit()
      aabb_half_size = 42
      msg.post(collisionobject.hurtbox1, msg.DISABLE)
   end -- attack1.on_exit

   ---------------------------------------
   -- attack2
   ---------------------------------------

   local function on_attack2_complete()
      turnaround(PLAYER)
      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif attack_followup then
         machine.enter_state(attack3)
      elseif scheduled_roll then
         machine.enter_state(roll)
      elseif move_direction == 0 then
         machine.enter_state(idle)
      else
         machine.enter_state(run)
      end
   end -- on_attack2_complete

   function attack2.on_enter()
      aabb_half_size = 84
      label.set_text(debug_label, "Attack2")
      play_animation(PLAYER, PLAYER.ATTACK2, nil, on_attack2_complete)
      snd.play_sound(snd.SWING_SWORD_02)
      velocity_x = 0
      attack_followup = false
      scheduled_roll = false
      attack_direction = instance.horizontal_look
      attack_stop_frame = runtime.current_frame + 1
      physics_set_hflip(collisionobject.hurtbox2, attack_direction ~= 1)
      msg.post(collisionobject.hurtbox2, msg.ENABLE)
      for k, _ in next, attack_targets do
         attack_targets[k] = nil
      end
   end -- attack2.on_enter

   function attack2.update(dt)
      check_directional_input()

      if runtime.current_frame > attack_stop_frame then
         msg.post(collisionobject.hurtbox2, msg.DISABLE)
         attack_stop_frame = INFINITY
      end

      if is_down(ATTACK_BTN) then
         attack_followup = true
      elseif is_down(ACTION_BTN) then
         scheduled_roll = true
      end

      local t = get(PLAYER.sprite, CURSOR)
      local stop = 3 / 10
      if t < stop then
         advance(move(dt, attack_direction, nil, 80))
      else
         if is_down(JUMP_BTN) and (jump_count < max_jumps)then
            velocity_y = JUMP_SPEED
         end
         advance(move(dt, 0))
         if velocity_y > 0 then
            machine.enter_state(jump)
         elseif velocity_y < 0 then
            machine.enter_state(fall)
         end
      end
   end -- attack2.update

   function attack2.on_exit()
      aabb_half_size = 42
      msg.post(collisionobject.hurtbox2, msg.DISABLE)
   end -- attack2.on_exit

   ---------------------------------------
   -- attack3
   ---------------------------------------

   local function on_attack3_complete()
      turnaround(PLAYER)
      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif scheduled_roll then
         machine.enter_state(roll)
      elseif move_direction == 0 then
         machine.enter_state(idle)
      else
         machine.enter_state(run)
      end
   end -- on_attack3_complete

   function attack3.on_enter()
      aabb_half_size = 84
      label.set_text(debug_label, "Attack3")
      play_animation(PLAYER, PLAYER.ATTACK3, nil, on_attack3_complete)
      snd.play_sound(snd.GOBLIN_SWORD_SLASH)
      velocity_x = 0
      scheduled_roll = false
      attack_direction = instance.horizontal_look
      attack_stop_frame = runtime.current_frame + 1
      physics_set_hflip(collisionobject.hurtbox3, attack_direction ~= 1)
      msg.post(collisionobject.hurtbox3, msg.ENABLE)
      for k, _ in next, attack_targets do
         attack_targets[k] = nil
      end
   end -- attack3.on_enter

   function attack3.update(dt)
      check_directional_input()

      if runtime.current_frame > attack_stop_frame then
         msg.post(collisionobject.hurtbox3, msg.DISABLE)
         attack_stop_frame = INFINITY
      end

      if is_down(ACTION_BTN) then
         scheduled_roll = true
      end

      advance(move(dt, 0))
      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      end
   end -- attack3.update

   function attack3.on_exit()
      aabb_half_size = 42
      msg.post(collisionobject.hurtbox3, msg.DISABLE)
   end -- attack3.on_exit

   ---------------------------------------
   -- air_attack
   ---------------------------------------

   local function on_air_attack_complete()
      -- utils.log(runtime.current_frame)
      turnaround(PLAYER)
      if (velocity_y > 0) or scheduled_jump then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif (velocity_y == 0) or ground then
         if scheduled_roll then
            machine.enter_state(roll)
         elseif move_direction == 0 then
            machine.enter_state(idle)
         else
            machine.enter_state(run)
         end
      elseif scheduled_roll then
         machine.enter_state(air_dash)
      end
   end -- on_air_attack_complete

   function air_attack.on_enter()
      aabb_half_size = 84
      -- utils.log(runtime.current_frame)
      label.set_text(debug_label, "Air_attack")
      attack_direction = instance.horizontal_look
      play_animation(PLAYER, PLAYER.ATTACK3, nil, on_air_attack_complete, nil, nil, attack_direction)
      snd.play_sound(snd.GOBLIN_SWORD_SLASH)
      scheduled_roll = false
      scheduled_jump = false
      attack_stop_frame = runtime.current_frame + 10
      physics_set_hflip(collisionobject.hurtbox3, attack_direction ~= 1)
      msg.post(collisionobject.hurtbox3, msg.ENABLE)
      for k, _ in next, attack_targets do
         attack_targets[k] = nil
      end
   end -- air_attack.on_enter

   function air_attack.update(dt)
      check_directional_input()
      -- advance(move(dt))

      if runtime.current_frame > attack_stop_frame then
         msg.post(collisionobject.hurtbox3, msg.DISABLE)
         attack_stop_frame = INFINITY
      end

      if is_down(JUMP_BTN) and (jump_count < max_jumps) then
         velocity_y = AIR_JUMP_SPEED
         scheduled_jump = true
      elseif is_down(ACTION_BTN) then
         scheduled_roll = true
      end

      if ground and velocity_y == 0 then
         velocity_x = 0
         advance(move(dt, 0))
      else
         advance(move(dt))
      end

      local t = get(PLAYER.sprite, CURSOR)
      local stop = 6 / 16
      -- utils.log(t, stop)
      if t > stop then
         -- utils.log("stop", runtime.current_frame)
         on_air_attack_complete()
      end
   end -- air_attack.update

   function air_attack.on_exit()
      aabb_half_size = 42
      msg.post(collisionobject.hurtbox3, msg.DISABLE)
   end -- air_attack.on_exit

   ---------------------------------------
   -- air_dash
   ---------------------------------------

   function air_dash.on_enter()
      label.set_text(debug_label, "Air_dash")
      play_animation(PLAYER, PLAYER.DASH)
      snd.play_sound(snd.KAHO_AIR_DASH)
      scheduled_jump = false
      scheduled_attack = false
      velocity_y = 0
      air_dash.exit_time = runtime.current_time + 0.12--AIR_DASH_DURATION
   end -- air_dash.on_enter

   function air_dash.update(dt)
      instance.needs_down_pass = true
      local dx, _ = move(dt, instance.horizontal_look, 10000, 810)
      advance(dx, 0)

      if is_down(JUMP_BTN) and (jump_count < max_jumps) then
         scheduled_jump = true
      elseif is_down(ATTACK_BTN) then
         scheduled_attack = true
      end

      -- if ground then
      --    if move_direction == 0 then
      --       machine.enter_state(idle)
      --    else
      --       machine.enter_state(run)
      --    end
      -- else
      if (runtime.current_time > air_dash.exit_time) or ground or contact_left or contact_right then
         check_directional_input()
         turnaround(PLAYER)
         if velocity_y > 0 then
            machine.enter_state(jump)
         elseif velocity_y < 0 then
            machine.enter_state(fall)
            -- elseif scheduled_attack then
            --    machine.enter_state(attack1)
         elseif ground then
            if move_direction == 0 then
               machine.enter_state(idle)
            else
               machine.enter_state(run)
            end
         end
      end
      -- end


   end -- air_dash.update

   function air_dash.on_exit()
      velocity_x = 0
   end -- air_dash.on_exit

   ---------------------------------------
   -- ledge_grab
   ---------------------------------------

   function ledge_grab.on_enter()
      label.set_text(debug_label, "Ledge_grab")
      play_animation(PLAYER, PLAYER.LEDGE_GRAB)
      play_sound(snd.ROGUE_LEDGE_GRAB)
      move_direction = 0
      jump_count = 0
      velocity_x = 0
      velocity_y = 0
   end -- ledge_grab.on_enter

   function ledge_grab.update(dt)
      local inst = get_instance(ledge_id)
      if inst then
         local dx = inst.dx or 0
         local dy = inst.dy or 0
         if is_down(JUMP_BTN) then
            velocity_y = JUMP_SPEED
            advance(move(dt))
            machine.enter_state(jump)
         elseif ground or is_pressed(DOWN_BTN) then
            advance(dx, dy)
            machine.enter_state(fall)
         else
            local id = raycast_controller.check_ledge(instance.horizontal_look, instance.x, instance.y, dy)
            advance(dx, dy, ledge_id)
            if not id then
               machine.enter_state(fall)
            end
         end
      else
         advance(move(dt))
         machine.enter_state(fall)
      end
   end -- ledge_grab.update

   ---------------------------------------
   -- hit
   ---------------------------------------

   local function on_hit_end()
      -- animation_done message sink
   end -- on_hit_end

   function hit.on_enter()
      label.set_text(debug_label, "Hit")
      play_animation(PLAYER, PLAYER.HIT, nil, on_hit_end)
      set(PLAYER.sprite, CONST.TINT, colors.WHITE)
      go.animate(PLAYER.sprite, CONST.TINT, go.PLAYBACK_ONCE_FORWARD, colors.EXAGGERATED_WHITE, HIT_FLASH_EASING, 0.3)
      go.animate(PLAYER.sprite, CONST.TINT_W, go.PLAYBACK_LOOP_PINGPONG, 0, HIT_BLINK_EASING, 0.3)
      nc.post_notification(CONST.CAMERA_SHAKE_REQUEST_NOTIFICATION, nil, 6, 0.15)
      velocity_y = 80
      velocity_x = 0
      move_direction = 0
      hit.stagger_end = runtime.current_time + 0.4 -- stagger duration
      invulnerability_end = runtime.current_time + invulnerability_duration
      invulnerable = true
   end -- hit.on_enter

   function hit.update(dt)
      advance(move(dt, hit.direction, 10000, 105))
      if ground or (runtime.current_time > hit.stagger_end) then
         go.cancel_animations(PLAYER.sprite, CONST.TINT)
         if instance.health > 0 then
            check_directional_input()
            turnaround(PLAYER)
            if velocity_y < 0 then
               machine.enter_state(fall)
            elseif velocity_y < 0 then
               machine.enter_state(jump)
            elseif move_direction ~= 0 then
               machine.enter_state(run)
            else
               machine.enter_state(idle)
            end
         else
            machine.enter_state(death)
         end
      end
   end -- hit.update

   ---------------------------------------
   -- death
   ---------------------------------------

   local function on_death_end()
      -- game.save()
   end -- on_death_end

   function death.on_enter()
      label.set_text(debug_label, "Death")
      play_animation(PLAYER, PLAYER.DEATH, nil, on_death_end)
      msg.post(collisionobject.hitbox, msg.DISABLE)
      -- game.set(nil, game.player, "last_position", nil)
      velocity_x = 0
      velocity_y = 0
      instance.dx = 0
      instance.dy = 0

      timer.delay(4, false, function()
         discard_responder(first_responder, false)
         nc.post_notification(CONST.ENTITY_DID_LEAVE_LEVEL_NOTIFICATION, root.path)
         runtime.remove_update_callback(instance)
         machine.enter_state(undefined)
      end)
   end -- death.on_enter

   function death.update()
      advance(0, 0)
   end -- death.update

   function death.on_exit()
      instance.health = 2
      msg.post(collisionobject.hitbox, msg.ENABLE)
   end

   ---------------------------------------
   -- approach
   ---------------------------------------

   function approach.on_enter()
      label.set_text(debug_label, "Approach")
      local target = get_instance(first_responder)
      if target then
         velocity_x = 0
         velocity_y = 0
         if fastmath.combined_is_equal(target.x, instance.x) then
            approach.t = INFINITY
         else
            approach.to = target.x - instance.x
            instance.horizontal_look = sign(approach.to)
            turnaround(PLAYER)
            play_animation(PLAYER, PLAYER.RUN)
            approach.t = 0
            approach.previous = 0
         end
      end
   end -- approach.on_enter

   function approach.update(dt)
      instance.needs_down_pass = true --for ground check (we need to know our ground)

      local target = get_instance(first_responder)
      if target then
         if approach.t <= 1 then
            approach.t = approach.t + (dt * 70) / abs(approach.to) -- ~ MAX_HORIZONTAL_SPEED - GROUND_ACCELERATION * dt
            local new = lerp(0, approach.to, approach.t)
            local delta = new - approach.previous
            approach.previous = new
            advance((target.dx or 0) + delta, (target.dy or 0))
         else
            if target.is_gate then
               machine.enter_state(map_change)
            elseif target.is_checkpoint then
               machine.enter_state(state_checkpoint)
            else
               advance(move(dt))
               machine.enter_state(idle)
            end
         end
      else
         advance(move(dt))
         machine.enter_state(idle)
      end
   end -- approach.update

   ---------------------------------------
   -- map_change
   ---------------------------------------

   local function turnaround_complete()
      local target = get_instance(first_responder)
      discard_responder(first_responder, false)
      nc.post_notification(CONST.ENTITY_DID_LEAVE_LEVEL_NOTIFICATION, root.path, target)
      machine.enter_state(idle)
   end --turnaround_complete

   -- local WALKOUT_TIME = 0.2 -- second

   function map_change.on_enter()
      label.set_text(debug_label, "Map_change")
      play_animation(PLAYER, PLAYER.TURN, nil, turnaround_complete)
      -- play_animation(PLAYER, PLAYER.IDLE)
      -- map_change.exit_time = runtime.current_time + WALKOUT_TIME
   end -- map_change.on_enter

   -- function map_change.update()
   --    if runtime.current_time >  map_change.exit_time then
   --       turnaround_complete()
   --    end
   -- end -- map_change.update

   ---------------------------------------
   -- state_checkpoint
   ---------------------------------------

   function state_checkpoint.on_enter()
      label.set_text(debug_label, "Checkpoint")
      play_animation(PLAYER, PLAYER.IDLE)
      runtime.execute_in_context(ui.hud_context.disable, ui.hud_context)
      runtime.execute_in_context(ui.single_touch_controls_context.enable, ui.single_touch_controls_context)
   end --state_checkpoint.on_enter

   local function check_responders()
      local min_distance = INFINITY
      local pretender = nil
      local pretender_instance = nil
      for id, enter in next, responders do
         local responder_instance = get_instance(id)
         if responder_instance then
            if enter and responder_instance.accepts_first_responder(instance, root.path) then
               local distance = abs(responder_instance.x - instance.x)
               if distance < min_distance then
                  min_distance = distance
                  pretender = id
                  pretender_instance = responder_instance
               end
            else
               discard_responder(id, enter)
            end
         else
            discard_responder(id, enter)
         end
      end

      if pretender and (first_responder ~= pretender) then
         -- if first_responder ~= pretender then
         resign_first_responder()
         first_responder = pretender
         pretender_instance.become_first_responder()
         -- end
      end
   end -- check_responders

   local function update_aabb(box, x, y)
      box[1] = x - aabb_half_size
      box[2] = y - aabb_half_size
      box[3] = x + aabb_half_size
      box[4] = y + aabb_half_size
      -- debug_draw.aabb(box, colors.GREEN)
   end -- update_aabb

   local function update(dt)
      -- utils.log(runtime.current_frame, dt)
      -- utils.log(velocity_y)
      -- update_aabb(aabb, instance.x, instance.y + 14)
      -- point_light.update(aabb, instance.x, instance.y + 14)
      -- previous_velocity_y = velocity_y
      contact_right = false
      contact_left = false
      if ground then
         jump_count = 0
         instance.can_push = true
      else
         instance.can_push = false
      end
      check_responders()
      if is_pressed(USE_BTN) then
         instance.SOLIDS = SOLIDS_WITH_BOX
      end
      machine.update(dt)
      update_aabb(aabb, instance.x, instance.y + 14)
      point_light.update(aabb, instance.x, instance.y + 14)
      instance.SOLIDS = BASE_SOLIDS
      if invulnerable and (runtime.current_time > invulnerability_end) then
         go.cancel_animations(PLAYER.sprite, CONST.TINT_W)
         set(PLAYER.sprite, CONST.TINT, colors.WHITE)
         invulnerable = false
      end

      -- if safe_to_save and (velocity_y == 0) then
      --    local ground_instance = get_instance(ground)
      --    if ground_instance and ground_instance.is_static then
      --       safe_position_x = instance.x
      --       safe_position_y = instance.y
      --    end
      -- end
   end -- update

   local function on_level_will_disappear()
      -- discard_responder(first_responder, false)
      -- runtime.execute_in_context(global.ingame_controls_context.disable, global.ingame_controls_context)
   end -- on_level_will_disappear

   local function on_level_did_disappear(_, quit_to_menu)
      if quit_to_menu then
         go.delete(root.path, true)
         return
      end
      -- elseif passage.instance then
      -- if passage.instance.is_horizontal then
      --    passage.elevation = instance.y - passage.instance.y
      -- else
      --    passage.shift = instance.x - passage.instance.x
      -- end
      -- passage.instance = nil
      -- runtime.remove_update_callback(instance)
      -- set(PLAYER.sprite, PLAYBACK_RATE, 0)
      point_light.disable()
      go.set(player_lamp, "material", light_data.nodraw_material)
      light_data = nil
      msg.post(player_lamp, msg.DISABLE)
      -- else
      -- utils.log("this should never happen")
      -- end
   end -- on_level_did_disappear

   local function on_level_will_appear()
      -- "location" is always here. It can't be nil.
      local location_instance = runtime.get_instance(global.location_id)
      if passage.elevation or passage.shift then
         local x, y = location_instance.get_exit_position()
         instance.x = x + (passage.shift or 0)
         instance.y = y + (passage.elevation or 0)
         passage.shift = nil; passage.elevation = nil
      else
         instance.x, instance.y = location_instance.get_spawn_position()
      end
      vector3_set_xyz(vector3_stub, instance.x, instance.y, 0)
      set_position(vector3_stub, root)
      -- instance.horizontal_look = 1
      -- msg.post(collisionobject.sensor, msg.ENABLE)
      if not location_instance.is_horizontal then
         if machine.current_state() == jump then
            velocity_y = JUMP_SPEED
         elseif machine.current_state() == fall then
            velocity_y = 0
         end
      end
      runtime.add_update_callback(instance, update)
      set(PLAYER.sprite, PLAYBACK_RATE, 1)
      light_data = point_light.enable(aabb)
      if light_data then
         go.set(player_lamp, "material", light_data.light_material)
         msg.post(player_lamp, msg.ENABLE)
         point_light.update(aabb, 0, 0 + 14)
      end
      -- runtime.execute_in_context(global.ingame_controls_context.enable, global.ingame_controls_context)
   end -- on_level_will_appear

   local function on_level_did_appear()
      -- safe_to_save = true
   end -- on_level_did_appear

   local function on_game_will_end()
      -- utils.log(game.map, safe_position_x, safe_position_y)
      -- if safe_position_x and safe_position_y then
      --    game.set(nil, game.player, "last_position", {
      --       map = game[game.map],
      --       position_x = safe_position_x,
      --       position_y = safe_position_y,
      --       horizontal_look = instance.horizontal_look,
      --    })
      -- end
   end -- on_game_will_end

   function instance.on_contact(_, direction, vx)
      if direction == 1 then
         contact_right = true
      else
         contact_left = true
      end
      return vx
   end -- instance.on_contact

   function instance.init()
      debug_label = msg.url("#debug_label")
      -- msg.post(debug_label, msg.DISABLE)
      root = msg.url("root")
      PLAYER.pivot = msg.url("pivot")
      player_lamp = msg.url("pivot#lamp")
      PLAYER.object = msg.url("rita")
      PLAYER.sprite = msg.url("rita#sprite")
      PLAYER.current_animation_group = nil
      PLAYER.current_animation = nil
      PLAYER.on_complete = nil
      collisionobject.hitbox = msg.url("#collisionobject_hitbox")
      collisionobject.hurtbox1 = msg.url("#collisionobject_hurtbox1")
      collisionobject.hurtbox2 = msg.url("#collisionobject_hurtbox2")
      collisionobject.hurtbox3 = msg.url("#collisionobject_hurtbox3")
      collisionobject.rollbox = msg.url("#collisionobject_rollbox")
      collisionobject.sensor = msg.url("#collisionobject_sensor")
      msg.post(collisionobject.hitbox, msg.ENABLE)
      msg.post(collisionobject.hurtbox1, msg.DISABLE)
      msg.post(collisionobject.hurtbox2, msg.DISABLE)
      msg.post(collisionobject.hurtbox3, msg.DISABLE)
      msg.post(collisionobject.rollbox, msg.DISABLE)
      vector3_set_xyz(vector3_stub, 0, 0, PLAYER_DEPTH)
      set_position(vector3_stub, PLAYER.pivot)
      acceleration = GROUND_ACCELERATION
      max_horizontal_speed = MAX_HORIZONTAL_SPEED
      gravity = NORMAL_GRAVITY
      velocity_x = 0
      velocity_y = 0
      move_direction = 0
      instance.horizontal_look = 1
      instance.vertical_look = 1
      previous_horizontal_look = 0
      ground = nil
      -- up_space = nil
      jump_count = 0
      jump_buffer_time = 0
      -- slide_buffer_time = 0
      max_jumps = MAX_JUMPS > 0 and MAX_JUMPS or INFINITY
      -- max_stamina = 20 -- load from save
      -- current_stamina = max_stamina
      -- stamina_per_second = 1
      contact_right = false
      contact_left = false
      ledge_id = nil
      invulnerability_duration = INVULNERABILITY_BASE_DURATION
      invulnerability_end = 0
      invulnerable = false
      melee_hit_frame = 0
      instance.health = 2
      damage_type = DAMAGE_TYPE.SLASH
      passage.instance = nil; passage.shift = nil; passage.elevation = nil
      raycast_controller.set_width(CHARACTER_WIDTH)
      raycast_controller.set_height(CHARACTER_HEIGHT)
      runtime.set_instance(root.path, instance)
      nc.add_observer(on_level_will_disappear, CONST.LEVEL_WILL_DISAPPEAR_NOTIFICATION)
      nc.add_observer(on_level_did_disappear, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.add_observer(on_level_will_appear, CONST.LEVEL_WILL_APPEAR_NOTIFICATION)
      nc.add_observer(on_level_did_appear, CONST.LEVEL_DID_APPEAR_NOTIFICATION)
      nc.add_observer(on_game_will_end, CONST.GAME_WILL_END_NOTIFICATION)
      -- cape
      -- cape_anchor = msg.url("cape_anchor")
      -- cape_position_local_x = CAPE_POSITION_X
      -- cape_position_local_y = CAPE_POSITION_Y_HIGH
      -- for i = 1, CAPE_SEGMENT_COUNT do
      --    cape_segments[i] = msg.url("cape_segment" .. i)
      -- end
      runtime.add_update_callback(instance, update)
      point_light = PointLight.new(0, 8)
      light_data = nil
      aabb_half_size = 42
      machine.reset()
      machine.enter_state(undefined)
   end -- init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(on_level_will_disappear, CONST.LEVEL_WILL_DISAPPEAR_NOTIFICATION)
      nc.remove_observer(on_level_did_disappear, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.remove_observer(on_level_will_appear, CONST.LEVEL_WILL_APPEAR_NOTIFICATION)
      nc.remove_observer(on_level_did_appear, CONST.LEVEL_DID_APPEAR_NOTIFICATION)
      nc.remove_observer(on_game_will_end, CONST.GAME_WILL_END_NOTIFICATION)
      on_game_will_end()
      -- game.save()
   end -- deinit

   function instance.on_collision_response(message)
      local other_instance = get_instance(message.other_id)
      if other_instance then
         if other_instance.collect_damage then
            local value = other_instance.collect_damage()
            apply_damage(value)
            -- elseif other_instance.passthrough then
            --    msg.post(sender, msg.DISABLE)
            --    nc.post_notification(CONST.ENTITY_DID_LEAVE_LEVEL_NOTIFICATION, root.path)
         end
      end
   end -- on_collision_response

   -- local function on_strike_complete()
   --    aabb_half_size = 32
   -- end -- on_strike_complete

   local function on_strike(position)
      if runtime.current_frame == melee_hit_frame then return end

      collectionfactory.create(MELEE_HIT_FACTORY, position, IDENTITY, nil, 1)
      set(player_lamp, CONST.SCALE, CONST.VECTOR3_TWO)
      -- aabb_half_size = 64
      -- go.animate(url, property, playback, to, easing, duration, delay, complete_function)
      go.animate(player_lamp, CONST.SCALE, go.PLAYBACK_ONCE_FORWARD, CONST.VECTOR3_ONE, go.EASING_INQUAD, 0.25)
      melee_hit_frame = runtime.current_frame
   end -- on_strike

   function instance.on_hit(direction)
      if invulnerable or (instance.health <= 0) then return false end

      instance.health = instance.health - 1
      -- if instance.health <= 0 then
      --    game.set(nil, game.checkpoint, "rest_counter", game.get(nil, game.checkpoint, "rest_counter", 0) + 1)
      -- end
      hit.direction = direction
      machine.enter_state(hit)
      return true
   end -- on_hit

   function instance.on_contact_point_response(message, sender)
      if sender == collisionobject.hitbox then return end

      local other_id = message.other_id
      if attack_targets[other_id] then return end
      attack_targets[other_id] = true
      on_strike(message.position)
      local other_instance = get_instance(other_id)
      if other_instance then
         other_instance.on_hit(instance.horizontal_look, damage_type)
         -- local target_type = other_instance.on_hit(instance.horizontal_look)
         -- if target_type then
         --    local fx = snd.get_hit_sound(weapon_type, target_type)
         --    utils.log(fx)
         --    snd.play_sound(fx)
         -- end
      end
   end -- on_contact_point_response

   function instance.on_passage(other_instance)
      passage.instance = other_instance
      gamestate.set(nil, gamestate.player, "last_location", {
         map = other_instance.map,
         location = other_instance.location,
         direction = instance.horizontal_look
      })
      if passage.instance.is_horizontal then
         passage.elevation = instance.y - passage.instance.y
      else
         passage.shift = instance.x - passage.instance.x
      end
      passage.instance = nil
      runtime.remove_update_callback(instance)
      set(PLAYER.sprite, PLAYBACK_RATE, 0)
      discard_responder(first_responder, false)
      runtime.execute_in_context(global.ingame_controls_context.disable, global.ingame_controls_context)
      runtime.execute_in_context(global.ingame_context.enable, global.ingame_context, other_instance.map, other_instance.location)
   end -- instance.on_passage

   function instance.on_trigger_response(message, sender)
      if sender == collisionobject.sensor then
         local other_instance = get_instance(message.other_id)
         if not other_instance then
            return
         end

         local enter = message.enter

         if enter then
            if other_instance.on_enter then
               other_instance.on_enter(instance)
            elseif other_instance.collect_currency then
               local value = other_instance.collect_currency()
               -- game.set(nil, game.player, "currency_counter", game.get(nil, game.player, "currency_counter", 0) + value)
            end
         elseif (not enter) and other_instance.on_exit then
            other_instance.on_exit()
         elseif other_instance.accepts_first_responder then
            responders[message.other_id] = message.enter
         end
      elseif (sender == collisionobject.rollbox) and message.enter then
         local other_instance = get_instance(message.other_id)
         if not other_instance then
            return
         end
         if other_instance.on_roll_over then
            other_instance.on_roll_over()
         end
         --    end
      end
   end -- on_trigger_response

   -- function instance.on_trigger_response(message, sender)
   --    local other_instance = get_instance(message.other_id)
   --    if not other_instance then return end
   --
   --    if sender == collisionobject.sensor then
   --       local enter = message.enter
   --       if enter and other_instance.collect_currency then
   --          local value = other_instance.collect_currency()
   --          game.set(nil, game.player, "currency_counter", game.get(nil, game.player, "currency_counter", 0) + value)
   --
   --       elseif enter and other_instance.is_passage then
   --          nc.post_notification(CONST.ENTITY_DID_LEAVE_LEVEL_NOTIFICATION, root.path, other_instance)
   --
   --       elseif other_instance.accepts_first_responder then
   --          responders[message.other_id] = message.enter
   --       end
   --
   --       -- not sensor
   --    elseif message.enter then -- there is only two triggers (sensor and rollbox)
   --       if other_instance.on_roll_over then
   --          other_instance.on_roll_over()
   --       end
   --    end
   -- end -- on_trigger_response

   return instance
end

local pool = Pool.new(make)

-- export
return {
   new = pool.new,
   free = pool.free,
}
