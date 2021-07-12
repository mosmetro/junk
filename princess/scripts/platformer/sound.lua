-- localization
local fmod = fmod
local fmod_studio_system = fmod.studio.system
-- local resource = resource
-- keys
local M = {
   -- gui
   BUTTON_CLICK = hash("BUTTON_CLICK"),

   -- player
   SHANTAE_CANNON_SHOT = hash("SHANTAE_CANNON_SHOT"),
   SHANTAE_LAND = hash("SHANTAE_LAND"),
   SHANTAE_HAT_OPEN = hash("SHANTAE_HAT_OPEN"),
   SHANTAE_DUCK = hash("SHANTAE_DUCK"),
   SHANTAE_WHIP_1 = hash("SHANTAE_WHIP_1"),
   SHANTAE_CRAWL = hash("SHANTAE_CRAWL"),
   SHANTAE_FOOT_STEP_CEMENT_1 = hash("SHANTAE_FOOT_STEP_CEMENT_1"),
   SHANTAE_FOOT_STEP_CEMENT_2 = hash("SHANTAE_FOOT_STEP_CEMENT_2"),
   SHANTAE_FOOT_STEP_CEMENT_3 = hash("SHANTAE_FOOT_STEP_CEMENT_3"),
   SHANTAE_FOOT_STEP_CEMENT_4 = hash("SHANTAE_FOOT_STEP_CEMENT_4"),
   SHANTAE_FOOT_STEP_CEMENT_5 = hash("SHANTAE_FOOT_STEP_CEMENT_5"),
   SHANTAE_FOOT_STEP_CEMENT_6 = hash("SHANTAE_FOOT_STEP_CEMENT_6"),
   SHANTAE_FOOT_STEP_CEMENT_7 = hash("SHANTAE_FOOT_STEP_CEMENT_7"),
   SHANTAE_FOOT_STEP_CEMENT_8 = hash("SHANTAE_FOOT_STEP_CEMENT_8"),

   -- general
   SHANTAE_EXPLOSION_POPCORN_1 = hash("SHANTAE_EXPLOSION_POPCORN_1"),
   SHANTAE_EXPLOSION_POPCORN_2 = hash("SHANTAE_EXPLOSION_POPCORN_2"),
   SHANTAE_EXPLOSION_POPCORN_3 = hash("SHANTAE_EXPLOSION_POPCORN_3"),
   SHANTAE_HIT_GLASS_01 = hash("SHANTAE_HIT_GLASS_01"),
   SHANTAE_HIT_GLASS_02 = hash("SHANTAE_HIT_GLASS_02"),

   SHANTAE_ITEM_BOUNCE = hash("SHANTAE_ITEM_BOUNCE"),
   SHANTAE_PICKUP_GEM_SMALL = hash("SHANTAE_PICKUP_GEM_SMALL"),
   SHANTAE_PICKUP_GEM_MEDIUM = hash("SHANTAE_PICKUP_GEM_MEDIUM"),
   SHANTAE_PICKUP_GEM_LARGE = hash("SHANTAE_PICKUP_GEM_LARGE"),

   SHANTAE_CLAY_JUG_SHATTER_LARGE = hash("SHANTAE_CLAY_JUG_SHATTER_LARGE"),
   SHANTAE_CLAY_JUG_SHATTER_MEDIUM = hash("SHANTAE_CLAY_JUG_SHATTER_MEDIUM"),
   SHANTAE_CLAY_JUG_SHATTER_SMALL = hash("SHANTAE_CLAY_JUG_SHATTER_SMALL"),

   SHANTAE_SHOOT_PISTOL = hash("SHANTAE_SHOOT_PISTOL"),
   SHANTAE_BULLET_HIT_WALL = hash("SHANTAE_BULLET_HIT_WALL"),

   SHANTAE_DOWN_THRUST_START = hash("SHANTAE_DOWN_THRUST_START"),
   SHANTAE_DOWN_THRUST_LAND = hash("SHANTAE_DOWN_THRUST_LAND"),

   SHANTAE_TEXT_TYPEOUT = hash("SHANTAE_TEXT_TYPEOUT"),
   SHANTAE_INITIATE_DIALOG = hash("SHANTAE_INITIATE_DIALOG"),
   SHANTAE_CANCEL = hash("SHANTAE_CANCEL"),
   SHANTAE_CONFIRM = hash("SHANTAE_CONFIRM"),

   SHANTAE_DEATH_SCREAM = hash("SHANTAE_DEATH_SCREAM"),

   SHANTAE_DESCEND_ROPE = hash("SHANTAE_DESCEND_ROPE"),
   SHANTAE_CLIMB_ROPE = hash("SHANTAE_CLIMB_ROPE"),
   SHANTAE_GRAB_ROPE = hash("SHANTAE_GRAB_ROPE"),

   SHANTAE_HIT_SPIKES = hash("SHANTAE_HIT_SPIKES"),

   SHANTAE_PICKUP_GEM = {
      [1] = hash("SHANTAE_PICKUP_GEM_SMALL"),
      [2] = hash("SHANTAE_PICKUP_GEM_MEDIUM"),
      [3] = hash("SHANTAE_PICKUP_GEM_LARGE"),
   },
} -- keys

