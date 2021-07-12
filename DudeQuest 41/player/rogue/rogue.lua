-- import
local Pool = require("m.pool")
local RaycastController = require("m.raycast_controller")
local StateMachine = require("m.state_machine")
local Maze = require("maze.maze")
local nc = require("m.notification_center")
local ui = require("m.ui.ui")
local snd = require("sound.sound")
local groups = require("m.groups")
-- local COLOR = require("m.colors")
local utils = require("m.utils")
-- local layers = require("m.layers")

-- local PLAYER_DEPTH = layers.get_depth(layers.PLAYER)
-- utils.log(PLAYER_DEPTH)
-- pprint(layers.depths)

-- localization
local hash = hash
local msg = msg
local vmath = vmath
local LEFT = ui.LEFT
local RIGHT = ui.RIGHT
local UP = ui.UP
local DOWN = ui.DOWN
local A = ui.A
-- local B = ui.B
local X = ui.X
local Y = ui.Y
local runtime = runtime
local is_down = runtime.is_down
local is_up = runtime.is_up
local is_pressed = runtime.is_pressed
local modf = math.modf
local sqrt = math.sqrt
local abs = fastmath.abs
local sign = fastmath.sign
local max = fastmath.max
-- local vector3_get_components = fastmath.vector3_get_components
local vector3_set_components = fastmath.vector3_set_components
local vector3_get_x = fastmath.vector3_get_x
local vector3_set_z_sign = fastmath.vector3_set_z_sign
local lerp = fastmath.lerp
local get_instance = runtime.get_instance
local set = go.set
local get = go.get
-- local get_world_position = go.get_world_position
local set_position = go.set_position
local play_flipbook = sprite.play_flipbook
local play_sound = snd.play_sound

-- constants
local INFINITY = 1 / 0
local HUGE = math.huge
local CHARACTER_WIDTH = 14
local CHARACTER_HIGH_STANCE = 34
local CHARACTER_LOW_STANCE = 14
local MAX_HORIZONTAL_SPEED = 110
local MAX_VERTICAL_SPEED = 800
local GROUND_ACCELERATION = 5000
local MAX_JUMPS = 300
local JUMP_HEIGHT = 44
local JUMP_TIME_TO_APEX = 0.38
local NORMAL_GRAVITY = -(2 * JUMP_HEIGHT) / (JUMP_TIME_TO_APEX * JUMP_TIME_TO_APEX)
local JUMP_SPEED = abs(NORMAL_GRAVITY) * JUMP_TIME_TO_APEX
local AIR_JUMP_SPEED = JUMP_SPEED-- * 0.8
local JUMP_CUT_SPEED = JUMP_SPEED * 0.4
local JUMP_GRACE_TIME = 1 / 60 * 10
local EULER_Y = hash("euler.y")
local CURSOR = hash("cursor")
local SHADOW_POSITION = vmath.vector3(2, 0, 0.01)

local ROGUE_JUMP_ATTACK2 = {
   { id = hash("rogue_jump_attack2_with_shield"), position = vmath.vector3(7, 19, 0), frame_step = 1 / 7 + 0.001 },
   { id = hash("rogue_jump_attack2_with_spear"),  position = vmath.vector3(7, 20, 0), frame_step = 1 / 7 + 0.001 },
   { id = hash("rogue_jump_attack2"),             position = vmath.vector3(7, 19, 0), frame_step = 1 / 7 + 0.001 },
}
local ROGUE_JUMP_ATTACK3 = {
   { id = hash("rogue_jump_attack3_with_shield"), position = vmath.vector3(7, 21, 0), frame_step = 1 / 7 + 0.001 },
   { id = hash("rogue_jump_attack3_with_spear"),  position = vmath.vector3(7, 22, 0), frame_step = 1 / 7 + 0.001 },
   { id = hash("rogue_jump_attack3"),             position = vmath.vector3(7, 21, 0), frame_step = 1 / 7 + 0.001 },
}
local ROGUE_JUMP_ATTACK4 = {
   { id = hash("rogue_jump_attack4_with_shield"), position = vmath.vector3(7, 21, 0), frame_step = 1 / 7 + 0.001 },
   { id = hash("rogue_jump_attack4_with_spear"),  position = vmath.vector3(7, 22, 0), frame_step = 1 / 7 + 0.001 },
   { id = hash("rogue_jump_attack4"),             position = vmath.vector3(7, 21, 0), frame_step = 1 / 7 + 0.001 },
}

