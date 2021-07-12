local Queue = require("m.queue")

local global = {
   draw_water = false,

   DEFAULT_SOUND_VOLUME = 100,
   DEFAULT_MUSIC_VOLUME = 100,

   view_aabb = { 0, 0, 0, 0 },
   view_x = 0,
   view_y = 0,

   shadow_casters = {},

   hud_back_stack = Queue.new(),

   start_checkpoint = { map = "e1m4", location = "/checkpoint/root", },
}

return global
