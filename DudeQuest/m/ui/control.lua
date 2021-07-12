local ui = require("m.ui.ui")
-- local utils = require("m.utils")

local is_enabled = gui.is_enabled
local get_parent = gui.get_parent
local aabb_contains_point = fastmath.aabb_contains_point
local POINTER_DOWN      = ui.POINTER_DOWN
local POINTER_UP        = ui.POINTER_UP
local POINTER_DRAGGED   = ui.POINTER_DRAGGED
local POINTER_CANCELLED = ui.POINTER_CANCELLED

local function check_enabled(node)
   local parent = get_parent(node)
   if parent then
      return check_enabled(parent)
   end
   return is_enabled(node)
end -- check_enabled

local function hit_test(control, x, y)
   return check_enabled(control.node) and aabb_contains_point(control.aabb, x, y) or false
end -- hit_test

local function new(control)
   control.is_active = true
   local tracking = false
   local pointer_inside = false

   if not control.hit_test then
      control.hit_test = hit_test
   end

   function control.on_event(event)
      if not control.is_active then return false end

      if event.type == POINTER_DOWN then
         if control:hit_test(event.x, event.y) then
            tracking = true
            pointer_inside = true
            if control.pointer_down_entered then control.pointer_down_entered(event) end
            return true
         end

      elseif event.type == POINTER_UP then
         if tracking then
            if pointer_inside then
               if control.pointer_up_inside then control.pointer_up_inside(event) end
            else
               if control.pointer_up_outside then control.pointer_up_outside(event) end
            end
            tracking = false
            pointer_inside = false
            return true
         end

      elseif event.type == POINTER_DRAGGED then
         if tracking then
            if control:hit_test(event.x, event.y) then
               if not pointer_inside then
                  pointer_inside = true
                  if control.pointer_down_entered then control.pointer_down_entered(event) end
               end
            else
               if pointer_inside then
                  pointer_inside = false
                  if control.pointer_down_exited then control.pointer_down_exited(event) end
               end
            end

            if control.pointer_dragged then control.pointer_dragged(event) end
            return true
         end

      elseif event.type == POINTER_CANCELLED then
         tracking = false
         pointer_inside = false
         if control.pointer_cancelled then control.pointer_cancelled() end
      end
      return false
   end -- on_event

   function control.activate()
      control.is_active = true
   end

   function control.deactivate()
      control.is_active = false
   end

   return control
end -- new

return {
   new = new,
}
