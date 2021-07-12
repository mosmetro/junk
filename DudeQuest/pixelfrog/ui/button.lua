local ButtonBase = require("m.ui.button_base")
-- local utils = require("m.utils")

local snd = require("sound.sound")

local fastmath = fastmath
local gui = gui
local play_flipbook = gui.play_flipbook

local function update_aabb(control)
   local x, y = fastmath.get_absolute_node_position(control.node)
   local w, h = fastmath.vector3_get_xy(gui.get_size(control.node))
   w = w * 0.5 + (control.margin_horizontal or 4)
   local h_up = h * 0.5 + (control.margin_up or 2)
   local h_down = h * 0.5 + (control.margin_down or 10)
   control.aabb = { x - w, y - h_down, x + w, y + h_up }
end -- update_aabb

local function new(control)
   if not control.aabb then
      update_aabb(control)
   end

   function control.press()
      if control.selected_pressed_animation then
         play_flipbook(control.node, control.is_on() and control.selected_pressed_animation or control.pressed_animation)
      else
         play_flipbook(control.node, control.pressed_animation)
      end
      if control.on_press then control.on_press() end
   end -- control.press

   function control.release(inside)
      if control.selected_released_animation then
         play_flipbook(control.node, control.is_on() and control.selected_released_animation or control.released_animation)
      else
         play_flipbook(control.node, control.released_animation)
      end
      if inside then
         snd.play_sound(snd.BUTTON_CLICK)
      end
   end -- control.release

   function control.show()
      gui.set_enabled(control.node, true)
      -- control.enable()
   end -- control.show

   function control.hide()
      gui.set_enabled(control.node, false)
      -- control.disable()
   end -- control.hide

   function control.enable()
      update_aabb(control)
      control.activate()
      play_flipbook(control.node,
      (control.is_on() and control.selected_released_animation) and control.selected_released_animation or control.released_animation)
   end -- control.enable

   function control.disable()
      control.deactivate()
      -- if control.selected_disabled_animation then
      --    play_flipbook(control.node, control.is_on() and control.selected_disabled_animation or (control.disabled_animation or control.released_animation))
      -- else
      --    play_flipbook(control.node, (control.disabled_animation or control.released_animation))
      -- end
      if control.disabled_animation then
         play_flipbook(control.node, control.disabled_animation)
      end
   end -- control.disable

   ButtonBase.new(control)
   control.release(false)
   return control
end -- new

return {
   new = new,
}
