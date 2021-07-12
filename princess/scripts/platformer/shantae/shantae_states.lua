-- import
local StateMachine = require("scripts.shared.state_machine")
local SND = require("scripts.platformer.sound")
local LAYER = require("scripts.shared.layers")
local FX = require("scripts.platformer.fx")
local game = require("scripts.platformer.game")
local ui = require("scripts.shared.ui.ui")
local utils = require("scripts.shared.utils")

-- localization
-- local animate = go.animate
local pairs = pairs
local label = label
local vector3 = vmath.vector3
local set_position = go.set_position
local get_world_position = go.get_world_position
local set = go.set
local is_down = game.is_down
local is_up = game.is_up
local is_pressed = game.is_pressed
local LEFT = ui.LEFT
local RIGHT = ui.RIGHT
local UP = ui.UP
local DOWN = ui.DOWN
local DOWN_LEFT = ui.DOWN_LEFT
local DOWN_RIGHT = ui.DOWN_RIGHT
local A = ui.A
local B = ui.B
local Y = ui.Y
local X = ui.X
local R = ui.R
local play_flipbook = sprite.play_flipbook
local get_context = game.get_context
local select_reset = utils.select_reset
local select_next = utils.select_next
local get_delta_position = game.get_delta_position
local play_fx = particlefx.play
local timer = timer
local factory = factory
local play_sound = SND.play_sound

-- functions
local make_machine

-- constants
local HUGE = math.huge
local EULER_Y = hash("euler.y")
-- local EULER_Z = hash("euler.z")
-- local POSITION_Y = hash("position.y")
local JUMP_GRACE_TIME = 1 / 60 * 7
-- local PLAYBACK_ONCE_FORWARD = go.PLAYBACK_ONCE_FORWARD
-- local EASING_LINEAR = go.EASING_LINEAR
local JUMP_CUT_VELOCITY = 200
local IDENTITY = vmath.quat()
local ONE = vmath.vector3(1)

-- animations
-- has been gathered in dictionary because of too many uvalues issue (more then 60)
local ANIMATION = {
   -- STANDING_IDLE      = { id = hash("shantae_standing_idle"),      position = vector3( 0.0,  0.0, 0) },
   STANDING_IDLE_FULL = { id = hash("shantae_standing_idle_full"), position = vector3(-6, 21, 0) },
   DUCK_DOWN          = { id = hash("shantae_duck_down"),          position = vector3( 0, 21, 0) },
   DUCK_UP            = { id = hash("shantae_duck_up"),            position = vector3( 0, 21, 0) },
   DUCK_IDLE          = { id = hash("shantae_duck_idle"),          position = vector3( 4, 12, 0) },
   RUN                = { id = hash("shantae_run"),                position = vector3(-2, 21, 0) },
   RUN_STOP           = { id = hash("shantae_run_stop"),           position = vector3(-2, 22, 0) },
   CRAWL              = { id = hash("shantae_crawl"),              position = vector3( 0, 13, 0) },
   JUMP               = { id = hash("shantae_jump"),               position = vector3(-2, 21, 0) },
   JUMP_FINISH        = { id = hash("shantae_jump_finish"),        position = vector3(-1, 22, 0) },
   FALL_START         = { id = hash("shantae_fall_start"),         position = vector3(-1, 22, 0) },
   FALL               = { id = hash("shantae_fall"),               position = vector3( 0, 31, 0) },
   LAND               = { id = hash("shantae_land"),               position = vector3(-3, 24, 0) },
   ROPE_IDLE          = { id = hash("shantae_rope_idle"),          position = vector3( 0, 20, 0) },
   ROPE_DOWN          = { id = hash("shantae_rope_down"),          position = vector3( 0, 22, 0) },
   HAT_INIT           = { id = hash("shantae_hat_init"),           position = vector3(-6, 44, 0) },
   HAT_GLIDE          = { id = hash("shantae_hat_glide"),          position = vector3(-8, 36, 0) },
   HAT_REMOVE         = { id = hash("shantae_hat_remove"),         position = vector3(-6, 44, 0) },
   CANNON_JUMP        = { id = hash("shantae_cannon_jump"),        position = vector3(-2, 28, 0) }, -- -1 28
   CANNON_FALL        = { id = hash("shantae_cannon_fall"),        position = vector3(-2, 28, 0) },
   DOWN_THRUST        = { id = hash("shantae_down_thrust"),        position = vector3(-2, 17, 0) },
   WALK               = { id = hash("shantae_walk"),               position = vector3(-3, 22, 0) },
}

local ROPE_UP_FRAME_TIME = 0.033
local ROPE_UP = {
   { id = hash("shantae_rope_up_1"),  position = vector3( 0, 19, 0) },
   { id = hash("shantae_rope_up_2"),  position = vector3( 0, 19, 0) },
   { id = hash("shantae_rope_up_3"),  position = vector3( 0, 19, 0) },
   { id = hash("shantae_rope_up_4"),  position = vector3( 0, 19, 0) },
   { id = hash("shantae_rope_up_5"),  position = vector3( 0, 19, 0) },
   { id = hash("shantae_rope_up_6"),  position = vector3( 0, 19, 0) },
   { id = hash("shantae_rope_up_7"),  position = vector3( 0, 19, 0) },
   { id = hash("shantae_rope_up_8"),  position = vector3( 0, 19, 0) },
   { id = hash("shantae_rope_up_9"),  position = vector3( 0, 19, 0) },
   { id = hash("shantae_rope_up_10"), position = vector3( 0, 19, 0) },
   { id = hash("shantae_rope_up_11"), position = vector3( 0, 19, 0) },
   { id = hash("shantae_rope_up_12"), position = vector3( 0, 19, 0) },
}

local WHIP_FRAME_TIME = 1 / 20
local WHIP_FRAME_COUNT = 8
local STANDING_WHIP = {
   { id = hash("shantae_standing_whip_1"), position = vector3(17, 20, 0) },
   { id = hash("shantae_standing_whip_2"), position = vector3(17, 20, 0) },
   { id = hash("shantae_standing_whip_3"), position = vector3(17, 20, 0) },
   { id = hash("shantae_standing_whip_4"), position = vector3(17, 20, 0) },
   { id = hash("shantae_standing_whip_5"), position = vector3(17, 20, 0) },
   { id = hash("shantae_standing_whip_6"), position = vector3(17, 20, 0) },
   { id = hash("shantae_standing_whip_7"), position = vector3(17, 20, 0) },
   { id = hash("shantae_standing_whip_8"), position = vector3(17, 20, 0) },
}

