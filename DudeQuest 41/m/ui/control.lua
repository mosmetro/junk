local ui = require("m.ui.ui")
-- local debug_draw = require("m.debug_draw")
-- local utils = require("m.utils")

local gui = gui
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
   return gui.is_enabled(node)
end -- check_enabled

local function new(control)
   local is_active = true
   local tracking = false
   local pointer_inside = false
   local aabb = { 0, 0, 0, 0 }

   local function update_aabb()
      local x, y = fastmath.get_absolute_node_position(control.node)
      aabb[1] = x + control.aabb[1]
      aabb[2] = y + control.aabb[2]
      aabb[3] = x + control.aabb[3]
      aabb[4] = y + control.aabb[4]
   end -- update_aabb

   function control.hit_test(x, y)
      update_aabb()
      -- debug_draw.aabb(aabb)
      return check_enabled(control.node) and aabb_contains_point(aabb, x, y) or false
   end -- hit_test

   function control.on_event(event)
      if not is_active then
         return false
      end

      if event.type == POINTER_DOWN then
         if control.hit_test(event.x, event.y) then
            tracking = true
            pointer_inside = true
            if control.pointer_down_entered then
               control.pointer_down_entered(event)
            end
            return true
         end

      elseif event.type == POINTER_UP then
         if tracking then
            if pointer_inside then
               if control.pointer_up_inside then
                  control.pointer_up_inside(event)
               end
            else
               if control.pointer_up_outside then
                  control.pointer_up_outside(event)
               end
            end
            tracking = false
            pointer_inside = false
            return true
         end

      elseif event.type == POINTER_DRAGGED then
         if tracking then
            if control.hit_test(event.x, event.y) then
               if not pointer_inside then
                  pointer_inside = true
                  if control.pointer_down_entered then
                     control.pointer_down_entered(event)
                  end
               end
            else
               if pointer_inside then
                  pointer_inside = false
                  if control.pointer_down_exited then
                     control.pointer_down_exited(event)
                  end
               end
            end

            if control.pointer_dragged then
               control.pointer_dragged(event)
            end
            return true
         end

      elseif event.type == POINTER_CANCELLED then
         tracking = false
         pointer_inside = false
         if control.pointer_cancelled then
            control.pointer_cancelled()
         end
      end
      return false
   end -- on_event

   function control.activate(callback)
      is_active = true
      if callback then
         control.callback = callback
      end
   end -- control.activate

   function control.deactivate()
      is_active = false
   end -- control.deactivate

   function control.enable(animated)
      is_active = true
      if control.on_enable then
         control.on_enable(animated)
      end
   end -- control.enable

   function control.disable(animated)
      is_active = false
      if control.on_disable then
         control.on_disable(animated)
      end
   end -- control.disable

   return control
end -- new

return {
   new = new,
}
