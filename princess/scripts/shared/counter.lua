-- import
local utils = require("scripts.shared.utils")

-- localization
local play_flipbook = gui.play_flipbook
local get_flipbook = gui.get_flipbook
local animate = gui.animate
local cancel_animation = gui.cancel_animation
local set_scale = gui.set_scale
local set_enabled = gui.set_enabled
local sign = utils.sign
local min = math.min
local max = math.max
local modf = math.modf
local vector3 = vmath.vector3
local hash = hash
local EASING_LINEAR = gui.EASING_LINEAR

-- functions
local new

-- constants


function new(counter)
   local images = counter.images -- required
   local nodes = counter.nodes -- required
   local base = #images
   local digits_count = #nodes
   local current_value = counter.current_value or 0
   local change_speed = counter.change_speed or 60
   local delta_value = 0
   local value_transformer = counter.value_transformer or nil

   local PROPERTY_SCALE = hash("scale")
   local IDENTITY_VALUE = vector3(1, 1, 1)
   local SCALE = 1.4
   local SCALED_VALUE = vector3(SCALE, SCALE, SCALE)
   local EASING = EASING_LINEAR
   local SCALE_DURATION = 0.2

   function counter.init(value, max_value)
      current_value = value
      counter.set(value)

      if max_value then
         max_value = max_value / digits_count
         for i = 1, digits_count do
            set_enabled(nodes[i], i <= max_value)
         end
      end
   end -- init

   function counter.set(value)
      value = value_transformer and value_transformer:transform(value) or value

      for i = 1, digits_count do
         local node = nodes[i]
         local image = images[(value % base) + 1]
         if get_flipbook(node) ~= image then
            play_flipbook(node, image)
            cancel_animation(node, "scale")
            set_scale(node, SCALED_VALUE)
            -- gui.animate(node, property, to, easing, duration, delay, complete_function, playback)
            animate(node, PROPERTY_SCALE, IDENTITY_VALUE, EASING, SCALE_DURATION)
         end
         value = (value - value % base) / base
      end
   end -- set

   function counter.update(new_value, dt)
      if current_value ~= new_value then
         delta_value = delta_value + change_speed * dt
         if delta_value < 1 then return end

         local integral, fractional = modf(delta_value)
         local next_value = sign(new_value - current_value) > 0
         and min(current_value + integral, new_value)
         or max(current_value - integral, new_value)
         if current_value ~= next_value then
            counter.set(next_value)
            current_value = next_value
            delta_value = fractional
         end
      else
         delta_value = 0
      end
   end -- update

   counter.set(current_value)
   return counter
end -- new

-- export
return {
   new = new,
}
