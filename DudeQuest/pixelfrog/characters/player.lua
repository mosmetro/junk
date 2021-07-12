local Pool = require("m.pool")
local RaycastController = require("m.raycast_controller")
local StateMachine = require("m.state_machine")
local groups = require("m.groups")
local const = require("m.constants")
local nc = require("m.notification_center")
local ui = require("m.ui.ui")
local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local game = require("pixelfrog.game.game")
local snd = require("sound.sound")

-- local play_sound = snd.play_sound
local vmath = vmath
local is_pressed = runtime.is_pressed
local is_down = runtime.is_down
local is_up = runtime.is_up
local set_position = go.set_position
local play_flipbook = sprite.play_flipbook
local set = go.set
local abs = fastmath.abs
local min = fastmath.min
local max = fastmath.max
local sign = fastmath.sign
local clamp = fastmath.clamp
local vector3_set_xyz = fastmath.vector3_set_xyz
local get_instance = runtime.get_instance

local LEFT_BTN = ui.LEFT
local RIGHT_BTN = ui.RIGHT
local JUMP_BTN = ui.B
local UP_BTN = ui.UP
local DOWN_BTN = ui.DOWN

local SCALE = const.SCALE
local INFINITY = const.INFINITY
local PLAYBACK_RATE = const.PLAYBACK_RATE
local PLAYER_DEPTH = layers.get_depth(layers.PLAYER)
local CHARACTER_WIDTH = 12
local CHARACTER_HEIGHT = 22
local MAX_HORIZONTAL_SPEED = 120
local MAX_FALL_SPEED = -500
local MAX_RISE_SPEED = 600
local GROUND_ACCELERATION = 2000
local MAX_AIR_SPEED = 120
local AIR_ACCELERATION = 2000
local MAX_JUMPS = 2
local JUMP_HEIGHT = 56--56
local JUMP_TIME_TO_APEX = 0.34--0.3--0.38
local NORMAL_GRAVITY = -(2 * JUMP_HEIGHT) / (JUMP_TIME_TO_APEX * JUMP_TIME_TO_APEX)
local JUMP_SPEED = abs(NORMAL_GRAVITY) * JUMP_TIME_TO_APEX
utils.log("gravity ", NORMAL_GRAVITY, "jump_speed ", JUMP_SPEED)
local JUMP_GRACE_TIME = (1 / 60) * 10
-- local JUMP_CUT_SPEED = JUMP_SPEED * 0.4
-- local JUMP_BUFFER_TIME = (1 / 60) * 8
local vector3_stub = vmath.vector3()
local IDLE_SQUASH = vmath.vector3(1.15, 0.85, 1)
local JUMP_STRETCH = vmath.vector3(0.9, 1.15, 1)

local BLANK = {
   { id = hash("blank"), position = vmath.vector3(0, 16, 0), },
}
local IDLE = {
   { id = hash("idle"), position = vmath.vector3(0, 16, 0), },
}
local RUN = {
   { id = hash("run"), position = vmath.vector3(0, 16, 0), },
}
local JUMP = {
   { id = hash("jump"), position = vmath.vector3(0, 16, 0), },
}
-- local DOUBLE_JUMP = {
--    { id = hash("double_jump"), position = vmath.vector3(0, 16, 0), },
-- }
local WALL_JUMP = {
   { id = hash("wall_jump"), position = vmath.vector3(-2, 16, 0), },
}
local LEDGE_GRAB = {
   { id = hash("ledge_grab"), position = vmath.vector3(-2, 16, 0), },
}
local FALL = {
   { id = hash("fall"), position = vmath.vector3(0, 16, 0), },
}
local HIT = {
   { id = hash("hit"), position = vmath.vector3(0, 16, 0), },
}
local APPEARANCE = {
   { id = hash("appearance"), position = vmath.vector3(0, 16, 0), },
}
-- local DISAPPEARANCE = {
--    { id = hash("disappearance"), position = vmath.vector3(0, 16, 0), },
-- }
local STANDSTILL = {
   { id = hash("standstill"), position = vmath.vector3(0, 16, 0), },
}


