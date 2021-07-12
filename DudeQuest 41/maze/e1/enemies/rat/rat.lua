local Pool = require("m.pool")
local RaycastController = require("m.raycast_controller")
local StateMachine = require("m.state_machine")
local CONST = require("m.constants")
local nc = require("m.notification_center")
local snd = require("sound.sound")
local groups = require("m.groups")
local layers = require("m.layers")
local game = require("maze.game")
local colors = require("m.colors")
local TARGET_TYPE = require("maze.target_type")
local utils = require("m.utils")
-- local debug_draw = require("m.debug_draw")

local global = require("game.global")


local fastmath = fastmath
local abs = fastmath.abs
local sign = fastmath.sign
local vector3_set_xy = fastmath.vector3_set_xy
local vector3_set_y = fastmath.vector3_set_y
local vector3_set_xyz = fastmath.vector3_set_xyz
local vector3_get_x = fastmath.vector3_get_x
local set_position = go.set_position
local set = go.set
local get = go.get
local play_flipbook = sprite.play_flipbook
local physics_set_hflip = physics.set_hflip
-- local ceil = math.ceil

local DEPTH = layers.get_depth(layers.ENEMIES)

local coin_toss = fastmath.bernoulli(0.5)
local speed_roll = fastmath.uniform_real(80, 130)
local x_roll = fastmath.uniform_real(-16, 16)
local y_roll = fastmath.uniform_real(0, 8)
local loot_velocity_x_roll = fastmath.uniform_int(-50, 50)
local loot_velocity_y_roll = fastmath.uniform_int(160, 190)
-- local random_delay = fastmath.uniform_real(0, 0.66)

local ROOT = hash("/root")
local params = {
   [ROOT] = {
      velocity_x = 0,
      velocity_y = -1,
   },
}

local IDENTITY = fastmath.IDENTITY
local INFINITY = 1 / 0
local CURSOR = CONST.CURSOR
local EULER_Y = CONST.EULER_Y
local CHARACTER_WIDTH = 30
local CHARACTER_HEIGHT = 14
local MAX_HORIZONTAL_SPEED
local MAX_VERTICAL_SPEED = 800
local GROUND_ACCELERATION = 2000
local JUMP_HEIGHT = 36
local JUMP_TIME_TO_APEX = 0.38
local NORMAL_GRAVITY = -(2 * JUMP_HEIGHT) / (JUMP_TIME_TO_APEX * JUMP_TIME_TO_APEX)
-- local JUMP_SPEED = abs(NORMAL_GRAVITY) * JUMP_TIME_TO_APEX
local ATTACK_COOLDOWN_TIME = 0.6
-- local CHECK_TARGET_COOLDOWN_TIME = 0.25
local TARGET_GROUPS = {
   groups.PLAYER_HITBOX,
   groups.SOLID,
}
local ray_start = vmath.vector3()
local ray_end = vmath.vector3()

local PLAYER_HIT_FACTORY = msg.url("game:/entities#effect_player_hit")
local SMALL_FLAME_FACTORY = msg.url("game:/entities#effect_small_flame")
local EFFECT_CIRCLE1_FACTORY = msg.url("game:/entities#effect_circle1")
local POTCHINA_LOOT_FACTORIES = {
   msg.url("game:/entities#coin"),
}
local DIE_SOUNDS = {
   snd.FATE_RAT_DIE1,
   snd.FATE_RAT_DIE2,
}

