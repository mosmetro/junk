local const = require("m.constants")
-- local utils = require("m.utils")

local min = fastmath.min
local max = fastmath.max
local abs = fastmath.abs
local modf = math.modf
local SCALE = const.SCALE

local function new(sprites, images, min_speed, scale, current_value, map)
   min_speed = min_speed or 30
   scale = scale or vmath.vector3(1.5, 1.5, 1)
   current_value = current_value or 0
   local speed = min_speed
   local change = 0
   local base = #images
   local digits = #sprites
   local current_images = {}
   for i = 1, digits do
      current_images[#current_images + 1] = images[1]
      sprite.play_flipbook(sprites[i], images[1])
   end

   -- local function reset()
   --    for i = 1, digits do
   --       current_images[#current_images + 1] = images[1]
   --       sprite.play_flipbook(sprites[i], images[1])
   --    end
   -- end -- reset

   local function set(value, animated)
      value = map and map[value] or value
      for i = 1, digits do
         local pos = sprites[i]
         local image = images[(value % base) + 1]
         if current_images[i] ~= image then
            current_images[i] = image
            sprite.play_flipbook(pos, image)
            if animated then
               go.cancel_animations(pos, SCALE)
               go.set(pos, SCALE, scale)
               -- go.animate(url, property, playback, to, easing, duration, delay, complete_function)
               go.animate(pos, SCALE, go.PLAYBACK_ONCE_FORWARD, const.VECTOR3_ONE, go.EASING_LINEAR, 0.1)
            end
         end
         value = (value - value % base) / base
      end
   end -- set

   local function update(new_value, dt)
      if current_value ~= new_value then
         local delta = new_value - current_value
         speed = max(abs(delta), speed)
         change = change + speed * dt
         if change < 1 then return false end

         local integral, fractional = modf(change)
         local next_value = (delta > 0) and min(current_value + integral, new_value) or max(current_value - integral, new_value)
         set(next_value, true)
         current_value = next_value
         change = fractional
         return true
      end
      change = 0
      speed = min_speed
      return false
   end -- update

   set(current_value, false)
   return update
end -- new

-- export
return {
   new = new,
}
