local Pool = require("m.pool")
local RaycastController = require("m.raycast_controller")
local StateMachine = require("m.state_machine")
local groups = require("m.groups")
local const = require("m.constants")
local animation = require("m.animation")
local nc = require("m.notification_center")
local ui = require("m.ui.ui")
local colors = require("m.colors")
local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local gamestate = require("pixelfrog.game.gamestate")
local snd = require("sound.sound")
local factories = require("pixelfrog.game.factories")
local loot_distributor = require("pixelfrog.props.collectable.loot_distributor")

local play_animation = animation.play
local play_sound = snd.play_sound
local is_pressed = runtime.is_pressed
local is_down = runtime.is_down
local is_up = runtime.is_up
local set_position = go.set_position
local set_scale = go.set_scale
local animate = go.animate
local set = go.set
local get = go.get
local abs = fastmath.abs
local min = fastmath.min
local max = fastmath.max
local sign = fastmath.sign
local clamp = fastmath.clamp
local pick_next = fastmath.pick_next
local ceil = math.ceil
local vector3_set_xyz = fastmath.vector3_set_xyz
local get_instance = runtime.get_instance
local physics_set_hflip = physics.set_hflip

local LEFT_BTN = ui.LEFT
local RIGHT_BTN = ui.RIGHT
local DOWN_BTN = ui.DOWN
local UP_BTN = ui.UP
local JUMP_BTN = ui.A
local ATTACK_BTN = ui.X
local ALT_ATTACK_BTN = ui.Y

local PLAYER_DEPTH = layers.get_depth(layers.PLAYER)
local CHARACTER_WIDTH = 14
local CHARACTER_HEIGHT = 24
local MAX_HORIZONTAL_SPEED = 140
local MAX_FALL_SPEED = -800
local MAX_RISE_SPEED = 600
local GROUND_ACCELERATION = 5000
local MAX_AIR_SPEED = 148
local AIR_ACCELERATION = 5000
local MAX_JUMPS = 2
-- local JUMP_HEIGHT = 54--56
local JUMP_TIME_TO_APEX = 0.46--0.3--0.38
local NORMAL_GRAVITY = -557.8512-- -(2 * JUMP_HEIGHT) / (JUMP_TIME_TO_APEX * JUMP_TIME_TO_APEX)
local JUMP_SPEED = 245.4545--abs(NORMAL_GRAVITY) * JUMP_TIME_TO_APEX
-- utils.log("gravity ", NORMAL_GRAVITY, "jump_speed ", JUMP_SPEED)
-- local JUMP_CUT_SPEED = JUMP_SPEED * 0.4
local vector3_stub = vmath.vector3()
local IDLE_SQUASH = vmath.vector3(1.15, 0.85, 1)
local JUMP_STRETCH = vmath.vector3(0.9, 1.15, 1)
-- local IDLE_SQUASH = vmath.vector3(1)
-- local JUMP_STRETCH = vmath.vector3(1)

local sword_properties = {
   [const.ROOT] = {
      speed = 0,
      damage_points = 0,
   }
}

local ANIMATION = {
   BLANK = {
      { id = hash("captain_blank"), position = vmath.vector3(0, 0, 0), },
   },
   IDLE = {
      { id = hash("captain_idle"), position = vmath.vector3(0, 14, 0), },
      { id = hash("captain_idle_sword"), position = vmath.vector3(7, 14, 0), },
   },
   RUN = {
      { id = hash("captain_run"), position = vmath.vector3(0, 15, 0), },
      { id = hash("captain_run_sword"), position = vmath.vector3(7, 15, 0), },
   },
   JUMP = {
      { id = hash("captain_jump"), position = vmath.vector3(0, 14, 0), },
      { id = hash("captain_jump_sword"), position = vmath.vector3(1, 14, 0), },
   },
   FALL = {
      { id = hash("captain_fall"), position = vmath.vector3(0, 15, 0), },
      { id = hash("captain_fall_sword"), position = vmath.vector3(6, 15, 0), },
      -- { id = hash("captain_fall_sword"), position = vmath.vector3(0, 15, 0), },
   },
   HIT = {
      { id = hash("captain_hit"), position = vmath.vector3(1, 15, 0), },
      { id = hash("captain_hit_sword"), position = vmath.vector3(7, 15, 0), },
   },
   DEAD = {
      { id = hash("captain_dead"), position = vmath.vector3(0, 13, 0), },
   },
   DEAD_GROUND = {
      { id = hash("captain_dead_ground"), position = vmath.vector3(0, 10, 0), },
   },
   ATTACK1 = {
      { id = hash("captain_attack1"), position = vmath.vector3(10, 15, 0), },
   },
   ATTACK2 = {
      { id = hash("captain_attack2"), position = vmath.vector3(8, 12, 0), },
   },
   ATTACK3 = {
      { id = hash("captain_attack3"), position = vmath.vector3(7, 16, 0), },
   },
   AIR_ATTACK1 = {
      { id = hash("captain_air_attack1"), position = vmath.vector3(6, 4, 0), },
   },
   THROW_SWORD = {
      { id = hash("captain_throw_sword"), position = vmath.vector3(1, 16, 0), },
   },
   APPEARANCE = {
      { id = hash("appearance"), position = vmath.vector3(-1, 17, 0), },
   },
}

-- local HIT_ENEMY_SOUNDS = {
--    snd.FATE_SLICE_FLESH_1,
--    snd.FATE_SLICE_FLESH_2,
--    snd.FATE_SLICE_FLESH_3,
-- }

-- local FOOT_STEPS = {
--    snd.SHANTAE_FOOT_STEP_GRASS_1,
--    snd.SHANTAE_FOOT_STEP_GRASS_2,
--    snd.SHANTAE_FOOT_STEP_GRASS_3,
--    snd.SHANTAE_FOOT_STEP_GRASS_4,
--    snd.SHANTAE_FOOT_STEP_GRASS_5,
-- }

