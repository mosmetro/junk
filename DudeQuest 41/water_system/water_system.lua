local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")

local global = require("game.global")
local game = require("maze.game")

local function make()
	local instance = {
		update_group = runtime.UPDATE_GROUP_LAST,
      x = 0,
      y = 0,
	}

   local url_root
   local res_water
   local buf_water
   local p
   local stream_texcoord0

   local function destroy()
      go.delete(url_root, true)
   end -- destroy

   local function update()
      local h = game.view_height
      local pos = go.get_position(url_root)
      local water_level = fastmath.clamp(pos.y - (global.view_y or 0) + game.view_half_height, 0, h)
      global.draw_water = water_level > 0
      if global.draw_water then
         local t = 2 / h * water_level
         local y1 = t - 1
         -- local y2 = y1 - (2 - t)
         p[1] = -1; p[2] = y1; p[3] = 1; p[4] = y1
         p[5] = -1; p[6] = y1 - 1; p[7] = 1; p[8] = y1 - 1

         local texture_coord_y = water_level / h
         global.water_level = texture_coord_y
         stream_texcoord0[1] = 0; stream_texcoord0[2] = texture_coord_y; stream_texcoord0[3] = 1; stream_texcoord0[4] = texture_coord_y
         stream_texcoord0[5] = 0; stream_texcoord0[6] = texture_coord_y + 1; stream_texcoord0[7] = 1; stream_texcoord0[8] = texture_coord_y + 1
         resource.set_buffer(res_water, buf_water)
         -- utils.log(water_level, texture_coord_y, vertex_coord_y)
      end
   end -- update

	function instance.init()
      url_root = msg.url(".")
      instance.x, instance.y = fastmath.vector3_get_xy(go.get_position(url_root))
      go.animate(url_root, "position.y", go.PLAYBACK_LOOP_PINGPONG, instance.y + 2, go.EASING_INOUTSINE, 4)
      runtime.add_update_callback(instance, update)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      res_water = go.get("#mesh", "vertices")
      buf_water = resource.get_buffer(res_water)
      p = buffer.get_stream(buf_water, "position")
      stream_texcoord0 = buffer.get_stream(buf_water, "texcoord0")
	end -- instance.init

	function instance.deinit()
      runtime.remove_update_callback(instance)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
	end -- instance.final

	return instance
end -- make

local pool = Pool.new(make)

return {
	new = pool.new,
	free = pool.free,
}
