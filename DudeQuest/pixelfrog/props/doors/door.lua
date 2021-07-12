local Pool = require("m.pool")
local StateMachine = require("m.state_machine")
local nc = require("m.notification_center")
local const = require("m.constants")
local animation = require("m.animation")
local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local gamestate = require("pixelfrog.game.gamestate")
local snd = require("sound.sound")

local DEPTH = layers.get_depth(layers.PROPS_BACK)

local vector3_stub = fastmath.vector3_stub
local play_animation = animation.play
-- local timer = timer
local runtime = runtime

-- local ANIMATION = {
--    CLOSED = {
--       { id = hash("door_wood_closed"), position = vmath.vector3(4, 24, 0), },
--       { id = hash("door_gold_closed"), position = vmath.vector3(4, 24, 0), },
--    },
--    LOCKED_RESPONSE = {
--       { id = hash("door_wood_locked_response"), position = vmath.vector3(-1, 24, 0), },
--       { id = hash("door_gold_locked_response"), position = vmath.vector3(-1, 24, 0), },
--    },
--    OPENING = {
--       { id = hash("door_wood_opening"), position = vmath.vector3(4, 24, 0), },
--       { id = hash("door_gold_opening"), position = vmath.vector3(4, 24, 0), },
--    },
--    OPENED = {
--       { id = hash("door_wood_opened"), position = vmath.vector3(4, 24, 0), },
--       { id = hash("door_gold_opened"), position = vmath.vector3(4, 24, 0), },
--    },
--    CLOSING = {
--       { id = hash("door_wood_closing"), position = vmath.vector3(4, 24, 0), },
--       { id = hash("door_gold_closing"), position = vmath.vector3(4, 24, 0), },
--    },
-- }

local ANIMATION = {
   CLOSED = {
      { id = hash("door_wood_closed"), position = vmath.vector3(4, 24, 0), },
      { id = hash("door_gold_closed"), position = vmath.vector3(4, 24, 0), },
   },
   LOCKED_RESPONSE = {
      { id = hash("door_wood_locked_response"), position = vmath.vector3(-1, 24, 0), },
      { id = hash("door_gold_locked_response"), position = vmath.vector3(-1, 24, 0), },
   },
   OPENING = {
      { id = hash("door_wood_opening"), position = vmath.vector3(4, 24, 0), },
      { id = hash("door_gold_opening"), position = vmath.vector3(4, 24, 0), },
   },
   OPENED = {
      { id = hash("door_wood_opened"), position = vmath.vector3(4, 24, 0), },
      { id = hash("door_gold_opened"), position = vmath.vector3(4, 24, 0), },
   },
   CLOSING = {
      { id = hash("door_wood_closing"), position = vmath.vector3(4, 24, 0), },
      { id = hash("door_gold_closing"), position = vmath.vector3(4, 24, 0), },
   },
}

