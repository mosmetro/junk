local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
local utils = require("m.utils")

local gamestate = require("game.gamestate")
local global = require("game.global")
local translations = require("game.translations")
-- local snd = require("sound.sound")

local sys = sys

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_FIRST,
   }
   local root

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function on_level_will_appear()
      runtime.execute_in_context(global.single_touch_controls_context.enable, global.single_touch_controls_context)
      runtime.execute_in_context(global.home_context.enable, global.home_context)
   end -- on_level_will_appear

   function instance.init()
      root = msg.url(".")
      local filename = sys.get_save_file(gamestate.get_app_id(), "meta")
      local meta = sys.load(filename)
      local current_slot = meta.current_slot
      if current_slot and gamestate.slot_exists(current_slot) then
         gamestate.set_save_slot(current_slot)
      else
         gamestate.set_save_slot(1)
      end
      local default_lang = sys.get_sys_info().device_language:sub(1, 2)
      translations.set_language(gamestate.get(nil, gamestate.player, "language", default_lang))
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.add_observer(on_level_will_appear, const.LEVEL_WILL_APPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.remove_observer(on_level_will_appear, const.LEVEL_WILL_APPEAR_NOTIFICATION)
   end -- instance.final

   return instance
end -- make

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
