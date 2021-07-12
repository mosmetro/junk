-- local Pot_debris = require("maze.e1.props.pots.china.potchina_debris")
local Pool = require("m.pool")
local nc = require("m.notification_center")
local CONST = require("m.constants")
local thread = require("m.thread")
-- local snd = require("sound.sound")
local ui = require("m.ui.ui")
local game = require("maze.game")
-- local colors = require("m.colors")
-- local layers = require("m.layers")
local utils = require("m.utils")
-- local debug_draw = require("m.debug_draw")
-- local waypoints_registry = require("maze.e1.props.platforms.waypoints_registry")

local global = require("game.global")

local hash = hash
local runtime = runtime
local msg = msg
local go = go
local vector3 = vmath.vector3
local set_instance = runtime.set_instance
local get_instance = runtime.get_instance
local add_update_callback = runtime.add_update_callback
local remove_update_callback = runtime.remove_update_callback
local execute_in_context = runtime.execute_in_context
local vector3_set_components = fastmath.vector3_set_components
-- local vector4_set_components = fastmath.vector4_set_components
local abs = fastmath.abs
-- local sign = fastmath.sign
local fast_step = fastmath.fast_step
-- local smooth_step = fastmath.smooth_step
local lerp = fastmath.lerp
local clamp = fastmath.clamp
local is_equal = fastmath.is_equal
local matrix4_set_translation = fastmath.matrix4_set_translation
local get_bounds = tilemap.get_bounds
-- local play_sound = snd.play_sound

-- constants
local INFINITY = 1 / 0
local ZERO = vector3()
-- local ONE = vector3(1)
local QUAT_IDENTITY = vmath.quat()
local TILE_SIZE = 16
local ROOT = hash("/root")
local STATIC_GEOMETRY = hash("/static_geometry")
local TILEMAP = hash("tilemap")
local UP_VIEW_SHIFT = 24
local DOWN_VIEW_SHIFT = -16
local VIEW_SHIFT_LIMIT = 38
local VIEW_MARGIN_X = 8
local VIEW_MARGIN_Y = 8

local view_left_limit = -INFINITY
local view_right_limit = INFINITY
local view_bottom_limit = -INFINITY
local view_top_limit = INFINITY

local camshake_roll = fastmath.uniform_real(-1, 1)

local start_checkpoint

local function window_event_listener(_, event)
   if event == window.WINDOW_EVENT_FOCUS_LOST then
      nc.post_notification(CONST.GAME_WILL_END_NOTIFICATION)
      game.save()
   end
end -- window_event_listener