local function make()
   local instance = {
      -- update_group = runtime.UPDATE_GROUP_BEFORE_PLAYER,
   }
   local root
   local collisionobject
   local kind
   local name
   local key_name
   local controller_name
   local stay_open
   local machine = StateMachine.new()
   local char = animation.new_target()
   local unlock_timer_handle
   local debug_label

   local locked = {}
   local closed = {}
   local locked_response = {}
   local unlock = {}
   local opening = {}
   local opened = {}
   local closing = {}
   local blocked = {}

   local function destroy()
      if unlock_timer_handle then timer.cancel(unlock_timer_handle) end
      go.delete(root, true)
   end -- destroy

   -- local function open()
   --    local current_state = machine.current_state()
   --    if current_state == closed then
   --
   -- end

   local function on_command(_, open)
      local current_state = machine.current_state()
      if current_state == blocked then return end

      if open then
         if not ((current_state == opening) or (current_state == opened)) then
            machine.enter_state(opening)
         end
      else
         if not ((current_state == closing) or (current_state == closed)) then
            machine.enter_state(closing)
         end
      end
   end -- on_command

   -- local function update(dt)
   --    machine.update(dt)
   -- end -- update

   ---------------------------------------
   -- locked
   ---------------------------------------

   function locked.on_enter()
      label.set_text(debug_label, "Locked")
      play_animation(char, ANIMATION.CLOSED, kind)
   end -- locked.on_enter

   ---------------------------------------
   -- closed
   ---------------------------------------

   function closed.on_enter()
      label.set_text(debug_label, "Closed")
      play_animation(char, ANIMATION.CLOSED, kind)
   end -- closed.on_enter

   ---------------------------------------
   -- locked_response
   ---------------------------------------

   local function locked_response_complete()
      if key_name == const.EMPTY then
         machine.enter_state(closed)
      else
         machine.enter_state(locked)
      end
   end -- locked_response_complete

   function locked_response.on_enter()
      label.set_text(debug_label, "Locked_response")
      play_animation(char, ANIMATION.LOCKED_RESPONSE, kind, locked_response_complete)
      snd.play_sound(snd.FATE_DOOR_CLOSED)
   end -- locked_response.on_enter

   ---------------------------------------
   -- unlock
   ---------------------------------------

   local function unlock_complete()
      machine.enter_state(opening)
   end -- unlock_complete

   function unlock.on_enter()
      label.set_text(debug_label, "Unlock")
      snd.play_sound(snd.PLAYER_USE_KEY)
      unlock_timer_handle = timer.delay(0.5, false, unlock_complete)
      -- runtime.add_update_callback(instance, update)
      -- unlock.done_time = runtime.current_time + 5.2
   end -- unlock.on_enter

   -- function unlock.update()
   --    if runtime.current_time > unlock.done_time then
   --       runtime.remove_update_callback(instance)
   --       machine.enter_state(open)
   --    end
   -- end -- unlock.update

   ---------------------------------------
   -- opening
   ---------------------------------------

   local function opening_complete()
      machine.enter_state(opened)
   end -- opening

   function opening.on_enter()
      label.set_text(debug_label, "Opening")
      play_animation(char, ANIMATION.OPENING, kind, opening_complete)
      snd.play_sound(snd.DOOR_OPEN)
      msg.post(collisionobject, msg.DISABLE)
   end -- opening.on_enter

   ---------------------------------------
   -- opened
   ---------------------------------------

   function opened.on_enter()
      label.set_text(debug_label, "Opened")
      play_animation(char, ANIMATION.OPENED, kind)
      msg.post(collisionobject, msg.DISABLE)
      if stay_open then
         gamestate.set(gamestate.map, name, "is_closed", false)
      end
      nc.post_notification("opened", name)
   end -- opened.on_enter

   ---------------------------------------
   -- closing
   ---------------------------------------

   local function closing_complete()
      machine.enter_state(closed)
   end -- closing

   function closing.on_enter()
      label.set_text(debug_label, "Closing")
      play_animation(char, ANIMATION.CLOSING, kind, closing_complete)
      snd.play_sound(snd.DOOR_CLOSE)
      msg.post(collisionobject, msg.ENABLE)
   end -- closing.on_enter

   function instance.on_collision(other_instance) if other_instance.on_hit then
         other_instance.on_hit(nil, 100) -- collision with static geometry results in instant death (damage == 100)
      end
   end -- instance.on_collision

   function instance.try_open(other_instance)
      local current_state = machine.current_state()
      if current_state == locked then
         if other_instance.check_key and other_instance.check_key(key_name) then
            machine.enter_state(unlock)
         else
            machine.enter_state(locked_response)
         end
      elseif current_state == closed then
         if controller_name == const.EMPTY then
            machine.enter_state(opening)
         else
            machine.enter_state(locked_response)
         end
      end
   end -- instance.try_open

   function instance.on_hit() --(hit_soundfx, damage_points, speed)
      snd.play_sound(snd.FATE_WOOD_FLESH_1)
      return false -- signal to embed sword
   end -- instance.on_hit

   function instance.init(self)
      debug_label = msg.url("#debug_label")
      msg.post(debug_label, msg.DISABLE)
      kind = self.kind
      name = self.name
      key_name = self.key_name
      controller_name = self.controller_name
      stay_open = self.stay_open
      root = msg.url(".")
      char.pivot = msg.url("pivot")
      char.anchor = msg.url("anchor")
      char.sprite = msg.url("anchor#sprite")
      char.current_animation_group = nil
      char.current_animation = nil
      char.on_complete = nil
      collisionobject = msg.url("#collisionobject")
      fastmath.vector3_set_xyz(vector3_stub, 0, 0, DEPTH)
      go.set_position(vector3_stub, char.pivot)
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      if self.direction < 0 then
         go.set(char.pivot, const.ROTATION, const.QUAT_Y_180)
         physics.set_hflip(collisionobject, true)
      end
      machine.reset()
      local is_locked = gamestate.get(gamestate.map, name, "is_locked", key_name ~= const.EMPTY)
      local is_closed = gamestate.get(gamestate.map, name, "is_closed", true)
      -- utils.log(gamestate.map, name, is_locked, is_closed)
      -- machine.enter_state(is_locked and locked or (is_closed and closed or opened))
      machine.enter_state((is_closed and is_locked) and locked or (is_closed and closed or opened))
      if controller_name ~= const.EMPTY then
         nc.add_observer(on_command, name, controller_name)
      end
   end -- instance.init

   function instance.deinit()
      runtime.set_instance(root.path, nil)
      -- runtime.remove_update_callback(instance)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.remove_observer(on_command, name, controller_name)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

-- export
return {
   new = pool.new,
   free = pool.free,
}
