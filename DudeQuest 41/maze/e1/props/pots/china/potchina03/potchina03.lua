local Pool = require("m.pool")
local StateMachine = require("m.state_machine")
local layers = require("m.layers")
local snd = require("sound.sound")
local nc = require("m.notification_center")
local CONST = require("m.constants")
local game = require("maze.game")
local utils = require("m.utils")

local go = go
local sprite = sprite
local hash = hash
local fastmath = fastmath

local DEPTH = layers.get_depth(layers.POTS)

local debris_roll = fastmath.uniform_int(3, 5)
local loot_velocity_x_roll = fastmath.uniform_int(-50, 50)
local loot_velocity_y_roll = fastmath.uniform_int(160, 190)
local rat_roll = fastmath.bernoulli(1)
local vector3_stub

local ROOT = hash("/root")
local SCALE = hash("scale")
local IDENTITY = vmath.quat()
local IMPACT = hash("potchina03_impact")
local INTACT = hash("potchina03_1")
local SHATTERED = hash("potchina03_2")
local POTCHINA_DEBRIS_FACTORIES = {
   msg.url("game:/entities#potchina_debris1"),
   msg.url("game:/entities#potchina_debris2"),
   msg.url("game:/entities#potchina_debris3"),
   msg.url("game:/entities#potchina_debris4"),
}
local RAT_FACTORY = msg.url("game:/entities#rat")
local POTCHINA_LOOT_FACTORIES = {
   msg.url("game:/entities#coin"),
}
local EFFECT_CIRCLE1_FACTORY = msg.url("game:/entities#effect_circle1")

local params = {
   [ROOT] = {
      velocity_x = 0,
      velocity_y = -1,
   },
}
-- local HIT_LEFT = 6

-- prevents engine sending unwanted message (animation_done)
local function message_sink()
   -- utils.log("unwanted message")
end -- message_sink

local function make()
   local instance =  {}
   local name
   local root
   local pot
   local pot_sprite
   local collisionobject_hitbox
   -- local eject_position
   local debris_count
   local platform
   local rat_inside
   local machine = StateMachine.new(instance, nil)

   -- states
   local intact = {}
   local shattered = {}

   ---------------------------------------
   -- intact
   ---------------------------------------

   function intact.on_enter()
      msg.post(collisionobject_hitbox, msg.ENABLE)
      debris_count = debris_roll()
      -- eject_position = go.get_position(root)
      -- local y = fastmath.vector3_get_y(eject_position)
      -- fastmath.vector3_set_y(eject_position, y + 3)
      sprite.play_flipbook(pot_sprite, INTACT, message_sink)
   end -- intact.on_enter

   ---------------------------------------
   -- shattered
   ---------------------------------------

   function shattered.on_enter(previous_state)
      if previous_state == intact then
         game.set(game.map, name, "shattered", game.get(nil, game.checkpoint, "rest_counter", 0))
         sprite.play_flipbook(pot_sprite, IMPACT, message_sink)
         go.set(pot, SCALE, 1.2)
         go.animate(pot, SCALE, go.PLAYBACK_ONCE_FORWARD, 1.0, go.EASING_INQUAD, 0.25)
         snd.play_sound(snd.SHANTAE_CLAY_JUG_SHATTER_LARGE)
         local eject_position = go.get_world_position(root)
         local y = fastmath.vector3_get_y(eject_position)
         fastmath.vector3_set_y(eject_position, y + 3)
         for _ = 1, debris_count do
            collectionfactory.create(fastmath.pick_next(POTCHINA_DEBRIS_FACTORIES, #POTCHINA_DEBRIS_FACTORIES), eject_position, IDENTITY, nil, 1)
         end
         local loot_factory
         if rat_inside and rat_roll() then
            params[ROOT].velocity_x = 0
            params[ROOT].velocity_y = 130
            loot_factory = RAT_FACTORY
         else
            params[ROOT].velocity_x = loot_velocity_x_roll()
            params[ROOT].velocity_y = loot_velocity_y_roll()
            loot_factory = POTCHINA_LOOT_FACTORIES[1]
         end
         collectionfactory.create(loot_factory, eject_position, IDENTITY, params, 1)
         factory.create(EFFECT_CIRCLE1_FACTORY, eject_position, IDENTITY)
      else
         sprite.play_flipbook(pot_sprite, SHATTERED, message_sink)
      end
      msg.post(collisionobject_hitbox, msg.DISABLE)
   end -- shattered.on_enter

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function platform_ready(_, _, parent)
      -- utils.log("setting parent")
      go.set_parent(root, parent, true)
   end -- platform_ready

   function instance.on_hit()
      -- utils.log("HIT!")
      nc.post_notification(CONST.CAMERA_SHAKE_REQUEST_NOTIFICATION, nil, 3, 0.25)
      machine.enter_state(shattered)
   end -- instance.on_hit

   function instance.on_roll_over()
      -- utils.log("ROLL!")
      instance.on_hit()
   end -- instance.on_roll_over

   function instance.init(self)
      name = self.name
      rat_inside = self.rat_inside
      platform = self.platform
      root = msg.url(".")
      pot = msg.url("pot")
      pot_sprite = msg.url("pot#sprite")
      collisionobject_hitbox = msg.url("#collisionobject_hitbox")
      vector3_stub = go.get_position(pot)
      fastmath.vector3_set_z(vector3_stub, DEPTH)
      go.set_position(vector3_stub, pot)
      machine.reset()
      runtime.set_instance(root.path, instance)
      if game.get(game.map, name, "shattered", -1) < game.get(nil, game.checkpoint, "rest_counter", 0) then
         machine.enter_state(intact)
      else
         machine.enter_state(shattered)
      end
      nc.add_observer(platform_ready, CONST.PLATFORM_READY_NOTIFICATION, platform)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      -- nc.add_observer(post_init, CONST.POST_INIT_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.remove_observer(platform_ready, CONST.PLATFORM_READY_NOTIFICATION, platform)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
