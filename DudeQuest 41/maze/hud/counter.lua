-- local utils = require("m.utils")

local sign = fastmath.sign
local min = fastmath.min
local max = fastmath.max
local abs = fastmath.abs
local modf = math.modf
local set_text = gui.set_text

local function new(text_node, min_speed, current_value)
   current_value = current_value or 0
   min_speed = min_speed or 60
   local speed = min_speed
   local change = 0
   set_text(text_node, current_value)

   local function update(new_value, dt)
      if current_value ~= new_value then
         local delta = new_value - current_value
         speed = max(abs(delta), speed)
         -- utils.log(speed)
         change = change + speed * dt
         if change < 1 then return false end

         local integral, fractional = modf(change)
         local next_value = sign(delta) > 0 and min(current_value + integral, new_value) or max(current_value - integral, new_value)
         set_text(text_node, next_value)
         current_value = next_value
         change = fractional
         return true
      end
      change = 0
      speed = min_speed
      return false
   end -- update

   return update
end -- new

-- export
return {
   new = new,
}