local function make()
   local instance = {
      is_player = true,
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

   local PLAYER = {
      pivot = 0,
      anchor = 0,
      sprite = 0,
      current_animation_group = 0,
      current_animation = 0,
      on_complete = 0,
   }

   local debug_label
   local move_direction
   local previous_horizontal_look
   local max_horizontal_speed
   local velocity_x
   local velocity_y
   local acceleration
   local gravity
   local ground
   -- local up_space
   local root
   local collisionobject_hitbox
   local collisionobject_sensor
   local jump_count
   -- local jump_buffer_time
   local max_jumps
   local jump_grace_time
   -- local contact_left
   -- local contact_right
   local ledge
   local wall
   local hit_list = {}
   local recoil
   local health

   local hidden = {}
   local appearance = {}
   local idle = {}
   local run = {}
   local jump = {}
   local fall = {}
   local ledge_grab = {}
   local wall_slide = {}
   local hit = {
      x = 0,
      y = 0,
      aabb = { 0, 0, 0, 0 }
   }
   local checkpoint_x
   local checkpoint_y

   local raycast_controller = RaycastController.new(instance)
   local machine = StateMachine.new(nil)

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
   local function play_animation(target, animation_group, index, on_complete, cursor, rate)
      local animation = animation_group[index or 1]
      if target.current_animation == animation then return end
      play_properties.offset = cursor or 0
      play_properties.playback_rate = rate or 1
      -- if direction then instance.horizontal_look = direction end
      set_position(animation.position, target.anchor)
      play_flipbook(target.sprite, animation.id, on_complete, play_properties)
      target.on_complete = on_complete
      target.current_animation_group = animation_group
      target.current_animation = animation
   end -- play_animation

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

   local function warp_to_position(x, y, horizontal_look)
      instance.horizontal_drag = 0
      instance.vertical_drag = 0
      velocity_x = 0
      velocity_y = 0
      instance.dx = 0
      instance.dy = 0
      instance.x = x
      instance.y = y
      vector3_set_xyz(vector3_stub, x, y, 0)
      set_position(vector3_stub, root)
      if horizontal_look then
         instance.horizontal_look = horizontal_look
      end
   end -- warp_to_position

   ---------------------------------------
   -- hidden
   ---------------------------------------

   function hidden.on_enter()
      label.set_text(debug_label, "Hidden")
      play_animation(PLAYER, BLANK)
   end -- hidden.on_enter

   ---------------------------------------
   -- appearance
   ---------------------------------------

   local function appearance_complete()
      machine.enter_state(fall)
   end -- appearance_complete

   function appearance.on_enter()
      label.set_text(debug_label, "Appearance")
      play_animation(PLAYER, APPEARANCE, nil, appearance_complete)
   end -- appearance.on_enter

   ---------------------------------------
   -- idle
   ---------------------------------------

   local function on_scale_complete()
      go.set_scale(1, PLAYER.pivot)
   end -- on_scale_complete

   function idle.on_enter(previous_state)
      label.set_text(debug_label, "Idle")
      play_animation(PLAYER, IDLE)
      if previous_state == fall then
         go.animate(PLAYER.pivot, SCALE, go.PLAYBACK_ONCE_PINGPONG, IDLE_SQUASH, go.EASING_INOUTQUAD, 0.15, 0, on_scale_complete)
      end
   end -- idle.on_enter

   -- local can_jump
   -- local function check_jump_input()
   --    if is_down(JUMP_BTN) then
   --       if ground then
   --          velocity_y = JUMP_SPEED
   --          can_jump = true
   --       elseif can_jump then
   --          velocity_y = JUMP_SPEED
   --          can_jump = false
   --       end
   --    end
   -- end

   function idle.update(dt)
      check_directional_input()
      turnaround(PLAYER)

      if is_down(JUMP_BTN) and (jump_count < max_jumps) then
         jump_count = jump_count + 1
         velocity_y = JUMP_SPEED
      end

      -- local g = get_instance(ground)
      -- -- move(dt, dir, acc, spd, grav)
      -- if g then
      --    acceleration = g.acceleration
      --    advance(move(dt, nil, nil, g.max_speed))
      -- else
      --    advance(move(dt))
      -- end
      advance(move(dt))

      if is_pressed(DOWN_BTN) then
         instance.vertical_look = -1
      end

      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif move_direction ~= 0 and (velocity_x ~= 0) then
         machine.enter_state(run)
      end
   end -- idle.update

   ---------------------------------------
   -- run
   ---------------------------------------

   function run.on_enter(previous_state)
      label.set_text(debug_label, "Run")
      play_animation(PLAYER, RUN)
      if previous_state == fall then
         go.animate(PLAYER.pivot, SCALE, go.PLAYBACK_ONCE_PINGPONG, IDLE_SQUASH, go.EASING_INOUTQUAD, 0.15, 0, on_scale_complete)
      end
   end -- run.on_enter

   function run.update(dt)
      check_directional_input()
      turnaround(PLAYER)

      if move_direction == 0 then
         play_animation(PLAYER, STANDSTILL)
      else
         play_animation(PLAYER, RUN)
      end

      if is_down(JUMP_BTN) and (jump_count < max_jumps) then
         jump_count = jump_count + 1
         velocity_y = JUMP_SPEED
      end

      -- local g = get_instance(ground)
      -- -- move(dt, dir, acc, spd, grav)
      -- if g then
      --    acceleration = g.acceleration
      --    advance(move(dt, nil, nil, g.max_speed))
      -- else
      --    advance(move(dt))
      -- end
      advance(move(dt))

      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif velocity_x == 0 then
         machine.enter_state(idle)
      end
   end -- run.update

   ---------------------------------------
   -- jump
   ---------------------------------------

   function jump.on_enter(previous_state)
      label.set_text(debug_label, "Jump")
      instance.can_push = false
      turnaround(PLAYER)
      play_animation(PLAYER, JUMP)
      jump.previous_state = previous_state
      go.animate(PLAYER.pivot, SCALE, go.PLAYBACK_ONCE_PINGPONG, JUMP_STRETCH, go.EASING_INOUTQUAD, JUMP_TIME_TO_APEX, 0, on_scale_complete)
   end -- jump.on_enter

   function jump.update(dt)
      check_directional_input()
      turnaround(PLAYER)

      if is_down(JUMP_BTN) and (jump_count < max_jumps) and (velocity_y < JUMP_SPEED) then
         jump_count = jump_count + 1
         velocity_y = JUMP_SPEED
         go.animate(PLAYER.pivot, SCALE, go.PLAYBACK_ONCE_PINGPONG, JUMP_STRETCH, go.EASING_INOUTQUAD, JUMP_TIME_TO_APEX, 0, on_scale_complete)
      elseif is_up(JUMP_BTN) and (instance.vertical_drag == 0) then
         velocity_y = velocity_y * 0.5
      end

      advance(move(dt))

      instance.vertical_look = 0

      if velocity_y < 0 then
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
      if previous_state == jump then
         jump_grace_time = INFINITY
      else
         jump_grace_time = JUMP_GRACE_TIME
      end
      ledge = nil
      wall = nil
      play_animation(PLAYER, FALL)
   end -- fall.on_enter

   function fall.update(dt)
      check_directional_input()
      turnaround(PLAYER)

      if instance.vertical_drag ~= 0 then
         jump_count = 1
      end

      if is_down(JUMP_BTN) and (jump_count < max_jumps) then
         if (jump_count == 0) and (jump_grace_time <= 0) then
            -- too late, consume one jump
            jump_count = jump_count + 1
         end
         if jump_count < max_jumps then
            velocity_y = fastmath.max(JUMP_SPEED, velocity_y)
            jump_count = jump_count + 1
         end
      end

      jump_grace_time = jump_grace_time - dt

      local dx, dy = move(dt)

      if (is_pressed(LEFT_BTN) or is_pressed(RIGHT_BTN) or is_pressed(UP_BTN)) and (not is_pressed(DOWN_BTN)) then
         ledge, wall, dy = raycast_controller.check_ledge(instance.horizontal_look, instance.x, instance.y, dy)
      end
      -- utils.log(ledge, wall)
      advance(dx, dy, ledge or wall)
      instance.vertical_look = 0

      if ledge then
         machine.enter_state(ledge_grab)
      elseif wall then
         machine.enter_state(wall_slide)
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
   end -- fall.on_exit

   ---------------------------------------
   -- ledge_grab
   ---------------------------------------

   function ledge_grab.on_enter()
      label.set_text(debug_label, "Ledge_grab")
      play_animation(PLAYER, LEDGE_GRAB)
      move_direction = 0
      velocity_x = 0
      velocity_y = 0
      jump_count = 1
      ledge_grab.countdown = 0.175
   end -- ledge_grab.on_enter

   function ledge_grab.update(dt)
      local inst = get_instance(ledge)
      if inst then
         local dx = inst.dx or 0
         local dy = inst.dy or 0
         local is_pressed_left = is_pressed(LEFT_BTN)
         local is_pressed_right = is_pressed(RIGHT_BTN)
         local ledge_left, ledge_right = instance.horizontal_look == -1, instance.horizontal_look == 1
         if (is_pressed_left and ledge_right) or (is_pressed_right and ledge_left) then
            if ledge_grab.countdown < 0 then
               move_direction = -instance.horizontal_look
               advance(dx, dy)
               machine.enter_state(fall)
               return
            else
               ledge_grab.countdown = ledge_grab.countdown - dt
            end
         elseif is_up(LEFT_BTN) or is_up(RIGHT_BTN) then
            ledge_grab.countdown = 0.175
         end
         if is_down(JUMP_BTN) then
            if (is_pressed_left and ledge_left) or (is_pressed_right and ledge_right) then -- climb
               jump_count = jump_count + 1
               velocity_x = -instance.horizontal_look * 160
               velocity_y = JUMP_SPEED * 0.74
            elseif (is_pressed_left and ledge_right) or (is_pressed_right and ledge_left) then -- away
               instance.horizontal_look = -instance.horizontal_look
               velocity_x = instance.horizontal_look * 460
               velocity_y = JUMP_SPEED * 0.43
            else
               jump_count = jump_count + 1
               velocity_y = JUMP_SPEED * 0.8
            end
            advance(move(dt))
            machine.enter_state(jump)
         elseif is_down(DOWN_BTN) or is_pressed(DOWN_BTN) then
            --- now ledge become wall
            wall = raycast_controller.check_ledge(instance.horizontal_look, instance.x, instance.y, dy - 1)
            -- utils.log(wall)
            local w = get_instance(wall)
            if w then
               -- local speed = w.max_speed or 0
               local speed = min(w.max_speed or INFINITY, MAX_HORIZONTAL_SPEED)
               if speed == 0 then
                  advance(dx, dy, wall)
               else
                  advance(dx, dy - 1, wall)
                  machine.enter_state(wall_slide)
               end
            end
         elseif ground then
            advance(dx, dy)
            machine.enter_state(idle)
         else
            -- still on ledge
            ledge = raycast_controller.check_ledge(instance.horizontal_look, instance.x, instance.y, dy)
            advance(dx, dy, ledge)
            if not ledge then
               machine.enter_state(fall)
            end
         end
      else
         advance(move(dt))
         machine.enter_state(fall)
      end
   end -- ledge_grab.update

   ---------------------------------------
   -- wall_slide
   ---------------------------------------

   function wall_slide.on_enter()
      label.set_text(debug_label, "Wall_slide")
      local w = get_instance(wall)
      if w then
         if w.max_speed == 0 then
            play_animation(PLAYER, LEDGE_GRAB)
         else
            play_animation(PLAYER, WALL_JUMP)
         end
      end
      move_direction = 0
      velocity_x = 0
      velocity_y = 0
      jump_count = 0
      wall_slide.countdown = 0.175
   end -- wall_slide.on_enter

   function wall_slide.update(dt)
      local _
      _, wall = raycast_controller.check_ledge(instance.horizontal_look, instance.x, instance.y, instance.dy)
      local inst = get_instance(wall)
      if inst then
         local dx = inst.dx or 0
         local dy = inst.dy or 0
         -- local speed = inst.max_speed or MAX_HORIZONTAL_SPEED
         local speed = min(inst.max_speed or INFINITY, MAX_HORIZONTAL_SPEED)
         local is_pressed_left = is_pressed(LEFT_BTN)
         local is_pressed_right = is_pressed(RIGHT_BTN)
         local wall_left, wall_right = instance.horizontal_look == -1, instance.horizontal_look == 1
         if (is_pressed_left and wall_right) or (is_pressed_right and wall_left) then
            if wall_slide.countdown < 0 then
               advance(dx, dy)
               machine.enter_state(fall)
               return
            else
               wall_slide.countdown = wall_slide.countdown - dt
            end
         elseif is_up(LEFT_BTN) or is_up(RIGHT_BTN) then
            wall_slide.countdown = 0.175
         end
         if is_down(JUMP_BTN) then
            if (is_pressed_left and wall_left) or (is_pressed_right and wall_right) then -- climb
               jump_count = jump_count + 2
               velocity_x = -instance.horizontal_look * 250
               velocity_y = JUMP_SPEED * 0.9
            elseif (is_pressed_left and wall_right) or (is_pressed_right and wall_left) then -- away
               jump_count = jump_count + 1
               instance.horizontal_look = -instance.horizontal_look
               velocity_x = instance.horizontal_look * 460
               velocity_y = JUMP_SPEED * 0.43
            else
               jump_count = jump_count + 1
               velocity_x = -instance.horizontal_look * 250
               velocity_y = JUMP_SPEED * 0.9
            end
            advance(move(dt))
            machine.enter_state(jump)
         elseif is_pressed(DOWN_BTN) and (not ground) then
            advance(dx, dy - (speed * 0.95 * dt), wall)
            -- advance(dx, dy - (114 * dt), wall)
         elseif ground then
            advance(dx, dy, wall)
            machine.enter_state(idle)
         else
            -- utils.log(speed)
            advance(dx, dy - (speed * 0.25 * dt), wall)
            -- advance(dx, dy - (30 * dt), wall)
         end
      else
         local dx, dy = move(dt)
         advance(dx, dy - 1)
         machine.enter_state(fall)
      end
   end -- wall_slide.update

   ---------------------------------------
   -- hit
   ---------------------------------------

   function hit.on_enter()
      label.set_text(debug_label, "Hit")
      play_animation(PLAYER, HIT)
      go.animate(PLAYER.anchor, const.EULER_Z, go.PLAYBACK_LOOP_FORWARD, 360, go.EASING_LINEAR, 2.5)
      msg.post(collisionobject_hitbox, msg.DISABLE)
      hit.direction = sign(velocity_x)
      hit.speed = abs(velocity_x)
      velocity_y = JUMP_SPEED * 0.66
      hit.x = instance.x
      hit.y = instance.y
      nc.post_notification(const.CAMERA_SHAKE_REQUEST_NOTIFICATION, nil, 6, 0.15)
   end -- hit.on_enter

   function hit.update(dt)
      hit.aabb[1] = hit.x - 16
      hit.aabb[2] = hit.y
      hit.aabb[3] = hit.x + 16
      hit.aabb[4] = hit.y + 32
      if not fastmath.aabb_overlap(game.view_aabb, hit.aabb) then
         warp_to_position(checkpoint_x, checkpoint_y)
         machine.enter_state(appearance)
         return
      end
      local dx, dy = move(dt * 1.15, hit.direction, AIR_ACCELERATION, hit.speed, NORMAL_GRAVITY)
      hit.x = hit.x + dx
      hit.y = hit.y + dy
      vector3_set_xyz(vector3_stub, hit.x, hit.y, 0)
      set_position(vector3_stub, root)
      instance.vertical_look = 1
   end -- hit.update

   function hit.on_exit()
      go.cancel_animations(PLAYER.anchor, const.EULER_Z)
      set(PLAYER.anchor, const.EULER_Z, 0)
      msg.post(collisionobject_hitbox, msg.ENABLE)
   end -- hit.on_exit

   local function update(dt)
      -- utils.log(instance.x)
      -- factory.create("game:/game#dot", vmath.vector3(instance.x, instance.y, 0))
      for k in next, hit_list do
         hit_list[k] = nil
      end
      recoil = 0
      -- contact_left = false
      -- contact_right = false
      -- every ground must have instance!
      local ground_instance = get_instance(ground)
      if ground_instance and ground_instance.is_ground then
         -- utils.log(ground)
         acceleration = ground_instance.acceleration or GROUND_ACCELERATION
         -- max_horizontal_speed = ground_instance.max_speed or MAX_HORIZONTAL_SPEED
         max_horizontal_speed = min(ground_instance.max_speed or INFINITY, MAX_HORIZONTAL_SPEED)
         jump_count = 0
         instance.can_push = true
      else
         if move_direction ~= 0 then
            acceleration = AIR_ACCELERATION
            max_horizontal_speed = max(max_horizontal_speed, MAX_AIR_SPEED)
         end
         instance.can_push = false
      end
      machine.update(dt)
      instance.horizontal_drag = 0
      instance.vertical_drag = 0
   end -- update

   local function on_level_will_disappear()
   end -- on_level_will_disappear

   local function on_level_did_disappear()
      runtime.remove_update_callback(instance)
      set(PLAYER.sprite, PLAYBACK_RATE, 0)
   end -- on_level_did_disappear

   local function on_level_will_appear(_, x, y, horizontal_look)
      instance.x = x
      instance.y = y
      checkpoint_x = x
      checkpoint_y = y
      vector3_set_xyz(vector3_stub, x, y, 0)
      set_position(vector3_stub, root)
      if horizontal_look then
         instance.horizontal_look = horizontal_look
      end
      runtime.add_update_callback(instance, update)
      set(PLAYER.sprite, PLAYBACK_RATE, 1)
   end -- on_level_will_appear

   local function on_level_did_appear()
      if machine.current_state() == hidden then
         machine.enter_state(appearance)
      end
   end -- on_level_did_appear

   local function on_game_will_end()
   end -- on_game_will_end

   function instance.on_ground_contact(_, group, id)
      if (not hit_list[id]) and ((group == groups.ENEMY_HITBOX) or (group == groups.PROPS_HITBOX)) then
         hit_list[id] = true
         local target = get_instance(id)
         if target then
            local r = target.on_hit and target.on_hit(snd.ROGUE_LAND, 1) or JUMP_SPEED
            if r > recoil then recoil = r end
         end
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

   function instance.on_collision_response(message)
      -- utils.log("on_collision")
      local other_instance = get_instance(message.other_id)
      if not other_instance then return end

      if other_instance.on_collision then
         other_instance.on_collision(instance)
      end
   end -- instance.on_collision_response

   -- function instance.on_trigger_response(message, sender)
   --    local other_instance = get_instance(message.other_id)
   --    if not other_instance then return end
   --
   --    if sender == collisionobject_sensor then
   --       local enter = message.enter
   --    end
   -- end -- on_trigger_response

   function instance.on_hit(sfx, damage, speed)
      health = health - (damage or 0)
      if sfx then
         snd.play_sound(sfx)
      end
      velocity_x = clamp(velocity_x + (speed or 0), -200, 200)
      machine.enter_state(hit)
   end -- instance.on_hit

   function instance.on_checkpoint(checkpoint_instance)
      checkpoint_x = checkpoint_instance.x
      checkpoint_y = checkpoint_instance.y
   end

   function instance.init()
      health = 3
      debug_label = msg.url("#debug_label")
      -- msg.post(debug_label, msg.DISABLE)
      root = msg.url(".")
      PLAYER.pivot = msg.url("pivot")
      PLAYER.anchor = msg.url("anchor")
      PLAYER.sprite = msg.url("anchor#sprite")
      PLAYER.current_animation_group = nil
      PLAYER.current_animation = nil
      PLAYER.on_complete = nil
      collisionobject_hitbox = msg.url("#collisionobject_hitbox")
      msg.post(collisionobject_hitbox, msg.ENABLE)
      collisionobject_sensor = msg.url("#collisionobject_sensor")
      msg.post(collisionobject_sensor, msg.ENABLE)
      vector3_set_xyz(vector3_stub, 0, 0, PLAYER_DEPTH)
      set_position(vector3_stub, PLAYER.pivot)
      acceleration = GROUND_ACCELERATION
      max_horizontal_speed = MAX_HORIZONTAL_SPEED
      gravity = NORMAL_GRAVITY
      velocity_x = 0
      velocity_y = 0
      instance.horizontal_drag = 0
      instance.vertical_drag = 0
      move_direction = 0
      instance.horizontal_look = 1
      instance.vertical_look = 1
      previous_horizontal_look = 0
      ground = nil
      -- up_space = nil
      jump_count = 0
      -- jump_buffer_time = 0
      max_jumps = MAX_JUMPS > 0 and MAX_JUMPS or INFINITY
      -- contact_left = false
      -- contact_right = false
      raycast_controller.set_width(CHARACTER_WIDTH)
      raycast_controller.set_height(CHARACTER_HEIGHT)
      runtime.set_instance(root.path, instance)
      nc.add_observer(on_level_will_disappear, const.LEVEL_WILL_DISAPPEAR_NOTIFICATION)
      nc.add_observer(on_level_did_disappear, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.add_observer(on_level_will_appear, const.LEVEL_WILL_APPEAR_NOTIFICATION)
      nc.add_observer(on_level_did_appear, const.LEVEL_DID_APPEAR_NOTIFICATION)
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
      nc.remove_observer(on_game_will_end, const.GAME_WILL_END_NOTIFICATION)
      on_game_will_end()
      game.save()
   end -- instance.deinit

   return instance
end

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
