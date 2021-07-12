-- import
local Pool = require("m.pool")
local RaycastController = require("m.raycast_controller")
local StateMachine = require("m.state_machine")
local Maze = require("maze.maze")
local nc = require("m.notification_center")
local ui = require("m.ui.ui")
local snd = require("sound.sound")
local groups = require("m.groups")
local layers = require("m.layers")
-- local COLOR = require("m.colors")
local utils = require("m.utils")

local PLAYER_DEPTH = layers.get_depth(layers.PLAYER)

-- localization
local hash = hash
local msg = msg
local vmath = vmath
local LEFT = ui.LEFT
local RIGHT = ui.RIGHT
local UP = ui.UP
local DOWN = ui.DOWN
local A = ui.A
local B = ui.B
local X = ui.X
-- local Y = ui.Y
local runtime = runtime
local is_down = runtime.is_down
local is_up = runtime.is_up
local is_pressed = runtime.is_pressed
local ceil = math.ceil
local sin = math.sin
local abs = fastmath.abs
local sign = fastmath.sign
local max = fastmath.max
-- local vector3_get_components = fastmath.vector3_get_components
local vector3_set_components = fastmath.vector3_set_components
local lerp = fastmath.lerp
local get_instance = runtime.get_instance
local get = go.get
local sprite_set_hflip = sprite.set_hflip
local physics_set_hflip = physics.set_hflip
-- local get_world_position = go.get_world_position
local set_position = go.set_position
local play_flipbook = sprite.play_flipbook
local play_sound = snd.play_sound

-- constants
local INFINITY = 1 / 0
local CHARACTER_WIDTH = 14
local CHARACTER_HIGH_STANCE = 30
local CHARACTER_LOW_STANCE = 22
local MAX_HORIZONTAL_SPEED = 120
local MAX_VERTICAL_SPEED = 800
local GROUND_ACCELERATION = 4000
local MAX_JUMPS = 2--300
local JUMP_HEIGHT = 44
local JUMP_TIME_TO_APEX = 0.38
local NORMAL_GRAVITY = -(2 * JUMP_HEIGHT) / (JUMP_TIME_TO_APEX * JUMP_TIME_TO_APEX)
local JUMP_SPEED = abs(NORMAL_GRAVITY) * JUMP_TIME_TO_APEX
local AIR_JUMP_SPEED = JUMP_SPEED-- * 0.8
local JUMP_CUT_SPEED = JUMP_SPEED * 0.4
local JUMP_GRACE_TIME = (1 / 60) * 10
local JUMP_BUFFER_TIME = (1 / 60) * 8
local SLIDE_BUFFER_TIME = (1 / 60) * 16
local CAPE_POSITION_X = 0
local CAPE_POSITION_Y_HIGH = 21
local CAPE_POSITION_Y_LOW = 16
local CURSOR = hash("cursor")

