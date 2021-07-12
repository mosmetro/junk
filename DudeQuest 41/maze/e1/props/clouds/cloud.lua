local Pool = require("m.pool")
-- local layers = require("m.layers")s
local nc = require("m.notification_center")
local CONST = require("m.constants")
-- local utils = require("m.utils")

local hash = hash

local POSITION_X = hash("position.x")
local TINT_W = hash("tint.w")

local opacity_roll = fastmath.uniform_real(0.2, 0.7)
local delay_roll = fastmath.uniform_real(0.8, 1.8)
local speed_roll = fastmath.uniform_real(1, 4.2)
local lifetime_roll = fastmath.uniform_real(6, 14)

local clouds = {
   hash("cloud_a1"),
   hash("cloud_a2"),
   hash("cloud_a3"),
   hash("cloud_a4"),
   hash("cloud_a5"),
   hash("cloud_a6"),
   hash("cloud_a7"),
   hash("cloud_a8"),
}

local function make()
   local instance = {}
   local root
   local cloud_sprite
   local start_x
   local direction
   local lifetime

   local function destroy()
      go.delete(root)
   end -- destroy

   -- local function fadeout()
   --    go.animate(cloud_sprite, TINT_W, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, lifetime * 0.5)
   -- end

   function instance.init(self)
      start_x = self.start_x
      direction = self.direction
      root = msg.url(".")
      cloud_sprite = msg.url("#sprite")
      sprite.play_flipbook(cloud_sprite, fastmath.pick_next(clouds, #clouds))
      local speed = speed_roll()
      lifetime = lifetime_roll()
      local delay = delay_roll()
      local opacity = opacity_roll()
      local end_x = start_x + lifetime * speed * direction
      go.set(cloud_sprite, TINT_W, 0)
      go.animate(root, POSITION_X, go.PLAYBACK_ONCE_FORWARD, end_x, go.EASING_LINEAR, lifetime, delay, destroy)
      go.animate(cloud_sprite, TINT_W, go.PLAYBACK_ONCE_PINGPONG, opacity, go.EASING_LINEAR, lifetime, delay)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