local JUMP_WHIP = {
   { id = hash("shantae_jump_whip_1"), position = vector3(17, 21, 0) },
   { id = hash("shantae_jump_whip_2"), position = vector3(17, 21, 0) },
   { id = hash("shantae_jump_whip_3"), position = vector3(17, 21, 0) },
   { id = hash("shantae_jump_whip_4"), position = vector3(17, 21, 0) },
   { id = hash("shantae_jump_whip_5"), position = vector3(17, 21, 0) },
   { id = hash("shantae_jump_whip_6"), position = vector3(17, 21, 0) },
   { id = hash("shantae_jump_whip_7"), position = vector3(17, 21, 0) },
   { id = hash("shantae_jump_whip_8"), position = vector3(17, 21, 0) },
}

local DUCK_WHIP = {
   { id = hash("shantae_duck_whip_1"), position = vector3(22, 14, 0) },
   { id = hash("shantae_duck_whip_2"), position = vector3(22, 14, 0) },
   { id = hash("shantae_duck_whip_3"), position = vector3(22, 14, 0) },
   { id = hash("shantae_duck_whip_4"), position = vector3(22, 14, 0) },
   { id = hash("shantae_duck_whip_5"), position = vector3(22, 14, 0) },
   { id = hash("shantae_duck_whip_6"), position = vector3(22, 14, 0) },
   { id = hash("shantae_duck_whip_7"), position = vector3(22, 14, 0) },
   { id = hash("shantae_duck_whip_8"), position = vector3(22, 14, 0) },
}

local BLAST_FRAME_TIME = 1 / 16
local BLAST_FRAME_COUNT = 6
local STANDING_BLAST = {
   { id = hash("shantae_pistol_blast_1"), position = vector3(-5, 22, 0) },
   { id = hash("shantae_pistol_blast_2"), position = vector3(-5, 22, 0) },
   { id = hash("shantae_pistol_blast_3"), position = vector3(-5, 22, 0) },
   { id = hash("shantae_pistol_blast_4"), position = vector3(-5, 22, 0) },
   { id = hash("shantae_pistol_blast_5"), position = vector3(-5, 22, 0) },
   { id = hash("shantae_pistol_blast_6"), position = vector3(-5, 22, 0) },
}

local JUMP_BLAST = {
   { id = hash("shantae_pistol_blast_jump_1"), position = vector3(-3, 24, 0) },
   { id = hash("shantae_pistol_blast_jump_2"), position = vector3(-3, 24, 0) },
   { id = hash("shantae_pistol_blast_jump_3"), position = vector3(-3, 24, 0) },
   { id = hash("shantae_pistol_blast_jump_4"), position = vector3(-3, 24, 0) },
   { id = hash("shantae_pistol_blast_jump_5"), position = vector3(-3, 24, 0) },
   { id = hash("shantae_pistol_blast_jump_6"), position = vector3(-3, 24, 0) },
}

local FOOTSTEPS_FRAME_TIME = 1 / 32 * 8 -- 32 - run animation fps, 8 - one step frames count
local FOOT_STEPS_CEMENT = {
   SND.SHANTAE_FOOT_STEP_CEMENT_1,
   SND.SHANTAE_FOOT_STEP_CEMENT_2,
   SND.SHANTAE_FOOT_STEP_CEMENT_3,
   SND.SHANTAE_FOOT_STEP_CEMENT_4,
   SND.SHANTAE_FOOT_STEP_CEMENT_5,
   SND.SHANTAE_FOOT_STEP_CEMENT_6,
   SND.SHANTAE_FOOT_STEP_CEMENT_7,
   SND.SHANTAE_FOOT_STEP_CEMENT_8,
}

---------------------------------------
-- make_machine
---------------------------------------

