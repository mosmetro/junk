local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
local debug_draw = require("m.debug_draw")
-- local utils = require("m.utils")

local game = require("pixelfrog.game.game")

local aabb_overlap = fastmath.aabb_overlap

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_FIRST,
   }
   local root
   local name
   local aabb = { 0, 0, 0, 0 }
   local visible

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function update()
      if aabb_overlap(game.view_aabb, aabb) then
         if not visible then
            -- utils.log("activate")
            visible = true
            nc.post_notification(const.ACTIVATE_NOTIFICATION, name)
         end
      else
         if visible then
            -- utils.log("deactivate")
            visible = false
            nc.post_notification(const.DEACTIVATE_NOTIFICATION, name)
         end
      end
      debug_draw.aabb(aabb)
   end

   function instance.init(self)
      name = self.name
      aabb[1] = self.min_x
      aabb[2] = self.min_y
      aabb[3] = self.max_x
      aabb[4] = self.max_y
      root = msg.url(".")
      visible = false
      runtime.add_update_callback(instance, update)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

-- export
return {
   new = pool.new,
   free = pool.free,
}
