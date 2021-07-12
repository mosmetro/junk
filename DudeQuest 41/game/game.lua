local Pool = require("m.pool")
local thread = require("m.thread")
local nc = require("m.notification_center")
local const = require("m.constants")
-- local utils = require("m.utils")
-- local debug_draw = require("m.debug_draw")

local global = require("game.global")
-- local gamestate = require("game.gamestate")


local tilemap = tilemap
local execute_in_context = runtime.execute_in_context
local matrix4_set_translation = fastmath.matrix4_set_translation
local fast_step = fastmath.fast_step
local clamp = fastmath.clamp
local is_equal = fastmath.is_equal
local abs = fastmath.abs
local get_instance = runtime.get_instance

-- local STATIC_GEOMETRY = hash("/static_geometry")
-- local TILEMAP = hash("tilemap")
local TILE_SIZE = 16
local UP_VIEW_SHIFT = 20
local DOWN_VIEW_SHIFT = -16
local VIEW_SHIFT_LIMIT = 38
local VIEW_MARGIN_X = 8
local VIEW_MARGIN_Y = 8

local function make()
   local instance = {
      update_group = runtime.UPDATE_GROUP_AFTER_PLAYER,
   }
   local id
   local previous_horizontal_look
   local view_limit_right
   local view_limit_left
   local view_limit_bottom
   local view_limit_top
   local target_view_shift = UP_VIEW_SHIFT
   local view_shift = UP_VIEW_SHIFT
   local previous_view_shift = UP_VIEW_SHIFT
   local view_shift_t  = 0

   local tx

   local function update(dt)
      thread.update(id, dt)

      local focus_instance = get_instance(global.focus_id)
      if not focus_instance then return end

      local target_x = focus_instance.x + focus_instance.horizontal_look * 20 -- side view shift
      local view_x = global.view_x or target_x
      if focus_instance.horizontal_look ~= previous_horizontal_look then
         tx = 0
         previous_horizontal_look = focus_instance.horizontal_look
      elseif tx < 1 then
         tx = tx + dt * 0.06
         view_x = fast_step(view_x, target_x, tx)
         if is_equal(view_x, target_x) then
            tx = 1
         end
      else
         view_x = view_x * 0.9 + target_x * 0.1
      end

      if focus_instance.vertical_look > 0 then
         target_view_shift = UP_VIEW_SHIFT
      elseif focus_instance.vertical_look < 0 then
         target_view_shift = DOWN_VIEW_SHIFT
      end

      if previous_view_shift ~= target_view_shift then
         view_shift_t = 0
         previous_view_shift = target_view_shift
      elseif view_shift_t <= 1 then
         view_shift_t = view_shift_t + dt * 0.06
         view_shift = fast_step(view_shift, target_view_shift, view_shift_t)
      end

      local target_y = focus_instance.y + view_shift
      local view_y = global.view_y or target_y
      view_y = fast_step(view_y, target_y, dt * (focus_instance.vertical_look >= 0 and 3 or 2))
      -- utils.log(view_y - target_y)
      if abs(view_y - target_y) > VIEW_SHIFT_LIMIT then
         if view_y > target_y then
            view_y = target_y + VIEW_SHIFT_LIMIT
         else
            view_y = target_y - VIEW_SHIFT_LIMIT
         end
      end

      view_x = clamp(view_x, view_limit_left, view_limit_right)
      view_y = clamp(view_y, view_limit_bottom, view_limit_top)
      -- debug_draw.circle(view_x, view_y, 2)

      global.view_x = view_x
      global.view_y = view_y

      global.view_aabb[1] = view_x - global.view_half_width - VIEW_MARGIN_X
      global.view_aabb[2] = view_y - global.view_half_height - VIEW_MARGIN_Y
      global.view_aabb[3] = view_x + global.view_half_width + VIEW_MARGIN_X
      global.view_aabb[4] = view_y + global.view_half_height + VIEW_MARGIN_Y

      matrix4_set_translation(global.view_matrix, view_x, view_y)
   end -- update

   local function change_map(map, location, direction, player, fadein_duration)
      thread.new(id, "game::change_map", function()

         nc.post_notification(const.LEVEL_WILL_DISAPPEAR_NOTIFICATION)
         local fadein_complete = false
         execute_in_context(global.fader_context.fadein, global.fader_context, function()
            fadein_complete = true
         end, fadein_duration)
         thread.wait_for_condition(id, function() return fadein_complete end)

         nc.post_notification(const.LEVEL_DID_DISAPPEAR_NOTIFICATION, nil, location == nil)
         global.focus_id = nil
         global.view_x = nil
         global.view_y = nil

         thread.wait_for_frames(id, 1)

         local ids
         if player then
            local player_factory = msg.url(nil, "/entities", player)
            ids = collectionfactory.create(player_factory, fastmath.VECTOR3_ZERO, fastmath.QUAT_IDENTITY, nil, 1)
            global.player_id = ids["/root"]
            local player_instance = get_instance(global.player_id)
            player_instance.horizontal_look = direction or 1
         end

         local map_factory = msg.url(nil, "/maps", map)
         ids = collectionfactory.create(map_factory, fastmath.VECTOR3_ZERO, fastmath.QUAT_IDENTITY, nil, 1)
         local tilemap_id = ids["/static_geometry"]
         if tilemap_id then
            global.tilemap_url = msg.url(nil, tilemap_id, "tilemap")
            global.tilemap_x, global.tilemap_y, global.tilemap_w, global.tilemap_h = tilemap.get_bounds(global.tilemap_url)
            global.map_left = (global.tilemap_x - 1) * TILE_SIZE
            global.map_right = global.tilemap_w * TILE_SIZE + global.map_left
            global.map_bottom = (global.tilemap_y - 1) * TILE_SIZE
            global.map_top = global.tilemap_h * TILE_SIZE + global.map_bottom
            view_limit_left = global.map_left + global.view_half_width + 64
            view_limit_right = global.map_right - global.view_half_width - 64
            view_limit_bottom = global.map_bottom + global.view_half_height - 16 + 64
            view_limit_top = global.map_top - global.view_half_height - 64
            -- utils.log(global.map_left, global.map_right, global.map_bottom, global.map_top)
            -- utils.log(global.map_top, view_limit_top)
         end

         if location then
            global.location_id = ids[location]
         end

         nc.post_notification(const.POST_INIT_NOTIFICATION)
         runtime.execute_in_context(global.ingame_controls_context.enable, global.ingame_controls_context)

         thread.wait_for_frames(id, 1)

         global.focus_id = global.player_id
         nc.post_notification(const.LEVEL_WILL_APPEAR_NOTIFICATION)

         local fadeout_complete = false
         execute_in_context(global.fader_context.fadeout, global.fader_context, function()
            fadeout_complete = true
         end)
         thread.wait_for_condition(id, function() return fadeout_complete end)
         nc.post_notification(const.LEVEL_DID_APPEAR_NOTIFICATION)
      end)
   end -- change_map

   local function enable(_, map, location, direction, player, fadein_duration)
      change_map(map, location, direction, player, fadein_duration)
   end -- enable

   function instance.init(self)
      global.ingame_context = self
      self.enable = enable
      id = go.get_id(".")
      runtime.add_update_callback(instance, update)
      change_map("e0m0", nil, nil, nil, 0)
   end -- instance.init

   function instance.deinit()
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

return {
   new = pool.new,
   free = pool.free,
}