local function make()
   local instance = {
      name = "rat",
      x = 0,
      y = 0,
      dx = 0,
      dy = 0,
      horizontal_look = 1,
      needs_down_pass = false,
      needs_up_pass = false,
      needs_left_pass = false,
      needs_right_pass = false,
      update_group = runtime.UPDATE_GROUP_BEFORE_PLAYER,
      can_push = false,
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
         groups.INVISIBLE_WALL,
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

   local health
   local aabb = { 0, 0, 0, 0 }
   local root
   local velocity_x
   local velocity_y
   local acceleration
   local gravity
   local max_horizontal_speed
   local move_direction
   local ground
   local previous_horizontal_look
   local vector3_stub
   -- local collisionobject_raycast
   local collisionobject_hitbox
   -- local collisionobject_sensor
   local collisionobject_hurtbox
   local contact_left
   local contact_right
   local attack_targets = {}
   local next_attack_time
   local target_position_x
   local invulnerability_timer_handler
   local hit_direction
   local target_type
   -- local hit_material
   -- local normal_material
   local debug_label

   local idle = {}
   local run = {}
   local jump = {}
   local attack = {}
   local hit = {}
   local death = {}

   local raycast_controller = RaycastController.new(instance)
   local machine = StateMachine.new(instance)

   local RAT = {
      pivot = nil,
      object = nil,
      sprite = nil,
      current_animation_group = nil,
      current_animation = nil,
      on_complete = nil,

      IDLE = {
         { id = hash("rat_idle"), position = vmath.vector3(-3, 7, 0), },
      },
      RUN = {
         { id = hash("rat_run"), position = vmath.vector3(-3, 10, 0), },
      },
      ATTACK = {
         { id = hash("rat_attack"), position = vmath.vector3(0, 9, 0), },
      },
      HIT = {
         { id = hash("rat_hit"), position = vmath.vector3(-6, 10, 0), },
      },
      DEATH = {
         { id = hash("rat_death"), position = vmath.vector3(-5, 10, 0), },
      },
   }

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

   local function destroy()
      runtime.remove_update_callback(instance)
      if invulnerability_timer_handler then
         timer.cancel(invulnerability_timer_handler)
      end
      go.delete(root, true)
   end -- destroy

   local function check_target()
      vector3_set_xy(ray_start, instance.x, instance.y + 14)
      vector3_set_xy(ray_end, instance.x + 100 * instance.horizontal_look, instance.y + 14)
      local ray_hit = physics.raycast(ray_start, ray_end, TARGET_GROUPS)
      -- debug_draw.line(ray_start.x, ray_start.y, ray_end.x, ray_end.y)
      if ray_hit and (ray_hit.group ~= groups.SOLID) then
         return vector3_get_x(ray_hit.position)
      end
      return nil
   end -- check_target

   ---------------------------------------
   -- idle
   ---------------------------------------

   function idle.on_enter()
      label.set_text(debug_label, "Idle")
      play_animation(RAT, RAT.IDLE)
      turnaround(RAT)
   end -- idle.on_enter

   function idle.update(dt)
      local _, dy = move(dt)
      advance(0, dy)

      if runtime.current_time > next_attack_time then
         target_position_x = check_target()
         if target_position_x and (abs(instance.x - target_position_x) < 18) then
            machine.enter_state(attack)
         else
            machine.enter_state(run)
         end
      end
   end -- idle.update

   ---------------------------------------
   -- run
   ---------------------------------------

   function run.on_enter()
      label.set_text(debug_label, "Run")
      play_animation(RAT, RAT.RUN)
   end -- run.on_enter

   function run.update(dt)
      turnaround(RAT)

      local dx, dy = move(dt)

      target_position_x = check_target()

      if target_position_x then -- has target
         if runtime.current_time > next_attack_time then -- attack allowed
            if abs(instance.x - target_position_x) < 18 then -- target in range
               machine.enter_state(attack)
               advance(0, dy)
               return
            end
         else -- has target, but should wait
            machine.enter_state(idle)
            advance(0, dy)
            return
         end
      end

      -- no taget, continue mindless run
      advance(dx, dy)

      if contact_left then
         move_direction = 1
         instance.horizontal_look = 1
      elseif contact_right then
         move_direction = -1
         instance.horizontal_look = -1
      end
   end -- run.update

   ---------------------------------------
   -- jump
   ---------------------------------------

   function jump.on_enter()
      label.set_text(debug_label, "Jump")
      -- play_animation(RAT, RAT.RUN)
   end -- jump.on_enter

   ---------------------------------------
   -- attack
   ---------------------------------------

   local function attack_complete()
      machine.enter_state(idle)
   end -- attack_complete

   function attack.on_enter()
      label.set_text(debug_label, "Attack")
      play_animation(RAT, RAT.ATTACK, nil, attack_complete)
      velocity_x = 0
      attack.stop_frame = INFINITY
      attack.completed = false
      next_attack_time = runtime.current_time + ATTACK_COOLDOWN_TIME
      for k, _ in next, attack_targets do
         attack_targets[k] = nil
      end
      -- attack.bite_frame = 4
      -- physics_set_hflip(collisionobject_hurtbox, instance.horizontal_look ~= 1)
      -- msg.post(collisionobject_hurtbox, msg.ENABLE)
   end -- attack.on_enter

   function attack.update(dt)
      local _, dy = move(dt)
      advance(0, dy)
      if runtime.current_frame > attack.stop_frame then
         msg.post(collisionobject_hurtbox, msg.DISABLE)
         attack.stop_frame = INFINITY
      end
      if (not attack.completed) and (RAT.current_animation_group == RAT.ATTACK) then
         local cursor = get(RAT.sprite, CURSOR)
         -- local frame = math.ceil(cursor * 7)
         -- if frame == 4 then
         if cursor > (2 / 7) then -- (bite frame - 1) / frame count
            -- play bite sound
            physics_set_hflip(collisionobject_hurtbox, instance.horizontal_look ~= 1)
            msg.post(collisionobject_hurtbox, msg.ENABLE)
            snd.play_sound(snd.RAT_BITE_HIT)
            attack.stop_frame = runtime.current_frame
            attack.completed = true
         end
      end
   end -- attack.update

   local next_death_flame_time

   ---------------------------------------
   -- hit
   ---------------------------------------

   local function on_hit_end()
      -- animation_done message sink
   end -- on_hit_end

   function hit.on_enter()
      label.set_text(debug_label, "Hit")
      play_animation(RAT, RAT.HIT, nil, on_hit_end)
   end -- hit.on_enter

   function hit.update(dt)
      advance(move(dt, hit_direction, 10000, 50))
      if (runtime.current_time > next_death_flame_time) then
         -- local shift_x = x_roll()
         -- local shift_y = y_roll()
         -- vector3_set_xy(vector3_stub, instance.x - (4 * instance.horizontal_look) + shift_x, instance.y + shift_y)
         vector3_set_xy(vector3_stub, instance.x - (4 * instance.horizontal_look), instance.y + 4)
         factory.create(SMALL_FLAME_FACTORY, vector3_stub, IDENTITY, nil, 0.8)
         next_death_flame_time = runtime.current_time + 0.15
      end
      if ground and (runtime.current_time > hit.stagger_end) then
         -- go.cancel_animations(RAT.sprite, CONST.TINT)
         -- set(RAT.sprite, CONST.TINT, colors.WHITE)
         if health <= 0 then
            machine.enter_state(death)
         else
            if hit_direction == instance.horizontal_look then
               instance.horizontal_look = -instance.horizontal_look
               move_direction = -move_direction
            end
            machine.enter_state(run)
         end
      end
   end -- hit.update

   ---------------------------------------
   -- death
   ---------------------------------------

   local function on_death_end()
      -- animation_done message sink
      -- next_death_flame_time = runtime.current_time
      go.animate(RAT.sprite, CONST.TINT_W, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_INQUAD, 1, 0, destroy)
      vector3_set_xy(vector3_stub, instance.x - 4 * instance.horizontal_look, instance.y + 6)
      factory.create(EFFECT_CIRCLE1_FACTORY, vector3_stub, IDENTITY)
      params[ROOT].velocity_x = loot_velocity_x_roll()
      params[ROOT].velocity_y = loot_velocity_y_roll()
      collectionfactory.create(POTCHINA_LOOT_FACTORIES[1], vector3_stub, IDENTITY, params, 1)
   end -- on_death_end

   function death.on_enter()
      label.set_text(debug_label, "Death")
      play_animation(RAT, RAT.DEATH, nil, on_death_end)
      snd.play_sound(fastmath.pick_any(DIE_SOUNDS))
      msg.post(collisionobject_hitbox, msg.DISABLE)
   end -- death.on_enter

   function death.update()
      if (runtime.current_time > next_death_flame_time) then
         local shift_x = x_roll()
         local shift_y = y_roll()
         vector3_set_xy(vector3_stub, instance.x - (4 * instance.horizontal_look) + shift_x, instance.y + shift_y)
         factory.create(SMALL_FLAME_FACTORY, vector3_stub, IDENTITY, nil, 0.8)
         next_death_flame_time = runtime.current_time + 0.15
      end
      advance(0, 0)
   end -- death.update

   local function update_aabb()
      aabb[1] = instance.x - 32
      aabb[2] = instance.y - 16
      aabb[3] = instance.x + 32
      aabb[4] = instance.y + 32
   end -- update_aabb

   local function update(dt)
      -- debug_draw.aabb(aabb)
      -- if platform still moving, we move too
      if not fastmath.aabb_overlap(global.view_aabb, aabb) then
         local inst = runtime.get_instance(ground)
         if inst and inst.aabb then
            if not fastmath.aabb_overlap(global.view_aabb, inst.aabb) then
               return
            end
         else
            return
         end
      end
      contact_left = false
      contact_right = false
      machine.update(dt)
      update_aabb()
   end -- update

   function instance.on_contact(_, direction, vx)
      if direction == 1 then
         contact_right = true
      else
         contact_left = true
      end
      return vx
   end -- instance.on_contact

   local function invulnerability_timer_callback()
      msg.post(collisionobject_hitbox, msg.ENABLE)
   end -- invulnerability_timer_callback

   function instance.init(self)
      debug_label = msg.url("#debug_label")
      msg.post(debug_label, msg.DISABLE)
      health = 3
      target_type = TARGET_TYPE.FLESH
      velocity_x = 0
      velocity_y = self.velocity_y
      root = msg.url("root")
      RAT.pivot = msg.url("pivot")
      RAT.object = msg.url("rat")
      RAT.sprite = msg.url("rat#sprite")
      RAT.current_animation_group = nil
      RAT.current_animation = nil
      RAT.on_complete = nil
      -- collisionobject_raycast = msg.url("#collisionobject_raycast")
      collisionobject_hitbox = msg.url("#collisionobject_hitbox")
      msg.post(collisionobject_hitbox, msg.DISABLE)
      invulnerability_timer_handler = timer.delay(0.25, false, invulnerability_timer_callback)
      -- collisionobject_sensor = msg.url("#collisionobject_sensor")
      collisionobject_hurtbox = msg.url("#collisionobject_hurtbox")
      msg.post(collisionobject_hurtbox, msg.DISABLE)
      acceleration = GROUND_ACCELERATION
      MAX_HORIZONTAL_SPEED = speed_roll()
      max_horizontal_speed = MAX_HORIZONTAL_SPEED
      gravity = NORMAL_GRAVITY
      ground = nil
      contact_left = false
      contact_right = false
      instance.horizontal_look = self.look_direction
      if instance.horizontal_look == 0 then
         instance.horizontal_look = coin_toss() and 1 or -1
      end
      move_direction = instance.horizontal_look
      previous_horizontal_look = 0
      next_attack_time = 0
      next_death_flame_time = INFINITY
      target_position_x = nil
      vector3_stub = go.get_position()
      instance.x, instance.y = fastmath.vector3_get_components(vector3_stub)
      update_aabb()
      vector3_set_xyz(vector3_stub, 0, 0, DEPTH)
      set_position(vector3_stub, RAT.pivot)
      instance.dx, instance.dy = 0, 0
      raycast_controller.set_width(CHARACTER_WIDTH)
      raycast_controller.set_height(CHARACTER_HEIGHT)
      runtime.set_instance(root.path, instance)
      runtime.add_update_callback(instance, update)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      machine.reset()
      machine.enter_state(run)
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   function instance.on_hit(direction, damage_type)
      if health <= 0 then return end

      health = health - 1
      hit_direction = direction
      velocity_y = 80
      velocity_x = 0
      hit.stagger_end = runtime.current_time + 0.15 -- stagger duration
      set(RAT.sprite, CONST.TINT, vmath.vector4(0.8, 0, 0, 2))
      go.animate(RAT.sprite, CONST.TINT, go.PLAYBACK_ONCE_FORWARD, colors.WHITE, go.EASING_INCUBIC, 0.2)
      local fx = snd.get_hit_sound(damage_type, target_type)
      if health > 0 then
         snd.play_sound(fastmath.pick_any(fx, #fx - 1))
         nc.post_notification(CONST.CAMERA_SHAKE_REQUEST_NOTIFICATION, nil, 4, 0.15)
      else
         snd.play_sound(fx[#fx]) -- last fx in array (fastmath.pick_last)
         next_death_flame_time = runtime.current_time
         vector3_set_xy(vector3_stub, instance.x - 4 * instance.horizontal_look, instance.y + 8)
         factory.create(SMALL_FLAME_FACTORY, vector3_stub, IDENTITY, nil, 0.8)
         nc.post_notification(CONST.CAMERA_SHAKE_REQUEST_NOTIFICATION, nil, 6, 0.15)
      end
      machine.enter_state(hit)
   end -- instance.on_hit

   local function bite(position)
      vector3_set_y(position, instance.y + 12)
      factory.create(PLAYER_HIT_FACTORY, position, IDENTITY, nil, 0.8)
   end -- bite

   function instance.on_contact_point_response(message, sender)
      if sender == collisionobject_hitbox then return end
      local other_id = message.other_id
      if attack_targets[other_id] then return end
      attack_targets[other_id] = true
      local other_instance = runtime.get_instance(other_id)
      if other_instance then
         if other_instance.on_hit(instance.horizontal_look) then
            bite(message.position)
         end
      end
   end -- on_contact_point_response

   return instance
end -- make

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
