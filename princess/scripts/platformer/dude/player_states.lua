-- import
local StateMachine = require("scripts.shared.state_machine")
local FX = require("scripts.platformer.fx")
local SND = require("scripts.platformer.sound")
-- local MSG = require("scripts.shared.messages")
local game = require("scripts.platformer.game")
-- local utils = require("scripts.shared.utils")

-- localization
local animate = go.animate
local pairs = pairs
local set_text = label.set_text
local vector3 = vmath.vector3
local set_position = go.set_position
local set = go.set
local create = factory.create
local is_down = game.is_down
local is_up = game.is_up
local is_pressed = game.is_pressed
local LEFT = game.LEFT
local RIGHT = game.RIGHT
-- local UP = game.UP
-- local DOWN = game.DOWN
-- local DOWN_LEFT = game.DOWN_LEFT
-- local DOWN_RIGHT = game.DOWN_RIGHT
local A = game.A -- jump
local X = game.X -- sword attack
local play_flipbook = sprite.play_flipbook

-- functions
local make_machine

-- constants
local HUGE = math.huge
local EULER_Y = hash("euler.y")
local EULER_Z = hash("euler.z")
local POSITION_Y = hash("position.y")
local JUMP_GRACE_TIME = (1 / 60) * 6
local PLAYBACK_ONCE_FORWARD = go.PLAYBACK_ONCE_FORWARD
local EASING_LINEAR = go.EASING_LINEAR


-- animations
local IDLE   = {id = hash("dude_idle"),   position = vector3(0, 16, 0)}
local RUN    = {id = hash("dude_run"),    position = vector3(0, 16, 0)}
local JUMP   = {id = hash("dude_jump"),   position = vector3(0, 16, 0)}
local FALL   = {id = hash("dude_fall"),   position = vector3(0, 16, 0)}
local ATTACK = {id = hash("dude_attack"), position = vector3(0, 16, 0)}


---------------------------------------
-- make_machine
---------------------------------------

