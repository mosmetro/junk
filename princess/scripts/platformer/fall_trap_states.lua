-- import
local StateMachine = require("scripts.shared.state_machine")

local utils = require("scripts.shared.utils")
local game = require("scripts.platformer.game")
local NTN = require("scripts.platformer.notifications")
local SND = require("scripts.platformer.sound")
-- local MSG = require("scripts.shared.messages")
local nc  = require("scripts.shared.notification_center")

-- localization
local set_text = label.set_text
local clamp = utils.clamp
local ease = utils.ease
local get_position = go.get_position
local set_position = go.set_position
local lerp = vmath.lerp

-- functions
local make_machine

---------------------------------------
-- make_machine
---------------------------------------

function make_machine (owner)
   -- states
   local idle = {}
   local fall = {}
   local bounce = {}
   local await = {}
   local rise = {}



   ---------------------------------------
   -- idle
   ---------------------------------------

   function idle.on_enter(machine)
      set_text(owner.label, "IDLE")

      nc.add_observer(machine.owner, NTN.TRIGGER_ENTER, function (_, sender)
         if sender == owner.trigger then
            machine.enter_state(fall)
         end
      end)
   end -- idle.on_enter

   function idle.on_exit(machine)
      nc.remove_observer(machine.owner, NTN.TRIGGER_ENTER)
   end -- idle.on_exit

   ---------------------------------------
   -- fall
   ---------------------------------------

   function fall.on_enter()
      set_text(owner.label, "FALL")
   end -- fall.on_enter

   function fall.execute(machine, dt)
      owner.position.y = owner.position.y + owner.delta_position.y
      set_position(owner.position)

      if owner.collision_below then
         machine.enter_state(bounce)
         return
      end

      owner:fall(dt)
   end -- fall.execute

   function fall.on_exit()
      SND.TRAP_HIT_GROUND:create_instance():start()
   end -- fall.on_exit

   ---------------------------------------
   -- bounce
   ---------------------------------------

   function bounce.on_enter(machine)
      set_text(machine.owner.label, "BOUNCE")
      bounce.recoil_velocity = owner.recoil_velocity
   end -- bounce.on_enter

   function bounce.execute(machine, dt)
      owner.position.y = owner.position.y + owner.delta_position.y
      set_position(owner.position)

      if bounce.recoil_velocity < 30.0 then
         machine.enter_state(await)
         return
      end

      if owner.collision_below then
         owner.velocity_y = bounce.recoil_velocity
         bounce.recoil_velocity = bounce.recoil_velocity * 0.6
      end

      owner:fall(dt)
   end -- bounce.execute

   ---------------------------------------
   -- await
   ---------------------------------------

   function await.on_enter()
      set_text(owner.label, "AWAIT")
      await.time = owner.wait_time
      owner.delta_position.y = 0
      game.set_delta_position(owner.gameobject, owner.delta_position)
   end -- await.on_enter

   function await.execute(machine, dt)
      await.time = await.time - dt
      if await.time <= 0.0 then
         machine.enter_state(rise)
      end
   end -- await.execute

   ---------------------------------------
   -- rise
   ---------------------------------------

   function rise.on_enter()
      set_text(owner.label, "RISE")
      rise.position = get_position()
      rise.distance = owner.idle_position.y - rise.position.y
      rise.interpolator = 0
   end -- rise.on_enter

   function rise.execute(machine, dt)
      owner.position.y = owner.position.y + owner.delta_position.y
      set_position(owner.position)

      if owner.position.y == owner.idle_position.y then
         owner.delta_position.y = 0
         game.set_delta_position(owner.gameobject, owner.delta_position)
         machine.enter_state(idle)
      else
         rise.interpolator = rise.interpolator + dt * owner.rise_speed / rise.distance
         rise.interpolator = clamp(rise.interpolator, 0, 1)
         local eased_interpolator = ease(rise.interpolator, owner.ease_factor)
         local new_position_y = lerp(eased_interpolator, rise.position.y, owner.idle_position.y)
         if new_position_y > owner.idle_position.y then
            new_position_y = owner.idle_position.y
         end
         owner.delta_position.y = new_position_y - owner.position.y
         game.set_delta_position(owner.gameobject, owner.delta_position)
      end

   end

   return StateMachine.new(owner, idle)
end -- make_machine

-- export
return {
   make_machine = make_machine,
}