local ROGUE = {
   object = nil,
   sprite = nil,
   current_animation_group = nil,
   current_animation = nil,
   on_complete = nil,

   IDLE = {
      -- { id = hash("tim_idle"), position = vmath.vector3(0, 28, 0) },
      { id = hash("rogue_idle_with_shield"), position = vmath.vector3(-1, 19, 0) },
      { id = hash("rogue_idle_with_spear"),  position = vmath.vector3(-2, 19, 0) },
      { id = hash("rogue_idle"),             position = vmath.vector3(-2, 19, 0) },
   },
   WALK = {
      -- { id = hash("tim_walk"), position = vmath.vector3(0, 28, 0), frame_step = 1 / 10 + 0.001 },
      { id = hash("rogue_walk_with_shield"), position = vmath.vector3(0, 19, 0), frame_step = 1 / 8 + 0.001 },
      { id = hash("rogue_walk_with_spear"),  position = vmath.vector3(-2, 19, 0), frame_step = 1 / 8 + 0.001 },
      { id = hash("rogue_walk"),             position = vmath.vector3(-1, 19, 0), frame_step = 1 / 8 + 0.001 },
   },
   CROUCH = {
      -- { id = hash("tim_crouch"), position = vmath.vector3(0, 28, 0) },
      { id = hash("rogue_crouch_with_shield"), position = vmath.vector3(-3, 18, 0) },
      { id = hash("rogue_crouch_with_spear"),  position = vmath.vector3(-4, 17, 0) },
      { id = hash("rogue_crouch"),             position = vmath.vector3(-4, 18, 0) },
   },
   -- workaround for flipbook offset bug
   CROUCH_WORKAROUND = {
      { id = hash("rogue_crouch_workaround_with_shield"), position = vmath.vector3(-3, 18, 0) },
      { id = hash("rogue_crouch_workaround_with_spear"),  position = vmath.vector3(-4, 17, 0) },
      { id = hash("rogue_crouch_workaround"),             position = vmath.vector3(-4, 18, 0) },
   },
   RISE = {
      -- { id = hash("tim_rise"), position = vmath.vector3(0, 28, 0) },
      { id = hash("rogue_rise_with_shield"), position = vmath.vector3(-3, 18, 0) },
      { id = hash("rogue_rise_with_spear"),  position = vmath.vector3(-4, 17, 0) },
      { id = hash("rogue_rise"),             position = vmath.vector3(-4, 18, 0) },
   },
   JUMP_LOOP = {
      -- { id = hash("tim_jump_loop"), position = vmath.vector3(0, 25, 0) },
      { id = hash("rogue_jump_loop_with_shield"), position = vmath.vector3(0, 20, 0) },
      { id = hash("rogue_jump_loop_with_spear"),  position = vmath.vector3(-2, 20, 0) },
      { id = hash("rogue_jump_loop"),             position = vmath.vector3(-3, 20, 0) },
   },
   JUMP_FINISH = {
      -- { id = hash("tim_jump_finish"), position = vmath.vector3(0, 23, 0), frame_step = 1 / 3 + 0.001 },
      { id = hash("rogue_jump_finish_with_shield"), position = vmath.vector3(1, 21, 0), frame_step = 1 / 4 + 0.001 },
      { id = hash("rogue_jump_finish_with_spear"),  position = vmath.vector3(-2, 21, 0), frame_step = 1 / 4 + 0.001 },
      { id = hash("rogue_jump_finish"),             position = vmath.vector3(-2, 21, 0), frame_step = 1 / 4  + 0.001 },
   },
   FALL = {
      -- { id = hash("tim_fall"), position = vmath.vector3(0, 25, 0), frame_step = 1 / 4 + 0.001 },
      { id = hash("rogue_fall_with_shield"), position = vmath.vector3(1, 20, 0), frame_step = 1 / 6 + 0.001 },
      { id = hash("rogue_fall_with_spear"),  position = vmath.vector3(-2, 20, 0), frame_step = 1 / 6 + 0.001 },
      { id = hash("rogue_fall"),             position = vmath.vector3(-1, 20, 0), frame_step = 1 / 6 + 0.001 },
   },
   -- workaround for flipbook offset bug
   FALL_AFTER_JUMP_ATTACK = {
      { id = hash("rogue_fall_after_jump_attack_with_shield"), position = vmath.vector3(1, 20, 0) },
      { id = hash("rogue_fall_after_jump_attack_with_spear"),  position = vmath.vector3(-2, 20, 0) },
      { id = hash("rogue_fall_after_jump_attack"),             position = vmath.vector3(-1, 20, 0) },
   },
   FALL2 = {
      { id = hash("rogue_fall2_with_shield"), position = vmath.vector3(0, 18, 0), },
      { id = hash("rogue_fall2_with_spear"),  position = vmath.vector3(0, 18, 0), },
      { id = hash("rogue_fall2"),             position = vmath.vector3(0, 18, 0), },
   },
   FALL3 = {
      -- { id = hash("tim_fall"), position = vmath.vector3(0, 25, 0), frame_step = 1 / 4 + 0.001 },
      { id = hash("rogue_fall3_with_shield"), position = vmath.vector3(1, 19, 0), },
      { id = hash("rogue_fall3_with_spear"),  position = vmath.vector3(0, 19, 0), },
      { id = hash("rogue_fall3"),             position = vmath.vector3(0, 19, 0), },
   },
   LAND = {
      -- { id = hash("tim_land"), position = vmath.vector3(0, 28, 0) },
      { id = hash("rogue_land_with_shield"), position = vmath.vector3(-1, 17, 0) },
      { id = hash("rogue_land_with_spear"),  position = vmath.vector3(-2, 18, 0) },
      { id = hash("rogue_land"),             position = vmath.vector3(-3, 17, 0) },
   },
   ATTACK = {
      { id = hash("rogue_attack_with_shield"), position = vmath.vector3(7, 19, 0), frame_step = 1 / 7 + 0.001 },
      { id = hash("rogue_attack_with_spear"),  position = vmath.vector3(7, 19, 0), frame_step = 1 / 7 + 0.001 },
      { id = hash("rogue_attack"),             position = vmath.vector3(7, 19, 0), frame_step = 1 / 7 + 0.001 },
   },
   CROUCH_ATTACK = {
      { id = hash("rogue_crouch_attack_with_shield"), position = vmath.vector3(5, 11, 0), frame_step = 1 / 7 + 0.001 },
      { id = hash("rogue_crouch_attack_with_spear"),  position = vmath.vector3(5, 12, 0), frame_step = 1 / 7 + 0.001 },
      { id = hash("rogue_crouch_attack"),             position = vmath.vector3(5, 11, 0), frame_step = 1 / 7 + 0.001 },
   },
   JUMP_ATTACK1 = {
      { id = hash("rogue_jump_attack1_with_shield"), position = vmath.vector3(7, 20, 0), frame_step = 1 / 7 + 0.001 },
      { id = hash("rogue_jump_attack1_with_spear"),  position = vmath.vector3(7, 20, 0), frame_step = 1 / 7 + 0.001 },
      { id = hash("rogue_jump_attack1"),             position = vmath.vector3(7, 20, 0), frame_step = 1 / 7 + 0.001 },
   },
   JUMP_ATTACK234 = {
      ROGUE_JUMP_ATTACK2,
      ROGUE_JUMP_ATTACK3,
      ROGUE_JUMP_ATTACK4,
      ROGUE_JUMP_ATTACK4,
   },
   FALL_ATTACK = {
      ROGUE_JUMP_ATTACK3,
      ROGUE_JUMP_ATTACK3,
      ROGUE_JUMP_ATTACK3,
      ROGUE_JUMP_ATTACK2,
      ROGUE_JUMP_ATTACK2,
      ROGUE_JUMP_ATTACK2,
   },
   LEDGE_GRAB = {
      { id = hash("rogue_ledge_grab"), position = vmath.vector3(3, 13, 0) },
   },
   LEDGE_CLIMB = {
      { id = hash("rogue_ledge_climb"), position = vmath.vector3(6, 19, 0) },
   },
   LEDGE_STAND = {
      { id = hash("rogue_ledge_stand"), position = vmath.vector3(13, 10, 0) },
   },
   TURNAROUND_DOOR = {
      { id = hash("rogue_turnaround_door"), position = vmath.vector3(2, 19, 0) },
   },
}

local ATTACK_TARGETS = {
   groups.ENEMY_HITBOX,
}

local swords = {
   [hash("red_sword")] = {
      id = "red_sword",
      name = "Short Sword",
      color = vmath.vector4(192/255, 45/255, 0, 1),
      effect = "None",
   },
}
local shields = {
   [hash("green_shield")] = {
      id = "green_shield",
      name = "Ordinary Shield",
      color_a = vmath.vector4(59/255, 135/255, 0, 1),
      color_b = vmath.vector4(33/255, 77/255, 0, 1),
      effect = "None",
   },
   [hash("red_shield")] = {
      id = "red_shield",
      name = "Avenger Shield",
      color_a = vmath.vector4(192/255, 45/255, 0, 1),
      color_b = vmath.vector4(109/255, 26/255, 0, 1),
      effect = "Bash Damage",
   },
}
local function get_weapon_hash(id, t)
   for k, v in next, t do
      if v.id == id then
         return k
      end
   end
   return nil
