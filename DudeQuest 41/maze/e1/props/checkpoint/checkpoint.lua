local Pool = require("m.pool")
local layers = require("m.layers")
local nc = require("m.notification_center")
local CONST = require("m.constants")
local snd = require("sound.sound")
local game = require("maze.game")
-- local utils = require("m.utils")

local go = go
local fastmath = fastmath

local DEPTH = layers.get_depth(layers.PROPS_BACK)

local vector3_stub
local TINT_W = hash("tint.w")

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_AFTER_PLAYER,
      x = 0,
      y = 0,
      is_checkpoint = true,
      map = 0,
      location = 0,
   }
   local checkpoint
   local root
   local eyes_sprite
   local glow_sprite
   local collisionobject_hitbox
   -- local player

   local function destroy()
      go.delete(root, true)
   end -- destroy

   -- local function update()
   --    local player_instance = runtime.get_instance(player)
   --    if player_instance then
   --       local delta = fastmath.abs(instance.x - player_instance.x)
   --       go.set(eyes_sprite, TINT_W, 1 - fastmath.clamp(delta / 40, 0, 1))
   --    end
   -- end -- update

   function instance.accepts_first_responder(other_instance)
      -- player = other_id
      return fastmath.abs(instance.y - other_instance.y) < 16
      -- return fastmath.combined_is_equal(instance.y, other_instance.y)
   end -- accepts_first_responder

   function instance.become_first_responder()
      go.animate(eyes_sprite, TINT_W, go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_OUTQUAD, 0.75)
      -- runtime.add_update_callback(instance, update)
   end -- become_first_responder

   function instance.resign_first_responder()
      go.animate(eyes_sprite, TINT_W, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_INQUAD, 0.75)
      -- player = nil
      -- runtime.remove_update_callback(instance)
   end -- resign_first_responder

   function instance.get_spawn_position()
      return instance.x, instance.y
   end -- instance.get_spawn_position

   local function glow_complete()
      msg.post(collisionobject_hitbox, msg.ENABLE)
   end -- glow_complete

   function instance.on_hit()
      game.set(nil, game.checkpoint, "rest_counter", game.get(nil, game.checkpoint, "rest_counter", 0) + 1)
      game.set(nil, game.player, "last_checkpoint", { map = game[instance.map], location = game[instance.location] }) -- we write strings in save files
      msg.post(collisionobject_hitbox, msg.DISABLE)
      go.set(glow_sprite, TINT_W, 1)
      go.animate(glow_sprite, TINT_W, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_OUTQUAD, 2.4, 0, glow_complete)
      snd.play_sound(snd.THIEF_BELL)
      nc.post_notification(CONST.CAMERA_SHAKE_REQUEST_NOTIFICATION, nil, 1, 2.2)
   end -- instance.on_hit

   function instance.init(self)
      instance.map = self.map
      instance.location = self.location
      root = msg.url("root")
      checkpoint = msg.url("checkpoint")
      eyes_sprite = msg.url("checkpoint#eyes")
      glow_sprite = msg.url("checkpoint#glow")
      collisionobject_hitbox = msg.url("#collisionobject_hitbox")
      instance.x, instance.y = fastmath.vector3_get_components(go.get_position())
      vector3_stub = go.get_position(checkpoint)
      fastmath.vector3_set_z(vector3_stub, DEPTH)
      go.set_position(vector3_stub, checkpoint)
      go.set(eyes_sprite, TINT_W, 0)
      go.set(glow_sprite, TINT_W, 0)
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      runtime.set_instance(root.path, nil)
      -- runtime.remove_update_callback(instance)
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
