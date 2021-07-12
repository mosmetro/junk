local Pool = require("m.pool")
local nc = require("m.notification_center")
local const = require("m.constants")
local thread = require("m.thread")
local ui = require("m.ui.ui")
local Counter = require("m.counter")
-- local colors = require("m.colors")
-- local layers = require("m.layers")
-- local utils = require("m.utils")
-- local debug_draw = require("m.debug_draw")

local gamestate = require("pixelfrog.game.gamestate")
-- local snd = require("sound.sound")

local tostring = tostring
local hash = hash
local runtime = runtime
local msg = msg
local go = go
local set_instance = runtime.set_instance
local get_instance = runtime.get_instance
local add_update_callback = runtime.add_update_callback
local remove_update_callback = runtime.remove_update_callback
local execute_in_context = runtime.execute_in_context
local vector3_set_xyz = fastmath.vector3_set_xyz
-- local vector4_set_components = fastmath.vector4_set_components
local abs = fastmath.abs
-- local sign = fastmath.sign
local fast_step = fastmath.fast_step
-- local smooth_step = fastmath.smooth_step
-- local lerp = fastmath.lerp
local clamp = fastmath.clamp
local is_equal = fastmath.is_equal
local matrix4_set_translation = fastmath.matrix4_set_translation

-- constants
local INFINITY = const.INFINITY
local TILE_SIZE = 16
-- local ROOT = hash("/root")
local STATIC_GEOMETRY = hash("/static_geometry")
local TILEMAP = hash("tilemap")
local UP_VIEW_SHIFT = 20
local DOWN_VIEW_SHIFT = -16
local VIEW_SHIFT_LIMIT = 38
local VIEW_MARGIN_X = 16
local VIEW_MARGIN_Y = 16
local PROJECTILE_SYMBOL = hash("sword")
local CURRENCY_SYMBOL = hash("coin")

local KEY = {
   IRON_PRESENTATION = hash("key_iron_presentation"),
   GOLD_PRESENTATION = hash("key_gold_presentation")
}

local view_left_limit = -INFINITY
local view_right_limit = INFINITY
local view_bottom_limit = -INFINITY
local view_top_limit = INFINITY

local camshake_roll = fastmath.uniform_real(-1, 1)

local start_checkpoint

local game = {}

local currency_animation_playing
local projectile_animation_playing

local health_sprites = {
   msg.url("game:/health#sprite1"),
   msg.url("game:/health#sprite2"),
   msg.url("game:/health#sprite3"),
   msg.url("game:/health#sprite4"),
   msg.url("game:/health#sprite5"),
   msg.url("game:/health#sprite6"),
}

local counter_digits = {
   hash("small_white_digits_0"),
   hash("small_white_digits_1"),
   hash("small_white_digits_2"),
   hash("small_white_digits_3"),
   hash("small_white_digits_4"),
   hash("small_white_digits_5"),
   hash("small_white_digits_6"),
   hash("small_white_digits_7"),
   hash("small_white_digits_8"),
   hash("small_white_digits_9"),
}

local function on_currency_animation_end()
   currency_animation_playing = false
end -- on_currency_animation_end

local function on_projectile_animation_end()
   projectile_animation_playing = false
end -- on_projectile_animation_end

local function window_event_listener(_, event)
   if event == window.WINDOW_EVENT_FOCUS_LOST then
      nc.post_notification(const.GAME_WILL_END_NOTIFICATION)
      gamestate.save()
   end
end -- window_event_listener

