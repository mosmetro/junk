local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
-- local gamestate = require("pixelfrog.game.gamestate")
local snd = require("sound.sound")

local DEPTH = layers.get_depth(layers.PROPS_BACK)

local runtime = runtime

local function make()
   local instance = {}
   local root
   local wave = {}
   local start_wave
   local is_stopped
   local name
   local controller_name

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function on_command(_, stop)
      is_stopped = stop
   end -- on_command

   function start_wave()
      if is_stopped then return end
      local animate = go.animate
      for i = 1, 16 do
         -- go.animate(url, property, playback, to, easing, duration, delay, complete_function)
         animate(wave[i], const.POSITION_Y, go.PLAYBACK_ONCE_PINGPONG, 0, go.EASING_LINEAR, 0.3, (i - 1) * 0.06, (i == 8) and start_wave or nil)
      end
   end -- start_wave

   -- local function wave_complete()
   --    start_wave()
   -- end -- wave_complete

   function instance.on_collision(other_instance)
      if other_instance and other_instance.on_hit then
         other_instance.on_hit(snd.SHANTAE_GETHIT, 100, 0)
      end
   end -- instance.on_collision

   function instance.init(self)
      name = self.name
      controller_name = self.controller_name
      root = msg.url(".")
      local pos = go.get_position()
      fastmath.vector3_set_z(pos, DEPTH)
      go.set_position(pos)
      is_stopped = false
      local set_instance = runtime.set_instance
      local url = msg.url
      for i = 1, 16 do
         local spike = url("spike" .. i)
         set_instance(spike.path, instance)
         wave[#wave + 1] = spike
      end
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      if controller_name ~= const.EMPTY then
         nc.add_observer(on_command, name, controller_name)
      end
      start_wave()
   end -- instance.init

   function instance.deinit()
      local set_instance = runtime.set_instance
      for i = 16, 1, -1 do
         set_instance(wave[i].path, nil)
         wave[i] = nil
      end
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
