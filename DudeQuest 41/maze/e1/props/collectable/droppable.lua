local Pool = require("m.pool")
local RaycastController = require("m.raycast_controller")
local layers = require("m.layers")
local groups = require("m.groups")
local snd = require("sound.sound")
local nc = require("m.notification_center")
local CONST = require("m.constants")
-- local utils = require("m.utils")
local game = require("maze.game")

local DEPTH = layers.get_depth(layers.COLLECTABLE)

local hash = hash
local play_flipbook = sprite.play_flipbook
local runtime = runtime
local fastmath = fastmath
local vector3_set_xyz = fastmath.vector3_set_xyz
local set_position = go.set_position
local get_position = go.get_position
-- local animate = go.animate
-- local cancel_animations = go.cancel_animations
local delete = go.delete
local abs = fastmath.abs
local sign = fastmath.sign

local params = {
   parent_id = nil,
}

-- local TINT_W = CONST.TINT_W
local COLLECT_CURRENCY = hash("collect_currency")
local MAX_VERTICAL_SPEED = 800
local NORMAL_GRAVITY = -500 -- ~player gravity

local PUFF_FACTORY = msg.url("game:/entities#effect_small_puff")
-- local EFFECT_GET_COIN_FACTORY = msg.url("maze:/factory#effect_get_coin")

local function make()
   local instance = {
      x = 0,
      y = 0,
      needs_down_pass = false,
      needs_up_pass = false,
      needs_left_pass = false,
      needs_right_pass = false,
      update_group = runtime.UPDATE_GROUP_BEFORE_PLAYER,
      GROUND = {
         groups.SOLID,
         groups.ONEWAY,
         groups.SLOPE,
         groups.BOX,
      },
      SOLIDS = {
         groups.SLOPE,
         groups.SOLID,
         groups.BOX,
      },
      CEILING = {
         groups.SOLID,
         groups.BOX,
      },
      SLOPES = {
         groups.SLOPE,
      },
      SLOPE = groups.SLOPE,
   }

   local root
   local droppable
   local droppable_sprite
   local velocity_x
   local velocity_y
   local ground
   local vector3_stub = vmath.vector3()
   local gravity
   local collisionobject_trigger
   local is_collectable
   local value
   local puff_timer_handle
   local raycast_controller = RaycastController.new(instance)

   local function destroy()
      if puff_timer_handle then
         timer.cancel(puff_timer_handle)
      end
      game.shadow_casters[root.path] = nil
      delete(root, true)
   end -- destroy

   local function puff()
      factory.create(PUFF_FACTORY, go.get_world_position(root), CONST.IDENTITY, nil, 0.8)
      destroy()
   end -- puff

   local function move(dt)
      local dx = velocity_x * dt
      local delta_velocity_y = gravity * dt
      local old_velocity_y = velocity_y
      velocity_y = velocity_y + delta_velocity_y
      if abs(velocity_y) > MAX_VERTICAL_SPEED then
         velocity_y = MAX_VERTICAL_SPEED * sign(velocity_y)
      end
      local dy = (old_velocity_y + velocity_y) * 0.5 * dt
      return dx, dy
   end -- move

   local function advance(dx, dy)
      dx, dy, velocity_x, velocity_y, ground = raycast_controller.update(instance.x, instance.y, dx, dy, velocity_x, velocity_y)
      instance.ground = ground
      instance.x = instance.x + dx
      instance.y = instance.y + dy
      vector3_set_xyz(vector3_stub, instance.x, instance.y, 0)
      set_position(vector3_stub, root)
   end -- advance

   -- NOTE: coin can drop through platforms because its size (8) narrower than min obstacle size for platforms (12)
   local function update(dt)
      velocity_x = velocity_x * 0.99
      if ground and (velocity_y == 0) then
         runtime.remove_update_callback(instance)
         puff_timer_handle = timer.delay(10, false, puff)
         local ground_instance = runtime.get_instance(ground)
         if ground_instance and (not ground_instance.is_static) then
            params.parent_id = ground
            msg.post(root, msg.SET_PARENT, params)
         end
      elseif (not is_collectable) and (velocity_y < 0) then
         is_collectable = true
         msg.post(collisionobject_trigger, msg.ENABLE)
      end
      advance(move(dt))
   end -- update

   function instance.on_ground_contact(vy)
      if vy < -60 then
         return -vy * 0.65
      end
      return 0
   end -- instance.on_ground_contact

   function instance.on_slope_contact(vy)
      if vy < -60 then
         return -vy * 0.65
      end
      return 0
   end -- instance.on_slope_contact

   function instance.on_contact(_, _, vx)
      return -vx * 0.8
   end -- instance.on_contact

   function instance.collect_currency()
      msg.post(collisionobject_trigger, msg.DISABLE)
      -- cancel_animations(droppable_sprite, TINT_W)
      play_flipbook(droppable_sprite, COLLECT_CURRENCY, destroy)
      -- vector3_set_xyz(vector3_stub, x, y, 0)
      -- factory.create(EFFECT_GET_COIN_FACTORY, vector3_stub)
      -- snd.play_sound(snd.THIEF_KACHING)
      snd.play_sound(snd.SHANTAE_PICKUP_GEM_SMALL)
      -- destroy()
      return value
   end -- instance.collect_currency

   function instance.init(self)
      instance.shadow_edges = self.shadow_edges
      velocity_x = self.velocity_x
      velocity_y = self.velocity_y
      -- utils.log(velocity_x, velocity_y)
      value = self.value
      root = msg.url(".")
      droppable = msg.url("droppable")
      droppable_sprite = msg.url("droppable#sprite")
      collisionobject_trigger = msg.url("#collisionobject_trigger")
      msg.post(collisionobject_trigger, msg.DISABLE)
      is_collectable = false
      vector3_stub = get_position(droppable)
      fastmath.vector3_set_z(vector3_stub, DEPTH)
      set_position(vector3_stub, droppable)
      gravity = NORMAL_GRAVITY
      -- animate(droppable_sprite, TINT_W, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, 1, 11, destroy)
      -- timer.delay(10, false, puff)
      instance.x, instance.y = fastmath.vector3_get_components(get_position(root))
      raycast_controller.set_width(self.entity_width)
      raycast_controller.set_height(self.entity_height)
      puff_timer_handle = nil
      runtime.set_instance(root.path, instance)
      runtime.add_update_callback(instance, update)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      game.shadow_casters[root.path] = instance
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end

local pool = Pool.new(make)

return {
   -- cleanup = cleanup,
   new = pool.new,
   free = pool.free,
}
