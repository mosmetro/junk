local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
local animation = require("m.animation")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local game = require("pixelfrog.game.game")

local DEPTH = layers.get_depth(layers.PROPS)

local vector3_stub = fastmath.vector3_stub
local play_animation = animation.play

local CHECKPOINT_NO_FLAG = {
   { id = hash("checkpoint_no_flag"), position = vmath.vector3(0, -20, 0), },
}
local CHECKPOINT_FLAG_OUT = {
   { id = hash("checkpoint_flag_out"), position = vmath.vector3(9, -20, 0), },
}
local CHECKPOINT_FLAG_IDLE = {
   { id = hash("checkpoint_flag_idle"), position = vmath.vector3(10, -20, 0), },
}

local function make()
   local instance = {
      x = 0,
      y = 0,
      map = 0,
      location = 0,
   }
   local root
   local collisionobject

   local checkpoint = animation.new_target()

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function on_complete()
      play_animation(checkpoint, CHECKPOINT_FLAG_IDLE)
   end -- on_complete

   function instance.on_collision(other_instance)
      play_animation(checkpoint, CHECKPOINT_FLAG_OUT, nil, on_complete)
      msg.post(collisionobject, msg.DISABLE)
      -- we write strings in save files
      game.set(nil, game.player, "last_checkpoint", { map = game[instance.map], location = game[instance.location] })
      game.set(instance.map, instance.location, "is_reached", true)
      if other_instance and other_instance.on_checkpoint then
         other_instance.on_checkpoint(instance)
      end
   end -- instance.on_hit

   function instance.init(self)
      instance.map = self.map
      instance.location = self.location
      root = msg.url(".")
      collisionobject = msg.url("#collisionobject")
      checkpoint.pivot = msg.url("pivot")
      checkpoint.anchor = msg.url("anchor")
      checkpoint.sprite = msg.url("anchor#sprite")
      checkpoint.current_animation_group = nil
      checkpoint.current_animation = nil
      checkpoint.on_complete = nil
      instance.x, instance.y = fastmath.vector3_get_components(go.get_position(root))
      fastmath.vector3_set_xyz(vector3_stub, 0, 0, DEPTH)
      go.set_position(vector3_stub, checkpoint.pivot)
      local is_reached = game.get(instance.map, instance.location, "is_reached", false)
      if is_reached then
         play_animation(checkpoint, CHECKPOINT_FLAG_IDLE)
         msg.post(collisionobject, msg.DISABLE)
      else
         play_animation(checkpoint, CHECKPOINT_NO_FLAG)
         msg.post(collisionobject, msg.ENABLE)
      end
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