local PLAYER = {
   object = nil,
   sprite = nil,
   current_animation_group = nil,
   current_animation = nil,
   on_complete = nil,

   IDLE = {
      { id = hash("tim_idle"), pos_right = vmath.vector3(2, 16, PLAYER_DEPTH), pos_left = vmath.vector3(-2, 16, PLAYER_DEPTH) },
   },
   WALK = {
      { id = hash("tim_walk"), pos_right = vmath.vector3(3, 17, PLAYER_DEPTH), pos_left = vmath.vector3(-3, 17, PLAYER_DEPTH), frame_count = 10 },
   },
   CROUCH = {
      { id = hash("tim_crouch"), pos_right = vmath.vector3(0, 15, PLAYER_DEPTH), pos_left = vmath.vector3(0, 15, PLAYER_DEPTH) },
   },
   RISE = {
      { id = hash("tim_rise"), pos_right = vmath.vector3(0, 15, PLAYER_DEPTH), pos_left = vmath.vector3(0, 15, PLAYER_DEPTH) },
   },
   JUMP_START = {
      { id = hash("tim_jump_start"), pos_right = vmath.vector3(1, 17, PLAYER_DEPTH), pos_left = vmath.vector3(-1, 17, PLAYER_DEPTH) },
   },
   JUMP = {
      { id = hash("tim_jump"), pos_right = vmath.vector3(2, 17, PLAYER_DEPTH), pos_left = vmath.vector3(-2, 17, PLAYER_DEPTH) },
   },
   JUMP_TO_FALL = {
      { id = hash("tim_jump_to_fall"), pos_right = vmath.vector3(2, 18, PLAYER_DEPTH), pos_left = vmath.vector3(-2, 18, PLAYER_DEPTH) },
   },
   FALL = {
      { id = hash("tim_fall"), pos_right = vmath.vector3(4, 18, PLAYER_DEPTH), pos_left = vmath.vector3(-4, 18, PLAYER_DEPTH) },
   },
   LAND = {
      { id = hash("tim_land"), pos_right = vmath.vector3(2, 18, PLAYER_DEPTH), pos_left = vmath.vector3(-2, 18, PLAYER_DEPTH) },
   },
   SLIDE_START = {
      { id = hash("tim_slide_start"), pos_right = vmath.vector3(1, 16, PLAYER_DEPTH), pos_left = vmath.vector3(-1, 16, PLAYER_DEPTH) },
   },
   SLIDE = {
      { id = hash("tim_slide"), pos_right = vmath.vector3(6, 12, PLAYER_DEPTH), pos_left = vmath.vector3(-6, 12, PLAYER_DEPTH) },
   },
   SLIDE_END = {
      { id = hash("tim_slide_end"), pos_right = vmath.vector3(2, 15, PLAYER_DEPTH), pos_left = vmath.vector3(-2, 15, PLAYER_DEPTH) },
   },
   LADDER = {
      { id = hash("tim_ladder"), position = vmath.vector3(2, 18, PLAYER_DEPTH) },
   },
   ATTACK = {
      { id = hash("tim_attack"), pos_right = vmath.vector3(4, 17, PLAYER_DEPTH), pos_left = vmath.vector3(-4, 17, PLAYER_DEPTH), frame_count = 6 },
   },
   AIR_ATTACK = {
      { id = hash("tim_air_attack"), pos_right = vmath.vector3(6, 19, PLAYER_DEPTH), pos_left = vmath.vector3(-6, 19, PLAYER_DEPTH), frame_count = 6 },
   },
   CROUCH_ATTACK = {
      { id = hash("tim_crouch_attack"), pos_right = vmath.vector3(6, 15, PLAYER_DEPTH), pos_left = vmath.vector3(-6, 15, PLAYER_DEPTH), frame_count = 6 },
   },
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
   }

   local cape_anchor
   local cape_position_local_x
   local cape_position_local_y
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
   local previous_velocity_y
   local acceleration
   local max_horizontal_speed
   local gravity
   local jump_count
   local max_jumps
   local jump_grace_time
   local jump_buffer_time
   local slide_buffer_time
   local ground
   local up_space
   local root
   local vector3_stub = vmath.vector3()
   local collisionobject_raycast_high
   local collisionobject_raycast_low
   local collisionobject_hitbox_high
   local collisionobject_hitbox_low
   local collisionobject_hurtbox
   local debug_label
   local debug_label2
   local debug_label3

   -- states
   local undefined = {}
   local idle = {}
   local walk = {}
   local slide = {}
   local jump = {}
   local land = {}
   local fall = {}
   local crouch = {}
   local attack = {}
   local air_attack = {}
   local crouch_attack = {}
   local approach = {}
   local map_change = {}

   local raycast_controller = RaycastController.new(instance)
   local machine = StateMachine.new(instance, undefined)

   local function check_directional_input()
      local is_pressed_left = is_pressed(LEFT)
      local is_pressed_right = is_pressed(RIGHT)

      if is_down(LEFT) then
         move_direction = -1
         instance.horizontal_look = -1
      elseif is_down(RIGHT) then
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
      set_position(instance.horizontal_look == 1 and animation.pos_right or animation.pos_left, target.object)
      sprite_set_hflip(target.sprite, instance.horizontal_look ~= 1)
      play_flipbook(target.sprite, animation.id, on_complete, play_properties)
      target.on_complete = on_complete
      target.current_animation_group = animation_group
      target.current_animation = animation
   end -- play_animation

   local function turnaround(target)
      if instance.horizontal_look == previous_horizontal_look then return end
      previous_horizontal_look = instance.horizontal_look
      set_position(instance.horizontal_look == 1 and target.current_animation.pos_right or target.current_animation.pos_left, target.object)
      sprite_set_hflip(target.sprite, instance.horizontal_look ~= 1)
   end -- turnaround

   local function set_stance(height)
      if height == CHARACTER_HIGH_STANCE then
         msg.post(collisionobject_raycast_high, msg.ENABLE)
         msg.post(collisionobject_hitbox_high, msg.ENABLE)
         msg.post(collisionobject_raycast_low, msg.DISABLE)
         msg.post(collisionobject_hitbox_low, msg.DISABLE)
      else
         msg.post(collisionobject_raycast_high, msg.DISABLE)
         msg.post(collisionobject_hitbox_high, msg.DISABLE)
         msg.post(collisionobject_raycast_low, msg.ENABLE)
         msg.post(collisionobject_hitbox_low, msg.ENABLE)
      end
      raycast_controller.set_height(height)
   end -- set_stance

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
      dx, dy, velocity_x, velocity_y, ground, up_space = raycast_controller.update(instance.x, instance.y, dx, dy, velocity_x, velocity_y)
      instance.ground = ground
      instance.x = instance.x + dx
      instance.y = instance.y + dy
      vector3_set_components(vector3_stub, instance.x, instance.y, 0)
      set_position(vector3_stub, root)
      instance.vertical_look = 1
      instance.dx = dx
      instance.dy = dy
      return dx, dy
   end -- advance

   local function apply_damage(amount)
      utils.log("received " .. tostring(amount) .. " damage points")
   end

   local function move_cape()
      -- cape
      -- cape_prev_pos_x[1] = cape_pos_x[1]
      -- cape_prev_pos_y[1] = cape_pos_y[1]
      -- cape_pos_x[1] = instance.x + cape_position_local_x * (move_direction == 0 and instance.horizontal_look or move_direction)
      -- cape_pos_y[1] = instance.y + cape_position_local_y * sin(runtime.current_time/500000) * 5
      -- vector3_set_components(vector3_stub,
      -- cape_position_local_x * (move_direction == 0 and instance.horizontal_look or move_direction),
      -- cape_position_local_y + sin(runtime.current_time * 10) * 2)
      -- set_position(vector3_stub, cape_anchor)
      sin(runtime.current_time * 10) -- remove this!
      -- for i = 1, CAPE_SEGMENT_COUNT do
      --    local dx = (cape_pos_x[i] - cape_prev_pos_x[i]) * CAPE_DRAG
      --    local dy = (cape_pos_y[i] - cape_prev_pos_y[i]) * CAPE_DRAG
      --    cape_prev_pos_x[i] = cape_pos_x[i]
      --    cape_prev_pos_y[i] = cape_pos_y[i]
      --    cape_pos_x[i] = cape_pos_x[i] + dx
      --    cape_pos_y[i] = cape_pos_y[i] + dy - CAPE_GRAVITY * dt
      -- end
      -- for i = 1, (CAPE_SEGMENT_COUNT - 1) do
      --    local ax = cape_pos_x[i]
      --    local ay = cape_pos_y[i]
      --    local bx = cape_pos_x[i + 1]
      --    local by = cape_pos_y[i + 1]
      --    local dx = bx - ax
      --    local dy = by - ay
      --    local distance = sqrt(dx * dx + dy * dy)
      --    if distance < 0.01 then distance = 0.01 end
      --    local difference = CAPE_CONSTRAINT_LENGTH - distance
      --    local percent = difference / distance
      --    if percent > 1 then percent = 1 end
      --    dx = dx * percent
      --    dy = dy * percent
      --    cape_pos_x[i + 1] = cape_pos_x[i + 1] + dx
      --    cape_pos_y[i + 1] = cape_pos_y[i + 1] + dy
      -- end
      -- for i = 1, CAPE_SEGMENT_COUNT do
      --    vector3_set_components(vector3_stub, cape_pos_x[i], cape_pos_y[i], -1)
      --    set_position(vector3_stub, cape_segments[i])
      -- end
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

   local function play_idle()
      play_animation(PLAYER, PLAYER.IDLE)
   end -- play_idle

   function idle.on_enter(previous_state)
      label.set_text(debug_label, "Idle")
      if previous_state == crouch then
         play_animation(PLAYER, PLAYER.RISE, nil, play_idle)
      elseif previous_state == slide then
         play_animation(PLAYER, PLAYER.SLIDE_END, nil, play_idle)
      else
         play_animation(PLAYER, PLAYER.IDLE)
      end
   end -- idle.on_enter

   function idle.update(dt)
      check_directional_input()
      turnaround(PLAYER)

      if PLAYER.current_animation_group == PLAYER.RISE then
         cape_position_local_y = lerp(CAPE_POSITION_Y_LOW, CAPE_POSITION_Y_HIGH, get(PLAYER.sprite, CURSOR))
         -- vector3_set_components(vector3_stub, cape_position_local_x, cape_position_local_y)
         -- set_position(vector3_stub, cape_anchor)
      end

      if is_down(A) and (jump_count < max_jumps) and (velocity_y < JUMP_SPEED) then
         velocity_y = JUMP_SPEED
      end

      advance(move(dt))

      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif is_down(X) then
         machine.enter_state(attack)
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

   local function play_walk()
      play_animation(PLAYER, PLAYER.WALK)
      max_horizontal_speed = MAX_HORIZONTAL_SPEED
   end -- play_walk_loop

   function walk.on_enter(previous_state)
      label.set_text(debug_label, "Walk")
      if previous_state == crouch then
         max_horizontal_speed = 20
         play_animation(PLAYER, PLAYER.RISE, nil, play_walk)
      elseif previous_state == slide then
         play_animation(PLAYER, PLAYER.SLIDE_END, nil, play_walk)
      else
         play_animation(PLAYER, PLAYER.WALK)
      end
      walk.loud_frame = 6 -- and 1
   end -- walk.on_enter

   function walk.update(dt)
      check_directional_input()
      turnaround(PLAYER)
      move_cape()

      if PLAYER.current_animation_group == PLAYER.WALK then
         local cursor = get(PLAYER.sprite, CURSOR)
         local frame = ceil(cursor * 10) -- frame count
         if frame == walk.loud_frame then
            play_sound(snd.ROGUE_FOOTSTEP)
            walk.loud_frame = walk.loud_frame == 1 and 6 or 1
         end
      end

      if is_down(A) and (jump_count < max_jumps) and (velocity_y < JUMP_SPEED) then
         -- jump_count = jump_count + 1
         velocity_y = JUMP_SPEED
      end

      advance(move(dt))

      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif is_down(X) then
         machine.enter_state(attack)
      elseif is_down(B) and not (contact_left or contact_right) then
         machine.enter_state(slide)
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
   end -- walk.update

   function walk.on_exit()
      max_horizontal_speed = MAX_HORIZONTAL_SPEED
   end -- walk.on_exit

   ---------------------------------------
   -- slide
   ---------------------------------------

   local SLIDE_DURATION = (1 / 60) * 16 + 0.15 -- slide itself + slide start ((1/20)*3)
   local SLIDE_SPEED = MAX_HORIZONTAL_SPEED * 1.5

   local function play_slide()
      play_animation(PLAYER, PLAYER.SLIDE)
   end -- play_slide

   function slide.on_enter()
      label.set_text(debug_label, "Slide")
      set_stance(CHARACTER_LOW_STANCE)
      slide.end_time = runtime.current_time + SLIDE_DURATION
      play_animation(PLAYER, PLAYER.SLIDE_START, nil, play_slide)
   end -- slide.on_enter

   function slide.update(dt)
      instance.needs_up_pass = true -- we need to know when stand up is safe
      advance(move(dt, nil, nil, SLIDE_SPEED))
      if (velocity_y ~= 0) or (contact_left or contact_right) or (runtime.current_time > slide.end_time) then
         if up_space and ((CHARACTER_LOW_STANCE + up_space) > CHARACTER_HIGH_STANCE) then
            set_stance(CHARACTER_HIGH_STANCE)
            if velocity_y > 0 then
               machine.enter_state(jump)
            elseif velocity_y < 0 then
               machine.enter_state(fall)
            elseif velocity_x == 0 then
               machine.enter_state(idle)
            else
               machine.enter_state(walk)
            end
         end
      end
   end -- slide.update

   ---------------------------------------
   -- jump
   ---------------------------------------

   local function play_jump()
      play_animation(PLAYER, PLAYER.JUMP)
   end -- play_jump

   function jump.on_enter(previous_state)
      label.set_text(debug_label, "Jump")
      jump_count = jump_count + 1
      instance.can_push = false
      if previous_state == air_attack then
         play_animation(PLAYER, PLAYER.JUMP)
      else
         play_animation(PLAYER, PLAYER.JUMP_START, nil, play_jump)
      end
   end -- jump.on_enter

   function jump.update(dt)
      check_directional_input()
      turnaround(PLAYER)

      if is_down(A) and (jump_count < max_jumps) then
         jump_count = jump_count + 1
         velocity_y = AIR_JUMP_SPEED
      elseif is_up(A) then
         if velocity_y > JUMP_CUT_SPEED then
            velocity_y = JUMP_CUT_SPEED
         end
      end

      advance(move(dt))
      instance.vertical_look = 0

      if is_down(X) then
         machine.enter_state(air_attack)
      elseif velocity_y <= 0 then
         machine.enter_state(fall)
      end
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
      play_animation(PLAYER, PLAYER.LAND, nil, land_complete)
      play_sound(snd.ROGUE_LAND, k)
   end -- land.on_enter

   function land.update(dt)
      check_directional_input()
      turnaround(PLAYER)

      if (is_down(A) or jump_buffer_time > 0) and (jump_count < max_jumps) then
         if jump_buffer_time > 0 then
            jump_count = 0
         end
         velocity_y = JUMP_SPEED
      end

      advance(move(dt))

      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif is_down(X) then
         machine.enter_state(attack)
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

   local function play_fall()
      play_animation(PLAYER, PLAYER.FALL)
   end -- play_fall

   function fall.on_enter(previous_state)
      label.set_text(debug_label, "Fall")
      if (previous_state == jump) or (previous_state == air_attack) then
         jump_grace_time = INFINITY
         play_animation(PLAYER, PLAYER.JUMP_TO_FALL, nil, play_fall)
      else
         jump_grace_time = JUMP_GRACE_TIME
         play_animation(PLAYER, PLAYER.FALL)
      end
   end -- fall.on_enter

   function fall.update(dt)
      check_directional_input()
      turnaround(PLAYER)

      if is_down(A) then
         if (jump_count == 0) and (jump_grace_time <= 0) then
            jump_count = jump_count + 1 -- too late, consume one jump
         end
         if jump_count < max_jumps then
            velocity_y = AIR_JUMP_SPEED
         else
            jump_buffer_time = JUMP_BUFFER_TIME
         end
      elseif is_down(B) and (move_direction ~= 0) then
         slide_buffer_time = SLIDE_BUFFER_TIME
      end

      jump_grace_time = jump_grace_time - dt

      advance(move(dt))
      instance.vertical_look = 0

      if is_down(X) then
         machine.enter_state(air_attack)
      elseif velocity_y > 0 then
         machine.enter_state(jump)
      elseif ground and (velocity_y == 0) then
         if (slide_buffer_time > 0) and (move_direction ~= 0) then
            machine.enter_state(slide)
         else
            machine.enter_state(land)
         end
      end

      jump_buffer_time = jump_buffer_time - dt
      slide_buffer_time = slide_buffer_time - dt
   end -- fall.update

   function fall.on_exit()
      instance.bypass = nil
      -- jump_count = 0
      -- instance.can_push = true
   end -- fall.on_exit

   ---------------------------------------
   -- crouch
   ---------------------------------------

   function crouch.on_enter(previous_state)
      label.set_text(debug_label, "Crouch")
      velocity_x = 0
      if previous_state ~= crouch_attack then
         set_stance(CHARACTER_LOW_STANCE)
         play_animation(PLAYER, PLAYER.CROUCH)
      else
         -- play_animation(target, animation_group, index, on_complete, cursor, rate, direction)
         play_animation(PLAYER, PLAYER.CROUCH, nil, nil, 1)
      end
      -- if previous_state == fall then
      --    play_sound(snd.ROGUE_LAND, abs(previous_velocity_y / MAX_VERTICAL_SPEED))
      -- end
   end -- crouch.on_enter

   function crouch.update(dt)
      check_directional_input()
      turnaround(PLAYER)

      if PLAYER.current_animation_group == PLAYER.CROUCH then
         cape_position_local_y = lerp(CAPE_POSITION_Y_HIGH, CAPE_POSITION_Y_LOW, get(PLAYER.sprite, CURSOR))
         -- vector3_set_components(vector3_stub, cape_position_local_x, cape_position_local_y)
         -- set_position(vector3_stub, cape_anchor)
      end

      if is_down(A) then
         local inst = get_instance(ground)
         if inst and inst.can_jump_down then
            instance.bypass = ground
         elseif (jump_count < max_jumps) then
            velocity_y = JUMP_SPEED
         end
      end

      instance.needs_up_pass = true -- we need to know when stand up is safe
      advance(move(dt, 0)) -- we don't move in that stance
      instance.vertical_look = -1 -- override to look down

      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif is_down(X) then
         machine.enter_state(crouch_attack)
      elseif not is_pressed(DOWN) then
         if up_space and ((CHARACTER_LOW_STANCE + up_space) > CHARACTER_HIGH_STANCE) then
            if move_direction ~= 0 then
               machine.enter_state(walk)
            else
               machine.enter_state(idle)
            end
         end
      end
   end -- crouch.update

   function crouch.on_exit(next_state)
      if next_state ~= crouch_attack then
         set_stance(CHARACTER_HIGH_STANCE)
      end
   end -- crouch.on_exit

   ---------------------------------------
   -- attack
   ---------------------------------------

   local function on_attack_complete()
      turnaround(PLAYER)

      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
         -- elseif attack_followup then
         --    machine.enter_state(attack2)
      elseif move_direction ~= 0 then
         machine.enter_state(walk)
      elseif is_down(DOWN) or is_pressed(DOWN) then
         machine.enter_state(crouch)
      else
         machine.enter_state(idle)
      end
   end -- on_attack_complete

   function attack.on_enter(previous_state)
      label.set_text(debug_label, "Attack")
      if (previous_state == air_attack) or (previous_state == crouch_attack) then
         play_animation(PLAYER, PLAYER.ATTACK, nil, on_attack_complete, go.get(PLAYER.sprite, CURSOR), nil, attack_direction)
      else
         attack_direction = instance.horizontal_look
         play_animation(PLAYER, PLAYER.ATTACK, nil, on_attack_complete)
      end
      vector3_set_components(vector3_stub, CAPE_POSITION_X, CAPE_POSITION_Y_HIGH)
      set_position(vector3_stub, cape_anchor)
      physics_set_hflip(collisionobject_hurtbox, attack_direction ~= 1)
      move_direction = 0
      velocity_x = 0
      attack.impact_frame = 3
   end -- attack.on_enter

   function attack.update(dt)
      if PLAYER.current_animation_group == PLAYER.ATTACK then
         local cursor = get(PLAYER.sprite, CURSOR)
         local frame = ceil(cursor * 6)
         if frame == attack.impact_frame then
            msg.post(collisionobject_hurtbox, msg.ENABLE)
            attack.impact_frame = 0
         end
      end

      if is_down(A) and (jump_count < max_jumps) then
         velocity_y = JUMP_SPEED
      end

      advance(move(dt, 0))

      if velocity_y ~= 0 then
         machine.enter_state(air_attack)
      elseif is_down(DOWN) or is_pressed(DOWN) then
         machine.enter_state(crouch_attack)
      end
   end -- attack.update

   function attack.on_exit(next_state)
      if not ((next_state == air_attack) or (next_state == crouch_attack)) then
         msg.post(collisionobject_hurtbox, msg.DISABLE)
      end
   end -- attack.on_exit

   ---------------------------------------
   -- crouch_attack
   ---------------------------------------

   local function on_crouch_attack_complete()
      turnaround(PLAYER)
      machine.enter_state(crouch)
   end -- on_crouch_attack_complete

   function crouch_attack.on_enter(previous_state)
      label.set_text(debug_label, "Crouch_attack")
      if previous_state ~= crouch then
         set_stance(CHARACTER_LOW_STANCE)
      end
      if previous_state == attack then
         play_animation(PLAYER, PLAYER.CROUCH_ATTACK, nil, on_crouch_attack_complete, go.get(PLAYER.sprite, CURSOR), nil, attack_direction)
      else
         attack_direction = instance.horizontal_look
         play_animation(PLAYER, PLAYER.CROUCH_ATTACK, nil, on_crouch_attack_complete)
      end
      vector3_set_components(vector3_stub, CAPE_POSITION_X, CAPE_POSITION_Y_LOW)
      set_position(vector3_stub, cape_anchor)
      physics_set_hflip(collisionobject_hurtbox, attack_direction ~= 1)
      crouch_attack.impact_frame = 3
   end -- crouch_attack.on_enter

   function crouch_attack.update(dt)
      if PLAYER.current_animation_group == PLAYER.CROUCH_ATTACK then
         local cursor = get(PLAYER.sprite, CURSOR)
         local frame = ceil(cursor * 6)
         if frame == crouch_attack.impact_frame then
            msg.post(collisionobject_hurtbox, msg.ENABLE)
            crouch_attack.impact_frame = 0
         end
      end

      if is_down(A) then
         local inst = get_instance(ground)
         if inst and inst.can_jump_down then
            instance.bypass = ground
         elseif (jump_count < max_jumps) then
            velocity_y = JUMP_SPEED
         end
      end

      instance.needs_up_pass = true -- we need to know when stand up is safe
      advance(move(dt, 0)) -- don't move
      instance.vertical_look = -1 -- override to look down

      if velocity_y ~= 0 then
         machine.enter_state(air_attack)
      elseif not is_pressed(DOWN) then
         if up_space and ((CHARACTER_LOW_STANCE + up_space) > CHARACTER_HIGH_STANCE) then -- if safe to stand up
            machine.enter_state(attack)
         end
      end
   end -- crouch_attack.update

   function crouch_attack.on_exit(next_state)
      if next_state ~= crouch then
         set_stance(CHARACTER_HIGH_STANCE)
      end
      if not ((next_state == attack) or (next_state == air_attack)) then
         msg.post(collisionobject_hurtbox, msg.DISABLE)
      end
   end -- crouch_attack.on_exit

   ---------------------------------------
   -- air_attack
   ---------------------------------------

   local function on_air_attack_complete()
      turnaround(PLAYER)

      if velocity_y > 0 then
         machine.enter_state(jump)
      elseif velocity_y < 0 then
         machine.enter_state(fall)
      elseif move_direction ~= 0 then
         machine.enter_state(walk)
      elseif is_down(DOWN) or is_pressed(DOWN) then
         machine.enter_state(crouch)
      else
         machine.enter_state(idle)
      end
   end -- on_air_attack_complete

   function air_attack.on_enter(previous_state)
      label.set_text(debug_label, "Air_attack")
      if (previous_state == attack) or (previous_state == crouch_attack) then
         play_animation(PLAYER, PLAYER.AIR_ATTACK, nil, on_air_attack_complete, go.get(PLAYER.sprite, CURSOR), nil, attack_direction)
      else
         attack_direction = instance.horizontal_look
         play_animation(PLAYER, PLAYER.AIR_ATTACK, nil, on_air_attack_complete)
      end
      vector3_set_components(vector3_stub, CAPE_POSITION_X, CAPE_POSITION_Y_HIGH)
      set_position(vector3_stub, cape_anchor)
      physics_set_hflip(collisionobject_hurtbox, attack_direction ~= 1)
      air_attack.impact_frame = 3
   end -- air_attack.on_enter

   function air_attack.update(dt)
      check_directional_input()
      advance(move(dt))

      if PLAYER.current_animation_group == PLAYER.AIR_ATTACK then
         local cursor = get(PLAYER.sprite, CURSOR)
         local frame = ceil(cursor * 6)
         if frame == air_attack.impact_frame then
            msg.post(collisionobject_hurtbox, msg.ENABLE)
            air_attack.impact_frame = 0
         end
      end

      if velocity_y == 0 then
         machine.enter_state(attack)
      end
   end -- air_attack.update

   function air_attack.on_exit(next_state)
      if not ((next_state == attack) or (next_state == crouch_attack)) then
         msg.post(collisionobject_hurtbox, msg.DISABLE)
      end
   end -- air_attack.on_exit

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
            play_animation(PLAYER, PLAYER.WALK)
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
            -- advance(dx, dy)
            if target.is_door then
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
      nc.post_notification(Maze.entity_did_leave_level_notification, root.path, target.map, target.gate)
      runtime.remove_update_callback(instance)
      machine.enter_state(undefined)
   end --turnaround_complete

   function map_change.on_enter()
      label.set_text(debug_label, "Map_change")
      -- play_animation(PLAYER, PLAYER.TURNAROUND_DOOR, nil, turnaround_complete)
      play_animation(PLAYER, PLAYER.CROUCH, nil, turnaround_complete)
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
      local min_distance = INFINITY
      local pretender = nil
      local pretender_instance = nil
      for id, enter in next, responders do
         local responder_instance = get_instance(id)
         if responder_instance then
            if enter and responder_instance.accepts_first_responder(instance) then
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
      previous_velocity_y = velocity_y
      contact_right = false
      contact_left = false
      if ground then
         jump_count = 0
         instance.can_push = true
      else
         instance.can_push = false
      end
      check_responders()
      machine.update(dt)
   end -- update

   local function on_level_appear(_, x, y)
      -- player
      instance.x = x
      instance.y = y
      velocity_x = 0
      velocity_y = 0
      instance.dx = 0
      instance.dy = 0
      vector3_set_components(vector3_stub, x, y, 0)
      set_position(vector3_stub, root)
      runtime.add_update_callback(instance, update)
   end -- on_level_appear

   function instance.on_contact(_, direction)
      if direction == 1 then
         contact_right = true
      else
         contact_left = true
      end
   end -- instance.on_contact

   function instance.init()
      root = msg.url(".")
      PLAYER.object = msg.url("tim")
      PLAYER.sprite = msg.url("tim#sprite")
      PLAYER.current_animation_group = nil
      PLAYER.current_animation = nil
      PLAYER.on_complete = nil
      collisionobject_raycast_high = msg.url("#collisionobject_raycast_high")
      collisionobject_raycast_low = msg.url("#collisionobject_raycast_low")
      collisionobject_hitbox_high = msg.url("#collisionobject_hitbox_high")
      collisionobject_hitbox_low = msg.url("#collisionobject_hitbox_low")
      collisionobject_hurtbox = msg.url("cape_anchor#collisionobject_hurtbox")
      msg.post(collisionobject_hurtbox, msg.DISABLE)
      vector3_set_components(vector3_stub, 0, 0, PLAYER_DEPTH)
      set_position(vector3_stub, PLAYER.object)
      acceleration = GROUND_ACCELERATION
      max_horizontal_speed = MAX_HORIZONTAL_SPEED
      gravity = NORMAL_GRAVITY
      velocity_x = 0
      velocity_y = 0
      move_direction = 0
      instance.horizontal_look = 1
      instance.vertical_look = 1
      ground = nil
      up_space = nil
      jump_count = 0
      jump_buffer_time = 0
      slide_buffer_time = 0
      max_jumps = MAX_JUMPS > 0 and MAX_JUMPS or INFINITY
      contact_right = false
      contact_left = false
      raycast_controller.set_width(CHARACTER_WIDTH)
      set_stance(CHARACTER_HIGH_STANCE)
      runtime.set_instance(root.path, instance)

      nc.add_observer(on_level_appear, Maze.level_will_appear_notification)

      debug_label = msg.url("#debug_label")
      debug_label2 = msg.url("#debug_label2")
      debug_label3 = msg.url("#debug_label3")
      msg.post(debug_label2, msg.DISABLE)
      msg.post(debug_label3, msg.DISABLE)

      -- cape
      cape_anchor = msg.url("cape_anchor")
      cape_position_local_x = CAPE_POSITION_X
      cape_position_local_y = CAPE_POSITION_Y_HIGH
      -- for i = 1, CAPE_SEGMENT_COUNT do
      --    cape_segments[i] = msg.url("cape_segment" .. i)
      -- end
   end -- init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(on_level_appear, Maze.level_will_appear_notification)
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
