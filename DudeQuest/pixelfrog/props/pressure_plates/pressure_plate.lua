local Pool = require("m.pool")
local StateMachine = require("m.state_machine")
local nc = require("m.notification_center")
local const = require("m.constants")
local animation = require("m.animation")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
-- local gamestate = require("pixelfrog.game.gamestate")
-- local snd = require("sound.sound")

local DEPTH = layers.get_depth(layers.PROPS)

local vector3_stub = fastmath.vector3_stub
local play_animation = animation.play
local runtime = runtime

local ANIMATION = {
   IDLE = {
      { id = hash("pressure_plate_big_idle"), position = vmath.vector3(0, 3, 0), },
      { id = hash("pressure_plate_small_idle"), position = vmath.vector3(0, 3, 0), },
   },
   PRESSING = {
      { id = hash("pressure_plate_big_pressing"), position = vmath.vector3(0, 3, 0), },
      { id = hash("pressure_plate_small_pressing"), position = vmath.vector3(0, 3, 0), },
   },
   PRESSED = {
      { id = hash("pressure_plate_big_pressed"), position = vmath.vector3(0, 1, 0), },
      { id = hash("pressure_plate_small_pressed"), position = vmath.vector3(0, 1, 0), },
   },
   RELEASING = {
      { id = hash("pressure_plate_big_releasing"), position = vmath.vector3(0, 4, 0), },
      { id = hash("pressure_plate_small_releasing"), position = vmath.vector3(0, 4, 0), },
   },
}

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_BEFORE_PLAYER,
      is_static = true,
      is_ground = true,
      acceleration = 0,
      max_speed = 0,
   }
   local root
   -- local collisionobject
   local name
   local target_name
   local kind
   local is_permanent
   local machine = StateMachine.new()
   local char = animation.new_target()
   local debug_label

   local idle = {}
   local pressing = {}
   local pressed = {}
   local releasing = {}

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function update(dt)
      machine.update(dt)
   end -- update

   ---------------------------------------
   -- idle
   ---------------------------------------

   function idle.on_enter()
      label.set_text(debug_label, "Idle")
      play_animation(char, ANIMATION.IDLE, kind)
   end -- idle.on_enter

   ---------------------------------------
   -- pressing
   ---------------------------------------

   local function pressing_complete()
      machine.enter_state(pressed)
   end -- pressing_complete

   function pressing.on_enter()
      label.set_text(debug_label, "Pressing")
      play_animation(char, ANIMATION.PRESSING, kind, pressing_complete)
      nc.post_notification(target_name, name, true)
   end -- pressing.on_enter

   ---------------------------------------
   -- pressed
   ---------------------------------------

   function pressed.on_enter()
      label.set_text(debug_label, "Pressed")
      play_animation(char, ANIMATION.PRESSED, kind)
      if is_permanent then return end
      runtime.add_update_callback(instance, update)
      pressed.release_time = runtime.current_time + 0.1
   end -- pressed.on_enter

   function pressed.update()
      if runtime.current_time > pressed.release_time then
         runtime.remove_update_callback(instance)
         machine.enter_state(releasing)
      end
   end -- pressed.update

   ---------------------------------------
   -- releasing
   ---------------------------------------

   local function releasing_complete()
      machine.enter_state(idle)
   end -- releasing_complete

   function releasing.on_enter()
      label.set_text(debug_label, "Releasing")
      play_animation(char, ANIMATION.RELEASING, kind, releasing_complete)
      nc.post_notification(target_name, name, false)
   end -- releasing.on_enter

   function instance.on_collision(other_instance)
      if other_instance.on_hit then
         other_instance.on_hit(nil, 100) -- collision with static geometry results in instant death (damage == 100)
      end
   end -- instance.on_collision

   function instance.on_step()
      local current_state = machine.current_state()
      if current_state == idle then
         machine.enter_state(pressing)
      elseif current_state == pressed then
         pressed.release_time = runtime.current_time + 0.1
      end
   end -- instance.on_step

   function instance.init(self)
      debug_label = msg.url("#debug_label")
      msg.post(debug_label, msg.DISABLE)
      name = self.name
      target_name = self.target_name
      kind = self.kind
      is_permanent = self.is_permanent
      instance.acceleration = self.acceleration
      instance.max_speed = self.max_speed
      root = msg.url(".")
      char.pivot = msg.url("pivot")
      char.anchor = msg.url("anchor")
      char.sprite = msg.url("anchor#sprite")
      char.current_animation_group = nil
      char.current_animation = nil
      char.on_complete = nil
      -- collisionobject = msg.url("#collisionobject")
      fastmath.vector3_set_xyz(vector3_stub, 0, 0, DEPTH)
      go.set_position(vector3_stub, char.pivot)
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      machine.reset()
      machine.enter_state(idle)
   end -- instance.init

   function instance.deinit()
      runtime.set_instance(root.path, nil)
      runtime.remove_update_callback(instance)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

-- export
return {
   new = pool.new,
   free = pool.free,
}