function make_machine(owner)
   -- states
   local idle = {}
   local run = {}
   local jump = {}
   local fall = {}
   local attack = {}

   local current_animation = nil
   local buffered_attack = false
   -- local buffered_jump = false
   local jump_count = 0

   -- local sword_sounds = {
   --   SND.SWING_SWORD_01,
   --   SND.SWING_SWORD_02,
   -- }

   local machine = StateMachine.new(idle)

   ---------------------------------------
   -- check_directional_input
   ---------------------------------------

   local function check_directional_input()
      if is_down(LEFT) or
      (is_up(RIGHT) and is_pressed(LEFT)) or
      (is_pressed(LEFT) and not is_pressed(RIGHT)) then
         owner.move_direction = -1
         owner.look_direction = -1
      elseif is_down(RIGHT) or
      (is_up(LEFT) and is_pressed(RIGHT)) or
      (is_pressed(RIGHT) and not is_pressed(LEFT)) then
         owner.move_direction = 1
         owner.look_direction = 1
      elseif (not is_pressed(LEFT)) and (not is_pressed(RIGHT)) then
         -- elseif ((is_up(LEFT) or is_up(RIGHT)) and not (is_pressed(LEFT) or is_pressed(RIGHT))) or
         -- (not is_pressed(LEFT) and not is_pressed(RIGHT)) then
         owner.move_direction = 0
      end
   end -- check_directional_input

   -- local function check_directional_input()
   --   if is_pressed(LEFT) or is_pressed(DOWN_LEFT) or is_down(LEFT) or is_down(DOWN_LEFT) then
   --     owner.move_direction = -1
   --     owner.look_direction = -1
   --   elseif is_pressed(RIGHT) or is_pressed(DOWN_RIGHT) or is_down(RIGHT) or is_down(DOWN_RIGHT) then
   --     owner.move_direction = 1
   --     owner.look_direction = 1
   --   elseif not (is_pressed(LEFT) or is_pressed(RIGHT) or is_pressed(DOWN_LEFT) or is_pressed(DOWN_RIGHT)) then
   --     owner.move_direction = 0
   --   end
   -- end -- check_directional_input

   ---------------------------------------
   -- play_animation
   ---------------------------------------

   local function play_animation(animation, on_complete)
      if current_animation == animation then return end
      set_position(animation.position, owner.body)
      play_flipbook(owner.body_sprite, animation.id, on_complete)
      current_animation = animation
   end -- play_animation

   ---------------------------------------
   -- idle
   ---------------------------------------

   function idle.on_enter()
      set_text(owner.label, "IDLE")
      play_animation(IDLE)
      jump_count = 0
      -- buffered_jump = false
   end -- idle.on_enter

   function idle.execute(dt)
      local velocity = owner.velocity

      check_directional_input(owner)

      if is_down(A) and (jump_count < owner.max_jumps) then
         -- buffered_jump = false
         jump_count = jump_count + 1
         velocity.y = owner.jump_speed
      end

      if is_down(X) or buffered_attack then
         buffered_attack = false
         machine.enter_state(attack)
      elseif velocity.y > 0 then
         machine.enter_state(jump)
      elseif velocity.y < 0 then
         machine.enter_state(fall)
      elseif velocity.x ~= 0 then
         machine.enter_state(run)
      end

      owner:move(dt)
   end -- idle.execute

   ---------------------------------------
   -- run
   ---------------------------------------

   function run.on_enter()
      set_text(owner.label, "RUN")
      play_animation(RUN)
      local dust_run = owner.look_direction > 0 and FX.DUDE_RUN_DUST_RIGHT or FX.DUDE_RUN_DUST_LEFT
      local position = vector3(owner.position)
      create(FX.FACTORY, position, nil, dust_run)
      jump_count = 0
      -- buffered_jump = false
   end -- run.on_enter

   function run.execute(dt)
      local velocity = owner.velocity

      check_directional_input(owner)
      set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)

      if is_down(A) and (jump_count < owner.max_jumps) then
         -- buffered_jump = false
         jump_count = jump_count + 1
         velocity.y = owner.jump_speed
      end

      if is_down(X) or buffered_attack then
         buffered_attack = false
         machine.enter_state(attack)
      elseif velocity.y > 0 then
         machine.enter_state(jump)
      elseif velocity.y < 0 then
         machine.enter_state(fall)
      elseif velocity.x == 0 then
         machine.enter_state(idle)
      end

      owner:move(dt)
   end -- run.execute

   ---------------------------------------
   -- jump
   ---------------------------------------

   function jump.on_enter()
      set_text(owner.label, "JUMP")
      play_animation(JUMP)
      SND.PLAYER_JUMP:create_instance():start()
   end -- jump.on_enter

   function jump.execute(dt)
      local velocity = owner.velocity

      check_directional_input(owner)
      set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)

      if is_down(A) and (jump_count < owner.max_jumps) then
         jump_count = jump_count + 1
         velocity.y = owner.jump_speed
         if jump_count > 1 then
            local position = vector3(owner.position)
            create(FX.FACTORY, position, nil, FX.DUDE_JUMP_DUST)
            SND.PLAYER_JUMP:create_instance():start()
         end
      elseif is_up(A) then
         velocity.y = velocity.y * 0.5
      end

      if is_down(X) or buffered_attack then
         buffered_attack = false
         machine.enter_state(attack)
      elseif velocity.y <= 0 then
         machine.enter_state(fall)
      end

      owner:move(dt)
   end -- jump.execute

   -- function jump.execute(dt)
   -- local velocity = owner.velocity
   --
   -- check_directional_input(owner)
   -- set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)
   --
   -- if is_down(A) and (jump_count < owner.max_jumps) then
   --   jump_count = jump_count + 1
   --   velocity.y = owner.jump_speed
   --   if jump_count > 1 then
   --     local position = vector3(owner.position)
   --     create(FX.FACTORY, position, nil, FX.DUDE_JUMP_DUST)
   --   end
   -- elseif is_up(A) then
   --   velocity.y = velocity.y * 0.5
   -- end
   --
   -- if is_down(X) or buffered_attack then
   --   buffered_attack = false
   --   machine.enter_state(attack)
   -- elseif velocity.y < 0 then
   --   machine.enter_state(fall)
   -- end
   --
   -- owner:move(dt)
   -- end -- jump.execute

   ---------------------------------------
   -- fall
   ---------------------------------------

   function fall.on_enter()
      set_text(owner.label, "FALL")
      play_animation(FALL)
      if machine.previous_state == idle or machine.previous_state == run then
         fall.jump_grace_time = JUMP_GRACE_TIME
      else
         fall.jump_grace_time = HUGE
      end
   end -- fall.on_enter

   function fall.execute(dt)
      local velocity = owner.velocity

      check_directional_input(owner)
      set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)

      if is_down(A) then --or buffered_jump then
         -- buffered_jump = false
         if fall.jump_grace_time < 0 then
            jump_count = jump_count + 1
         end
         if jump_count < owner.max_jumps then
            jump_count = jump_count + 1
            velocity.y = owner.jump_speed
            if jump_count > 1 then
               local position = vector3(owner.position)
               create(FX.FACTORY, position, nil, FX.DUDE_JUMP_DUST)
            end
         end
      end

      fall.jump_grace_time = fall.jump_grace_time - dt

      if is_down(X) or buffered_attack then
         buffered_attack = false
         machine.enter_state(attack)
      elseif velocity.y == 0 then
         if velocity.x == 0 then
            machine.enter_state(idle)
         else
            machine.enter_state(run)
         end
      elseif velocity.y > 0 then
         machine.enter_state(jump)
      end

      owner:move(dt)
   end -- fall.execute

   ---------------------------------------
   -- attack
   ---------------------------------------

   local function on_attack_complete()
      local velocity = owner.velocity

      if velocity.y == 0 then
         if velocity.x == 0 then
            machine.enter_state(idle)
         else
            machine.enter_state(run)
         end
      elseif velocity.y > 0 then
         machine.enter_state(jump)
      else
         machine.enter_state(fall)
      end
   end

   function attack.on_enter()
      set_text(owner.label, "ATTACK")
      play_animation(ATTACK, on_attack_complete)
      -- go.animate(url, property, playback, to, easing, duration, delay, complete_function)
      animate(owner.sword_a, POSITION_Y, PLAYBACK_ONCE_FORWARD, 30, EASING_LINEAR, 0.1875, 0.0625)
      animate(owner.sword_start, EULER_Z, PLAYBACK_ONCE_FORWARD, -85, EASING_LINEAR, 0.1875, 0.0625)
      SND.SWING_SWORD_01:create_instance():start()
      attack.time = 0
      for k in pairs(owner.hits) do
         owner.hits[k] = nil
      end
   end -- attack.on_enter

   function attack.execute(dt)
      local velocity = owner.velocity

      check_directional_input(owner)

      if is_down(A) and (jump_count < owner.max_jumps) then
         jump_count = jump_count + 1
         velocity.y = owner.jump_speed
         if jump_count > 1 then
            local position = vector3(owner.position)
            create(FX.FACTORY, position, nil, FX.DUDE_JUMP_DUST)
         end
      elseif is_up(A) then
         velocity.y = velocity.y * 0.5
      end

      if is_down(X) then
         buffered_attack = true
      end

      if velocity.y == 0 then
         owner.move_direction = 0
      end

      owner:move(dt)
      if attack.time > 0.0625 then
         owner:sword_attack()
      end
      attack.time = attack.time + dt
   end -- attack.execute

   function attack.on_exit()
      set(owner.sword_a, "position.y", 0)
      set(owner.sword_start, "euler.z", 105)
   end -- attack.on_exit

   return machine
end -- make_machine

-- export
return {
   make_machine = make_machine
}