local function make()
   local context
   local max_health
   local currency
   local currency_symbol
   local currency_counter
   -- local reset_currency_counter
   local health
   local health_counter
   local projectile
   local projectile_symbol
   local projectiles_counter
   local key_placeholder
   local key_placeholder_sprite
   local gameobject
   local tx
   -- local view_x
   -- local view_y
   local previous_horizontal_look
   local vector3_stub = fastmath.vector3_stub
   local instance = {
      update_group = runtime.UPDATE_GROUP_AFTER_PLAYER
   }
   local player_id
   local player
   -- local player_factory = msg.url("/characters#ninja_frog")
   local player_factory = msg.url("/characters#captain")

   local target_view_shift = UP_VIEW_SHIFT
   local view_shift = UP_VIEW_SHIFT
   local previous_view_shift = UP_VIEW_SHIFT
   local view_shift_t  = 0

   local camshake_magnitude
   local camshake_value = 0
   local camshake_elapsed_time
   local camshake_duration
   local camshake_easing_func

   local change_map

   local function update(dt)
      thread.update(gameobject, dt)

      local player_instance = player -- get_instance(player)
      if not player_instance then
         -- utils.log("no player")
         return
      end

      local target_x = player_instance.x + player_instance.horizontal_look * 20 -- side view shift
      local view_x = game.view_x or target_x
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
      local view_y = game.view_y or target_y
      -- view_y = view_y or target_y
      view_y = fast_step(view_y, target_y, dt * (player_instance.vertical_look >= 0 and 3 or 2))
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

      game.view_x = view_x
      game.view_y = view_y

      game.view_aabb[1] = view_x - game.view_half_width - VIEW_MARGIN_X
      game.view_aabb[2] = view_y - game.view_half_height - VIEW_MARGIN_Y
      game.view_aabb[3] = view_x + game.view_half_width + VIEW_MARGIN_X
      game.view_aabb[4] = view_y + game.view_half_height + VIEW_MARGIN_Y

      -- debug_draw.aabb(game.view_aabb, colors.GREEN)
      -- debug_draw.circle(view_x, view_y, 2, 8, colors.GREEN)

      matrix4_set_translation(game.view_matrix, view_x, view_y)

      health_counter(gamestate.get(nil, gamestate.player, "health", max_health), dt)

      local success
      success = projectiles_counter(gamestate.get(nil, gamestate.player, "projectiles", 0), dt)
      if success and (not projectile_animation_playing) then
         sprite.play_flipbook(projectile_symbol, PROJECTILE_SYMBOL, on_projectile_animation_end)
         projectile_animation_playing = true
      end

      success = currency_counter(gamestate.get(nil, gamestate.player, "wealth", 0), dt)
      if success and (not currency_animation_playing) then
         sprite.play_flipbook(currency_symbol, CURRENCY_SYMBOL, on_currency_animation_end)
         currency_animation_playing = true
      end
   end -- update

   -- -- change_map is wrapped because it's may be called from gui
   local function change_map_wrapper(sender, mediator)
      runtime.execute_in_context(change_map, context, sender, mediator)
   end -- change_map_wrapper

   -- (context, args)
   local function start(_, selected_level)
      -- utils.log("START", selected_level)
      -- health counter setup --
      max_health = gamestate.get(nil, gamestate.player, "max_health", 3)

      for i = #health_sprites, (max_health + 1), -1 do
         msg.post(health_sprites[i], msg.DISABLE)
         health_sprites[i] = nil
      end

      vector3_set_xyz(vector3_stub, -game.view_half_width + 10, game.view_half_height - 8, 0)
      go.set_position(vector3_stub, health)

      health_counter = Counter.new(
      health_sprites,
      {
         hash("heart_empty"),
         hash("heart_full"),
      },
      20,
      nil,
      gamestate.get(nil, gamestate.player, "health", max_health),
      {
         [0] = 0,
         [1] = 1,
         [2] = 3,
         [3] = 7,
         [4] = 15,
         [5] = 31,
         [6] = 63,
      })

      -- currency counter setup --

      vector3_set_xyz(vector3_stub, game.view_half_width - 39, game.view_half_height - 8, 0)
      go.set_position(vector3_stub, currency)

      currency_symbol = msg.url("currency#symbol")
      sprite.play_flipbook(currency_symbol, CURRENCY_SYMBOL, on_currency_animation_end, { offset = 1 })

      currency_counter = Counter.new(
      {
         msg.url("currency#ones"),
         msg.url("currency#tens"),
         msg.url("currency#hundreds"),
         msg.url("currency#thousands"),
      },
      counter_digits,
      20,
      nil,
      gamestate.get(nil, gamestate.player, "wealth", 0))

      -- projectiles counter setup --

      vector3_set_xyz(vector3_stub, game.view_half_width - 70, game.view_half_height - 8, 0)
      go.set_position(vector3_stub, projectile)

      projectile_symbol = msg.url("projectile#symbol")
      sprite.play_flipbook(projectile_symbol, PROJECTILE_SYMBOL, on_projectile_animation_end, { offset = 1 })

      projectiles_counter = Counter.new(
      {
         msg.url("projectile#ones"),
      },
      counter_digits,
      20,
      nil,
      gamestate.get(nil, gamestate.player, "projectiles", 0))

      -- keys setup --

      vector3_set_xyz(vector3_stub, game.view_half_width - 96, game.view_half_height - 8, 0)
      go.set_position(vector3_stub, key_placeholder)

      local ids = collectionfactory.create(player_factory, const.VECTOR3_ZERO)
      player_id = ids[const.ROOT]
      game.player_id = player_id
      nc.add_observer(change_map_wrapper, const.ENTITY_DID_LEAVE_LEVEL_NOTIFICATION, player_id)
      start_checkpoint = {
         map = "level" .. tostring(selected_level),
         location = "/teleport1/root",
      }
      change_map(nil, player_id)
   end -- start

   -- (sender, args)
   local function start_wrapper(_, selected_level)
      runtime.execute_in_context(start, context, selected_level)
   end -- start_wrapper

   -- change_map is wrapped because it's may be called from gui
   local function restart()
      runtime.execute_in_context(change_map, context, player_id)
   end -- restart

   local function exit()
      runtime.execute_in_context(change_map, context)
   end -- exit

   function change_map(ctx, sender, mediator, fadein_duration)
      -- utils.log(ctx, sender, mediator, fadein_duration)
      local position_x
      local position_y
      local map
      local location
      local transit
      if mediator then
         map = msg.url(nil, "/levels", mediator.map)
         location = mediator.location
         transit = mediator.transit
         gamestate.map = gamestate[mediator.map]
      elseif sender then
         local destination = gamestate.get(nil, gamestate.player, "last_checkpoint", start_checkpoint)
         map = msg.url(nil, "/levels", destination.map)
         location = destination.location
         gamestate.map = gamestate[destination.map]
      else
         map = msg.url("/levels#level0")
      end
      -- if sender then
      --    local destination = gamestate.get(nil, gamestate.player, "last_checkpoint", start_checkpoint)
      --    map = msg.url(nil, "/levels", destination.map)
      --    location = destination.location
      --    -- next_game_map = game[destination.map]
      -- else
      --    map = msg.url("/levels#level0")
      --    location = nil
      -- end

      thread.new(gameobject, "pixelfrog::change_map", function()
         -- delete current level
         execute_in_context(ui.ingame_controls_context.disable, ui.ingame_controls_context)
         nc.post_notification(const.LEVEL_WILL_DISAPPEAR_NOTIFICATION)

         local fadein_complete = false
         execute_in_context(ui.fader_context.fadein, ui.fader_context, function()
            fadein_complete = true
         end, fadein_duration)
         thread.wait_for_condition(gameobject, function() return fadein_complete end)

         local shift = 0
         local elevation = 0
         local player_instance = get_instance(sender)
         if player_instance and transit then
            shift, elevation = transit(player_instance.x, player_instance.y)
         end

         nc.post_notification(const.LEVEL_DID_DISAPPEAR_NOTIFICATION)

         if sender then

            local existing_player = player
            -- camera should not move
            player = nil

            for i = 1, max_health do
               msg.post(health_sprites[i], msg.ENABLE)
            end
            msg.post(projectile, msg.ENABLE)
            msg.post(currency, msg.ENABLE)

            if gamestate.get(nil, gamestate.player, "has_key", false) then
               msg.post(key_placeholder_sprite, msg.ENABLE)
            else
               msg.post(key_placeholder_sprite, msg.DISABLE)
            end

            thread.wait_for_frames(gameobject, 2)

            -- utils.log("creating map: ", gamestate.map, map)
            local current_gameobjects = collectionfactory.create(map, const.VECTOR3_ZERO, const.QUAT_IDENTITY, nil, 1)

            nc.post_notification(const.POST_INIT_NOTIFICATION)

            local tilemap_url = msg.url(nil, current_gameobjects[STATIC_GEOMETRY], TILEMAP)
            local mx, my, mw, mh = tilemap.get_bounds(tilemap_url)
            -- tilemap.set_visible(tilemap_url, "backdrop", false)
            local map_left = (mx - 1) * TILE_SIZE
            local map_right = mw * TILE_SIZE + map_left
            local map_bottom = (my - 1) * TILE_SIZE
            local map_top = mh * TILE_SIZE + map_bottom

            -- utils.log(mx, my, mw, mh)
            -- utils.log(map_left, map_right, map_bottom, map_top)

            view_left_limit = map_left + 48 + game.view_half_width
            view_right_limit = map_right - 48 - game.view_half_width
            -- view_bottom_limit = clamp(map_bottom + (TILE_SIZE * 3) + game.view_half_height, -INFINITY, 0)
            view_bottom_limit = map_bottom  + TILE_SIZE * 3 + game.view_half_height
            -- view_top_limit = clamp(map_top - (TILE_SIZE) - game.view_half_height, 0, INFINITY)
            view_top_limit = map_top - TILE_SIZE - game.view_half_height

            -- utils.log(view_left_limit, view_right_limit, view_bottom_limit, view_top_limit)

            game.view_x = nil
            game.view_y = nil

            if location then
               local location_id = current_gameobjects[location]
               local location_instance = get_instance(location_id)
               -- utils.log(location, location_id, location_instance)
               -- pprint(current_gameobjects)
               position_x = location_instance.x
               position_y = location_instance.y
            end

            -- if not sender then
            --    vector3_set_xyz(vector3_stub, position_x + shift, position_y + elevation, 0)
            --    local ids = collectionfactory.create(player_factory, vector3_stub)
            --    sender = ids[ROOT]
            --    nc.add_observer(change_map, const.ENTITY_DID_LEAVE_LEVEL_NOTIFICATION, sender)
            -- end

            thread.wait_for_frames(gameobject, 1)

            nc.post_notification(const.LEVEL_WILL_APPEAR_NOTIFICATION, nil, position_x + shift, position_y + elevation)

            -- local s = gamestate.get_save_slot()
            -- local w = gamestate.get(nil, gamestate.player, "wealth", 0)
            -- utils.log(s, w)
            -- reset_currency_counter(gamestate.get(nil, gamestate.player, "wealth", 0), false)

            player = get_instance(sender) or existing_player

            thread.wait_for_frames(gameobject, 1)

            execute_in_context(ui.ingame_controls_context.enable, ui.ingame_controls_context)

            local fadeout_complete = false
            execute_in_context(ui.fader_context.fadeout, ui.fader_context, function()
               fadeout_complete = true
            end)
            thread.wait_for_condition(gameobject, function() return fadeout_complete end)

            nc.post_notification(const.LEVEL_DID_APPEAR_NOTIFICATION)
         else
            if player_id then
               go.delete(player_id, true)
            end
            player_id = nil
            player = nil

            msg.post(health, msg.DISABLE)
            msg.post(projectile, msg.DISABLE)
            msg.post(currency, msg.DISABLE)
            msg.post(key_placeholder_sprite, msg.DISABLE)

            thread.wait_for_frames(gameobject, 2)

            collectionfactory.create(map, const.VECTOR3_ZERO, const.QUAT_IDENTITY, nil, 1)

            nc.post_notification(const.POST_INIT_NOTIFICATION)

            game.view_x = 0
            game.view_y = 0
            matrix4_set_translation(game.view_matrix, 0, 0)


            thread.wait_for_frames(gameobject, 1)

            nc.post_notification(const.LEVEL_WILL_APPEAR_NOTIFICATION)

            thread.wait_for_frames(gameobject, 1)

            local fadeout_complete = false
            execute_in_context(ui.fader_context.fadeout, ui.fader_context, function()
               fadeout_complete = true
            end)
            thread.wait_for_condition(gameobject, function() return fadeout_complete end)

            nc.post_notification(const.LEVEL_DID_APPEAR_NOTIFICATION)
         end
      end)
   end -- change_map

   local function camera_shake_request(_, magnitude, duration, easing_func)
      if magnitude > camshake_value then
         -- utils.log("shake", magnitude, duration, easing_func, runtime.current_frame)
         camshake_magnitude = magnitude
         camshake_value = magnitude
         camshake_elapsed_time = 0
         camshake_duration = duration or 0.2
         camshake_easing_func = easing_func or fastmath.easing_linear
      end
   end -- camera_shake_request

   local function show_iron_key()
      msg.post(key_placeholder_sprite, msg.ENABLE)
      sprite.play_flipbook(key_placeholder_sprite, KEY.IRON_PRESENTATION)
   end -- show_iron_key

   local function show_gold_key()
      msg.post(key_placeholder_sprite, msg.ENABLE)
      sprite.play_flipbook(key_placeholder_sprite, KEY.GOLD_PRESENTATION)
   end -- show_gold_key

   local function hide_key()
      msg.post(key_placeholder_sprite, msg.DISABLE)
   end -- hide_key

   function instance.init(self)
      context = self

      -- snd.init_sound()
      gameobject = go.get_id()
      set_instance(gameobject, instance)
      add_update_callback(instance, update)
      nc.add_observer(camera_shake_request, const.CAMERA_SHAKE_REQUEST_NOTIFICATION)
      nc.add_observer(start_wrapper, const.LEVEL_START_NOTIFICATION)
      nc.add_observer(restart, const.LEVEL_RESTART_NOTIFICATION)
      nc.add_observer(exit, const.EXIT_GAME_NOTIFICATION)
      nc.add_observer(show_iron_key, "key_iron")
      nc.add_observer(show_gold_key, "key_gold")
      nc.add_observer(hide_key, "hide_key")
      window.set_listener(window_event_listener)

      camshake_magnitude = 0
      health = msg.url("health")
      currency = msg.url("currency")
      projectile = msg.url("projectile")
      key_placeholder = msg.url("key_placeholder")
      key_placeholder_sprite = msg.url("key_placeholder#sprite")

      change_map(nil, nil, nil, 0)

      -- local filename = sys.get_save_file(gamestate.get_app_id(), "meta")
      -- local meta = sys.load(filename)
      -- -- meta.current_slot = 1
      -- local current_slot = meta.current_slot
      -- if current_slot and gamestate.slot_exists(current_slot) then
      --    gamestate.set_save_slot(current_slot)
      --    fmod.studio.system:get_bus("bus:/soundfx"):set_volume(gamestate.get(nil, gamestate.player, "sound_volume", 100) / 100)
      --    fmod.studio.system:get_bus("bus:/music"):set_volume(gamestate.get(nil, gamestate.player, "music_volume", 100) / 100)
      --
      --    -- health counter setup --
      --
      --    max_health = gamestate.get(nil, gamestate.player, "max_health", 3)
      --
      --    for i = #health_sprites, (max_health + 1), -1 do
      --       msg.post(health_sprites[i], msg.DISABLE)
      --       health_sprites[i] = nil
      --    end
      --
      --    vector3_set_xyz(vector3_stub, -game.view_half_width + 10, game.view_half_height - 8, 0)
      --    go.set_position(vector3_stub, health)
      --
      --    health_counter = Counter.new(
      --    health_sprites,
      --    {
      --       hash("heart_empty"),
      --       hash("heart_full"),
      --    },
      --    20,
      --    nil,
      --    gamestate.get(nil, gamestate.player, "health", max_health),
      --    {
      --       [0] = 0,
      --       [1] = 1,
      --       [2] = 3,
      --       [3] = 7,
      --       [4] = 15,
      --       [5] = 31,
      --       [6] = 63,
      --    })
      --
      --    -- currency counter setup --
      --
      --    vector3_set_xyz(vector3_stub, game.view_half_width - 39, game.view_half_height - 8, 0)
      --    go.set_position(vector3_stub, currency)
      --
      --    currency_symbol = msg.url("currency#symbol")
      --    sprite.play_flipbook(currency_symbol, CURRENCY_SYMBOL, on_currency_animation_end, { offset = 1 })
      --
      --    currency_counter = Counter.new(
      --    {
      --       msg.url("currency#ones"),
      --       msg.url("currency#tens"),
      --       msg.url("currency#hundreds"),
      --       msg.url("currency#thousands"),
      --    },
      --    counter_digits,
      --    20,
      --    nil,
      --    gamestate.get(nil, gamestate.player, "wealth", 0))
      --
      --    -- projectiles counter setup --
      --
      --    vector3_set_xyz(vector3_stub, game.view_half_width - 70, game.view_half_height - 8, 0)
      --    go.set_position(vector3_stub, projectile)
      --
      --    projectile_symbol = msg.url("projectile#symbol")
      --    sprite.play_flipbook(projectile_symbol, PROJECTILE_SYMBOL, on_projectile_animation_end, { offset = 1 })
      --
      --    projectiles_counter = Counter.new(
      --    {
      --       msg.url("projectile#ones"),
      --    },
      --    counter_digits,
      --    20,
      --    nil,
      --    gamestate.get(nil, gamestate.player, "projectiles", 0))
      --
      --    start_checkpoint = {
      --       map = "level1",
      --       location = "teleport1",
      --    }
      --    -- game.map = nil
      --
      --    local ids = collectionfactory.create(player_factory, const.VECTOR3_ZERO)
      --    player_id = ids[ROOT]
      --    nc.add_observer(change_map_wrapper, const.ENTITY_DID_LEAVE_LEVEL_NOTIFICATION, player_id)
      --
      --    change_map(nil, player_id, nil, 0)
      --    snd.start_music(snd.AROUND_THE_CASTLE_LOOP)
      -- else
      --    change_map(nil, nil, nil, 0)
      -- end
   end -- instance.init

   function instance.deinit()
      nc.remove_observer(change_map_wrapper, const.ENTITY_DID_LEAVE_LEVEL_NOTIFICATION, player)
      nc.remove_observer(camera_shake_request, const.CAMERA_SHAKE_REQUEST_NOTIFICATION)
      nc.remove_observer(start_wrapper, const.LEVEL_START_NOTIFICATION)
      nc.remove_observer(restart, const.LEVEL_RESTART_NOTIFICATION)
      nc.remove_observer(exit, const.EXIT_GAME_NOTIFICATION)
      nc.remove_observer(show_iron_key, "key_iron")
      nc.remove_observer(show_gold_key, "key_gold")
      nc.remove_observer(hide_key, "hide_key")
      remove_update_callback(instance)
      set_instance(gameobject, nil)
   end -- instance.deinit

   return instance
end -- make

local pool = Pool.new(make)

game.view_aabb = { 0, 0, 0, 0 }
game.new = pool.new
game.free = pool.free

return game
