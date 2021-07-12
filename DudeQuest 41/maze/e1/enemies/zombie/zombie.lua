-- import
local Pool = require("m.pool")
local RaycastController = require("m.raycast_controller")
local StateMachine = require("m.state_machine")
local Maze = require("maze.maze")
local groups = require("m.groups")
local nc = require("m.notification_center")
local utils = require("m.utils")

-- localization
local hash = hash
local msg = msg
-- local vmath = vmath
-- local LEFT = ui.LEFT
-- local RIGHT = ui.RIGHT
-- local UP = ui.UP
-- local DOWN = ui.DOWN
-- local A = ui.A
-- -- local B = ui.B
-- local X = ui.X
-- local Y = ui.Y
-- local runtime = runtime
-- local is_down = runtime.is_down
-- local is_up = runtime.is_up
-- local is_pressed = runtime.is_pressed
-- local modf = math.modf
local abs = fastmath.abs
local sign = fastmath.sign
-- local max = fastmath.max
local vector3_set_components = fastmath.vector3_set_components
-- local vector3_get_x = fastmath.vector3_get_x
local vector3_set_z_sign = fastmath.vector3_set_z_sign
-- local lerp = fastmath.lerp
local get_instance = runtime.get_instance
local set = go.set
-- local get = go.get
local set_position = go.set_position
local play_flipbook = sprite.play_flipbook
-- local play_sound = snd.play_sound


local CHARACTER_WIDTH = 20
local CHARACTER_HEIGHT = 38
local MAX_VERTICAL_SPEED = 800
local MAX_HORIZONTAL_SPEED = 22
local GROUND_ACCELERATION = 5000
local JUMP_HEIGHT = 44
local JUMP_TIME_TO_APEX = 0.38
local NORMAL_GRAVITY = -(2 * JUMP_HEIGHT) / (JUMP_TIME_TO_APEX * JUMP_TIME_TO_APEX)
local EULER_Y = hash("euler.y")

local coin_toss = fastmath.bernoulli(0.5)
local random_delay = fastmath.uniform_real(0, 0.66)

local hit_material
local MATERIAL = hash("material")

