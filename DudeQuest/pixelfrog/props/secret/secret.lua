local Pool = require("m.pool")
local const = require("m.constants")
local nc = require("m.notification_center")
local utils = require("m.utils")

-- local gamestate = require("pixelfrog.game.gamestate")

local function make()
   local instance = {
   }

   local root
   local cover

   local function destroy()
      go.delete(root, true)
   end -- destroy

   function instance.on_enter()
      -- utils.log("enter secret")
      -- go.animate(url,property,playback,to,easing,duration,[delay],[complete_function])
      go.animate(cover, const.TINT_W, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_INOUTQUAD, 0.5)
   end -- instance.on_enter

   function instance.on_exit()
      -- utils.log("exit secret")
      go.animate(cover, const.TINT_W, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_INOUTQUAD, 0.5)
   end -- instance.on_enter

   function instance.init()
      root = msg.url(".")
      cover = msg.url("#cover")
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      runtime.set_instance(root.path, nil)
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
