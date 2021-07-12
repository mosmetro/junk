local Pool = require("m.pool")
-- local layers = require("m.layers")
-- local nc = require("m.notification_center")
-- local CONST = require("m.constants")
local utils = require("m.utils")
-- local debug_draw = require("m.debug_draw")
-- local COLOR = require("m.colors")
-- local game = require("maze.game")

-- local hash = hash

local FLASH_ROTATIONS = {}
for angle = 0, 360, 20 do
   FLASH_ROTATIONS[#FLASH_ROTATIONS + 1] = vmath.quat_rotation_z(math.rad(angle))
end

local next_rotation = fastmath.uniform_int(1, #FLASH_ROTATIONS)
local set_rotation = go.set_rotation
local set_scale = go.set_scale
local animate = go.animate

local INFINITY = 1 / 0
local TINT_W = hash("tint.w")
local SCALE = hash("scale")
local PLAYBACK_ONCE_FORWARD = go.PLAYBACK_ONCE_FORWARD
local EASING_LINEAR = go.EASING_LINEAR
local EASING_OUTQUAD = go.EASING_OUTQUAD

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_LAST,
   }
   local root
   local flash
   local sparks
   local next_flash_time
   local flash_count

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function update()
      if runtime.current_time > next_flash_time then
         if flash_count == 0 then
            next_flash_time = INFINITY
            particlefx.play(sparks)
            go.delete(flash)
            runtime.remove_update_callback(instance)
         else
            flash_count = flash_count - 1
            set_rotation(FLASH_ROTATIONS[next_rotation()], flash)
            next_flash_time = runtime.current_time + 0.04
         end
      end
   end -- update

   function instance.init()
      root = msg.url(".")
      flash = msg.url("flash")
      sparks = msg.url("#hit_spark")
      flash_count = 3
      next_flash_time = 0
      set_scale(0.01, "circle")
      animate("circle", SCALE, PLAYBACK_ONCE_FORWARD, 0.55, EASING_LINEAR, 0.4, 0, destroy)
      animate("circle#sprite", TINT_W, PLAYBACK_ONCE_FORWARD, 0, EASING_OUTQUAD, 0.4)
      runtime.add_update_callback(instance, update)
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
