local Pool = require("m.pool")
local RaycastController = require("m.raycast_controller")
local groups = require("m.groups")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")

local layers = require("pixelfrog.render.layers")
local snd = require("sound.sound")
local factories = require("pixelfrog.game.factories")

local DEPTH = layers.get_depth(layers.COLLECTABLE)

local animation_offset_roll = fastmath.uniform_real(0, 1)
local animation_properties = {
   offset = 0,
}
local play_flipbook = sprite.play_flipbook
local runtime = runtime
local fastmath = fastmath
local vector3_set_xyz = fastmath.vector3_set_xyz
local clamp = fastmath.clamp
local set_position = go.set_position
local get_position = go.get_position
local delete = go.delete

-- local params = {
--    parent_id = nil,
-- }
local MAX_VERTICAL_SPEED = 600
local NORMAL_GRAVITY = -600

local function make()
   local instance = {
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
   local velocity_x
   local velocity_y
   local x
   local y
   local ground
   local vector3_stub = fastmath.vector3_stub
   local gravity
   local collisionobject_trigger
   local is_collectable
   local is_persistent
   local kind
   local variant
   local collect_vfx
   local collect_sfx
   local bounce_sfx
   local animation
   local puff_timer_handle
   local raycast_controller = RaycastController.new(instance)

   local function destroy()
      if puff_timer_handle then
         timer.cancel(puff_timer_handle)
      end
      delete(root, true)
   end -- destroy

   local function puff()
      -- factory.create(url, position, rotation, properties, scale)
      factory.create(factories.EFFECT_SMALL_PUFF, go.get_world_position(root), const.QUAT_IDENTITY, nil, 1)
      delete(root, true)
   end -- puff

   local function move(dt)
      local dx = velocity_x * dt
      local old_velocity_y = velocity_y
      velocity_y = clamp(velocity_y + gravity * dt, -MAX_VERTICAL_SPEED, MAX_VERTICAL_SPEED)
      local dy = (old_velocity_y + velocity_y) * 0.5 * dt
      return dx, dy
   end -- move

   local function advance(dx, dy)
      dx, dy, velocity_x, velocity_y, ground = raycast_controller.update(x, y, dx, dy, velocity_x, velocity_y)
      instance.ground = ground
      x = x + dx
      y = y + dy
      vector3_set_xyz(vector3_stub, x, y, 0)
      set_position(vector3_stub, root)
   end -- advance

   -- NOTE: coin can drop through platforms because its size (8) narrower than min obstacle size for platforms (12)
   -- local function update(dt)
   --    -- factory.create("game:/game#dot", vmath.vector3(x, y, 1))
   --    velocity_x = velocity_x * 0.99
   --    if ground and (velocity_y == 0) then
   --       if not is_persistent then
   --          puff_timer_handle = timer.delay(10, false, puff)
   --       end
   --       local ground_instance = runtime.get_instance(ground)
   --       if ground_instance and ground_instance.is_static then
   --          runtime.remove_update_callback(instance)
   --       end
   --    elseif (not is_collectable) and (velocity_y < 0) then
   --       is_collectable = true
   --       msg.post(collisionobject_trigger, msg.ENABLE)
   --    end
   --    advance(move(dt))
   -- end -- update

   local function update(dt)
      -- factory.create("game:/game#dot", vmath.vector3(x, y, 1))
      velocity_x = velocity_x * 0.99
      if ground then
         if velocity_y == 0 then
            if not (is_persistent or puff_timer_handle) then
               puff_timer_handle = timer.delay(10, false, puff)
            end
            local ground_instance = runtime.get_instance(ground)
            if ground_instance and ground_instance.is_static then
               runtime.remove_update_callback(instance)
            end
         elseif (bounce_sfx ~= const.EMPTY) and (velocity_y > 0) then
            local k = velocity_y / 150
            snd.play_sound(bounce_sfx, clamp(k * k, 0.05, 1))
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

   function instance.on_collision(other_instance)
      if other_instance and other_instance.on_collect then
         if not other_instance.on_collect(kind, variant) then return end
      end
      fastmath.vector3_set_xyz(vector3_stub, x, y + 8, 0)
      factory.create(collect_vfx, vector3_stub, const.QUAT_IDENTITY, nil, 1)
      snd.play_sound(collect_sfx)
      destroy()
   end -- instance.collect_currency

   -- function instance.on_collision(other_instance)
   --    fastmath.vector3_set_xyz(vector3_stub, x, y + 8, 0)
   --    factory.create(collect_vfx, vector3_stub, const.QUAT_IDENTITY, nil, 1)
   --    snd.play_sound(collect_sfx)
   --    if other_instance and other_instance.on_collect then
   --       other_instance.on_collect(kind, amount)
   --    end
   --    destroy()
   -- end -- instance.collect_currency

   function instance.init(self)
      velocity_x = self.velocity_x
      velocity_y = self.velocity_y
      kind = self.kind
      variant = self.variant
      is_persistent = self.is_persistent
      collect_vfx = self.collect_vfx
      collect_sfx = self.collect_sfx
      bounce_sfx = self.bounce_sfx
      animation = self.animation
      root = msg.url(".")
      local pivot = msg.url("pivot")
      local pivot_sprite = msg.url("pivot#sprite")
      animation_properties.offset = animation_offset_roll()
      if animation ~= const.EMPTY then
         play_flipbook(pivot_sprite, animation, nil, animation_properties)
      end
      collisionobject_trigger = msg.url("#collisionobject_trigger")
      msg.post(collisionobject_trigger, msg.DISABLE)
      is_collectable = false
      local pos = get_position(pivot)
      fastmath.vector3_set_z(pos, DEPTH)
      set_position(pos, pivot)
      gravity = NORMAL_GRAVITY
      ground = nil
      -- animate(droppable_sprite, TINT_W, go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, 1, 11, destroy)
      -- timer.delay(10, false, puff)
      x, y = fastmath.vector3_get_components(get_position(root))
      raycast_controller.set_width(self.entity_width)
      raycast_controller.set_height(self.entity_height)
      puff_timer_handle = nil
      runtime.set_instance(root.path, instance)
      runtime.add_update_callback(instance, update)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   return instance
end

local pool = Pool.new(make)

return {
   -- cleanup = cleanup,
   new = pool.new,
   free = pool.free,
}
