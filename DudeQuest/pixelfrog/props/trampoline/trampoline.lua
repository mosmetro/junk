local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local snd = require("sound.sound")

local DEPTH = layers.get_depth(layers.PROPS)

local vector3_stub = fastmath.vector3_stub

local IDLE = hash("trampoline_idle")
local JUMP = hash("trampoline_jump")

local function make()
   local instance = {}
   local root
   local anchor_sprite

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function on_complete()
      sprite.play_flipbook(anchor_sprite, IDLE)
   end -- on_complete

   -- function instance.on_hit()
   --    sprite.play_flipbook(anchor_sprite, JUMP, on_complete)
   --    snd.play_sound(snd.TRAMPOLINE_JUMP)
   --    -- TODO: this needs to be adjusted
   --    return 1000
   -- end -- instance.on_hit

   function instance.on_jump()
      sprite.play_flipbook(anchor_sprite, JUMP, on_complete)
      snd.play_sound(snd.TRAMPOLINE_JUMP)
      return 1000
   end -- instance.on_jump

   function instance.init()
      root = msg.url(".")
      anchor_sprite = msg.url("anchor#sprite")
      vector3_stub = go.get_position("anchor")
      fastmath.vector3_set_z(vector3_stub, DEPTH)
      go.set_position(vector3_stub, "anchor")
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
