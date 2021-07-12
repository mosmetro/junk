local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
local animation = require("m.animation")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
-- local gamestate = require("pixelfrog.game.gamestate")
local snd = require("sound.sound")

local DEPTH = layers.get_depth(layers.PROPS)

local vector3_stub = fastmath.vector3_stub
local play_animation = animation.play
local runtime = runtime

local ANIMATION = {
   HIDDEN = {
      { id = hash("spikes_hidden16"), position = vmath.vector3(8, 2, 0), },
      { id = hash("spikes_hidden32"), position = vmath.vector3(16, 2, 0), },
      { id = hash("spikes_hidden48"), position = vmath.vector3(24, 2, 0), },
      { id = hash("spikes_hidden64"), position = vmath.vector3(32, 2, 0), },
   },
   APPEARING = {
      { id = hash("spikes_appearing16"), position = vmath.vector3(8, 8, 0), },
      { id = hash("spikes_appearing32"), position = vmath.vector3(16, 8, 0), },
      { id = hash("spikes_appearing48"), position = vmath.vector3(24, 8, 0), },
      { id = hash("spikes_appearing64"), position = vmath.vector3(32, 8, 0), },
   },
   READY = {
      { id = hash("spikes_ready16"), position = vmath.vector3(8, 7, 0), },
      { id = hash("spikes_ready32"), position = vmath.vector3(16, 7, 0), },
      { id = hash("spikes_ready48"), position = vmath.vector3(24, 7, 0), },
      { id = hash("spikes_ready64"), position = vmath.vector3(32, 7, 0), },
   },
   WILL_DISAPPEAR = {
      { id = hash("spikes_will_disappear16"), position = vmath.vector3(8, 7, 0), },
      { id = hash("spikes_will_disappear32"), position = vmath.vector3(16, 7, 0), },
      { id = hash("spikes_will_disappear48"), position = vmath.vector3(24, 7, 0), },
      { id = hash("spikes_will_disappear64"), position = vmath.vector3(32, 7, 0), },
   },
   DISAPPEARING = {
      { id = hash("spikes_disappearing16"), position = vmath.vector3(8, 7, 0), },
      { id = hash("spikes_disappearing32"), position = vmath.vector3(16, 7, 0), },
      { id = hash("spikes_disappearing48"), position = vmath.vector3(24, 7, 0), },
      { id = hash("spikes_disappearing64"), position = vmath.vector3(32, 7, 0), },
   },
   STATIC = {
      { id = hash("spikes_static16"), position = vmath.vector3(8, 7, 0), },
      { id = hash("spikes_static32"), position = vmath.vector3(16, 7, 0), },
      { id = hash("spikes_static48"), position = vmath.vector3(24, 7, 0), },
      { id = hash("spikes_static64"), position = vmath.vector3(32, 7, 0), },
   },
}

local function make()
   local instance = {}
   local root
   local collisionobject
   local char = animation.new_target()
   local damage_points
   local kind

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local hidden_complete

   local function disappearing_complete()
      play_animation(char, ANIMATION.HIDDEN, kind, hidden_complete)
   end -- disappearing_complete

   local function will_disappear_complete()
      msg.post(collisionobject, msg.DISABLE)
      play_animation(char, ANIMATION.DISAPPEARING, kind, disappearing_complete)
   end -- will_disappear_complete

   local function ready_complete()
      -- utils.log(socket.gettime() - t1)
      play_animation(char, ANIMATION.WILL_DISAPPEAR, kind, will_disappear_complete)
   end -- ready_complete
   -- local t1
   local function appearing_complete()
      -- t1 = socket.gettime()
      play_animation(char, ANIMATION.READY, kind, ready_complete)
   end -- appearing_complete

   function hidden_complete()
      msg.post(collisionobject, msg.ENABLE)
      play_animation(char, ANIMATION.APPEARING, kind, appearing_complete)
   end -- hidden_complete

   function instance.on_collision(other_instance)
      if other_instance and other_instance.on_hit then
         other_instance.on_hit(snd.SHANTAE_GETHIT, damage_points, 0)
      end
   end -- instance.on_collision

   function instance.init(self)
      damage_points = self.damage_points
      root = msg.url(".")
      kind = self.kind / 16
      char.pivot = msg.url("pivot")
      char.anchor = msg.url("anchor")
      char.sprite = msg.url("anchor#sprite")
      char.current_animation_group = nil
      char.current_animation = nil
      char.on_complete = nil
      if not self.is_static then
         collisionobject = msg.url("#collisionobject")
         msg.post(collisionobject, msg.DISABLE)
         play_animation(char, ANIMATION.HIDDEN, kind, hidden_complete)
      else
         play_animation(char, ANIMATION.STATIC, kind)
      end
      fastmath.vector3_set_xyz(vector3_stub, 0, 0, DEPTH)
      go.set_position(vector3_stub, char.pivot)
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
