-- import
local Pool = require("m.pool")
local RaycastController = require("m.raycast_controller")
local StateMachine = require("m.state_machine")
local groups = require("m.groups")
local utils = require("m.utils")
local nc = require("m.notification_center")
local CONST = require("m.constants")
local game = require("maze.game")
local debug_draw = require("m.debug_draw")

local global = require("game.global")

-- localization
local runtime = runtime
local vector3_set_components = fastmath.vector3_set_components
local set_position = go.set_position
local abs = fastmath.abs
local sign = fastmath.sign

local MAX_VERTICAL_SPEED = 300

local function make()
   local instance = {
      dx = 0,
      dy = 0,
      needs_down_pass = false,
      needs_up_pass = false,
      needs_left_pass = false,
      needs_right_pass = false,
      update_group = runtime.UPDATE_GROUP_MOVABLE_OBJECTS,
      can_push = false,
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
         groups.ENTITY,
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
   local aabb = { 0, 0, 0, 0 }
   local name
   local root
   local vector3_stub
   local position_x
   local position_y
   local velocity_x
   local velocity_y
   local gravity
   local recoil_velocity
   local ground
   local max_horizontal_speed
   local one_shot
   local trigger
   local debug_label

   local RECOIL_VELOCITY_MAX

   local ready = {}
   local fall = {}
   local idle = {}
   local await = {}
   local rise = {}

   local raycast_controller = RaycastController.new(instance)
   local machine = StateMachine.new(instance, nil)

   local post_init
   function post_init()
      nc.remove_observer(post_init, CONST.POST_INIT_NOTIFICATION)
      nc.post_notification(CONST.PLATFORM_READY_NOTIFICATION, name, instance, root) -- for something parented with me
   end -- post_init

   local function destroy()
      go.delete(root, true)
   end -- destroy

   local function move(dt)
      local old_velocity_y = velocity_y
      velocity_y = velocity_y + gravity * dt
      if abs(velocity_y) > MAX_VERTICAL_SPEED then
         velocity_y = MAX_VERTICAL_SPEED * sign(velocity_y)
      end
      local dy = (old_velocity_y + velocity_y) * 0.5 * dt
      return 0, dy
   end -- move

   local function advance(dx, dy, my_ground)
      dx, dy, velocity_x, velocity_y, ground = raycast_controller.update(position_x, position_y, dx, dy, velocity_x, velocity_y, my_ground)
      position_x = position_x + dx
      position_y = position_y + dy
      vector3_set_components(vector3_stub, position_x, position_y, 0)
      set_position(vector3_stub, root)
      instance.dx = dx
      instance.dy = dy
      return dx, dy
   end -- advance

   local function update_aabb()
      aabb[1] = position_x - 32
      aabb[2] = position_y - 32
      aabb[3] = position_x + 32
      aabb[4] = position_y + 32
      debug_draw.aabb(aabb)
   end -- update_aabb

   ---------------------------------------
   -- ready
   ---------------------------------------

   local function on_trigger_enter()
      machine.enter_state(fall)
   end -- on_trigger_enter

   function ready.on_enter()
      label.set_text(debug_label, "Ready")
      nc.add_observer(on_trigger_enter, CONST.TRIGGER_ENTER_NOTIFICATION, trigger)
   end -- ready.on_enter

   function ready.on_exit()
      nc.remove_observer(on_trigger_enter, CONST.TRIGGER_ENTER_NOTIFICATION, trigger)
   end

   ---------------------------------------
   -- fall
   ---------------------------------------

   function fall.on_enter()
      label.set_text(debug_label, "Fall")
      recoil_velocity = RECOIL_VELOCITY_MAX
   end -- fall.on_enter

   function fall.update(dt)
      if ground then
         velocity_y = recoil_velocity
         recoil_velocity = recoil_velocity * 0.6
      end
      if recoil_velocity < 30 then
         if one_shot then
            machine.enter_state(idle)
         else
            machine.enter_state(await)
         end
         return
      end
      advance(move(dt))
   end -- fall.update

   ---------------------------------------
   -- idle
   ---------------------------------------

   function idle.on_enter()
      label.set_text(debug_label, "Idle")
      update_aabb()
   end -- idle.on_enter

   function idle.update(dt)
      if not fastmath.aabb_overlap(global.view_aabb, aabb) then
         local inst = runtime.get_instance(ground)
         if inst and inst.aabb then
            if not fastmath.aabb_overlap(global.view_aabb, inst.aabb) then
               return
            end
         else
            return
         end
      end
      advance(move(dt))
      update_aabb()
   end -- idle.update

   ---------------------------------------
   -- await
   ---------------------------------------

   function await.on_enter()
      label.set_text(debug_label, "Await")
   end -- await.on_enter

   local function update(dt)
      utils.log(velocity_y)
      machine.update(dt)
   end -- update

   -- function instance.on_ground_contact()
   --    local vy = recoil_velocity
   --    recoil_velocity = recoil_velocity * 0.6
   --    utils.log(recoil_velocity, runtime.current_frame)
   --    return vy
   -- end -- instance.on_ground_contact

   function instance.push(dx)
      local dt = runtime.delta_time
      local push_limit = max_horizontal_speed * dt
      dx = fastmath.clamp(dx, -push_limit, push_limit)
      local _, dy = move(dt)
      instance.dx, instance.dy = advance(dx, dy, ground)
      return instance.dx
   end -- instance.push

   function instance.on_hit(amount)
      utils.log("received " .. tostring(amount) .. " damage points")
      destroy()
   end -- instance.on_hit

   function instance.init(self)
      debug_label = msg.url("#debug_label")
      -- msg.post(debug_label, msg.DISABLE)
      name = self.name
      one_shot = self.one_shot
      trigger = self.trigger
      gravity = self.gravity
      RECOIL_VELOCITY_MAX = self.recoil_velocity
      max_horizontal_speed = self.max_horizontal_speed
      root = msg.url("root")
      vector3_stub = go.get_position()
      position_x, position_y = fastmath.vector3_get_components(vector3_stub)
      velocity_x = 0
      velocity_y = 0
      instance.dx = 0
      instance.dy = 0
      instance.can_push = true
      raycast_controller.set_width(self.width)
      raycast_controller.set_height(self.height)
      ground = nil
      runtime.set_instance(root.path, instance)
      runtime.add_update_callback(instance, update)
      nc.add_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.add_observer(post_init, CONST.POST_INIT_NOTIFICATION)
      machine.reset()
      machine.enter_state(ready)
   end -- instance.init

   function instance.deinit()
      runtime.remove_update_callback(instance)
      runtime.set_instance(root.path, nil)
      nc.remove_observer(destroy, CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
      nc.remove_observer(post_init, CONST.POST_INIT_NOTIFICATION)
      nc.remove_observer(on_trigger_enter, CONST.TRIGGER_ENTER_NOTIFICATION, trigger)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

-- export
return {
   new = pool.new,
   free = pool.free,
   fill = pool.fill,
   purge = pool.purge,
}