end

local function make()
   local CAPE_SEGMENT_COUNT = 6
   local CAPE_CONSTRAINT_LENGTH = 3
   local CAPE_GRAVITY = 20
   local CAPE_DRAG = 0.75
   local cape_anchor
   local cape_position_local_x
   local cape_position_local_y
   local cape_segments = {}
   local cape_pos_x = {}
   local cape_pos_y = {}
   local cape_prev_pos_x = {}
   local cape_prev_pos_y = {}
   local first_responder
   local responders = {}
   local look_direction
   local previous_look_direction
   local move_direction
   local vertical_look
   local velocity_x
   local velocity_y
   local previous_velocity_y
   local acceleration
   local max_horizontal_speed
   local gravity
   local jump_count = 0
   local max_jumps
   local jump_grace_time
   local ground
   local root
   local vector3_stub = vmath.vector3()
   local position_x
   local position_y
   local pivot
   local collisionobject_raycast_high
   local collisionobject_raycast_low
   local collisionobject_hitbox_high
   -- local collisionobject_hitbox_low
   local current_sword = get_weapon_hash("red_sword", swords)
   local current_shield = get_weapon_hash("green_shield", shields)
   local spear_count = 3
   local secondary_weapon = 1 -- 1 - shield, 2 - spear
   local buffered_sword_attack
   local attack_targets = {}
   local debug_label
   local debug_label2
   local debug_label3

   -- states
   local undefined = {}
   local idle = {}
   local walk = {}
   local jump = {}
   local land = {}
   local fall = {}
   local crouch = {}
   local attack = { attack_length = 32, attack_height = 28 }
   local crouch_attack = { attack_length = 29, attack_height = 14 }
   local jump_attack = { attack_length = 30, attack_height = 32 }
   local ledge_grab = {}
   local ledge_climb = {}
   local ledge_stand = {}
   local approach = {}
   local map_change = {}

   local contact_left
   local contact_right
   local contact_up
   local ledge = {
      id = nil,
      from = 0,
      to = 0,
      t = 0,
      previous = 0,
      body_x = 0,
      body_y = 0,
   }

   local instance = {
      dx = 0,
      dy = 0,
      needs_down_pass = false,
      needs_up_pass = false,
      needs_left_pass = false,
      needs_right_pass = false,
      update_group = runtime.UPDATE_GROUP_PLAYER,
      can_push = true,
   }

   local raycast_controller = RaycastController.new(instance, {
      GROUND = {
         groups.SOLID,
         groups.ONEWAY,
         groups.SLOPE,
         groups.BOX,
      },
      SOLIDS = {
         groups.SLOPE,
         groups.SOLID,
         groups.BOX,
      },
      CEILING = {
         groups.SOLID,
         groups.BOX,
      },
      SLOPES = {
         groups.SLOPE,
      },
      SLOPE = groups.SLOPE,
   })
   local machine = StateMachine.new(instance, undefined)

   local function check_directional_input()
      local is_pressed_left = is_pressed(LEFT)
      local is_pressed_right = is_pressed(RIGHT)

      if is_down(LEFT) then
         move_direction = -1
         look_direction = -1
      elseif is_down(RIGHT) then
         move_direction = 1
         look_direction = 1
      elseif is_pressed_left and (not is_pressed_right) then
         move_direction = -1
         look_direction = -1
      elseif is_pressed_right and (not is_pressed_left) then
         move_direction = 1
         look_direction = 1
      elseif not(is_pressed_left or is_pressed_right) then
         move_direction = 0
      end
   end -- check_directional_input

   local play_properties = { offset = 0, playback_rate = 1 }

   local function play_animation(target, animation_group, index, on_complete, cursor, rate)
      local animation = animation_group[index or 1]
      if target.current_animation == animation then return end
      play_properties.offset = cursor or 0
      play_properties.playback_rate = rate or 1
      set_position(animation.position, target.object)
      play_flipbook(target.sprite, animation.id, on_complete, play_properties)
      vector3_set_z_sign(SHADOW_POSITION, -look_direction)
      set_position(SHADOW_POSITION, target.shadow_object)
      play_flipbook(target.shadow_sprite, animation.id, nil, play_properties)
      target.on_complete = on_complete
      target.current_animation_group = animation_group
      target.current_animation = animation
   end -- play_animation

   local function turnaround(target)
      if previous_look_direction == look_direction then return end
      previous_look_direction = look_direction
      set(pivot, EULER_Y, look_direction == 1 and 0 or 180)
      vector3_set_z_sign(SHADOW_POSITION, -look_direction)
      set_position(SHADOW_POSITION, target.shadow_object)
   end -- turnaround

   local function set_stance(height)
      if height == CHARACTER_HIGH_STANCE then
         msg.post(collisionobject_raycast_high, msg.ENABLE)
         msg.post(collisionobject_hitbox_high, msg.ENABLE)
         msg.post(collisionobject_raycast_low, msg.DISABLE)
      else
         msg.post(collisionobject_raycast_high, msg.DISABLE)
         msg.post(collisionobject_hitbox_high, msg.DISABLE)
         msg.post(collisionobject_raycast_low, msg.ENABLE)
      end
      raycast_controller.set_height(height)
   end -- set_stance

   local function move(dt, dir, acc, spd)
      local target_speed_x = (dir or move_direction) * (spd or max_horizontal_speed)
      local speed_diff_x = target_speed_x - velocity_x
      local acceleration_x = (acc or acceleration) * sign(speed_diff_x)
      -- utils.log(acceleration_x, velocity_x)
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

   local function advance(dx, dy, ledge_id)
      dx, dy, velocity_x, velocity_y, ground = raycast_controller.update(position_x, position_y, dx, dy, velocity_x, velocity_y, ledge_id)
      instance.ground = ground
      position_x = position_x + dx
      position_y = position_y + dy
      instance.dx = dx
      instance.dy = dy
      vector3_set_components(vector3_stub, position_x, position_y, 0)
      set_position(vector3_stub, root)
      vertical_look = 1
      return dx, dy
   end -- advance

   local function apply_damage(amount)
      utils.log("received " .. tostring(amount) .. " damage points")
   end

   local function check_weapon_change()
      if is_down(Y) then
         if secondary_weapon == 1 then -- shied equiped
            if spear_count == 0 then
               secondary_weapon = 3 -- no weapon
            else
               secondary_weapon = 2 -- equip spear
            end
            play_sound(snd.EQUIP_SPEAR)
         else
            secondary_weapon = 1 -- equip shield
            play_sound(snd.EQUIP_SHIELD)
         end
         -- secondary_weapon = (secondary_weapon == 1) and ((spear_count == 0) and 3 or 2) or 1
         play_animation(ROGUE, ROGUE.current_animation_group, secondary_weapon, ROGUE.on_complete, get(ROGUE.sprite, CURSOR))
      end
   end -- check_weapon_change

   local function sword_attack(length, height)
      local x1 = position_x
      local x2 = position_x + length * look_direction
      local y = position_y + height
      repeat
         local hit = raycast_controller.cast_ray(x1, y, x2, y, ATTACK_TARGETS)
         local stop
         if hit then
            if not attack_targets[hit.id] then
               attack_targets[hit.id] = true
               local inst = get_instance(hit.id)
               if inst then
                  utils.log(hit.id)
                  inst.apply_damage()
                  play_sound(snd.ROGUE_ENEMY_HIT)
               end
            end
            x1 = vector3_get_x(hit.position) + 0.01 * look_direction
            if look_direction == 1 then
               stop = x1 >= x2
            else
               stop = x1 <= x2
            end
         else
            stop = true
         end
      until stop
   end -- sword_attack

   local function perform_attack(attack_state)
      local cursor = get(ROGUE.sprite, CURSOR)
      local frame = modf(cursor / ROGUE.current_animation.frame_step) + 1
      if frame == 4 then
         sword_attack(attack_state.attack_length, attack_state.attack_height)
      end
   end -- perform_attack

   local function clear_attack_targets()
      for k, _ in next, attack_targets do
         attack_targets[k] = nil
      end
   end

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

   local function play_idle_loop()
      play_animation(ROGUE, ROGUE.IDLE, secondary_weapon)
   end -- play_idle_loop

   function idle.on_enter(previous_state)
      label.set_text(debug_label, "Idle")
      if previous_state == crouch then
         play_animation(ROGUE, ROGUE.RISE, secondary_weapon, play_idle_loop)
      else
         play_animation(ROGUE, ROGUE.IDLE, secondary_weapon)
      end
   end -- idle.on_enter

   function idle.update(dt)
      check_directional_input()
      check_weapon_change()
      turnaround(ROGUE)

      if is_down(X) then
         advance(move(dt))
         machine.enter_state(attack)
         return
      end

      if is_down(A) and (jump_count < max_jumps) then
         jump_count = jump_count + 1
         velocity_y = JUMP_SPEED
      end

      advance(move(dt))

      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         -- utils.log(velocity_y, ground)
         machine.enter_state(fall)
      elseif move_direction ~= 0 then
         machine.enter_state(walk)
      elseif is_down(UP) or is_pressed(UP) then
         local inst = get_instance(first_responder)
         if inst then
            machine.enter_state(approach)
         end
      elseif is_down(DOWN) or is_pressed(DOWN) then
         machine.enter_state(crouch)
      end
   end -- idle.update

   ---------------------------------------
   -- walk
   ---------------------------------------

   local function play_walk_loop()
      play_animation(ROGUE, ROGUE.WALK, secondary_weapon)
      max_horizontal_speed = MAX_HORIZONTAL_SPEED
   end -- play_walk_loop

   function walk.on_enter(previous_state)
      label.set_text(debug_label, "Walk")
      if previous_state == crouch then
         max_horizontal_speed = 20
         play_animation(ROGUE, ROGUE.RISE, secondary_weapon, play_walk_loop)
      else
         play_animation(ROGUE, ROGUE.WALK, secondary_weapon)
      end
      walk.frame = 0
   end -- walk.on_enter

   function walk.update(dt)
      check_directional_input()
      check_weapon_change()
      turnaround(ROGUE)

      if is_down(X) then
         advance(move(dt))
         machine.enter_state(attack)
         return
      end

      if is_down(A) and (jump_count < max_jumps) then
         jump_count = jump_count + 1
         velocity_y = JUMP_SPEED
      end

      advance(move(dt))

      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif move_direction == 0 and velocity_x == 0 then
         machine.enter_state(idle)
      elseif is_down(UP) or is_pressed(UP) then
         local inst = get_instance(first_responder)
         if inst then
            machine.enter_state(approach)
         end
      elseif is_down(DOWN) or is_pressed(DOWN) then
         machine.enter_state(crouch)
      end

      if ROGUE.current_animation_group == ROGUE.WALK then
         local cursor = get(ROGUE.sprite, CURSOR)
         local frame = modf(cursor / ROGUE.current_animation.frame_step) + 1
         if (frame ~= walk.frame) and (frame == 3 or frame == 7) then
            play_sound(snd.ROGUE_FOOTSTEP)
            walk.frame = frame
         end
         -- if secondary_weapon == 2 then
         --    if (frame ~= walk.frame) and (frame == 3 or frame == 7) then
         --       play_sound(snd.ROGUE_FOOTSTEP)
         --       walk.frame = frame
         --    end
         -- elseif secondary_weapon == 1 then
         --    if (frame ~= walk.frame) and (frame == 1 or frame == 6) then -- tim
         --       play_sound(snd.ROGUE_FOOTSTEP)
         --       walk.frame = frame
         --    end
         -- end
         -- if (frame ~= walk.frame) and (frame == 1 or frame == 6) then -- tim
         --    play_sound(snd.ROGUE_FOOTSTEP)
         --    walk.frame = frame
         -- end
      end
   end -- walk.update

   function walk.on_exit()
      max_horizontal_speed = MAX_HORIZONTAL_SPEED
   end -- walk.on_exit

   ---------------------------------------
   -- jump
   ---------------------------------------

   function jump.on_enter(previous_state)
      label.set_text(debug_label, "Jump")
      if previous_state ~= jump_attack then
         play_animation(ROGUE, ROGUE.JUMP_LOOP, secondary_weapon)
      end
   end -- jump.on_enter

   function jump.update(dt)
      check_directional_input()
      check_weapon_change()
      turnaround(ROGUE)

      if velocity_y < 150 then -- pure empirical value
         play_animation(ROGUE, ROGUE.JUMP_FINISH, secondary_weapon)
      end

      if is_down(X) then
         advance(move(dt))
         machine.enter_state(jump_attack)
         return
      end

      if is_down(A) and (jump_count < max_jumps) then
         jump_count = jump_count + 1
         velocity_y = AIR_JUMP_SPEED
      elseif is_up(A) then
         if velocity_y > JUMP_CUT_SPEED then
            velocity_y = JUMP_CUT_SPEED
         end
      end

      advance(move(dt))
      vertical_look = 0

      if velocity_y <= 0 then
         machine.enter_state(fall)
      end


      -- if ROGUE.current_animation.id == ROGUE.JUMP_FINISH[secondary_weapon].id then
      --    local cursor = get(ROGUE.sprite, CURSOR)
      --    local frame = modf(cursor / ROGUE.current_animation.frame_step) + 1
      --    log(frame, cursor)
      -- end
   end -- jump.update

   ---------------------------------------
   -- land
   ---------------------------------------

   local function land_complete()
      if ground then
         if move_direction ~= 0 then
            machine.enter_state(walk)
         else
            machine.enter_state(idle)
         end
      else
         machine.enter_state(fall)
      end
   end -- land_complete

   function land.on_enter()
      label.set_text(debug_label, "Land")
      local k = max(abs(previous_velocity_y / MAX_VERTICAL_SPEED), 0.2)
      max_horizontal_speed = (1 - k) * MAX_HORIZONTAL_SPEED
      play_animation(ROGUE, ROGUE.LAND, secondary_weapon, land_complete)
      play_sound(snd.ROGUE_LAND, k)
   end -- land.on_enter

   function land.update(dt)
      check_directional_input()
      check_weapon_change()
      turnaround(ROGUE)

      if is_down(X) then
         advance(move(dt))
         machine.enter_state(attack)
         return
      end

      if is_down(A) and (jump_count < max_jumps) then
         jump_count = jump_count + 1
         velocity_y = JUMP_SPEED
      end

      advance(move(dt))

      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif ground and (is_down(DOWN) or is_pressed(DOWN)) then
         machine.enter_state(crouch)
      end
   end -- land.update

   function land.on_exit()
      max_horizontal_speed = MAX_HORIZONTAL_SPEED
   end -- land.on_exit

   ---------------------------------------
   -- fall
   ---------------------------------------

   function fall.on_enter(previous_state)
      label.set_text(debug_label, "Fall")
      jump_grace_time = (previous_state == jump) and HUGE or JUMP_GRACE_TIME
      ledge.id = nil
      if (previous_state == walk) or (previous_state == crouch) then
         play_animation(ROGUE, ROGUE.FALL3, secondary_weapon)
      elseif (previous_state == jump_attack) or (previous_state == ledge_grab) then
         play_animation(ROGUE, ROGUE.FALL_AFTER_JUMP_ATTACK, secondary_weapon) -- workaround for flipbook offset bug
      else
         play_animation(ROGUE, ROGUE.FALL, secondary_weapon)
      end
      -- label.set_text(debug_label2, tostring(ROGUE.current_animation.id))
   end -- fall.on_enter

   function fall.update(dt)
      check_directional_input()
      check_weapon_change()
      turnaround(ROGUE)

      if is_down(X) then
         advance(move(dt))
         machine.enter_state(jump_attack)
         return
      end

      if is_down(A) then
         if (jump_count == 0) and (jump_grace_time <= 0) then
            jump_count = jump_count + 1 -- too late, consume one jump
         end
         if jump_count < max_jumps then
            jump_count = jump_count + 1
            velocity_y = AIR_JUMP_SPEED
         end
      end
      jump_grace_time = jump_grace_time - dt

      local dx, dy = move(dt)

      if ((move_direction == look_direction) or is_down(UP) or is_pressed(UP)) and not (is_down(DOWN) or is_pressed(DOWN)) then
         ledge.id, dy = raycast_controller.check_ledge(look_direction, position_x, position_y, dy)
      end

      advance(dx, dy)
      vertical_look = 0

      if ledge.id then
         machine.enter_state(ledge_grab)
      elseif velocity_y > 0 then
         machine.enter_state(jump)
      elseif ground and (velocity_y == 0) then
         machine.enter_state(land)
         -- if move_direction == 0 then
         --    if is_down(DOWN) or is_pressed(DOWN) then
         --       machine.enter_state(crouch)
         --    else
         --       machine.enter_state(idle)
         --    end
         -- else
         --    machine.enter_state(walk)
         -- end
      end
   end -- fall.update

   function fall.on_exit()
      instance.bypass = nil
   end -- fall.on_exit

   ---------------------------------------
   -- crouch
   ---------------------------------------

   function crouch.on_enter(previous_state)
      label.set_text(debug_label, "Crouch")
      velocity_x = 0
      if previous_state == crouch_attack then
         -- play_animation(ROGUE, ROGUE.CROUCH, secondary_weapon, nil, 1)
         play_animation(ROGUE, ROGUE.CROUCH_WORKAROUND, secondary_weapon) -- workaround for flipbook offset bug
      else
         set_stance(CHARACTER_LOW_STANCE)
         play_animation(ROGUE, ROGUE.CROUCH, secondary_weapon)
         if previous_state == fall then
            play_sound(snd.ROGUE_LAND, abs(previous_velocity_y / MAX_VERTICAL_SPEED))
         end
      end
   end -- crouch.on_enter

   function crouch.update(dt)
      check_directional_input()
      check_weapon_change()
      turnaround(ROGUE)

      if is_down(X) then
         advance(move(dt))
         machine.enter_state(crouch_attack)
         return
      end

      if is_down(A) then
         local inst = get_instance(ground)
         -- utils.log(inst)
         if inst and inst.can_jump_down then
            instance.bypass = ground
         elseif (jump_count < max_jumps) then
            jump_count = jump_count + 1
            velocity_y = JUMP_SPEED
         end
      end

      advance(move(dt, 0)) -- we don't move in that stance
      vertical_look = -1 -- override

      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif not is_pressed(DOWN) then
         if move_direction ~= 0 then
            machine.enter_state(walk)
         else
            machine.enter_state(idle)
         end
      end
   end -- crouch.update

   function crouch.on_exit(next_state)
      if next_state ~= crouch_attack then
         set_stance(CHARACTER_HIGH_STANCE)
      end
   end -- crouch.on_exit

   ---------------------------------------
   -- rise
   ---------------------------------------

   -- function rise.on_enter()
   --    label.set_text(debug_label, "Rise")
   --    play_animation(ROGUE, ROGUE.RISE, secondary_weapon)
   -- end

   ---------------------------------------
   -- attack
   ---------------------------------------

   local function attack_complete()
      clear_attack_targets()
      if buffered_sword_attack then
         buffered_sword_attack = false
         ROGUE.current_animation = nil -- overide
         attack.on_enter()
      else
         check_directional_input()
         turnaround(ROGUE)
         if velocity_y > 0 then
            machine.enter_state(jump)
         elseif velocity_y < 0 then
            machine.enter_state(fall)
         elseif ground then
            if move_direction ~= 0 then
               machine.enter_state(walk)
            elseif is_down(DOWN) or is_pressed(DOWN) then
               machine.enter_state(crouch)
            else
               machine.enter_state(idle)
            end
         end
      end
   end -- attack_complete

   function attack.on_enter(previous_state)
      label.set_text(debug_label, "Attack")

      if (previous_state ~= jump_attack) and (previous_state ~= crouch_attack) then
         play_animation(ROGUE, ROGUE.ATTACK, secondary_weapon, attack_complete)
         play_sound(snd.ROGUE_SWORD_ATTACK)
      else
         play_animation(ROGUE, ROGUE.ATTACK, secondary_weapon, attack_complete, get(ROGUE.sprite, CURSOR))
         if previous_state == jump_attack then
            local k = max(abs(previous_velocity_y / MAX_VERTICAL_SPEED), 0.2)
            play_sound(snd.ROGUE_LAND, k)
         end
      end
      move_direction = 0
      velocity_x = 0
   end -- attack.on_enter

   function attack.update(dt)
      perform_attack(attack)

      if is_down(X) then
         buffered_sword_attack = true
      elseif is_down(A) and (jump_count < max_jumps) then
         jump_count = jump_count + 1
         velocity_y = JUMP_SPEED
      end

      advance(move(dt))

      if velocity_y > 0 then
         machine.enter_state(jump_attack)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif is_down(DOWN) or is_pressed(DOWN) then
         machine.enter_state(crouch_attack)
      end
   end -- attack.update

   ---------------------------------------
   -- crouch_attack
   ---------------------------------------

   local function crouch_attack_complete()
      clear_attack_targets()
      if buffered_sword_attack then
         buffered_sword_attack = false
         ROGUE.current_animation = nil -- overide
         crouch_attack.on_enter()
      else
         check_directional_input()
         turnaround(ROGUE)
         if velocity_y > 0 then
            machine.enter_state(jump)
         elseif velocity_y < 0 then
            machine.enter_state(fall)
         elseif ground then
            if is_down(DOWN) or is_pressed(DOWN) then
               machine.enter_state(crouch)
            elseif move_direction ~= 0 then
               machine.enter_state(walk)
            else
               machine.enter_state(idle)
            end
         end
      end
   end -- crouch_attack_complete

   function crouch_attack.on_enter(previous_state)
      label.set_text(debug_label, "Crouch attack")
      if previous_state == attack then
         play_animation(ROGUE, ROGUE.CROUCH_ATTACK, secondary_weapon, crouch_attack_complete, get(ROGUE.sprite, CURSOR))
      else
         play_animation(ROGUE, ROGUE.CROUCH_ATTACK, secondary_weapon, crouch_attack_complete)
         play_sound(snd.ROGUE_SWORD_ATTACK)
      end
   end -- crouch_attack.on_enter

   function crouch_attack.update(dt)
      perform_attack(crouch_attack)

      if is_down(X) then
         buffered_sword_attack = true
      elseif is_down(A) and (jump_count < max_jumps) then
         jump_count = jump_count + 1
         velocity_y = JUMP_SPEED
      end

      advance(move(dt, 0)) -- we don't move in that stance
      vertical_look = -1 -- override

      if velocity_y > 0 then
         machine.enter_state(jump_attack)
      elseif velocity_y < 0 then
         machine.enter_state(jump_attack)
      elseif not is_pressed(DOWN) then
         machine.enter_state(attack)
      end
   end -- crouch_attack.update

   function crouch_attack.on_exit(next_state)
      if next_state ~= crouch then
         set_stance(CHARACTER_HIGH_STANCE)
      end
   end -- crouch_attack.on_exit

   ---------------------------------------
   -- jump_attack
   ---------------------------------------

   local function jump_attack_complete()
      clear_attack_targets()
      if buffered_sword_attack then
         buffered_sword_attack = false
         ROGUE.current_animation = nil -- overide
         jump_attack.on_enter()
      else
         if ground then
            machine.enter_state(land)
         else
            if velocity_y > 0 then
               machine.enter_state(jump)
            else
               machine.enter_state(fall)
            end
            -- machine.enter_state(fall)
         end
      end
   end -- jump_attack_complete

   function jump_attack.on_enter(previous_state)
      label.set_text(debug_label, "Jump_attack")
      local current_animation_group = ROGUE.current_animation_group
      if current_animation_group == ROGUE.JUMP_LOOP then
         play_animation(ROGUE, ROGUE.JUMP_ATTACK1, secondary_weapon, jump_attack_complete)
         play_sound(snd.ROGUE_SWORD_ATTACK)
      elseif current_animation_group == ROGUE.JUMP_FINISH then
         local cursor = get(ROGUE.sprite, CURSOR)
         local frame = modf(cursor / ROGUE.current_animation.frame_step) + 1
         -- label.set_text(debug_label3, frame)
         play_animation(ROGUE, ROGUE.JUMP_ATTACK234[frame], secondary_weapon, jump_attack_complete)
         play_sound(snd.ROGUE_SWORD_ATTACK)
      elseif current_animation_group == ROGUE.FALL then
         local cursor = get(ROGUE.sprite, CURSOR)
         local frame = modf(cursor / ROGUE.current_animation.frame_step) + 1
         play_animation(ROGUE, ROGUE.FALL_ATTACK[frame], secondary_weapon, jump_attack_complete)
         play_sound(snd.ROGUE_SWORD_ATTACK)
      else
         if previous_state == attack or previous_state == crouch_attack then
            play_animation(ROGUE, ROGUE.JUMP_ATTACK234[1], secondary_weapon, jump_attack_complete, get(ROGUE.sprite, CURSOR))
         else
            play_animation(ROGUE, ROGUE.JUMP_ATTACK234[1], secondary_weapon, jump_attack_complete)
            play_sound(snd.ROGUE_SWORD_ATTACK)
         end
      end
   end -- jump_attack.on_enter

   function jump_attack.update(dt)
      perform_attack(jump_attack)

      if is_down(X) then
         buffered_sword_attack = true
      end

      if is_down(A) and (jump_count < max_jumps) then
         jump_count = jump_count + 1
         velocity_y = AIR_JUMP_SPEED
      elseif is_up(A) then
         if velocity_y > JUMP_CUT_SPEED then
            velocity_y = JUMP_CUT_SPEED
         end
      end

      check_directional_input()
      look_direction = previous_look_direction
      advance(move(dt))
      if ground then
         machine.enter_state(attack)
      end
   end -- jump_attack.update

   ---------------------------------------
   -- ledge_grab
   ---------------------------------------

   function ledge_grab.on_enter()
      label.set_text(debug_label, "Ledge_grab")
      play_animation(ROGUE, ROGUE.LEDGE_GRAB)
      play_sound(snd.ROGUE_LEDGE_GRAB)
      move_direction = 0
      jump_count = 0
      velocity_x = 0
      velocity_y = 0
   end -- ledge_grab.on_enter

   function ledge_grab.update(dt)
      local inst = get_instance(ledge.id)
      if inst then
         local dx = inst.dx or 0
         local dy = inst.dy or 0
         if ground or is_pressed(DOWN) then
            advance(dx, dy)
            machine.enter_state(fall)
         elseif is_down(A) or is_pressed(A) then
            advance(dx, dy)
            machine.enter_state(ledge_climb)
         else
            local id = raycast_controller.check_ledge(look_direction, position_x, position_y, dy)
            advance(dx, dy, ledge.id)
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
   -- ledge_climb
   ---------------------------------------

   function ledge_climb.on_enter()
      label.set_text(debug_label, "Ledge_climb")
      -- local hit = raycast_controller.check_down(position_x + (18 * look_direction), position_y + CHARACTER_HIGH_STANCE, 1)
      -- -- utils.log(hit)
      -- if not hit then
      --    look_direction = -look_direction
      --    turnaround(ROGUE)
      -- end
      play_animation(ROGUE, ROGUE.LEDGE_CLIMB)
      ledge_climb.rogue_x, ledge_climb.rogue_y = fastmath.vector3_get_components(ROGUE.current_animation.position)
      ledge_climb.previous = 0
   end -- ledge_climb.on_enter

   function ledge_climb.update(dt)
      local inst = get_instance(ledge.id)
      if inst then
         local dx = inst.dx or 0
         local dy = inst.dy or 0
         if ground or contact_up then
            advance(dx, dy)
            machine.enter_state(fall)
         else
            local t = get(ROGUE.sprite, CURSOR)
            local new = lerp(0, CHARACTER_HIGH_STANCE, t)
            local delta = new - ledge_climb.previous
            ledge_climb.previous = new
            advance(dx, dy + delta)
            ledge_climb.rogue_y = ledge_climb.rogue_y - delta
            vector3_set_components(vector3_stub, ledge_climb.rogue_x, ledge_climb.rogue_y)
            set_position(vector3_stub, ROGUE.object)
            if t == 1 then
               machine.enter_state(ledge_stand)
            end
         end
      else
         advance(move(dt))
         machine.enter_state(fall)
      end
   end -- ledge_climb.update

   ---------------------------------------
   -- ledge_stand
   ---------------------------------------

   function ledge_stand.on_enter()
      label.set_text(debug_label, "Ledge_stand")
      play_animation(ROGUE, ROGUE.LEDGE_STAND)
      play_sound(snd.ROGUE_LEDGE_CLIMB)
      ledge_stand.rogue_x, ledge_stand.rogue_y = fastmath.vector3_get_components(ROGUE.current_animation.position)
      ledge_stand.previous = 0
   end -- ledge_stand.on_enter

   function ledge_stand.update(dt)
      instance.needs_down_pass = true
      local inst = get_instance(ledge.id)
      if inst then
         local dx = inst.dx or 0
         local dy = inst.dy or 0
         -- else
         local t = get(ROGUE.sprite, CURSOR)
         local new = lerp(0, 18, t)
         local delta = new - ledge_stand.previous
         ledge_stand.previous = new
         velocity_x = 0
         velocity_y = 0
         advance(dx + delta * look_direction, dy, ledge.id)
         ledge_stand.rogue_x = ledge_stand.rogue_x - delta
         vector3_set_components(vector3_stub, ledge_stand.rogue_x, ledge_stand.rogue_y)
         set_position(vector3_stub, ROGUE.object)
         if t == 1 then
            if not ground then
               machine.enter_state(fall)
            else
               machine.enter_state(idle)
            end
         end
         -- end
      else
         advance(move(dt))
         machine.enter_state(fall)
      end
   end -- ledge_stand.update

   ---------------------------------------
   -- approach
   ---------------------------------------

   function approach.on_enter()
      label.set_text(debug_label, "Approach")
      local target = get_instance(first_responder)
      if target then
         velocity_x = 0
         velocity_y = 0
         jump_count = 0
         local target_x = target.get_position()
         if fastmath.combined_is_equal(target_x, position_x) then
            approach.t = INFINITY
         else
            approach.to = target_x - position_x
            look_direction = sign(approach.to)
            turnaround(ROGUE)
            play_animation(ROGUE, ROGUE.WALK, secondary_weapon)
            approach.t = 0
            approach.previous = 0
         end
      end
   end -- approach.on_enter

   function approach.update(dt)
      instance.needs_down_pass = true -- for ground check (we need to know our ground)

      local target = get_instance(first_responder)
      if target then
         local dx = target.dx or 0
         local dy = target.dy or 0
         if approach.t <= 1 then
            approach.t = approach.t + (dt * 70) / abs(approach.to) -- ~ MAX_HORIZONTAL_SPEED - GROUND_ACCELERATION * dt
            local new = lerp(0, approach.to, approach.t)
            local delta = new - approach.previous
            approach.previous = new
            advance(dx + delta, dy)
         else
            -- advance(dx, dy)
            if target.get_destination then
               -- map_change.map, map_change.door = target.get_destination()
               machine.enter_state(map_change)
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
      local map, door = target.get_destination()
      nc.post_notification(Maze.entity_did_leave_level_notification, root.path, map, door)
      runtime.remove_update_callback(instance)
      machine.enter_state(undefined)
   end --turnaround_complete

   function map_change.on_enter()
      label.set_text(debug_label, "Map_change")
      play_animation(ROGUE, ROGUE.TURNAROUND_DOOR, nil, turnaround_complete)
   end -- map_change.on_enter

   local function resign_first_responder()
      local inst = get_instance(first_responder)
      if inst then
         inst.resign_first_responder()
      end
      first_responder = nil
   end -- resign_first_responder

   local function discard_responder(responder, enter)
      if responder == first_responder then
         resign_first_responder()
      end
      if not enter then
         responders[responder] = nil
      end
   end -- discard_responder

   local function check_responders()
      local min_distance = HUGE
      local pretender = nil
      local pretender_instance = nil
      for id, enter in next, responders do
         local responder_instance = get_instance(id)
         if responder_instance then
            if enter and responder_instance.accepts_first_responder(instance) then
               local responder_position_x = responder_instance.get_position()
               local distance = abs(responder_position_x - position_x)
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

   local function update(dt)
      -- previous_move_direction = move_direction
      -- previous_look_direction = look_direction
      previous_velocity_y = velocity_y
      if ground then jump_count = 0 end
      instance.can_push = ground ~= nil
      check_responders()
      machine.update(dt)
      -- label.set_text(debug_label2, string.format("%.2f, %.2f", position_x, position_y))

      -- cape
      cape_prev_pos_x[1] = cape_pos_x[1]
      cape_prev_pos_y[1] = cape_pos_y[1]
      cape_pos_x[1] = position_x + cape_position_local_x * (move_direction == 0 and look_direction or move_direction)
      cape_pos_y[1] = position_y + cape_position_local_y
      for i = 1, CAPE_SEGMENT_COUNT do
         local dx = (cape_pos_x[i] - cape_prev_pos_x[i]) * CAPE_DRAG
         local dy = (cape_pos_y[i] - cape_prev_pos_y[i]) * CAPE_DRAG
         cape_prev_pos_x[i] = cape_pos_x[i]
         cape_prev_pos_y[i] = cape_pos_y[i]
         cape_pos_x[i] = cape_pos_x[i] + dx
         cape_pos_y[i] = cape_pos_y[i] + dy - CAPE_GRAVITY * dt
      end
      for i = 1, (CAPE_SEGMENT_COUNT - 1) do
         local ax = cape_pos_x[i]
         local ay = cape_pos_y[i]
         local bx = cape_pos_x[i + 1]
         local by = cape_pos_y[i + 1]
         local dx = bx - ax
         local dy = by - ay
         local distance = sqrt(dx * dx + dy * dy)
         if distance < 0.01 then distance = 0.01 end
         local difference = CAPE_CONSTRAINT_LENGTH - distance
         local percent = difference / distance
         if percent > 1 then percent = 1 end
         dx = dx * percent
         dy = dy * percent
         cape_pos_x[i + 1] = cape_pos_x[i + 1] + dx
         cape_pos_y[i + 1] = cape_pos_y[i + 1] + dy
      end
      for i = 1, CAPE_SEGMENT_COUNT do
         vector3_set_components(vector3_stub, cape_pos_x[i], cape_pos_y[i], -1)
         set_position(vector3_stub, cape_segments[i])
      end
   end -- update

   function instance.on_contact(contact, direction)
      if contact == ledge.id then return end
      if direction == 1 then
         contact_right = true
      else
         contact_left = true
      end
   end -- instance.on_contact

   function instance.on_contact_up()
      contact_up = true
   end -- instance.on_contact

   function instance.before_update()
      contact_left = false
      contact_right = false
      contact_up = false
   end -- instance.before_update

   local function on_level_appear(_, x, y)
      -- player
      position_x = x
      position_y = y
      velocity_x = 0
      velocity_y = 0
      vector3_set_components(vector3_stub, x, y, 0)
      set_position(vector3_stub, root)
      runtime.add_update_callback(instance, update)

      -- cape
      local cape_x = cape_position_local_x + position_x
      local cape_y = cape_position_local_y + position_y
      vector3_set_components(vector3_stub, cape_x, cape_y)
      set_position(vector3_stub, cape_anchor)
      for i = 1, CAPE_SEGMENT_COUNT do
         cape_pos_x[i] = cape_x
         cape_pos_y[i] = cape_y
         cape_prev_pos_x[i] = cape_x
         cape_prev_pos_y[i] = cape_y
         vector3_set_components(vector3_stub, cape_x, cape_y, 1)
         set_position(vector3_stub, cape_segments[i])
         cape_y = cape_y - 3
      end
   end -- on_level_appear

   function instance.init()
      root = msg.url(".")
      instance.root = root
      instance.can_push = true
      pivot = msg.url(nil, "pivot", nil)
      ROGUE.object = msg.url(nil, "rogue", nil)
      ROGUE.sprite = msg.url("rogue#sprite")
      ROGUE.shadow_object = msg.url(nil, "shadow", nil)
      ROGUE.shadow_sprite = msg.url("shadow#sprite")
      ROGUE.current_animation_group = nil
      ROGUE.current_animation = nil
      ROGUE.on_complete = nil
      collisionobject_raycast_high = msg.url("#collisionobject_raycast_high")
      collisionobject_raycast_low = msg.url("#collisionobject_raycast_low")
      collisionobject_hitbox_high = msg.url("#collisionobject_hitbox_high")
      -- collisionobject_hitbox_low = msg.url("#collisionobject_hitbox_low")
      vector3_stub = go.get_position()
      position_x, position_y = fastmath.vector3_get_components(vector3_stub)
      acceleration = GROUND_ACCELERATION
      max_horizontal_speed = MAX_HORIZONTAL_SPEED
      gravity = NORMAL_GRAVITY
      velocity_x = 0
      velocity_y = 0
      instance.dx = 0
      instance.dy = 0
      move_direction = 0
      look_direction = 1
      vertical_look = 1
      ground = nil
      previous_look_direction = 0
      buffered_sword_attack = false
      max_jumps = MAX_JUMPS > 0 and MAX_JUMPS or HUGE
      raycast_controller.set_width(CHARACTER_WIDTH)
      set_stance(CHARACTER_HIGH_STANCE)
      runtime.set_instance(root.path, instance)

      nc.add_observer(on_level_appear, Maze.level_will_appear_notification)

      debug_label = msg.url("#debug_label")
      debug_label2 = msg.url("#debug_label2")
      debug_label3 = msg.url("#debug_label3")
      msg.post(ROGUE.shadow_sprite, msg.DISABLE)
      -- go.set(ROGUE.sprite, "tint.w", 0)
      -- msg.post(debug_label, msg.DISABLE)
      msg.post(debug_label2, msg.DISABLE)
      msg.post(debug_label3, msg.DISABLE)
      msg.post("rogue1#sprite", msg.DISABLE)
      -- utils.log(gameobject .. " gravity: " .. NORMAL_GRAVITY .. ", jump speed: " .. JUMP_SPEED)

      -- red sword
      go.set(ROGUE.sprite, "sword", swords[current_sword].color)

      -- red shield
      -- go.set(ROGUE.sprite, "shield_a", vmath.vmath.vector4(192/255, 45/255, 0, 1))
      -- go.set(ROGUE.sprite, "shield_b", vmath.vmath.vector4(109/255, 26/255, 0, 1))

      -- green shield
      go.set(ROGUE.sprite, "shield_a", shields[current_shield].color_a)
      go.set(ROGUE.sprite, "shield_b", shields[current_shield].color_b)

      -- cape
      cape_anchor = msg.url("cape_anchor")
      cape_position_local_x, cape_position_local_y = fastmath.vector3_get_components(go.get_position(cape_anchor))
      for i = 1, CAPE_SEGMENT_COUNT do
         cape_segments[i] = msg.url("cape_segment" .. i)
      end
   end -- init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(on_level_appear, Maze.level_will_appear_notification)
      fastmath.clear_arrays(cape_segments, cape_pos_x, cape_pos_y, cape_prev_pos_x, cape_prev_pos_y)
   end -- deinit

   function instance.on_collision_response(message)
      local other_instance = get_instance(message.other_id)
      if other_instance then
         if other_instance.collect_damage then
            local value = other_instance.collect_damage()
            apply_damage(value)
         end
      end
   end -- on_collision_response

   function instance.on_trigger_response(message)
      local other_instance = get_instance(message.other_id)
      if other_instance then
         if other_instance.accepts_first_responder then
            responders[message.other_id] = message.enter
         end
      end
   end -- on_trigger_response

   function instance.get_position()
      return position_x, position_y, look_direction, vertical_look
   end -- instance.get_position

   return instance
end

local pool = Pool.new(make)

-- export
return {
   new = pool.new,
   free = pool.free,
   fill = pool.fill,
   purge = pool.purge,
}
