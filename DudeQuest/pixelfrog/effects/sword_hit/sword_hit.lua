local Pool = require("m.pool")
local const = require("m.constants")

local FLASH_ROTATIONS = {}
for angle = 0, 360, 20 do
   FLASH_ROTATIONS[#FLASH_ROTATIONS + 1] = vmath.quat_rotation_z(math.rad(angle))
end

local scale_roll = fastmath.uniform_real(1, 2)
local next_rotation = fastmath.uniform_int(1, #FLASH_ROTATIONS)
local set_rotation = go.set_rotation
local set_scale = go.set_scale
local animate = go.animate
local delete = go.delete
local vector3_set_xyz = fastmath.vector3_set_xyz
local vector3_stub = fastmath.vector3_stub
local remove_update_callback = runtime.remove_update_callback

local INFINITY = const.INFINITY
local PLAYBACK_ONCE_FORWARD = go.PLAYBACK_ONCE_FORWARD
local EASING_LINEAR = go.EASING_LINEAR
local EASING_OUTQUAD = go.EASING_OUTQUAD

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_LAST,
   }
   local root
   local flash
   -- local sparks
   local next_flash_time
   local flash_count

   local function destroy()
      delete(root, true)
   end -- destroy

   local function update()
      if runtime.current_time > next_flash_time then
         if flash_count == 0 then
            next_flash_time = INFINITY
            -- particlefx.play(sparks)
            delete(flash)
            remove_update_callback(instance)
         else
            flash_count = flash_count - 1
            set_rotation(FLASH_ROTATIONS[next_rotation()], flash)
            vector3_set_xyz(vector3_stub, scale_roll(), 0.75, 1)
            set_scale(vector3_stub, flash)
            next_flash_time = runtime.current_time + 0.04
         end
      end
   end -- update

   function instance.init()
      root = msg.url(".")
      flash = msg.url("flash")
      -- sparks = msg.url("#hit_spark")
      flash_count = 3
      next_flash_time = 0
      set_scale(0.01, "circle")
      animate("circle", const.SCALE, PLAYBACK_ONCE_FORWARD, 0.85, EASING_LINEAR, 0.4, 0, destroy)
      animate("circle#sprite", const.TINT_W, PLAYBACK_ONCE_FORWARD, 0, EASING_OUTQUAD, 0.4)
      runtime.add_update_callback(instance, update)
   end -- instance.init

   function instance.deinit()
      remove_update_callback(instance)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