-- storage
local soundfx = {}

local function init_sound()
   fmod_studio_system:load_bank_memory(resource.load("/banks/mobile/master.bank"), fmod.STUDIO_LOAD_BANK_NORMAL)
   fmod_studio_system:load_bank_memory(resource.load("/banks/mobile/master.strings.bank"), fmod.STUDIO_LOAD_BANK_NORMAL)
   -- fmod_studio_system:load_bank_memory(resource.load("/banks/mobile/music.bank"), fmod.STUDIO_LOAD_BANK_NORMAL)
   local soundfx_bank = fmod_studio_system:load_bank_memory(resource.load("/banks/mobile/soundfx.bank"), fmod.STUDIO_LOAD_BANK_NORMAL)
   soundfx_bank:load_sample_data()

   soundfx[M.BUTTON_CLICK] = fmod_studio_system:get_event("event:/goblin-sword-button2")

   soundfx[M.SHANTAE_CANNON_SHOT] = fmod_studio_system:get_event("event:/shantae_player_risky_cannon_fire")
   soundfx[M.SHANTAE_LAND] = fmod_studio_system:get_event("event:/shantae_player_land")
   soundfx[M.SHANTAE_HAT_OPEN] = fmod_studio_system:get_event("event:/shantae_player_risky_hat_open")
   soundfx[M.SHANTAE_DUCK] = fmod_studio_system:get_event("event:/shantae_player_risky_duck")
   soundfx[M.SHANTAE_WHIP_1] = fmod_studio_system:get_event("event:/shantae_player_hair_whip_normal")
   soundfx[M.SHANTAE_CRAWL] = fmod_studio_system:get_event("event:/shantae_player_crawl_squeaky")

   soundfx[M.SHANTAE_FOOT_STEP_CEMENT_1] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_cement_01")
   soundfx[M.SHANTAE_FOOT_STEP_CEMENT_2] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_cement_02")
   soundfx[M.SHANTAE_FOOT_STEP_CEMENT_3] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_cement_03")
   soundfx[M.SHANTAE_FOOT_STEP_CEMENT_4] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_cement_04")
   soundfx[M.SHANTAE_FOOT_STEP_CEMENT_5] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_cement_05")
   soundfx[M.SHANTAE_FOOT_STEP_CEMENT_6] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_cement_06")
   soundfx[M.SHANTAE_FOOT_STEP_CEMENT_7] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_cement_07")
   soundfx[M.SHANTAE_FOOT_STEP_CEMENT_8] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_cement_08")

   soundfx[M.SHANTAE_EXPLOSION_POPCORN_1] = fmod_studio_system:get_event("event:/shantae_explosion_popcorn_01")
   soundfx[M.SHANTAE_EXPLOSION_POPCORN_2] = fmod_studio_system:get_event("event:/shantae_explosion_popcorn_02")
   soundfx[M.SHANTAE_EXPLOSION_POPCORN_3] = fmod_studio_system:get_event("event:/shantae_explosion_popcorn_03")

   soundfx[M.SHANTAE_HIT_GLASS_01] = fmod_studio_system:get_event("event:/shantae_player_patty_hit_glass_01")
   soundfx[M.SHANTAE_HIT_GLASS_02] = fmod_studio_system:get_event("event:/shantae_player_patty_hit_glass_02")

   soundfx[M.SHANTAE_ITEM_BOUNCE] = fmod_studio_system:get_event("event:/shantae_item_bounce_chest")
   soundfx[M.SHANTAE_PICKUP_GEM_SMALL] = fmod_studio_system:get_event("event:/shantae_pickup_gem_small")
   soundfx[M.SHANTAE_PICKUP_GEM_MEDIUM] = fmod_studio_system:get_event("event:/shantae_pickup_gem_med")
   soundfx[M.SHANTAE_PICKUP_GEM_LARGE] = fmod_studio_system:get_event("event:/shantae_pickup_gem_large")

   soundfx[M.SHANTAE_CLAY_JUG_SHATTER_LARGE] = fmod_studio_system:get_event("event:/shantae_clay_jug_shatter_large")
   soundfx[M.SHANTAE_CLAY_JUG_SHATTER_MEDIUM] = fmod_studio_system:get_event("event:/shantae_clay_jug_shatter_medium")
   soundfx[M.SHANTAE_CLAY_JUG_SHATTER_SMALL] = fmod_studio_system:get_event("event:/shantae_clay_jug_shatter_small")

   soundfx[M.SHANTAE_SHOOT_PISTOL] = fmod_studio_system:get_event("event:/shantae_player_risky_shoot_pistol")
   soundfx[M.SHANTAE_BULLET_HIT_WALL] = fmod_studio_system:get_event("event:/shantae_boss_risky_pistol_impact")

   soundfx[M.SHANTAE_DOWN_THRUST_START] = fmod_studio_system:get_event("event:/shantae_player_ninja_projectile_throw")
   soundfx[M.SHANTAE_DOWN_THRUST_LAND] = fmod_studio_system:get_event("event:/shantae_enemy_stomp")

   soundfx[M.SHANTAE_TEXT_TYPEOUT] = fmod_studio_system:get_event("event:/shantae_menu_text_types_out_02")
   soundfx[M.SHANTAE_INITIATE_DIALOG] = fmod_studio_system:get_event("event:/shantae_interface_initiate_dialogue")
   soundfx[M.SHANTAE_CANCEL] = fmod_studio_system:get_event("event:/shantae_menu_cancel")
   soundfx[M.SHANTAE_CONFIRM] = fmod_studio_system:get_event("event:/shantae_menu_confirm")

   soundfx[M.SHANTAE_DEATH_SCREAM] = fmod_studio_system:get_event("event:/shantae_vo_s_death_01")

   soundfx[M.SHANTAE_DESCEND_ROPE] = fmod_studio_system:get_event("event:/shantae_player_descend_rope")
   soundfx[M.SHANTAE_CLIMB_ROPE] = fmod_studio_system:get_event("event:/shantae_player_climb_rope")
   soundfx[M.SHANTAE_GRAB_ROPE] = fmod_studio_system:get_event("event:/shantae_player_risky_grapple_fire")

   soundfx[M.SHANTAE_HIT_SPIKES] = fmod_studio_system:get_event("event:/shantae_ready_impact")
end -- init_sound

local function play_sound(key, volume)
   local instance = soundfx[key]:create_instance()
   if volume then
      instance:set_volume(volume)
   end
   instance:start()
end -- play_sound

M.init_sound = init_sound
M.play_sound = play_sound

-- export
return M