local FOOT_STEPS = {
   snd.SHANTAE_FOOT_STEP_CEMENT_1,
   snd.SHANTAE_FOOT_STEP_CEMENT_2,
   snd.SHANTAE_FOOT_STEP_CEMENT_3,
   snd.SHANTAE_FOOT_STEP_CEMENT_4,
   snd.SHANTAE_FOOT_STEP_CEMENT_5,
   snd.SHANTAE_FOOT_STEP_CEMENT_6,
   snd.SHANTAE_FOOT_STEP_CEMENT_7,
   snd.SHANTAE_FOOT_STEP_CEMENT_8,
}


local function make()
   local instance = {
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
      horizontal_drag = 0,
      vertical_drag = 0,
      GROUND = {
         groups.SOLID,
         groups.ONEWAY,
         groups.SLOPE,
         groups.BOX,
         groups.ENEMY_HITBOX,
         groups.PROPS_HITBOX,
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
      CLIMBABLE = {
         groups.SOLID,
         groups.BOX,
         -- groups.PROPS_HITBOX,
      },
   }

   local char = animation.new_target()

   local debug_label
   local move_direction
   local horizontal_look
   local max_horizontal_speed
   local velocity_x
   local velocity_y
   local acceleration
   local gravity
   local ground
   -- local up_space
   local root
   local collisionobject_sensor
   local collisionobject_hitbox
   local collisionobject_hurtbox1
   local collisionobject_hurtbox2
   local collisionobject_hurtbox3
   local collisionobject_hurtbox4
   local jump_count
   local jump_buffer_time
   local max_jumps
   local jump_grace_time
   -- local contact_left
   -- local contact_right
   local attack_followup
   local attack_start_frame
   local attack_stop_frame
   -- local scheduled_attack
   local attack_direction
   local hit_list = {}
   local recoil
   local stagger_end_time
   local hit_direction
   local is_flashing
   local next_switch_time = 0
   local visible = false
   local flash_count = 16
   local sword_speed
   local sword_damage_points
   local attack_followup_time
   local next_attack
   local responders = {}
   local first_responder

   local transit_state
   local hidden = {}
   local appearance = {}
   local idle = {}
   local run = {}
   local jump = {}
   local fall = {}
   local hit = {}
   local dead = {}
   local attack1 = {}
   local attack2 = {}
   local attack3 = {}
   local air_attack1 = {}
   local throw = {}
   -- local checkpoint_x
   -- local checkpoint_y
   local sword_count
   local play_time

   local raycast_controller = RaycastController.new(instance)
   local machine = StateMachine.new()

   local attack_targets = {}

   local function check_directional_input()
      local is_pressed_left = is_pressed(LEFT_BTN)
      local is_pressed_right = is_pressed(RIGHT_BTN)

      if is_down(LEFT_BTN) then
         move_direction = -1
         horizontal_look = -1
      elseif is_down(RIGHT_BTN) then
         move_direction = 1
         horizontal_look = 1
      elseif is_pressed_left and (not is_pressed_right) then
         move_direction = -1
         horizontal_look = -1
      elseif is_pressed_right and (not is_pressed_left) then
         move_direction = 1
         horizontal_look = 1
      elseif not(is_pressed_left or is_pressed_right) then
         move_direction = 0
      end
   end -- check_directional_input

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

   local function advance(dx, dy, id)
      dx, dy, velocity_x, velocity_y, ground = raycast_controller.update(instance.x, instance.y, dx, dy, velocity_x, velocity_y, id)
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

   local function turnaround(target, direction)
      if direction == instance.horizontal_look then return end
      instance.horizontal_look = direction
      go.set_rotation(direction >= 0 and const.QUAT_Y_0 or const.QUAT_Y_180, target.pivot)
   end -- turnaround

   -- local function warp_to_position(x, y, horizontal_look)
   --    instance.horizontal_drag = 0
   --    instance.vertical_drag = 0
   --    velocity_x = 0
   --    velocity_y = 0
   --    instance.dx = 0
   --    instance.dy = 0
   --    instance.x = x
   --    instance.y = y
   --    vector3_set_xyz(vector3_stub, x, y, 0)
   --    set_position(vector3_stub, root)
   --    if horizontal_look then
   --       instance.horizontal_look = horizontal_look
   --    end
   -- end -- warp_to_position

   local function perform_jump(speed, effect)
      jump_count = jump_count + 1
      velocity_y = speed
      vector3_set_xyz(vector3_stub, instance.x, instance.y, 0)
      factory.create(effect, vector3_stub, instance.horizontal_look < 0 and const.QUAT_IDENTITY or const.QUAT_Y_180, nil, 1)
      play_sound(snd.SHANTAE_JUMP2)
   end -- perform_jump

   local function alter_health(amount)
      local maximum = gamestate.get(nil, gamestate.player, "max_health", 3)
      local current = gamestate.get(nil, gamestate.player, "health", maximum)
      local next = current + amount
      if next > maximum then
         return false
      end
      next = clamp(next, 0, maximum)
      gamestate.set(nil, gamestate.player, "health", next)
      return next
   end -- alter_health

   local function alter_wealth(amount)
      local current = gamestate.get(nil, gamestate.player, "wealth", 0)
      local next = current + amount
      if (next < 0) or (next > 9999) then
         return false
      end
      gamestate.set(nil, gamestate.player, "wealth", next)
      return true
   end -- alter_wealth

   local function alter_projectiles(amount)
      local current = gamestate.get(nil, gamestate.player, "projectiles", 0)
      local next = current + amount
      if (next < 0) or (next > 9) then
         return false
      end
      gamestate.set(nil, gamestate.player, "projectiles", next)
      sword_count = next
      return true
   end -- alter_projectiles

   local function get_key(variant)
      local key_name = gamestate[variant]
      local has_key = gamestate.get(nil, gamestate.player, "has_key", nil) == key_name
      if not has_key then
         gamestate.set(nil, gamestate.player, "has_key", key_name)
         nc.post_notification(key_name)
         return true
      end
      return false
   end -- get_key

   local function save_play_time()
      -- utils.log("saving play time...")
      gamestate.set(nil, gamestate.player, "play_time", gamestate.get(nil, gamestate.player, "play_time", 0) + play_time)
      play_time = 0
   end -- save_play_time

   local function resign_first_responder()
      local inst = get_instance(first_responder)
      if inst then
         inst.resign_first_responder()
      end
      first_responder = nil
   end -- resign_first_responder

   local function discard_responder(responder, enter)
      if not responder then
         return
      end
      if responder == first_responder then
         resign_first_responder()
      end
      if not enter then
         responders[responder] = nil
      end
   end -- discard_responder

   local function check_responders()
      local min_distance = const.INFINITY
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

   local function update(dt)
      -- if runtime.current_frame % 2 == 0 then
      --    factory.create("game:/game#dot", vmath.vector3(instance.x, instance.y, 0))
      -- end
      -- if (not ground) and (runtime.current_frame % 2 == 0) then
      --    factory.create("game:/game#dot", vmath.vector3(instance.x, instance.y, 0))
      -- end
      play_time = play_time + dt

      check_responders()

      for k in next, hit_list do
         hit_list[k] = nil
      end
      recoil = 0
      if runtime.current_time > attack_followup_time then
         next_attack = attack1
      end
      -- contact_left = false
      -- contact_right = false
      -- every ground must have instance!
      local ground_instance = get_instance(ground)
      -- utils.log(ground)
      if ground_instance and ground_instance.is_ground then
         -- utils.log(ground)
         acceleration = ground_instance.acceleration or GROUND_ACCELERATION
         max_horizontal_speed = min(ground_instance.max_speed or const.INFINITY, MAX_HORIZONTAL_SPEED)
         jump_count = 0
         instance.can_push = true
         if ground_instance.on_step then
            ground_instance.on_step()
         end
      else
         -- if move_direction ~= 0 then
         acceleration = AIR_ACCELERATION
         max_horizontal_speed = max(max_horizontal_speed, MAX_AIR_SPEED)
         -- end
         instance.can_push = false
      end
      machine.update(dt)
      if flash_count < 0 then
         is_flashing = false
         visible = false
         flash_count = 20
         -- set(char.sprite, const.TINT_W, 1)
         set(char.sprite, const.TINT, colors.WHITE)
         msg.post(collisionobject_hitbox, msg.ENABLE)
      end
      if is_flashing and (runtime.current_time > next_switch_time) then
         next_switch_time = runtime.current_time + 0.05
         flash_count = flash_count - 1
         visible = not visible
         -- set(char.sprite, const.TINT_W, visible and 1 or 0)
         set(char.sprite, const.TINT, visible and colors.WHITE or colors.TRANSPARENT_WHITE)
      end
      instance.horizontal_drag = 0
      instance.vertical_drag = 0
   end -- update

   ---------------------------------------
   -- hidden
   ---------------------------------------

   function hidden.on_enter()
      label.set_text(debug_label, "Hidden")
      play_animation(char, ANIMATION.BLANK)
      -- runtime.remove_update_callback(instance)
   end -- hidden.on_enter

   ---------------------------------------
   -- appearance
   ---------------------------------------

   local function appearance_complete()
      msg.post(collisionobject_hitbox, msg.ENABLE)
      msg.post(collisionobject_sensor, msg.ENABLE)
      is_flashing = false
      visible = false
      flash_count = 16
      set(char.sprite, const.TINT, colors.WHITE)
      -- set(char.sprite, const.TINT_W, 1)
      -- runtime.add_update_callback(instance, update)
      velocity_x = 0
      velocity_y = 0
      machine.enter_state(fall)
   end -- appearance_complete

   function appearance.on_enter()
      label.set_text(debug_label, "Appearance")
      play_animation(char, ANIMATION.APPEARANCE, nil, appearance_complete)
      gamestate.set(nil, gamestate.player, "health", gamestate.get(nil, gamestate.player, "max_health", 3))
   end -- appearance.on_enter

   ---------------------------------------
   -- idle
   ---------------------------------------

   local function on_scale_complete()
      set_scale(1, char.pivot)
   end -- on_scale_complete

   function idle.on_enter(previous_state)
      label.set_text(debug_label, "Idle")
      play_animation(char, ANIMATION.IDLE, sword_count > 0 and 2 or 1)
      if (previous_state == fall) or (previous_state == run) or (previous_state == hit) then
         animate(char.pivot, const.SCALE, go.PLAYBACK_ONCE_PINGPONG, IDLE_SQUASH, go.EASING_INOUTQUAD, 0.15, 0, on_scale_complete)
         if previous_state ~= run then
            vector3_set_xyz(vector3_stub, instance.x, instance.y, 0)
            factory.create(factories.CAPTAIN_LAND_DUST, vector3_stub, const.QUAT_IDENTITY, nil, 1)
            -- play_sound(snd.SHANTAE_LAND)
         end
      end
   end -- idle.on_enter

   function idle.update(dt)
      check_directional_input()
      turnaround(char, horizontal_look)

      local is_pressed_down_btn = is_pressed(DOWN_BTN)

      if (jump_buffer_time > 0) or is_down(JUMP_BTN) then
         jump_buffer_time = 0
         if is_pressed_down_btn then
            local inst = get_instance(ground)
            if inst and inst.can_jump_down then
               instance.bypass = ground
            elseif jump_count < max_jumps then
               perform_jump(JUMP_SPEED, factories.CAPTAIN_JUMP_DUST)
            end
         elseif jump_count < max_jumps then
            perform_jump(JUMP_SPEED, factories.CAPTAIN_JUMP_DUST)
         end
      end

      advance(move(dt))

      if is_pressed_down_btn then
         instance.vertical_look = -1
      end

      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif is_down(UP_BTN) then
         nc.post_notification("launch", nil, instance.x, instance.y)
      elseif is_down(ATTACK_BTN) and (sword_count > 0) then
         machine.enter_state(next_attack)
      elseif is_down(ALT_ATTACK_BTN) and (sword_count > 0) then
         machine.enter_state(throw)
      elseif move_direction ~= 0 and (velocity_x ~= 0) then
         machine.enter_state(run)
      end
   end -- idle.update

   ---------------------------------------
   -- run
   ---------------------------------------

   function run.on_enter(previous_state)
      label.set_text(debug_label, "Run")
      play_animation(char, ANIMATION.RUN, sword_count > 0 and 2 or 1)
      if (previous_state == fall) or (previous_state == air_attack1) or (previous_state == hit) then
         animate(char.pivot, const.SCALE, go.PLAYBACK_ONCE_PINGPONG, IDLE_SQUASH, go.EASING_INOUTQUAD, 0.15, 0, on_scale_complete)
         vector3_set_xyz(vector3_stub, instance.x, instance.y, 0)
         factory.create(factories.CAPTAIN_RUN_DUST, vector3_stub, instance.horizontal_look > 0 and const.QUAT_IDENTITY or const.QUAT_Y_180, nil, 1)
         -- play_sound(snd.SHANTAE_LAND)
      end
      run.loud_frame = 3
   end -- run.on_enter

   function run.update(dt)
      check_directional_input()
      turnaround(char, horizontal_look)

      if move_direction == 0 then
         play_animation(char, ANIMATION.IDLE, sword_count > 0 and 2 or 1)
      else
         play_animation(char, ANIMATION.RUN, sword_count > 0 and 2 or 1)
         local cursor = get(char.sprite, const.CURSOR)
         local frame = ceil(cursor * 6) -- frame count
         -- utils.log(frame)
         if frame == run.loud_frame then
            vector3_set_xyz(vector3_stub, instance.x, instance.y, 0)
            factory.create(factories.CAPTAIN_RUN_DUST, vector3_stub, instance.horizontal_look > 0 and const.QUAT_IDENTITY or const.QUAT_Y_180, nil, 1)
            -- play_sound(snd.KAHO_GRASS_FOOTSTEP)
            -- play_sound(snd.ROGUE_FOOTSTEP)
            play_sound(pick_next(FOOT_STEPS, 8))
            run.loud_frame = run.loud_frame == 3 and 6 or 3
         end
      end

      if ((jump_buffer_time > 0) or is_down(JUMP_BTN)) and (jump_count < max_jumps) then
         jump_buffer_time = 0
         perform_jump(JUMP_SPEED, factories.CAPTAIN_JUMP_DUST)
      end

      advance(move(dt))

      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif is_down(ATTACK_BTN) and (sword_count > 0) then
         machine.enter_state(next_attack)
      elseif is_down(ALT_ATTACK_BTN) and (sword_count > 0) then
         machine.enter_state(throw)
      elseif velocity_x == 0 then
         machine.enter_state(idle)
      end
   end -- run.update

   ---------------------------------------
   -- jump
   ---------------------------------------

   function jump.on_enter()
      label.set_text(debug_label, "Jump")
      instance.can_push = false
      turnaround(char, horizontal_look)
      play_animation(char, ANIMATION.JUMP, sword_count > 0 and 2 or 1)
      animate(char.pivot, const.SCALE, go.PLAYBACK_ONCE_PINGPONG, JUMP_STRETCH, go.EASING_INOUTQUAD, JUMP_TIME_TO_APEX * 0.7, 0, on_scale_complete)
   end -- jump.on_enter

   function jump.update(dt)
      check_directional_input()
      turnaround(char, horizontal_look)

      if is_down(JUMP_BTN) and (jump_count < max_jumps) and (velocity_y < JUMP_SPEED) then
         perform_jump(JUMP_SPEED * 0.85, factories.CAPTAIN_AIR_JUMP_DUST)
         animate(char.pivot, const.SCALE, go.PLAYBACK_ONCE_PINGPONG, JUMP_STRETCH, go.EASING_INOUTQUAD, JUMP_TIME_TO_APEX * 0.7, 0, on_scale_complete)
      elseif is_up(JUMP_BTN) and (instance.vertical_drag == 0) then
         velocity_y = velocity_y * 0.6
      end

      advance(move(dt))

      instance.vertical_look = 0

      if is_down(ATTACK_BTN) and (sword_count > 0) then
         machine.enter_state(air_attack1)
      elseif is_down(ALT_ATTACK_BTN) and (sword_count > 0) then
         machine.enter_state(throw)
      elseif velocity_y < 0 then
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
      -- utils.log("FALL")
      label.set_text(debug_label, "Fall")
      jump_grace_time = (previous_state == hit) and 0 or ((1 / 60) * 10)
      play_animation(char, ANIMATION.FALL,sword_count > 0 and 2 or 1)
      gravity = -1000
   end -- fall.on_enter

   function fall.update(dt)
      check_directional_input()
      turnaround(char, horizontal_look)

      if instance.vertical_drag ~= 0 then
         jump_count = 1
      end

      jump_buffer_time = jump_buffer_time - dt

      if is_down(JUMP_BTN) then
         local js = JUMP_SPEED * 0.85
         if jump_count < max_jumps then
            if jump_count == 0 then
               if jump_grace_time > 0 then
                  js = JUMP_SPEED
               else
                  jump_count = jump_count + 1
               end
            end
            if jump_count < max_jumps then
               perform_jump(js, factories.CAPTAIN_AIR_JUMP_DUST)
            end
         else
            jump_buffer_time = (1 / 60) * 10
         end
      end

      jump_grace_time = jump_grace_time - dt

      advance(move(dt))

      instance.vertical_look = 0

      if is_down(ATTACK_BTN) and (sword_count > 0) then
         jump_count = jump_count + 1
         machine.enter_state(air_attack1)
      elseif is_down(ALT_ATTACK_BTN) and (sword_count > 0) then
         machine.enter_state(throw)
      elseif velocity_y > 0 then
         machine.enter_state(jump)
      elseif ground then
         if velocity_x == 0 then
            machine.enter_state(idle)
         else
            machine.enter_state(run)
         end
      end
   end -- fall.update

   function fall.on_exit()
      instance.bypass = nil
      gravity = NORMAL_GRAVITY
   end -- fall.on_exit

   ---------------------------------------
   -- hit
   ---------------------------------------

   function hit.on_enter()
      label.set_text(debug_label, "Hit")
      play_animation(char, ANIMATION.HIT, sword_count > 0 and 2 or 1, animation.done_sink)
      msg.post(collisionobject_hitbox, msg.DISABLE)
      stagger_end_time = runtime.current_time + 0.4
      velocity_x = 0
      velocity_y = 100
      nc.post_notification(const.CAMERA_SHAKE_REQUEST_NOTIFICATION, nil, 8, 0.15)
   end -- hit.on_enter

   function hit.update(dt)
      advance(move(dt * 1.25, hit_direction, AIR_ACCELERATION, 100, NORMAL_GRAVITY))
      -- advance(move(dt * 1.25, hit_direction, AIR_ACCELERATION, 140, NORMAL_GRAVITY * 0.725))
      if ground or (runtime.current_time > stagger_end_time) then
         check_directional_input()
         turnaround(char, horizontal_look)
         is_flashing = true
         if velocity_y > 0 then
            machine.enter_state(jump)
         elseif velocity_y < 0 then
            machine.enter_state(fall)
         elseif move_direction == 0 then
            machine.enter_state(idle)
         else
            machine.enter_state(run)
         end
      end
   end -- hit.update

   ---------------------------------------
   -- dead
   ---------------------------------------

   local function on_dead_done()
      nc.post_notification(const.ENTITY_DID_LEAVE_LEVEL_NOTIFICATION, root.path)
      transit_state = hidden
      -- warp_to_position(checkpoint_x, checkpoint_y)
      -- runtime.add_update_callback(instance, update)
      -- runtime.remove_update_callback(instance)
   end -- on_dead_done

   function dead.on_enter()
      label.set_text(debug_label, "Dead")
      snd.play_sound(snd.SHANTAE_DEATH)
      play_animation(char, ANIMATION.DEAD, nil, animation.done_sink)
      msg.post(collisionobject_hitbox, msg.DISABLE)
      -- msg.post(collisionobject_sensor, msg.DISABLE)
      velocity_x = 0
      velocity_y = 100
      nc.post_notification(const.CAMERA_SHAKE_REQUEST_NOTIFICATION, nil, 8, 0.15)
   end -- dead.on_enter

   function dead.update(dt)
      advance(move(dt * 1.25, hit_direction, AIR_ACCELERATION, 100, NORMAL_GRAVITY))
      if ground then
         runtime.remove_update_callback(instance)
         velocity_x = 0
         velocity_y = 0
         instance.dx = 0
         instance.dy = 0
         play_animation(char, ANIMATION.DEAD_GROUND, nil, on_dead_done)
      end
   end -- dead.update

   ---------------------------------------
   -- attack1
   ---------------------------------------

   local function on_attack1_complete()
      turnaround(char, horizontal_look)
      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif attack_followup then
         machine.enter_state(attack2)
      elseif move_direction == 0 then
         machine.enter_state(idle)
      else
         machine.enter_state(run)
      end
   end -- on_attack1_complete

   function attack1.on_enter(previous_state)
      label.set_text(debug_label, "Attack1")
      if previous_state == air_attack1 then
         play_animation(char, ANIMATION.ATTACK1, nil, on_attack1_complete, get(char.sprite, const.CURSOR))
      else
         play_animation(char, ANIMATION.ATTACK1, nil, on_attack1_complete)
         snd.play_sound(snd.SWING_SWORD_01)
         for k, _ in next, attack_targets do
            attack_targets[k] = nil
         end
      end
      velocity_x = 0
      attack_followup = false
      attack_followup_time = runtime.current_time + 0.4
      next_attack = attack2
      attack_direction = instance.horizontal_look
      attack_start_frame = runtime.current_frame + 3
      attack_stop_frame = attack_start_frame + 1
      physics_set_hflip(collisionobject_hurtbox1, attack_direction ~= 1)
   end -- attack1.on_enter

   function attack1.update(dt)
      check_directional_input()

      if runtime.current_frame == attack_start_frame then
         msg.post(collisionobject_hurtbox1, msg.ENABLE)
         attack_start_frame = 0
      elseif runtime.current_frame == attack_stop_frame then
         msg.post(collisionobject_hurtbox1, msg.DISABLE)
         attack_stop_frame = 0
      end

      if is_down(ATTACK_BTN) then
         attack_followup = true
      end

      -- local t = get(char.sprite, const.CURSOR)
      -- local stop = 3 / 10
      -- if t > 0.75 then
      --    advance(move(dt, attack_direction, nil, 60))
      -- else
      if is_down(JUMP_BTN) and (jump_count < max_jumps)then
         velocity_y = JUMP_SPEED
      end
      -- advance(move(dt, attack_direction, nil, 30))
      advance(move(dt, 0))
      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      end
      -- end
   end -- attack1.update

   function attack1.on_exit()
      msg.post(collisionobject_hurtbox1, msg.DISABLE)
   end -- attack1.on_exit

   ---------------------------------------
   -- attack2
   ---------------------------------------

   local function on_attack2_complete()
      turnaround(char, horizontal_look)
      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif attack_followup then
         machine.enter_state(attack3)
      elseif move_direction == 0 then
         machine.enter_state(idle)
      else
         machine.enter_state(run)
      end
   end -- on_attack2_complete

   function attack2.on_enter()
      label.set_text(debug_label, "Attack2")
      play_animation(char, ANIMATION.ATTACK2, nil, on_attack2_complete)
      snd.play_sound(snd.SWING_SWORD_02)
      velocity_x = 0
      attack_followup = false
      attack_followup_time = runtime.current_time + 0.4
      next_attack = attack3
      attack_direction = instance.horizontal_look
      attack_start_frame = runtime.current_frame + 3
      attack_stop_frame = attack_start_frame + 1
      physics_set_hflip(collisionobject_hurtbox2, attack_direction ~= 1)
      for k, _ in next, attack_targets do
         attack_targets[k] = nil
      end
      -- pprint(attack_targets)
   end -- attack2.on_enter

   function attack2.update(dt)
      check_directional_input()

      if runtime.current_frame == attack_start_frame then
         msg.post(collisionobject_hurtbox2, msg.ENABLE)
         attack_start_frame = 0
      elseif runtime.current_frame == attack_stop_frame then
         msg.post(collisionobject_hurtbox2, msg.DISABLE)
         attack_stop_frame = 0
      end

      if is_down(ATTACK_BTN) then
         attack_followup = true
      end

      -- local t = get(char.sprite, const.CURSOR)
      -- local stop = 3 / 10
      -- if t > 0.75 then
      --    advance(move(dt, attack_direction, nil, 60))
      -- else
      if is_down(JUMP_BTN) and (jump_count < max_jumps)then
         velocity_y = JUMP_SPEED
      end
      -- advance(move(dt, attack_direction, nil, 30))
      advance(move(dt, 0))
      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      end
      -- end
   end -- attack2.update

   function attack2.on_exit()
      msg.post(collisionobject_hurtbox2, msg.DISABLE)
   end -- attack2.on_exit

   ---------------------------------------
   -- attack3
   ---------------------------------------

   local function on_attack3_complete()
      turnaround(char, horizontal_look)
      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif move_direction == 0 then
         machine.enter_state(idle)
      else
         machine.enter_state(run)
      end
   end -- on_attack3_complete

   function attack3.on_enter()
      label.set_text(debug_label, "Attack3")
      play_animation(char, ANIMATION.ATTACK3, nil, on_attack3_complete)
      snd.play_sound(snd.GOBLIN_SWORD_SLASH)
      velocity_x = 0
      attack_followup_time = 0
      attack_direction = instance.horizontal_look
      attack_start_frame = runtime.current_frame + 3
      attack_stop_frame = attack_start_frame + 1
      physics_set_hflip(collisionobject_hurtbox3, attack_direction ~= 1)
      for k, _ in next, attack_targets do
         attack_targets[k] = nil
      end
      -- pprint(attack_targets)
   end -- attack3.on_enter

   function attack3.update(dt)
      check_directional_input()

      if runtime.current_frame == attack_start_frame then
         msg.post(collisionobject_hurtbox3, msg.ENABLE)
         attack_start_frame = 0
      elseif runtime.current_frame == attack_stop_frame then
         msg.post(collisionobject_hurtbox3, msg.DISABLE)
         attack_stop_frame = 0
      end

      -- local t = get(char.sprite, const.CURSOR)
      -- local stop = 3 / 10
      -- if t > 0.75 then
      --    advance(move(dt, attack_direction, nil, 60))
      -- else
      if is_down(JUMP_BTN) and (jump_count < max_jumps)then
         velocity_y = JUMP_SPEED
      end
      -- advance(move(dt, attack_direction, nil, 30))
      advance(move(dt, 0))
      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      end
      -- end
   end -- attack3.update

   function attack3.on_exit()
      msg.post(collisionobject_hurtbox3, msg.DISABLE)
   end -- attack3.on_exit

   ---------------------------------------
   -- air_attack1
   ---------------------------------------

   local function on_air_attack1_complete()
      turnaround(char, horizontal_look)
      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif move_direction == 0 then
         machine.enter_state(idle)
      else
         machine.enter_state(run)
      end
   end -- on_air_attack1_complete

   function air_attack1.on_enter()
      label.set_text(debug_label, "Air_attack1")
      play_animation(char, ANIMATION.AIR_ATTACK1, nil, on_air_attack1_complete)
      snd.play_sound(snd.GOBLIN_SWORD_SLASH)
      attack_direction = instance.horizontal_look
      attack_start_frame = runtime.current_frame + 3
      attack_stop_frame = attack_start_frame + 1
      physics_set_hflip(collisionobject_hurtbox4, attack_direction ~= 1)
      for k, _ in next, attack_targets do
         attack_targets[k] = nil
      end
      if velocity_y > 0 then
         velocity_y = velocity_y * 0.6
      end
   end -- air_attack1.on_enter

   function air_attack1.update(dt)
      check_directional_input()

      if runtime.current_frame == attack_start_frame then
         msg.post(collisionobject_hurtbox4, msg.ENABLE)
         attack_start_frame = 0
      elseif runtime.current_frame == attack_stop_frame then
         msg.post(collisionobject_hurtbox4, msg.DISABLE)
         attack_stop_frame = 0
      end

      if is_down(JUMP_BTN) and (jump_count < max_jumps) and (velocity_y < JUMP_SPEED) then
         perform_jump(JUMP_SPEED * 0.85, factories.CAPTAIN_AIR_JUMP_DUST)
         animate(char.pivot, const.SCALE, go.PLAYBACK_ONCE_PINGPONG, JUMP_STRETCH, go.EASING_INOUTQUAD, JUMP_TIME_TO_APEX * 0.7, 0, on_scale_complete)
      end
      -- advance(move(dt, move_direction, nil, MAX_AIR_SPEED))
      if ground then
         advance(move(dt, 0))
         machine.enter_state(attack1)
      else
         advance(move(dt, move_direction, nil, MAX_AIR_SPEED))
      end
   end -- air_attack1.update

   function air_attack1.on_exit()
      msg.post(collisionobject_hurtbox4, msg.DISABLE)
   end -- air_attack1.on_exit

   ---------------------------------------
   -- throw
   ---------------------------------------

   local function on_throw_complete()
      alter_projectiles(-1)
      if sword_count == 0 then
         nc.post_notification(gamestate.sword_spawner, nil, factories.SWORD_PICKUP, 0, 110)
      end
      turnaround(char, horizontal_look)
      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif move_direction == 0 then
         machine.enter_state(idle)
      else
         machine.enter_state(run)
      end
   end -- on_throw_complete

   function throw.on_enter()
      label.set_text(debug_label, "Throw")
      play_animation(char, ANIMATION.THROW_SWORD, nil, on_throw_complete)
      attack_direction = instance.horizontal_look
      attack_start_frame = runtime.current_frame + 3
      -- vector3_set_xyz(vector3_stub, instance.x + direction * 20, instance.y + 17, 0)
      -- sword_properties[const.ROOT].speed = sword_speed * direction
      -- sword_properties[const.ROOT].damage_points = sword_damage_points
      -- collectionfactory.create(FACTORY.SWORD_SPINNING, vector3_stub, const.QUAT_IDENTITY, sword_properties, 1)
      -- snd.play_sound(snd.FATE_BOWMISS)
   end -- throw.on_enter

   function throw.update(dt)
      if runtime.current_frame == attack_start_frame then
         attack_start_frame = 0
         vector3_set_xyz(vector3_stub, instance.x, instance.y + 12, 0)
         sword_properties[const.ROOT].speed = sword_speed * attack_direction
         sword_properties[const.ROOT].damage_points = sword_damage_points
         collectionfactory.create(factories.CAPTAIN_SWORD_SPINNING, vector3_stub, const.QUAT_IDENTITY, sword_properties, 1)
         -- snd.play_sound(snd.FATE_SWORD_SWING)
         snd.play_sound(snd.SHANTAE_DOWN_THRUST_START)
      end
      if ground and velocity_y == 0 then
         velocity_x = 0
         advance(move(dt, 0))
      else
         check_directional_input()
         advance(move(dt))
      end
      if is_down(JUMP_BTN) and (jump_count < max_jumps) and (velocity_y < JUMP_SPEED) then
         perform_jump(JUMP_SPEED * 0.85, factories.CAPTAIN_AIR_JUMP_DUST)
         animate(char.pivot, const.SCALE, go.PLAYBACK_ONCE_PINGPONG, JUMP_STRETCH, go.EASING_INOUTQUAD, JUMP_TIME_TO_APEX * 0.7, 0, on_scale_complete)
      end
   end -- throw.update

   local function on_level_will_disappear()
   end -- on_level_will_disappear

   local function on_level_did_disappear()
      save_play_time()
      if transit_state then
         machine.enter_state(transit_state)
      end
      runtime.remove_update_callback(instance)
      set(char.sprite, const.PLAYBACK_RATE, 0)
   end -- on_level_did_disappear

   local function on_level_will_appear(_, x, y, direction)
      instance.x = x
      instance.y = y
      -- checkpoint_x = x
      -- checkpoint_y = y
      vector3_set_xyz(vector3_stub, x, y, 0)
      set_position(vector3_stub, root)
      if direction then
         turnaround(char, direction)
      end
      runtime.add_update_callback(instance, update)
      set(char.sprite, const.PLAYBACK_RATE, 1)
      gamestate.set(nil, gamestate.player, "has_key", false)
      nc.post_notification("hide_key")
   end -- on_level_will_appear

   local function on_level_did_appear()
      if machine.current_state() == hidden then
         machine.enter_state(appearance)
      end
   end -- on_level_did_appear

   local function on_level_restart()
      transit_state = hidden
   end -- on_level_restart

   local function on_game_will_end()
      save_play_time()
   end -- on_game_will_end

   function instance.on_contact(other_id, _, vx)
      local other_instance = get_instance(other_id)
      if other_instance and other_instance.try_open then
         other_instance.try_open(instance)
      end
      return vx
   end -- instance.on_contact

   function instance.on_ground_contact(_, group, id)
      local target = get_instance(id)
      if not (target and target.on_jump) then return 0 end

      if (not hit_list[id]) and ((group == groups.ENEMY_HITBOX) or (group == groups.PROPS_HITBOX)) then
         hit_list[id] = true
         local r = target.on_jump(snd.ROGUE_LAND, 1) or JUMP_SPEED
         if r > recoil then recoil = r end
         jump_count = 1
      end
      return recoil
   end -- instance.on_ground_contact

   function instance.on_contact_up(group, id)
      if (group == groups.PROPS_HITBOX) and (not hit_list[id]) then
         hit_list[id] = true
         local target = get_instance(id)
         if target and target.on_hit then
            target.on_hit(snd.ROGUE_LAND, 1)
         end
      end
   end -- instance.on_contact_up

   function instance.on_trigger_response(message, sender)
      if sender == collisionobject_sensor then
         local other_instance = get_instance(message.other_id)
         if not other_instance then
            return
         end

         local enter = message.enter

         if enter and other_instance.on_enter then
            other_instance.on_enter(instance)
         elseif (not enter) and other_instance.on_exit then
            other_instance.on_exit()
         elseif other_instance.accepts_first_responder then
            responders[message.other_id] = message.enter
         end
      end
   end -- on_trigger_response

   function instance.on_collision_response(message, sender)
      if (sender == collisionobject_hitbox) or (sender == collisionobject_sensor) then
         local other_instance = get_instance(message.other_id)
         if other_instance and other_instance.on_collision then
            other_instance.on_collision(instance)
         end
      end
   end -- instance.on_collision_response

   --    local function on_strike(position)
   --    -- if runtime.current_frame == melee_hit_frame then return end
   --    -- melee_hit_frame = runtime.current_frame
   --
   --    collectionfactory.create(MELEE_HIT_FACTORY, position, IDENTITY, nil, 1)
   -- end -- on_strike

   function instance.on_contact_point_response(message, sender)
      if sender == collisionobject_hitbox then
         return
      end

      local other_id = message.other_id
      if attack_targets[other_id] then return end
      attack_targets[other_id] = true
      -- collectionfactory.create(url, position, rotation, properties, scale)
      local other_instance = get_instance(other_id)
      if other_instance then
         local x, y = fastmath.vector3_get_xy(message.position)
         -- vector3_set_xyz(vector3_stub, x, instance.y + 10, 0)
         vector3_set_xyz(vector3_stub, x, y, 0)
         collectionfactory.create(factories.EFFECT_SWORD_HIT, vector3_stub, const.QUAT_IDENTITY, nil, 1)
         -- snd.play_sound(fastmath.pick_next(HIT_ENEMY_SOUNDS, 3))
         -- snd.play_sound(fastmath.pick_any(HIT_ENEMY_SOUNDS, 2))

         -- TODO: move this to responsible target!!!! (always implemented in mushroom, but not in other enemies!)
         -- nc.post_notification(const.CAMERA_SHAKE_REQUEST_NOTIFICATION, nil, 3, 0.15)
         other_instance.on_hit(nil, 1)
      end
   end -- on_contact_point_response

   function instance.on_hit(sfx, damage, speed)
      hit_direction = sign(speed or 0)
      if hit_direction == 0 then
         hit_direction = -instance.horizontal_look
      end
      local health = alter_health(-damage or 0)
      -- utils.log(health, damage)
      if sfx then
         snd.play_sound(sfx)
      end
      if health and (health > 0) then
         machine.enter_state(hit)
      else
         machine.enter_state(dead)
      end
   end -- instance.on_hit

   function instance.on_instant_death()
      local maximum = gamestate.get(nil, gamestate.player, "max_health", 3)
      local current = gamestate.get(nil, gamestate.player, "health", maximum)
      if current > 0 then
         snd.play_sound(snd.SHANTAE_DEATH)
      end
      gamestate.set(nil, gamestate.player, "health", 0)
      msg.post(collisionobject_hitbox, msg.DISABLE)
      msg.post(collisionobject_sensor, msg.DISABLE)
      runtime.remove_update_callback(instance)
      on_dead_done()
   end -- instance.on_instant_death

   -- function instance.on_checkpoint(checkpoint_instance)
   --    checkpoint_x = checkpoint_instance.x
   --    checkpoint_y = checkpoint_instance.y
   -- end -- instance.on_checkpoint

   function instance.on_passage(passage_instance)
      gamestate.set(nil, gamestate.player, "last_checkpoint", { map = passage_instance.map, location = passage_instance.location })
      nc.post_notification(const.ENTITY_DID_LEAVE_LEVEL_NOTIFICATION, root.path, passage_instance)
      transit_state = nil
   end -- instance.on_passage

   function instance.on_collect(kind, variant)
      if kind == gamestate.currency then
         return alter_wealth(loot_distributor.amount[variant])
      elseif kind == gamestate.projectile then
         return alter_projectiles(loot_distributor.amount[variant])
      elseif kind == gamestate.health then
         return alter_health(loot_distributor.amount[variant])
      elseif kind == gamestate.key then
         return get_key(variant)
      end
      -- can't collect
      return false
   end -- instance.on_collect

   function instance.check_key(key_name)
      local success = gamestate.get(nil, gamestate.player, "has_key", nil) == gamestate[key_name]
      if success then
         gamestate.set(nil, gamestate.player, "has_key", false)
         nc.post_notification("hide_key")
      end
      return success
   end -- instance.check_key

   function instance.init()
      sword_count = gamestate.get(nil, gamestate.player, "projectiles", 0)
      debug_label = msg.url("#debug_label")
      msg.post(debug_label, msg.DISABLE)
      root = msg.url(".")
      char.pivot = msg.url("pivot")
      char.anchor = msg.url("anchor")
      char.sprite = msg.url("anchor#sprite")
      char.current_animation_group = nil
      char.current_animation = nil
      char.on_complete = nil
      collisionobject_sensor = msg.url("#collisionobject_sensor")
      collisionobject_hitbox = msg.url("#collisionobject_hitbox")
      collisionobject_hurtbox1 = msg.url("#collisionobject_hurtbox1")
      msg.post(collisionobject_hurtbox1, msg.DISABLE)
      collisionobject_hurtbox2 = msg.url("#collisionobject_hurtbox2")
      msg.post(collisionobject_hurtbox2, msg.DISABLE)
      collisionobject_hurtbox3 = msg.url("#collisionobject_hurtbox3")
      msg.post(collisionobject_hurtbox3, msg.DISABLE)
      collisionobject_hurtbox4 = msg.url("#collisionobject_hurtbox4")
      msg.post(collisionobject_hurtbox4, msg.DISABLE)
      vector3_set_xyz(vector3_stub, 0, 0, PLAYER_DEPTH)
      set_position(vector3_stub, char.pivot)
      acceleration = GROUND_ACCELERATION
      max_horizontal_speed = MAX_HORIZONTAL_SPEED
      gravity = NORMAL_GRAVITY
      velocity_x = 0
      velocity_y = 0
      instance.horizontal_drag = 0
      instance.vertical_drag = 0
      move_direction = 0
      horizontal_look = 1
      instance.horizontal_look = horizontal_look
      instance.vertical_look = 1
      ground = nil
      -- up_space = nil
      jump_count = 0
      jump_buffer_time = 0
      max_jumps = MAX_JUMPS > 0 and MAX_JUMPS or const.INFINITY
      is_flashing = false
      sword_speed = 300
      sword_damage_points = 1
      attack_followup_time = 0
      play_time = 0
      transit_state = nil
      -- contact_left = false
      -- contact_right = false
      raycast_controller.set_width(CHARACTER_WIDTH)
      raycast_controller.set_height(CHARACTER_HEIGHT)
      runtime.set_instance(root.path, instance)
      nc.add_observer(on_level_will_disappear, const.LEVEL_WILL_DISAPPEAR_NOTIFICATION)
      nc.add_observer(on_level_did_disappear, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.add_observer(on_level_will_appear, const.LEVEL_WILL_APPEAR_NOTIFICATION)
      nc.add_observer(on_level_did_appear, const.LEVEL_DID_APPEAR_NOTIFICATION)
      nc.add_observer(on_level_restart, const.LEVEL_RESTART_NOTIFICATION)
      nc.add_observer(on_game_will_end, const.GAME_WILL_END_NOTIFICATION)
      runtime.add_update_callback(instance, update)
      machine.reset()
      machine.enter_state(hidden)
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(on_level_will_disappear, const.LEVEL_WILL_DISAPPEAR_NOTIFICATION)
      nc.remove_observer(on_level_did_disappear, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.remove_observer(on_level_will_appear, const.LEVEL_WILL_APPEAR_NOTIFICATION)
      nc.remove_observer(on_level_did_appear, const.LEVEL_DID_APPEAR_NOTIFICATION)
      nc.remove_observer(on_level_restart, const.LEVEL_RESTART_NOTIFICATION)
      nc.remove_observer(on_game_will_end, const.GAME_WILL_END_NOTIFICATION)
      on_game_will_end()
      gamestate.save()
   end -- instance.deinit

   return instance
end

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
