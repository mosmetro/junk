local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
local utils = require("m.utils")

local layers = require("m.layers")
-- local gamestate = require("game.gamestate")
local DEPTH = layers.get_depth(layers.PROPS_BACK)

local go = go
local set_instance = runtime.set_instance
local get_instance = runtime.get_instance
local set_position = go.set_position
local get_position = go.get_position
local vector3_get_xy = fastmath.vector3_get_xy
local vector3_set_xyz = fastmath.vector3_set_xyz
local sign = fastmath.sign

local function make()
   local instance = {
      x = 0,
      y = 0,
   }
   local vector3_stub = fastmath.vector3_stub
   local root
   local disturber_id
   local enter_offset
   local is_bending
   local anchor_sprite

   local function destroy()
      go.delete(root, true)
   end -- destroy

   function instance.init()
      root = msg.url(".")
      instance.x, instance.y = vector3_get_xy(get_position(root))
      local x, y = vector3_get_xy(get_position("anchor"))
      vector3_set_xyz(vector3_stub, x, y, DEPTH)
      set_position(vector3_stub, "anchor")
      anchor_sprite = msg.url("anchor#sprite")
      disturber_id = nil
      is_bending = false
      set_instance(root.path, instance)
      nc.add_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.init

   function instance.deinit()
      set_instance(root.path, nil)
      nc.remove_observer(destroy, const.LEVEL_DID_DISAPPEAR_NOTIFICATION)
   end -- instance.deinit

   function instance.on_collision_response(message)
      if (not disturber_id) or message.other_id ~= disturber_id then return end

      local other_instance = get_instance(disturber_id)
      if other_instance then
         local offset = (other_instance.x - instance.x) / (8 + 5)
         if (not is_bending) and (sign(offset) ~= sign(enter_offset)) then
            is_bending = true
         end
         if is_bending then
            go.set(anchor_sprite, "offset", vmath.vector4(offset * 6, 0, 0, 0))
            utils.log(offset)
         end
      end
   end -- on_collision_response

   function instance.on_trigger_response(message)
      if disturber_id and message.other_id ~= disturber_id then return end
      disturber_id = message.other_id
      local other_instance = get_instance(disturber_id)
      if other_instance then
         if message.enter then
            utils.log("enter")
            enter_offset = other_instance.x - instance.x
         else
            utils.log("exit")
            is_bending = false
            disturber_id = nil
         end
      else
         disturber_id = nil
      end
   end -- on_trigger_response

   return instance
end -- make

local pool = Pool.new(make)

-- export
return {
   new = pool.new,
   free = pool.free,
}