local function make()
   local root
   local pivot
   local instance = {
      dx = 0,
      dy = 0,
      needs_down_pass = false,
      needs_up_pass = false,
      needs_left_pass = false,
      needs_right_pass = false,
      update_group = runtime.UPDATE_GROUP_AFTER_PLAYER,
   }
   local collisionobject_raycast
   local collisionobject_hitbox
   local collisionobject_hurtbox
   local vector3_stub
   local position_x
   local position_y
   local acceleration
   local max_horizontal_speed = MAX_HORIZONTAL_SPEED
   local gravity = NORMAL_GRAVITY
   local velocity_x
   local velocity_y
   local previous_velocity_y
   local move_direction
   local look_direction
   local previous_look_direction
   local ground
   local contact_left
   local contact_right
   local debug_label

   -- states
   local idle = {}
   local rise = {}
   local walk = {}

   -- animations
   local ZOMBIE = {
      object = nil,
      sprite = nil,
      current_animation_group = nil,
      current_animation = nil,
      on_complete = nil,

      IDLE = {
         { id = hash("zombie_idle"), position = vmath.vector3(4, 19, 0.01) },
      },
      RISE = {
         { id = hash("zombie_rise"), position = vmath.vector3(4, 19, 0.01) },
      },
      WALK = {
         { id = hash("zombie_walk"), position = vmath.vector3(4, 19, 0.01) },
      },
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
   })
   raycast_controller.set_width(CHARACTER_WIDTH)
   raycast_controller.set_height(CHARACTER_HEIGHT)

   local machine = StateMachine.new(instance, nil)

   local play_properties = { offset = 0, playback_rate = 1 }

   local function play_animation(target, animation_group, index, on_complete, cursor, rate)
      local animation = animation_group[index or 1]
      if target.current_animation == animation then return end
      play_properties.offset = cursor or 0
      play_properties.playback_rate = rate or 1
      vector3_set_z_sign(animation.position, -look_direction)
      set_position(animation.position, target.object)
      play_flipbook(target.sprite, animation.id, on_complete, play_properties)
      target.on_complete = on_complete
      target.current_animation_group = animation_group
      target.current_animation = animation
   end -- play_animation

   local function turnaround(target)
      if previous_look_direction == look_direction then return end
      previous_look_direction = look_direction
      set(pivot, EULER_Y, look_direction == 1 and 0 or 180)
      local animation_position = target.current_animation.position
      vector3_set_z_sign(animation_position, -look_direction)
      set_position(animation_position, target.object)
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
      dx, dy, velocity_x, velocity_y, ground = raycast_controller.update(position_x, position_y, dx, dy, velocity_x, velocity_y)
      position_x = position_x + dx
      position_y = position_y + dy
      vector3_set_components(vector3_stub, position_x, position_y, 0)
      set_position(vector3_stub, root)
      instance.dx = dx
      instance.dy = dy
      return dx, dy
   end -- advance

   ---------------------------------------
   -- idle
   ---------------------------------------

   local function on_rise()
      timer.delay(random_delay(), false, function()
         machine.enter_state(rise)
      end)
   end -- on_rise

   function idle.on_enter()
      label.set_text(debug_label, "Idle")
      play_animation(ZOMBIE, ZOMBIE.IDLE)
      turnaround(ZOMBIE)
      msg.post(collisionobject_hitbox, msg.DISABLE)
      msg.post(collisionobject_hurtbox, msg.DISABLE)
      msg.post(collisionobject_raycast, msg.DISABLE)
      nc.add_observer(on_rise, Maze.level_did_appear_notification)
   end -- idle.on_enter

   function idle.on_exit()
      nc.remove_observer(on_rise, Maze.level_did_appear_notification)
      msg.post(collisionobject_hitbox, msg.ENABLE)
      msg.post(collisionobject_hurtbox, msg.ENABLE)
      msg.post(collisionobject_raycast, msg.ENABLE)
   end -- idle.on_exit

   ---------------------------------------
   -- rise
   ---------------------------------------

   local function on_rise_complete()
      machine.enter_state(walk)
   end -- on_rise_complete

   function rise.on_enter()
      label.set_text(debug_label, "Rise")
      play_animation(ZOMBIE, ZOMBIE.RISE, nil, on_rise_complete)
   end -- rise.on_enter

   local function update(dt)
      previous_velocity_y = velocity_y
      machine.update(dt)
   end -- update

   ---------------------------------------
   -- walk
   ---------------------------------------

   function walk.on_enter()
      label.set_text(debug_label, "Walk")
      play_animation(ZOMBIE, ZOMBIE.WALK)
   end -- walk.on_enter

   function walk.update(dt)
      advance(move(dt))
      if contact_left then
         move_direction = 1
         look_direction = 1
      elseif contact_right then
         move_direction = -1
         look_direction = -1
      end
   end -- walk.update

   function instance.init(self)
      hit_material = self.hit_material
      root = msg.url(".")
      pivot = msg.url(nil, "pivot", nil)
      ZOMBIE.object = msg.url(nil, "zombie", nil)
      ZOMBIE.sprite = msg.url("zombie#sprite")
      ZOMBIE.current_animation_group = nil
      ZOMBIE.current_animation = nil
      ZOMBIE.on_complete = nil
      collisionobject_raycast = msg.url("#collisionobject_raycast")
      collisionobject_hitbox = msg.url("#collisionobject_hitbox")
      collisionobject_hurtbox = msg.url("#collisionobject_hurtbox")
      vector3_stub = go.get_position()
      position_x, position_y = fastmath.vector3_get_components(vector3_stub)
      acceleration = GROUND_ACCELERATION
      velocity_x = 0
      velocity_y = 0
      look_direction = self.look_direction
      if look_direction == 0 then
         look_direction = coin_toss() and 1 or -1
      end
      move_direction = look_direction
      previous_look_direction = 0
      ground = nil
      debug_label = msg.url("#debug_label")
      machine.reset()
      machine.enter_state(idle)
      runtime.add_update_callback(instance, update)
      runtime.set_instance(root.path, instance)
   end -- init

   function instance.deinit()
      nc.remove_observer(on_rise, Maze.level_did_appear_notification)
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
   end -- deinit

   function instance.apply_damage(amount)
      utils.log("received " .. tostring(amount) .. " damage points")
      -- local mat = go.get(ZOMBIE.sprite, MATERIAL)
      -- go.set(ZOMBIE.sprite, MATERIAL, hit_material)
      -- -- go.set(ZOMBIE.sprite, "tint", vmath.vector4(1000, 1000, 1000, 1))
      -- -- sprite.set_constant(ZOMBIE.sprite, "tint", vmath.vector4(100, 100, 100, 1))
      -- timer.delay(0.1, false, function()
      --    -- sprite.reset_constant(ZOMBIE.sprite, "tint")
      --    go.set(ZOMBIE.sprite, MATERIAL, mat)
      -- end)
      go.delete(root, true)
   end

   function instance.on_contact(_, direction)
      move_direction = -direction
      look_direction = -direction
      turnaround(ZOMBIE)
   end -- instance.on_contact

   -- function instance.before_update()
   --    contact_left = false
   --    contact_right = false
   -- end -- instance.before_update

   function instance.on_collision_response(message)
      local other_instance = get_instance(message.other_id)
      if other_instance then
         if other_instance.collect_damage then
            local value = other_instance.collect_damage()
            instance.apply_damage(value) -- or just apply_damage?
         end
      end
   end -- on_collision_response

   -- function instance.on_trigger_response(message)
   --    utils.log("on_trigger_response", gameobject)
   -- end -- on_trigger_response

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