function make_machine(owner)
   -- states
   local idle = { JUMP_GRACE_TIME = JUMP_GRACE_TIME, name = "IDLE" }
   local run = { JUMP_GRACE_TIME = JUMP_GRACE_TIME, name = "RUN" }
   local duck = { JUMP_GRACE_TIME = JUMP_GRACE_TIME, name = "DUCK" }
   local crawl = { JUMP_GRACE_TIME = JUMP_GRACE_TIME, name = "CRAWL" }
   local jump = { JUMP_GRACE_TIME = HUGE, name = "JUMP" }
   local fall = { jump_grace_time = 0, name = "FALL" }
   local glide = { JUMP_GRACE_TIME = 0, name = "GLIDE" }
   local climb = { JUMP_GRACE_TIME = JUMP_GRACE_TIME, dt = ROPE_UP_FRAME_TIME, name = "CLIMB" }

   local standing_whip = { JUMP_GRACE_TIME = HUGE, name = "STANDING_WHIP" }
   local jump_whip = { JUMP_GRACE_TIME = HUGE, name = "JUMP_WHIP" }
   local duck_whip = { JUMP_GRACE_TIME = HUGE, name = "DUCK_WHIP" }

   local standing_blast = { JUMP_GRACE_TIME = HUGE, name = "STANDING_BLAST" }
   local jump_blast = { JUMP_GRACE_TIME = HUGE, name = "JUMP_BLAST" }

   local down_thrust = { JUMP_GRACE_TIME = HUGE, name = "DOWN_THRUST" }

   local cutscene = { name = "CUTSCENE" }

   local jump_count = 0
   local current_animation = nil
   local buffered_whip = false
   local low_profile = false
   local run_time = 0
   local whip_frame = 1
   local whip_frame_time = 0
   local blast_frame = 1
   local blast_frame_time = 0
   local buffered_blast = false
   local attack_look_direction = nil
   local bullet_properties = { direction = 1 }
   local pull_the_trigger = false

   local machine = nil

   ---------------------------------------
   -- check_directional_input
   ---------------------------------------

   local function check_directional_input()
      -- utils.log("check_directional_input start")

      local is_pressed_left = is_pressed(LEFT)
      local is_pressed_rigth = is_pressed(RIGHT)
      local is_pressed_down_left = is_pressed(DOWN_LEFT)
      local is_pressed_down_right = is_pressed(DOWN_RIGHT)
      local is_pressed_down = is_pressed(DOWN)

      -- if
      -- (is_pressed_left and is_pressed_rigth) or
      -- (is_pressed_down_left and is_pressed_down_right) or
      -- ((is_pressed_left or is_pressed_rigth) and is_pressed(DOWN)) then
      --   return
      if is_down(LEFT) then
         owner.move_direction = -1
         owner.look_direction = -1
         low_profile = is_pressed_down
      elseif is_down(RIGHT) then
         owner.move_direction = 1
         owner.look_direction = 1
         low_profile = is_pressed_down
      elseif is_down(DOWN) then
         low_profile = true
      elseif is_down(DOWN_LEFT) then
         owner.move_direction = -1
         owner.look_direction = -1
         low_profile = true
      elseif is_down(DOWN_RIGHT) then
         owner.move_direction = 1
         owner.look_direction = 1
         low_profile = true
      elseif is_pressed_left and (not is_pressed_rigth) then
         owner.move_direction = -1
         owner.look_direction = -1
         low_profile = is_pressed_down
      elseif is_pressed_rigth and (not is_pressed_left) then
         owner.move_direction = 1
         owner.look_direction = 1
         low_profile = is_pressed_down
      elseif is_pressed_down_left then
         owner.move_direction = -1
         owner.look_direction = -1
         low_profile = true
      elseif is_pressed_down_right then
         owner.move_direction = 1
         owner.look_direction = 1
         low_profile = true
      elseif is_pressed(DOWN) and not (is_pressed_left or is_pressed_rigth) then
         owner.move_direction = 0
         low_profile = true
      elseif not (is_pressed_left or  is_pressed_rigth or is_pressed_down_left or is_pressed_down_right) then
         low_profile = false
         owner.move_direction = 0
      end

      -- utils.log("check_directional_input end")
   end -- check_directional_input

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

   local function play_idle_animation()
      play_animation(ANIMATION.STANDING_IDLE_FULL)
   end -- play_idle_animation

   function idle.on_enter(previous_state)
      -- utils.log(idle.name, whip_frame, game.get_frame())
      label.set_text(owner.label, idle.name)

      set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)

      if (previous_state == fall) or (previous_state == glide) or (previous_state == down_thrust) then
         play_animation(ANIMATION.LAND, play_idle_animation)
         play_fx(owner.fx_dust_left)
         play_fx(owner.fx_dust_right)
         play_sound(previous_state == down_thrust and SND.SHANTAE_DOWN_THRUST_LAND or SND.SHANTAE_LAND)
      elseif (previous_state == run) and (run_time > 0.3) then
         play_animation(ANIMATION.RUN_STOP, play_idle_animation)
         if owner.look_direction == 1 then
            play_fx(owner.fx_dust_right)
         else
            play_fx(owner.fx_dust_left)
         end
      elseif (previous_state == duck) or (previous_state == crawl) then
         play_animation(ANIMATION.DUCK_UP, play_idle_animation)
      else
         play_animation(ANIMATION.STANDING_IDLE_FULL)
      end
      if owner.velocity.y == 0 then
         jump_count = 0
      end
   end -- idle.on_enter

   function idle.execute(dt)
      check_directional_input()
      local velocity = owner.velocity

      if is_down(X) or buffered_whip then
         buffered_whip = false
         machine.enter_state(standing_whip)
      elseif is_down(B) or buffered_blast then
         pull_the_trigger = true
         machine.enter_state(standing_blast)
      elseif is_down(A) and (jump_count < owner.max_jumps) then
         jump_count = jump_count + 1
         velocity.y = owner.jump_speed
         machine.enter_state(jump)
      elseif owner.rope and (is_down(Y) or is_pressed(Y)) then
         local rope_context = get_context(owner.rope)
         if rope_context then
            owner.rope_platform = rope_context.platform
            machine.enter_state(climb)
            owner:climb(0)
            return
         end
      elseif owner.interactor and is_down(R) then
         game.set_pause_allowed(false)
         machine.enter_state(cutscene)
         return
      elseif velocity.y > 0 then
         jump_count = jump_count + 1
         machine.enter_state(jump)
      elseif velocity.y < 0 then
         machine.enter_state(fall)
      elseif (owner.move_direction ~= 0) or (velocity.x ~= 0) then
         if low_profile then
            machine.enter_state(crawl)
         else
            machine.enter_state(run)
         end
      elseif low_profile then
         machine.enter_state(duck)
      end

      owner:move(dt)
   end -- idle.execute

   ---------------------------------------
   -- run
   ---------------------------------------

   local function play_footsteps_fx()
      play_sound(select_next(FOOT_STEPS_CEMENT))
   end -- play_footsteps_fx

   function run.on_enter(previous_state)
      -- utils.log(run.name, whip_frame, game.get_frame())
      label.set_text(owner.label, run.name)

      play_animation(ANIMATION.RUN)
      -- if not ((previous_state == idle) or (previous_state == duck) or (previous_state == crawl)) then
      if (previous_state ~= idle) and (previous_state ~= duck) and (previous_state ~= crawl) then
         if owner.look_direction == 1 then
            play_fx(owner.fx_dust_left)
         else
            play_fx(owner.fx_dust_right)
         end
         play_sound(SND.SHANTAE_LAND)
      end

      run.footsteps_timer_handle = timer.delay(FOOTSTEPS_FRAME_TIME, true, play_footsteps_fx)

      jump_count = 0
      run_time = 0
   end -- run.on_enter

   function run.execute(dt)
      check_directional_input()
      set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)
      local velocity = owner.velocity

      run_time = run_time + dt

      if is_down(X) or buffered_whip then
         buffered_whip = false
         machine.enter_state(standing_whip)
      elseif is_down(B) or buffered_blast then
         pull_the_trigger = true
         -- buffered_blast = false
         machine.enter_state(standing_blast)
      elseif is_down(A) and (jump_count < owner.max_jumps) then
         jump_count = jump_count + 1
         velocity.y = owner.jump_speed
         machine.enter_state(jump)
      elseif velocity.y > 0 then
         machine.enter_state(jump) -- external force? enter_state(launch?)
      elseif velocity.y < 0 then
         machine.enter_state(fall)
      elseif velocity.x == 0 then
         machine.enter_state(idle)
      elseif low_profile then
         machine.enter_state(crawl)
      end

      owner:move(dt)
   end -- run.execute

   function run.on_exit()
      timer.cancel(run.footsteps_timer_handle)
   end -- run.on_exit

   ---------------------------------------
   -- jump
   ---------------------------------------

   local function cannon_shot()
      play_sound(SND.SHANTAE_CANNON_SHOT)
      local ball_position = vector3(owner.position)
      ball_position.x = ball_position.x - owner.look_direction * 3
      ball_position.z = LAYER.DEBRIS_3
      factory.create(FX.CANNON_BALL_FACTORY, ball_position, IDENTITY, nil, ONE)
   end -- cannon_shot

   local function cannon_jump_complete()
      play_animation(ANIMATION.CANNON_FALL)
   end -- cannon_jump_complete

   function jump.on_enter(previous_state)
      -- utils.log(jump.name, whip_frame, game.get_frame())
      label.set_text(owner.label, jump.name)

      if jump_count <= 1 then
         if owner.velocity.y < 120 then
            play_animation(ANIMATION.JUMP_FINISH)
         else
            play_animation(ANIMATION.JUMP)
            -- play_sound(SND.SHANTAE_JUMP) -- "Shantae and the Pirate's Curse" don't play this
         end
      else
         current_animation = nil -- allows restart the same animation
         play_animation(ANIMATION.CANNON_JUMP, cannon_jump_complete)
         cannon_shot()
      end

      jump.previous_state = previous_state
   end -- jump.on_enter

   function jump.execute(dt)
      check_directional_input()
      set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)
      local velocity = owner.velocity

      if (jump_count == 1) and (velocity.y < 120) then
         play_animation(ANIMATION.JUMP_FINISH)
      end

      if is_down(X) or buffered_whip then
         buffered_whip = false
         machine.enter_state(jump_whip)
      elseif is_down(B) or buffered_blast then
         pull_the_trigger = true
         -- buffered_blast = false
         machine.enter_state(jump_blast)
      elseif is_down(A) and (jump_count < owner.max_jumps) then
         jump_count = jump_count + 1
         velocity.y = owner.jump_speed
         current_animation = nil
         play_animation(ANIMATION.CANNON_JUMP, cannon_jump_complete)
         cannon_shot()
      elseif is_up(A) then
         if velocity.y > JUMP_CUT_VELOCITY then
            velocity.y = JUMP_CUT_VELOCITY
         end
      elseif owner.rope and (is_down(Y) or is_pressed(Y)) and (jump.previous_state ~= climb) then
         local rope_context = get_context(owner.rope)
         if rope_context then
            owner.rope_platform = rope_context.platform
            machine.enter_state(climb)
            owner:climb(0)
            return
         end
      elseif velocity.y <= 0 then
         machine.enter_state(fall)
      end

      owner:move(dt)
   end -- jump.execute

   ---------------------------------------
   -- fall
   ---------------------------------------

   local function fall_start_complete()
      play_animation(ANIMATION.FALL)
   end -- fall_start_complete

   local function hat_remove_complete()
      play_animation(ANIMATION.FALL_START, fall_start_complete)
   end -- hat_remove_complete

   function fall.on_enter(previous_state)
      -- utils.log(fall.name, whip_frame, game.get_frame())
      label.set_text(owner.label, fall.name)

      if previous_state == glide then
         play_animation(ANIMATION.HAT_REMOVE, hat_remove_complete)
      else
         if (jump_count <= 1) or (previous_state == jump_whip) or (previous_state == jump_blast) then
            play_animation(ANIMATION.FALL_START, fall_start_complete)
         end
      end
      fall.jump_grace_time = previous_state.JUMP_GRACE_TIME
      fall.previous_state = previous_state
   end -- fall.on_enter

   function fall.execute(dt)
      check_directional_input(owner)
      set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)
      local velocity = owner.velocity

      if is_down(A) then
         if (jump_count == 0) and (fall.jump_grace_time <= 0) then
            jump_count = jump_count + 1
         end
         if jump_count < owner.max_jumps then
            jump_count = jump_count + 1
            velocity.y = owner.jump_speed
         end
      end
      fall.jump_grace_time = fall.jump_grace_time - dt

      if is_down(X) or buffered_whip then
         buffered_whip = false
         machine.enter_state(jump_whip)
      elseif is_down(B) or buffered_blast then
         pull_the_trigger = true
         machine.enter_state(jump_blast)
      elseif is_down(R) or is_pressed(R) then
         machine.enter_state(down_thrust)
      elseif (not owner.ground) and (is_down(Y) or is_pressed(Y)) then
         local rope_context = get_context(owner.rope)
         if rope_context then
            owner.rope_platform = rope_context.platform
            machine.enter_state(climb)
            owner:climb(0)
            return
         elseif (current_animation ~= ANIMATION.HAT_REMOVE) then
            machine.enter_state(glide)
            if (fall.previous_state == glide) or (fall.previous_state == crawl) or (fall.previous_state == duck) then
               velocity.y = 0 -- more controllable fall (comment out for more realistic)
            else
               velocity.y = 155
            end
            owner:glide(dt)
            return
         end
      elseif velocity.y > 0 then
         machine.enter_state(jump)
      elseif velocity.y == 0 then
         if velocity.x == 0 then
            if low_profile then
               machine.enter_state(duck)
            else
               machine.enter_state(idle)
            end
         else
            if low_profile then
               machine.enter_state(crawl)
            else
               machine.enter_state(run)
            end
         end
      end

      owner:move(dt)
   end -- fall.execute

   ---------------------------------------
   -- duck
   ---------------------------------------
   local function duck_down_complete()
      play_animation(ANIMATION.DUCK_IDLE)
   end -- duck_down_complete

   function duck.on_enter (previous_state)
      -- utils.log(duck.name, whip_frame, game.get_frame())
      label.set_text(owner.label, duck.name)

      if (previous_state ~= crawl) and (previous_state ~= duck_whip) then
         owner:set_height_profile(owner.raycast_low_profile)
         play_animation(ANIMATION.DUCK_DOWN, duck_down_complete)
         play_sound(SND.SHANTAE_DUCK)
      else
         play_animation(ANIMATION.DUCK_IDLE)
      end
      if (previous_state ~= duck_whip) and (previous_state ~= idle) and (previous_state ~= crawl) then
         play_fx(owner.fx_dust_left)
         play_fx(owner.fx_dust_right)
      end
      jump_count = 0
   end -- duck.on_enter

   function duck.execute (dt)
      check_directional_input(owner)
      local velocity = owner.velocity

      if is_down(X) or buffered_whip then
         buffered_whip = false
         machine.enter_state(duck_whip)
         owner:move(dt)
         return
      end

      if owner.up_space > owner.raycast_profile_delta then
         if is_down(A) and (jump_count < owner.max_jumps) then
            jump_count = jump_count + 1
            velocity.y = owner.jump_speed
         end

         if is_down(B) or buffered_blast then
            pull_the_trigger = true
            -- buffered_blast = false
            machine.enter_state(standing_blast)
         elseif velocity.y > 0 then
            machine.enter_state(jump)
         elseif velocity.y < 0 then
            machine.enter_state(fall)
         elseif velocity.x ~= 0 then
            if low_profile then
               machine.enter_state(crawl)
            else
               machine.enter_state(run)
            end
         elseif not low_profile then
            machine.enter_state(idle)
         end

      else
         if velocity.y < 0 then
            machine.enter_state(fall)
         elseif velocity.x ~= 0 then
            machine.enter_state(crawl)
         end
      end

      owner:move(dt)
   end -- duck.execute

   function duck.on_exit (next_state)
      if (next_state ~= crawl) and (next_state ~= duck_whip) then
         owner:set_height_profile(owner.raycast_high_profile)
      end
   end -- duck.on_exit

   ---------------------------------------
   -- crawl
   ---------------------------------------

   local function play_crawl_sound_fx()
      play_sound(SND.SHANTAE_CRAWL)
   end -- play_crawl_sound_fx

   function crawl.on_enter(previous_state)
      -- utils.log(crawl.name, whip_frame, game.get_frame())
      label.set_text(owner.label, crawl.name)

      play_animation(ANIMATION.CRAWL)
      play_crawl_sound_fx()
      crawl.squeaky_timer = timer.delay(0.33, true, play_crawl_sound_fx)

      if previous_state ~= duck then
         owner:set_height_profile(owner.raycast_low_profile)
      end
      if (previous_state ~= duck) and (previous_state ~= duck_whip) and (previous_state ~= idle) and (previous_state ~= run) then
         if owner.look_direction == 1 then
            play_fx(owner.fx_dust_left)
         else
            play_fx(owner.fx_dust_right)
         end
      end
      jump_count = 0
   end -- crawl.on_enter

   function crawl.execute(dt)
      check_directional_input(owner)
      set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)
      local velocity = owner.velocity

      if owner.up_space > owner.raycast_profile_delta then
         if is_down(A) and (jump_count < owner.max_jumps) then
            jump_count = jump_count + 1
            velocity.y = owner.jump_speed
         end

         if is_down(X) or buffered_whip then
            buffered_whip = false
            machine.enter_state(duck_whip)
         elseif is_down(B) or buffered_blast then
            pull_the_trigger = true
            -- buffered_blast = false
            machine.enter_state(standing_blast)
         elseif velocity.y > 0 then
            machine.enter_state(jump)
         elseif velocity.y < 0 then
            machine.enter_state(fall)
         elseif velocity.x == 0 then
            if low_profile then
               machine.enter_state(duck)
            else
               machine.enter_state(idle)
            end
         elseif owner.move_direction ~= 0 and (not low_profile) then
            machine.enter_state(run)
         end
      else
         if is_down(X) or buffered_whip then
            buffered_whip = false
            machine.enter_state(duck_whip)
         elseif velocity.y < 0 then
            machine.enter_state(fall)
         elseif velocity.x == 0 then
            machine.enter_state(duck)
         end
      end

      owner:move(dt)
   end -- crawl.execute

   function crawl.on_exit(next_state)
      timer.cancel(crawl.squeaky_timer)
      if (next_state ~= duck) and (next_state ~= duck_whip) then
         owner:set_height_profile(owner.raycast_high_profile)
      end
   end -- crawl.on_exit

   ---------------------------------------
   -- climb
   ---------------------------------------

   function climb.on_enter()
      -- utils.log(climb.name, whip_frame, game.get_frame())
      label.set_text(owner.label, climb.name)

      owner.delta_position.x = 0
      owner.delta_position.y = 0
      owner.velocity.x = 0
      owner.velocity.y = 0
      local rope_position = get_world_position(owner.rope)
      local rope_delta_position = get_delta_position(owner.rope_platform)
      owner.position.x = rope_position.x + rope_delta_position.x
      if (owner.position.y + owner.raycast_high_profile) > (rope_position.y + rope_delta_position.y) then
         owner.position.y = rope_position.y + rope_delta_position.y - owner.raycast_high_profile
      end
      set_position(owner.position, owner.gameobject)
      select_reset(ROPE_UP)
      play_animation(select_next(ROPE_UP))
      play_sound(SND.SHANTAE_GRAB_ROPE)
      jump_count = 0
   end -- climb.on_enter

   function climb.execute(dt)
      check_directional_input()
      local old_velocity_y = owner.velocity.y
      local new_velocity_y = old_velocity_y

      if is_down(A) then
         jump_count = jump_count + 1
         owner.velocity.y = owner.jump_speed
         machine.enter_state(jump)
         owner:move(dt)
         return
      end

      if is_down(UP) then
         new_velocity_y = owner.climb_speed
      elseif is_down(DOWN) or is_down(DOWN_LEFT) or is_down(DOWN_RIGHT) then
         new_velocity_y = owner.climb_speed * -2
      elseif is_pressed(UP) and (not is_pressed(DOWN)) then
         new_velocity_y = owner.climb_speed
      elseif (is_pressed(DOWN) or is_pressed(DOWN_LEFT) or is_pressed(DOWN_RIGHT))  and (not is_pressed(UP)) then
         new_velocity_y = owner.climb_speed * -2
      elseif not (is_pressed(UP) and is_pressed(DOWN) and is_pressed(DOWN_LEFT) and is_pressed(DOWN_RIGHT)) then
         new_velocity_y = 0
      end

      if new_velocity_y > 0 then
         climb.dt = climb.dt + dt
         if climb.dt > ROPE_UP_FRAME_TIME then
            play_sound(SND.SHANTAE_CLIMB_ROPE)
            play_animation(select_next(ROPE_UP))
            climb.dt = 0
         end
      elseif new_velocity_y < 0 then
         play_sound(SND.SHANTAE_DESCEND_ROPE)
         play_animation(ANIMATION.ROPE_DOWN)
         select_reset(ROPE_UP)
         climb.dt = ROPE_UP_FRAME_TIME
      else
         if current_animation == ANIMATION.ROPE_DOWN then
            play_animation(ANIMATION.ROPE_IDLE)
            select_reset(ROPE_UP)
         end
         climb.dt = ROPE_UP_FRAME_TIME
      end

      owner.velocity.x = 0
      owner.velocity.y = new_velocity_y
      local dy = (old_velocity_y + new_velocity_y) * 0.5 * dt

      local rope_context = get_context(owner.rope)
      if rope_context then
         local rope_position = get_world_position(owner.rope)
         if (owner.position.y + owner.raycast_high_profile + dy) >= rope_position.y then
            dy = 0
         end
      else
         machine.enter_state(fall)
         owner:move(dt)
         return
      end

      owner:climb(dy)
   end -- climb.execute

   function climb.on_exit()
      owner.rope_platform = nil
   end -- climb.on_exit

   ---------------------------------------
   -- glide
   ---------------------------------------

   local function hat_init_complete()
      play_animation(ANIMATION.HAT_GLIDE)
   end -- hat_init_complete

   function glide.on_enter()
      -- utils.log(glide.name, whip_frame, game.get_frame())
      label.set_text(owner.label, glide.name)

      play_animation(ANIMATION.HAT_INIT, hat_init_complete)
      play_sound(SND.SHANTAE_HAT_OPEN)
   end -- glide.on_enter

   function glide.execute(dt)
      check_directional_input()
      set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)
      local velocity = owner.velocity

      if is_down(X) or buffered_whip then
         buffered_whip = false
         machine.enter_state(jump_whip)
         owner:move(dt)
         return
      elseif is_down(B) or buffered_blast then
         pull_the_trigger = true
         -- buffered_blast = false
         machine.enter_state(jump_blast)
         owner:move(dt)
         return
      elseif (not is_pressed(Y)) then -- elseif (velocity.y < 0) and (not is_pressed(Y)) then
         -- velocity.y = 0
         machine.enter_state(fall)
         owner:move(dt)
         return
      elseif owner.ground then
         if velocity.x == 0 then
            if low_profile then
               machine.enter_state(duck)
            else
               machine.enter_state(idle)
            end
         else
            if low_profile then
               machine.enter_state(crawl)
            else
               machine.enter_state(run)
            end
         end
         owner:move(dt)
         return
      end
      owner:glide(dt)
   end -- glide.execute

   function glide.on_exit()
      owner.velocity.y = 0
   end

   ---------------------------------------
   -- standing_whip
   ---------------------------------------

   function standing_whip.on_enter(previous_state)
      -- utils.log(standing_whip.name, whip_frame, game.get_frame())
      label.set_text(owner.label, standing_whip.name)

      if previous_state == jump_whip then
         play_fx(owner.fx_dust_left)
         play_fx(owner.fx_dust_right)
      end
      play_animation(STANDING_WHIP[whip_frame])
      jump_count = 0
      attack_look_direction = owner.look_direction
   end -- standing_whip.on_enter

   function standing_whip.execute(dt)
      check_directional_input()
      local velocity = owner.velocity
      local whip_context = get_context(owner.whip)

      if is_down(A) and (jump_count < owner.max_jumps) then
         jump_count = jump_count + 1
         velocity.y = owner.jump_speed
         machine.enter_state(jump_whip)
         owner:move(dt)
         return
      elseif velocity.y ~= 0 then
         machine.enter_state(jump_whip)
         owner:move(dt)
         return
      elseif low_profile then
         machine.enter_state(duck_whip)
         owner:move(dt)
         return
      end

      whip_frame_time = whip_frame_time + dt
      if whip_frame_time >  WHIP_FRAME_TIME then
         if whip_frame == 1 then
            for k in pairs(whip_context.hits) do
               whip_context.hits[k] = nil
            end
            attack_look_direction = owner.look_direction
            set(owner.pivot, EULER_Y, attack_look_direction == 1 and 0 or 180)
            play_sound(SND.SHANTAE_WHIP_1)
         end
         whip_frame_time = 0
         whip_frame = whip_frame + 1
         if whip_frame > WHIP_FRAME_COUNT then
            whip_frame = 1
            if not buffered_whip then
               if buffered_blast then
                  buffered_blast = false
                  machine.enter_state(standing_blast)
               else
                  machine.enter_state(idle)
               end
               owner:move(dt)
               return
            end
            buffered_whip = false
         end
         play_animation(STANDING_WHIP[whip_frame])
      end

      if is_down(X) then
         buffered_whip = true
      elseif is_down(B) then
         buffered_blast = true
         pull_the_trigger = true
      end

      owner.move_direction = 0
      velocity.x = 0
      owner:move(dt)
      if (whip_frame > 3) and (whip_frame < 8) then
         utils.execute_in_context(whip_context, whip_context.whip, owner.position, 18, attack_look_direction) -- 18 height shift
      end
   end -- standing_whip.execute

   ---------------------------------------
   -- duck_whip
   ---------------------------------------

   function duck_whip.on_enter (previous_state)
      -- utils.log(duck_whip.name, whip_frame, game.get_frame())
      label.set_text(owner.label, duck_whip.name)

      if (previous_state ~= duck) and (previous_state ~= crawl) then
         owner:set_height_profile(owner.raycast_low_profile)
      end
      if previous_state == jump_whip then
         play_fx(owner.fx_dust_left)
         play_fx(owner.fx_dust_right)
      end
      play_animation(DUCK_WHIP[whip_frame])
      jump_count = 0
      attack_look_direction = owner.look_direction
   end -- duck_whip.on_enter

   function duck_whip.execute (dt)
      check_directional_input(owner)
      local velocity = owner.velocity
      local whip_context = get_context(owner.whip)

      if owner.up_space > owner.raycast_profile_delta then
         if is_down(A) and (jump_count < owner.max_jumps) then
            jump_count = jump_count + 1
            velocity.y = owner.jump_speed
            whip_frame = 1
            whip_frame_time = 0
            machine.enter_state(jump)
            owner:move(dt)
            return
         end

         if velocity.y < 0 then
            machine.enter_state(jump_whip)
         elseif not low_profile then
            machine.enter_state(standing_whip)
         end

      else
         if velocity.y < 0 then
            machine.enter_state(jump_whip)
         end
      end

      whip_frame_time = whip_frame_time + dt
      if whip_frame_time >  WHIP_FRAME_TIME then
         if whip_frame == 1 then
            for k in pairs(whip_context.hits) do
               whip_context.hits[k] = nil
            end
            attack_look_direction = owner.look_direction
            set(owner.pivot, EULER_Y, attack_look_direction == 1 and 0 or 180)
            play_sound(SND.SHANTAE_WHIP_1)
         end
         whip_frame_time = 0
         whip_frame = whip_frame + 1
         if whip_frame > WHIP_FRAME_COUNT then
            whip_frame = 1
            if not buffered_whip then
               if buffered_blast then
                  buffered_blast = false
                  machine.enter_state(standing_blast)
               else
                  machine.enter_state(duck)
               end
               owner:move(dt)
               return
            end
            buffered_whip = false
         end
         play_animation(DUCK_WHIP[whip_frame])
      end

      if is_down(X) then
         buffered_whip = true
      elseif is_down(B) then
         buffered_blast = true
         pull_the_trigger = true
      end

      owner.move_direction = 0
      velocity.x = 0
      owner:move(dt)
      if (whip_frame > 3) and (whip_frame < 8) then
         utils.execute_in_context(whip_context, whip_context.whip, owner.position, 9, attack_look_direction)
      end
   end -- duck_whip.execute

   function duck_whip.on_exit(next_state)
      -- utils.log(duck_whip.name, next_state.name, game.get_frame())

      if (next_state ~= duck) and (next_state ~= crawl) then
         owner:set_height_profile(owner.raycast_high_profile)
      end
   end -- duck_whip.on_exit

   ---------------------------------------
   -- jump_whip
   ---------------------------------------

   function jump_whip.on_enter ()
      -- utils.log(jump_whip.name, whip_frame, game.get_frame())
      label.set_text(owner.label, jump_whip.name)

      play_animation(JUMP_WHIP[whip_frame])
      attack_look_direction = owner.look_direction
   end -- jump_whip.on_enter

   function jump_whip.execute(dt)
      check_directional_input(owner)
      local velocity = owner.velocity
      local whip_context = get_context(owner.whip)

      if is_down(A) then
         if fall.jump_grace_time < 0 then
            jump_count = jump_count + 1
         end
         if jump_count < owner.max_jumps then
            jump_count = jump_count + 1
            velocity.y = owner.jump_speed
            whip_frame = 1
            whip_frame_time = 0
            machine.enter_state(jump)
            owner:move(dt)
            return
         end
      elseif is_up(A) then
         if velocity.y > JUMP_CUT_VELOCITY then
            velocity.y = JUMP_CUT_VELOCITY
         end
      end
      fall.jump_grace_time = fall.jump_grace_time - dt

      if owner.ground and velocity.y == 0 then
         if low_profile then
            machine.enter_state(duck_whip)
            owner:move(dt)
            return
         else
            machine.enter_state(standing_whip)
            owner:move(dt)
            return
         end
      end

      whip_frame_time = whip_frame_time + dt
      if whip_frame_time >  WHIP_FRAME_TIME then
         if whip_frame == 1 then
            for k in pairs(whip_context.hits) do
               whip_context.hits[k] = nil
            end
            attack_look_direction = owner.look_direction
            set(owner.pivot, EULER_Y, attack_look_direction == 1 and 0 or 180)
            play_sound(SND.SHANTAE_WHIP_1)
         end
         whip_frame_time = 0
         whip_frame = whip_frame + 1
         if whip_frame > WHIP_FRAME_COUNT then
            whip_frame = 1
            if not buffered_whip then
               if buffered_blast then
                  buffered_blast = false
                  machine.enter_state(jump_blast)
               elseif is_down(Y) or is_pressed(Y) then
                  local rope_context = get_context(owner.rope)
                  if rope_context then
                     owner.rope_platform = rope_context.platform
                     whip_frame = 1
                     whip_frame_time = 0
                     machine.enter_state(climb)
                     owner:climb(0)
                     return
                  else
                     whip_frame = 1
                     whip_frame_time = 0
                     machine.enter_state(glide)
                     if fall.previous_state ~= glide and fall.previous_state ~= crawl and fall.previous_state ~= duck then
                        velocity.y = 155
                     end
                     owner:glide(dt)
                     return
                  end
               elseif velocity.y > 0 then
                  machine.enter_state(jump)
               elseif velocity.y < 0 then
                  machine.enter_state(fall)
               elseif owner.ground then
                  if velocity.x == 0 then
                     if low_profile then
                        machine.enter_state(duck)
                     else
                        machine.enter_state(idle)
                     end
                  else
                     if low_profile then
                        machine.enter_state(crawl)
                     else
                        machine.enter_state(run)
                     end
                  end
               end
               owner:move(dt)
               return
            end
            buffered_whip = false
         else
            play_animation(JUMP_WHIP[whip_frame])
         end
      end

      if is_down(X) then
         buffered_whip = true
      elseif is_down(B) then
         buffered_blast = true
         pull_the_trigger = true
      end

      owner:move(dt)

      if (whip_frame > 3) and (whip_frame < 8) then
         utils.execute_in_context(whip_context, whip_context.whip, owner.position, 23, attack_look_direction)
      end
   end -- jump_whip.execute

   ---------------------------------------
   -- standing_blast
   ---------------------------------------

   local function pistol_blast(shift_y)
      buffered_blast = false
      play_sound(SND.SHANTAE_SHOOT_PISTOL)
      local bullet_position = vector3(owner.position)
      bullet_position.x = bullet_position.x + owner.delta_position.x + owner.look_direction * 10
      bullet_position.y = bullet_position.y + owner.delta_position.y + shift_y
      bullet_position.z = LAYER.FX_A--LAYER.DEBRIS_1
      bullet_properties.direction = owner.look_direction
      factory.create(FX.PISTOL_BULLET_1_FACTORY, bullet_position, IDENTITY, bullet_properties, ONE)
   end -- pistol_blast

   function standing_blast.on_enter(previous_state)
      -- utils.log(standing_blast.name, blast_frame, game.get_frame())
      label.set_text(owner.label, standing_blast.name)

      if previous_state == jump_blast then
         play_fx(owner.fx_dust_left)
         play_fx(owner.fx_dust_right)
      end
      play_animation(STANDING_BLAST[blast_frame])
      if pull_the_trigger then
         pull_the_trigger = false
         set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)
         pistol_blast(22)
      end
      jump_count = 0
   end -- standing_blast.on_enter

   function standing_blast.execute(dt)
      check_directional_input()
      local velocity = owner.velocity

      if is_down(A) and (jump_count < owner.max_jumps) then
         jump_count = jump_count + 1
         velocity.y = owner.jump_speed
         machine.enter_state(jump_blast)
         owner:move(dt)
         return
      elseif velocity.y ~= 0 then
         machine.enter_state(jump_blast)
         owner:move(dt)
         return
      end

      blast_frame_time = blast_frame_time + dt
      if blast_frame_time >  BLAST_FRAME_TIME then
         blast_frame_time = 0
         blast_frame = blast_frame + 1
         if blast_frame > BLAST_FRAME_COUNT then
            blast_frame = 1
            if not buffered_blast then
               if buffered_whip then
                  buffered_whip = false
                  machine.enter_state(standing_whip)
               else
                  machine.enter_state(idle)
               end
               owner:move(dt)
               return
            end
            set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)
            pistol_blast(22)
         end
         play_animation(STANDING_BLAST[blast_frame])
      end

      if is_down(B) then
         buffered_blast = true
      elseif is_down(X) then
         buffered_whip = true
      end

      owner.move_direction = 0
      velocity.x = 0
      owner:move(dt)
   end -- standing_blast.execute

   ---------------------------------------
   -- jump_blast
   ---------------------------------------

   function jump_blast.on_enter()
      -- utils.log(jump_blast.name, blast_frame, game.get_frame())
      label.set_text(owner.label, jump_blast.name)

      play_animation(JUMP_BLAST[blast_frame])
      if pull_the_trigger then
         pull_the_trigger = false
         set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)
         pistol_blast(28)
      end
   end -- jump_blast.on_enter

   function jump_blast.execute(dt)
      check_directional_input(owner)
      local velocity = owner.velocity

      if is_down(A) then
         if fall.jump_grace_time < 0 then
            jump_count = jump_count + 1
         end
         if jump_count < owner.max_jumps then
            jump_count = jump_count + 1
            velocity.y = owner.jump_speed
            blast_frame = 1
            blast_frame_time = 0
            machine.enter_state(jump)
            owner:move(dt)
            return
         end
      elseif is_up(A) then
         if velocity.y > JUMP_CUT_VELOCITY then
            velocity.y = JUMP_CUT_VELOCITY
         end
      end
      fall.jump_grace_time = fall.jump_grace_time - dt

      if owner.ground and velocity.y == 0 then
         machine.enter_state(standing_blast)
         owner:move(dt)
         return
      end

      blast_frame_time = blast_frame_time + dt
      if blast_frame_time >  BLAST_FRAME_TIME then
         blast_frame_time = 0
         blast_frame = blast_frame + 1
         if blast_frame > BLAST_FRAME_COUNT then
            blast_frame = 1
            if not buffered_blast then
               if buffered_whip then
                  buffered_whip = false
                  machine.enter_state(jump_whip)
               elseif is_down(Y) or is_pressed(Y) then
                  local rope_context = get_context(owner.rope)
                  if rope_context then
                     owner.rope_platform = rope_context.platform
                     blast_frame = 1
                     blast_frame_time = 0
                     machine.enter_state(climb)
                     owner:climb(0)
                     return
                  else
                     blast_frame = 1
                     blast_frame_time = 0
                     machine.enter_state(glide)
                     if fall.previous_state ~= glide and fall.previous_state ~= crawl and fall.previous_state ~= duck then
                        velocity.y = 155
                     end
                     owner:glide(dt)
                     return
                  end
               elseif velocity.y > 0 then
                  machine.enter_state(jump)
               elseif velocity.y < 0 then
                  machine.enter_state(fall)
               elseif owner.ground then
                  if velocity.x == 0 then
                     if low_profile then
                        machine.enter_state(duck)
                     else
                        machine.enter_state(idle)
                     end
                  else
                     if low_profile then
                        machine.enter_state(crawl)
                     else
                        machine.enter_state(run)
                     end
                  end
               end
               owner:move(dt)
               return
            end
            set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)
            pistol_blast(28)
         end
         play_animation(JUMP_BLAST[blast_frame])
      end

      if is_down(B) then
         buffered_blast = true
      elseif is_down(X) then
         buffered_whip = true
      end

      owner:move(dt)
   end -- jump_blast.execute

   ---------------------------------------
   -- down_thrust
   ---------------------------------------

   function down_thrust.on_enter()
      label.set_text(owner.label, down_thrust.name)

      play_animation(ANIMATION.DOWN_THRUST)
      play_sound(SND.SHANTAE_DOWN_THRUST_START)
      owner.speed = owner.max_horizontal_speed * 0.8
   end -- down_thrust.on_enter

   function down_thrust.execute(dt)
      check_directional_input(owner)
      set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)
      local velocity = owner.velocity

      if owner.ground and (velocity.y == 0) then
         machine.enter_state(idle)
         owner:move(dt)
         return
      end


      if velocity.y <= 0 then
         local whip_context = get_context(owner.whip)
         owner.gravity = owner.normal_gravity * 2.4
         owner:move(dt)
         utils.execute_in_context(whip_context, whip_context.down_thrust, owner.position)
      else
         owner.gravity = owner.normal_gravity
         owner:move(dt)
      end
   end -- down_thrust.execute

   function down_thrust.on_exit()
      owner.speed = owner.max_horizontal_speed
      owner.gravity = owner.normal_gravity
      get_context(owner.camera).shake_y = 12
   end -- down_thrust.on_exit

   ---------------------------------------
   -- cutscene
   ---------------------------------------

   function cutscene.on_enter()
      label.set_text(owner.label, cutscene.name)
      local context = get_context(owner.interactor)
      if context and context.start_interaction then
         utils.execute_in_context(context, context.start_interaction)
      else
         owner.interactor = nil
         owner.end_cutscene = true
      end
   end -- cutscene.on_enter

   function cutscene.execute(dt)
      set(owner.pivot, EULER_Y, owner.look_direction == 1 and 0 or 180)

      if owner.end_cutscene or (not owner.interactor) then
         owner.end_cutscene = false
         game.set_pause_allowed(true)
         machine.enter_state(idle)
      end
      owner:move(dt)

      if owner.velocity.x ~= 0 then
         play_animation(ANIMATION.RUN)
      else
         play_animation(ANIMATION.STANDING_IDLE_FULL)
      end
   end -- cutscene.execute

   machine = StateMachine.new(idle)
   return machine
end -- make_machine

-- export
return {
   make_machine = make_machine,
}