local function make()
   local gameobject
   local tx
   -- local view_x
   -- local view_y
   local previous_horizontal_look
   local vector3_stub = vector3()
   local instance = {
      update_group = runtime.UPDATE_GROUP_AFTER_PLAYER
   }
   local player
   local player_factory = msg.url("#player")

   local target_view_shift = UP_VIEW_SHIFT
   local view_shift = UP_VIEW_SHIFT
   local previous_view_shift = UP_VIEW_SHIFT
   local view_shift_t  = 0

   local camshake_magnitude
   local camshake_value = 0
   local camshake_elapsed_time
   local camshake_duration
   local camshake_easing_func

   local function update(dt)
      thread.update(gameobject, dt)

      local player_instance = player -- get_instance(player)
      if not player_instance then
         return
      end

      local target_x = player_instance.x + player_instance.horizontal_look * 20 -- side view shift
      local view_x = global.view_x or target_x
      -- view_x = view_x or target_x
      if player_instance.horizontal_look ~= previous_horizontal_look then
         tx = 0
         previous_horizontal_look = player_instance.horizontal_look
      elseif tx < 1 then
         tx = tx + dt * 0.06
         -- utils.log(tx)
         view_x = fast_step(view_x, target_x, tx)
         if is_equal(view_x, target_x) then
            tx = 1
         end
      else
         -- utils.log("else")
         view_x = view_x * 0.9 + target_x * 0.1
         -- view_x = view_x + (target_x - view_x) * 0.1
         -- view_x = target_x
      end

      if player_instance.vertical_look > 0 then
         target_view_shift = UP_VIEW_SHIFT
      elseif player_instance.vertical_look < 0 then
         target_view_shift = DOWN_VIEW_SHIFT
      end

      if previous_view_shift ~= target_view_shift then
         view_shift_t = 0
         previous_view_shift = target_view_shift
      elseif view_shift_t <= 1 then
         view_shift_t = view_shift_t + dt * 0.06
         view_shift = fast_step(view_shift, target_view_shift, view_shift_t)
      end

      local target_y = player_instance.y + view_shift
      local view_y = global.view_y or target_y
      -- view_y = view_y or target_y
      view_y = lerp(view_y, target_y, dt * (player_instance.vertical_look >= 0 and 3 or 2))
      -- utils.log(view_y - target_y)
      if abs(view_y - target_y) > VIEW_SHIFT_LIMIT then
         if view_y > target_y then
            view_y = target_y + VIEW_SHIFT_LIMIT
         else
            view_y = target_y - VIEW_SHIFT_LIMIT
         end
      end

      -- utils.log(runtime.current_frame, view_x, view_left_limit, view_right_limit)
      view_x = clamp(view_x, view_left_limit, view_right_limit)
      -- view_y = clamp(view_y, (view_bottom_limit or -INFINITY), INFINITY)
      -- view_y = clamp(view_y, (view_bottom_limit or -INFINITY), INFINITY)
      view_y = clamp(view_y, view_bottom_limit, view_top_limit)

      -- camera shake
      if camshake_value > 0 then
         camshake_value = camshake_easing_func(camshake_elapsed_time, camshake_magnitude, -camshake_magnitude, camshake_duration)
         view_x = view_x + camshake_roll() * camshake_value
         view_y = view_y + camshake_roll() * camshake_value
         camshake_elapsed_time = fastmath.clamp(camshake_elapsed_time + dt, 0, camshake_duration)
         if camshake_value < 0.01 then
            camshake_value = 0
         end
      end

      global.view_x = view_x
      global.view_y = view_y

      global.view_aabb[1] = view_x - game.view_half_width - VIEW_MARGIN_X
      global.view_aabb[2] = view_y - game.view_half_height - VIEW_MARGIN_Y
      global.view_aabb[3] = view_x + game.view_half_width + VIEW_MARGIN_X
      global.view_aabb[4] = view_y + game.view_half_height + VIEW_MARGIN_Y

      -- debug_draw.aabb(global.view_aabb, colors.GREEN)
      -- debug_draw.circle(view_x, view_y, 2, 8, COLOR.GREEN)

      matrix4_set_translation(game.view_matrix, view_x, view_y)


      -- local ssy = game.projection_matrix.m11 * (-10 - view_y) * 0.5 + 0.5

      -- local water_y = -12
      -- local water_level = water_y - view_y
      -- if water_level > -game.view_half_height then
      --    utils.log(water_level + game.view_half_height)
      -- end

      -- local ssy = (game.view_half_height + (water_level - view_y))
      -- utils.log(ssy)
   end -- update

   local change_map
   function change_map(sender, mediator)
      local position_x
      local position_y
      local horizontal_look
      local map
      local location
      local transit
      local next_game_map
      if mediator then
         map = msg.url(nil, "/maps", mediator.map)
         location = mediator.location
         transit = mediator.transit
         next_game_map = mediator.map
      else
         local destination = game.get(nil, game.player, "last_position", game.get(nil, game.player, "last_checkpoint", start_checkpoint))
         map = msg.url(nil, "/maps", destination.map)
         location = destination.location
         position_x = destination.position_x
         position_y = destination.position_y
         horizontal_look = destination.horizontal_look
         next_game_map = game[destination.map]
      end

      thread.new(gameobject, "maze::change_map", function()
         -- delete current level
         runtime.execute_in_context(ui.ingame_controls_context.disable, ui.ingame_controls_context)
         nc.post_notification(CONST.LEVEL_WILL_DISAPPEAR_NOTIFICATION)

         local fadein_complete = false
         execute_in_context(ui.fader_context.fadein, ui.fader_context, function()
            fadein_complete = true
         end)
         thread.wait_for_condition(gameobject, function() return fadein_complete end)

         local shift = 0
         local elevation = 0
         local player_instance = get_instance(sender)
         if player_instance and transit then
            shift, elevation = transit(player_instance.x, player_instance.y)
         end

         nc.post_notification(CONST.LEVEL_DID_DISAPPEAR_NOTIFICATION)
         player = nil
         thread.wait_for_frames(gameobject, 2)
         -- pprint(nc.inspect())
         game.map = next_game_map
         utils.log("creating map: ", next_game_map, map)
         local current_gameobjects = collectionfactory.create(map, ZERO, QUAT_IDENTITY, nil, 1)

         nc.post_notification(CONST.POST_INIT_NOTIFICATION)

         local tilemap_url = msg.url(nil, current_gameobjects[STATIC_GEOMETRY], TILEMAP)
         local mx, my, mw, mh = get_bounds(tilemap_url)

         game.tilemap_url = tilemap_url
         game.tilemap_x = mx
         game.tilemap_y = my
         game.tilemap_w = mw
         game.tilemap_h = mh

         local map_left = (mx - 1) * TILE_SIZE
         local map_right = mw * TILE_SIZE + map_left
         local map_bottom = (my - 1) * TILE_SIZE
         local map_top = mh * TILE_SIZE + map_bottom

         view_left_limit = clamp(map_left + (TILE_SIZE * 6) + game.view_half_width, -INFINITY, 0)
         view_right_limit = clamp(map_right - (TILE_SIZE * 6) - game.view_half_width, 0, INFINITY)
         view_bottom_limit = clamp(map_bottom - game.view_half_height, -INFINITY, 0)
         view_top_limit = clamp(map_top - game.view_half_height, 0, INFINITY)

         global.view_x = nil
         global.view_y = nil

         if location then
            local location_id = current_gameobjects[location]
            local location_instance = get_instance(location_id)
            position_x = location_instance.x
            position_y = location_instance.y
         end

         if not sender then
            vector3_set_components(vector3_stub, position_x + shift, position_y + elevation, 0)
            local ids = collectionfactory.create(player_factory, vector3_stub)
            sender = ids[ROOT]
            nc.add_observer(change_map, CONST.ENTITY_DID_LEAVE_LEVEL_NOTIFICATION, sender)
         end

         execute_in_context(ui.ingame_controls_context.enable, ui.ingame_controls_context)

         thread.wait_for_frames(gameobject, 1)

         nc.post_notification(CONST.LEVEL_WILL_APPEAR_NOTIFICATION, nil, position_x + shift, position_y + elevation, horizontal_look)

         thread.wait_for_frames(gameobject, 1)

         player = get_instance(sender)

         local fadeout_complete = false
         execute_in_context(ui.fader_context.fadeout, ui.fader_context, function()
            fadeout_complete = true
         end)
         thread.wait_for_condition(gameobject, function() return fadeout_complete end)

         nc.post_notification(CONST.LEVEL_DID_APPEAR_NOTIFICATION)
      end)
   end -- change_map

   local function camera_shake_request(_, magnitude, duration, easing_func)
      if magnitude > camshake_value then
         -- utils.log("shake", magnitude, duration, easing_func)
         camshake_magnitude = magnitude
         camshake_value = magnitude
         camshake_elapsed_time = 0
         camshake_duration = duration or 0.2
         camshake_easing_func = easing_func or fastmath.easing_linear
      end
   end -- camera_shake_request

   function instance.init()
      gameobject = go.get_id()
      camshake_magnitude = 0
      start_checkpoint = {
         map = "e1m2",
         location = "/gate1/root",
      }
      game.map = nil

      set_instance(gameobject, instance)
      add_update_callback(instance, update)
      nc.add_observer(camera_shake_request, CONST.CAMERA_SHAKE_REQUEST_NOTIFICATION)
      window.set_listener(window_event_listener)
      -- snd.play_sound(snd.SHADOWCRYPT_MUSIC)

      change_map()
   end -- instance.init

   function instance.deinit()
      nc.remove_observer(change_map, CONST.ENTITY_DID_LEAVE_LEVEL_NOTIFICATION, player)
      nc.remove_observer(camera_shake_request, CONST.CAMERA_SHAKE_REQUEST_NOTIFICATION)
      remove_update_callback(instance)
      set_instance(gameobject, nil)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

-- export
return {
   new = pool.new,
   free = pool.free,
}
