local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
local animation = require("m.animation")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local gamestate = require("pixelfrog.game.gamestate")
local snd = require("sound.sound")
local loot_distributor = require("pixelfrog.props.collectable.loot_distributor")
local factories = require("pixelfrog.game.factories")

local DEPTH = layers.get_depth(layers.PROPS)

local vector3_stub = fastmath.vector3_stub
local play_animation = animation.play
local runtime = runtime
local animate = go.animate

-- local HIT_SOUNDS = {
--    snd.FATE_SLICE_FLESH_1,
--    snd.FATE_SLICE_FLESH_2,
--    snd.FATE_SLICE_FLESH_3,
-- }

local ANIMATION = {
   CLOSED = {
      { id = hash("chest_gold_closed"), position = vmath.vector3(6, 12, 0), },
   },
   OPEN = {
      { id = hash("chest_gold_open"), position = vmath.vector3(6, 12, 0), },
   },
   OPENED = {
      { id = hash("chest_gold_opened"), position = vmath.vector3(6, 12, 0), },
   },
}

local chests = {
   [gamestate.chest_gold] = 1,
   [gamestate.chest_iron] = 2,
}

local pre = vmath.vector3(1.1, 0.9, 1)
local post = vmath.vector3(0.9, 1.2, 1)

local function make()
   local instance = {}
   local root
   local name
   local kind
   local collisionobject
   local char = animation.new_target()
   local loot_count
   local root_position

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local on_open_complete

   local function on_complete()
      if loot_count > 0 then
         loot_count = loot_count - 1
         animate(char.pivot, const.SCALE, go.PLAYBACK_ONCE_FORWARD, post, go.EASING_LINEAR, 0.07, 0, on_open_complete)
         loot_distributor.drop(fastmath.coin_toss() and factories.COIN_GOLD or fastmath.pick_any(factories.GEMS), root_position)
         -- snd.play_sound(snd.POP_SOUNDS_8)
      else
         animate(char.pivot, const.SCALE, go.PLAYBACK_ONCE_FORWARD, const.VECTOR3_ONE, go.EASING_LINEAR, 0.07, 0, animation.done_sink)
      end
   end -- on_complete

   function on_open_complete()
      -- go.animate(url, property, playback, to, easing, duration, delay, complete_function)
      animate(char.pivot, const.SCALE, go.PLAYBACK_ONCE_FORWARD, pre, go.EASING_LINEAR, 0.08, 0, on_complete)
   end -- on_open_complete

   function instance.on_hit()
      msg.post(collisionobject, msg.DISABLE)
      snd.play_sound(snd.MAGICAL_CHEST_OPENING_2)
      nc.post_notification(const.CAMERA_SHAKE_REQUEST_NOTIFICATION, nil, 3, 0.25)
      play_animation(char, ANIMATION.OPEN, kind, on_open_complete)
      gamestate.set(gamestate.map, name, "opened", true)
   end -- instance.on_hit

   function instance.on_jump(sfx, dp, speed)
      instance.on_hit(sfx, dp, speed)
      return 150 -- recoil velocity
   end -- instance.on_jump

   function instance.init(self)
      name = self.name
      root = msg.url(".")
      kind = chests[name]
      root_position = go.get_position(root)
      char.pivot = msg.url("pivot")
      char.anchor = msg.url("anchor")
      char.sprite = msg.url("anchor#sprite")
      char.current_animation_group = nil
      char.current_animation = nil
      char.on_complete = nil
      collisionobject = msg.url("#collisionobject")
      fastmath.vector3_set_xyz(vector3_stub, 0, 0, DEPTH)
      go.set_position(vector3_stub, char.pivot)
      runtime.set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      if self.direction < 0 then
         go.set(char.pivot, const.ROTATION, const.QUAT_Y_180)
      end
      if gamestate.get(gamestate.map, name, "opened", false) then
         msg.post(collisionobject, msg.DISABLE)
         play_animation(char, ANIMATION.OPENED, kind)
      end
      loot_count = 10
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
