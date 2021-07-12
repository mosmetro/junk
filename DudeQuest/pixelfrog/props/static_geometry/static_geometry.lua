local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")

local snd = require("sound.sound")

local set_instance = runtime.set_instance

local function make()
   local instance = {
      can_jump_down = false,
      can_climb_up = true,
      is_static = true,
      is_ground = true,
      acceleration = 0,
      max_speed = 0,
   }
   local root
   local impenetrable

   local function destroy()
      go.delete(root, true)
   end -- destroy

   function instance.on_collision(other_instance)
      if other_instance.on_hit then
         other_instance.on_hit(nil, 100) -- collision with static geometry results in instant death (damage == 100)
      end
   end -- instance.on_collision

   function instance.on_hit(sfx) --(hit_soundfx, damage_points, speed)
      snd.play_sound(snd.FATE_WOOD_FLESH_1)
      if sfx then
         snd.play_sound(sfx)
      elseif impenetrable then
         -- snd.play_sound(snd.FATE_WOOD_FLESH_1)
      else
         snd.play_sound(snd.FATE_WOOD_FLESH_1)
      end
      return not impenetrable -- signal to embed sword
   end -- instance.on_hit

   function instance.init(self)
      root = msg.url(".")
      instance.can_jump_down = self.can_jump_down
      instance.can_climb_up = self.can_climb_up
      instance.acceleration = self.acceleration
      instance.max_speed = self.max_speed
      impenetrable = self.impenetrable
      if self.disable_sprite then
         msg.post("#sprite", msg.DISABLE)
      end
      set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      set_instance(root.path, nil)
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
