local Pool = require("m.pool")
-- local utils = require("m.utils")

local function make()
   local fire_fx
   local instance = {}

   function instance.init()
      fire_fx = msg.url("#sconce_fire")
      go.set("shadow#sprite1", "tint.w", 0.33)
      particlefx.play(fire_fx)
   end -- instance.init

   function instance.deinit()
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

-- export
return {
   new = pool.new,
   free = pool.free,
}
