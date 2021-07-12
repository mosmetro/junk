local DAMAGE_TYPE = require("maze.damage_type")
local TARGET_TYPE = require("maze.target_type")
-- local utils = require("m.utils")

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
   -- SHANTAE_JUMP = hash("SHANTAE_JUMP"),
   SHANTAE_JUMP2 = hash("SHANTAE_JUMP2"),
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

   KAHO_JUMP = hash("KAHO_JUMP"),
   KAHO_STONE_FOOTSTEP = hash("KAHO_STONE_FOOTSTEP"),
   KAHO_LAND_SOFT = hash("KAHO_SOFT_LAND"),
   KAHO_LAND_HARD = hash("KAHO_HARD_LAND"),
   KAHO_LADDER_ENTER = hash("KAHO_LADDER_ENTER"),
   KAHO_LADDER = hash("KAHO_LADDER"),
   KAHO_DASH = hash("KAHO_DASH"),
   KAHO_AIR_DASH = hash("KAHO_AIR_DASH"),

   AROUND_THE_CASTLE_LOOP = hash("around_the_castle_loop"),
   SHADOWCRYPT_MUSIC = hash("shadowcrypt_music"),
   PORTCULLIS = hash("portcullis"),
   ROGUE_LAND = hash("rogue_land"),
   PORTCULLIS_CLOSE = hash("portcullis_close"),
   EQUIP_SPEAR = hash("equip_spear"),
   EQUIP_SHIELD = hash("equip_shield"),
   ROGUE_FOOTSTEP = hash("rogue_footstep"),
   ROGUE_LEDGE_GRAB = hash("rogue_ledge_grab"),
   ROGUE_LEDGE_CLIMB = hash("rogue_ledge_climb"),
   ROGUE_SWORD_ATTACK = hash("rogue_sword_attack"),
   ROGUE_ENEMY_HIT = hash("rogue_enemy_hit"),
   ROGUE_BOW_SHOOT = hash("rogue_bow_shoot"),

   SWING_SWORD_01 = hash("SWING_SWORD_01"),
   SWING_SWORD_02 = hash("SWING_SWORD_02"),
   GOBLIN_SWORD_SLASH = hash("GOBLIN_SWORD_SLASH"),
   GOBLIN_SWORD_JUMP = hash("GOBLIN_SWORD_JUMP"),

   THIEF_BELL = hash("THIEF_BELL"),
   THIEF_KACHING = hash("THIEF_KACHING"),

   RAT_BITE_MISS = hash("RAT_BITE_MISS"),
   RAT_BITE_HIT = hash("RAT_BITE_HIT"),

   -- ALICE_VORPAL_SLASH_01 = hash("ALICE_VORPAL_SLASH_01"),

   FATE_SLICE_FLESH_1 = hash("FATE_SLICE_FLESH_1"),
   FATE_SLICE_FLESH_2 = hash("FATE_SLICE_FLESH_2"),
   FATE_SLICE_FLESH_3 = hash("FATE_SLICE_FLESH_3"),

   FATE_RAT_DIE1 = hash("FATE_RAT_DIE1"),
   FATE_RAT_DIE2 = hash("FATE_RAT_DIE2"),
} -- keys

-- storage
local soundfx = {}

local function init_sound()
   fmod_studio_system:load_bank_memory(resource.load("/res/common/fmod/mobile/master.bank"), fmod.STUDIO_LOAD_BANK_NORMAL)
   fmod_studio_system:load_bank_memory(resource.load("/res/common/fmod/mobile/master.strings.bank"), fmod.STUDIO_LOAD_BANK_NORMAL)
   fmod_studio_system:load_bank_memory(resource.load("/res/common/fmod/mobile/music.bank"), fmod.STUDIO_LOAD_BANK_NORMAL)
   local soundfx_bank = fmod_studio_system:load_bank_memory(resource.load("/res/common/fmod/mobile/soundfx.bank"), fmod.STUDIO_LOAD_BANK_NORMAL)
   soundfx_bank:load_sample_data()

   soundfx[M.BUTTON_CLICK] = fmod_studio_system:get_event("event:/goblin-sword-button2")

   soundfx[M.SHANTAE_CANNON_SHOT] = fmod_studio_system:get_event("event:/shantae_player_risky_cannon_fire")
   soundfx[M.SHANTAE_LAND] = fmod_studio_system:get_event("event:/shantae_player_land")
   soundfx[M.SHANTAE_HAT_OPEN] = fmod_studio_system:get_event("event:/shantae_player_risky_hat_open")
   soundfx[M.SHANTAE_DUCK] = fmod_studio_system:get_event("event:/shantae_player_risky_duck")
   soundfx[M.SHANTAE_WHIP_1] = fmod_studio_system:get_event("event:/shantae_player_hair_whip_normal")
   soundfx[M.SHANTAE_CRAWL] = fmod_studio_system:get_event("event:/shantae_player_crawl_squeaky")
   -- soundfx[M.SHANTAE_JUMP] = fmod_studio_system:get_event("event:/shantae_player_jump")
   soundfx[M.SHANTAE_JUMP2] = fmod_studio_system:get_event("event:/shantae_hgh_player_monkey_jump")

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

   soundfx[M.KAHO_JUMP] = fmod_studio_system:get_event("event:/kaho_sndJump")
   soundfx[M.KAHO_STONE_FOOTSTEP] = fmod_studio_system:get_event("event:/kaho_sndstone_footstep")
   soundfx[M.KAHO_LAND_SOFT] = fmod_studio_system:get_event("event:/kaho_sndSoftland")
   soundfx[M.KAHO_LAND_HARD] = fmod_studio_system:get_event("event:/kaho_sndHardland")
   soundfx[M.KAHO_LADDER_ENTER] = fmod_studio_system:get_event("event:/kaho_sndLadder1")
   soundfx[M.KAHO_LADDER] = fmod_studio_system:get_event("event:/kaho_sndLadder2")
   soundfx[M.KAHO_DASH] = fmod_studio_system:get_event("event:/kaho_sndRoll")
   soundfx[M.KAHO_AIR_DASH] = fmod_studio_system:get_event("event:/kaho_sndAirRoll")

   soundfx[M.AROUND_THE_CASTLE_LOOP] = fmod_studio_system:get_event("event:/around-the-castle-loop")
   soundfx[M.SHADOWCRYPT_MUSIC] = fmod_studio_system:get_event("event:/snd_shadowcrypt_music")

   soundfx[M.PORTCULLIS] = fmod_studio_system:get_event("event:/snd_portcullis")
   soundfx[M.ROGUE_LAND] = fmod_studio_system:get_event("event:/snd_land")
   soundfx[M.PORTCULLIS_CLOSE] = fmod_studio_system:get_event("event:/doorc1c")
   soundfx[M.EQUIP_SHIELD] = fmod_studio_system:get_event("event:/snd_equipshield")
   soundfx[M.EQUIP_SPEAR] = fmod_studio_system:get_event("event:/snd_equipspear")
   soundfx[M.ROGUE_FOOTSTEP] = fmod_studio_system:get_event("event:/snd_footstep")
   soundfx[M.ROGUE_LEDGE_GRAB] = fmod_studio_system:get_event("event:/snd_ledgehang")
   soundfx[M.ROGUE_LEDGE_CLIMB] = fmod_studio_system:get_event("event:/snd_ledgeclimb")
   soundfx[M.ROGUE_SWORD_ATTACK] = fmod_studio_system:get_event("event:/snd_swordslash")
   soundfx[M.ROGUE_ENEMY_HIT] = fmod_studio_system:get_event("event:/snd_enemyhit")
   soundfx[M.ROGUE_BOW_SHOOT] = fmod_studio_system:get_event("event:/snd_bowshoot")

   soundfx[M.SWING_SWORD_01] = fmod_studio_system:get_event("event:/swing_sword_01")
   soundfx[M.SWING_SWORD_02] = fmod_studio_system:get_event("event:/swing_sword_02")
   soundfx[M.GOBLIN_SWORD_SLASH] = fmod_studio_system:get_event("event:/goblin-sword-slash")
   soundfx[M.GOBLIN_SWORD_JUMP] = fmod_studio_system:get_event("event:/goblin-sword-jump")

   soundfx[M.THIEF_BELL] = fmod_studio_system:get_event("event:/bellchur")
   soundfx[M.THIEF_KACHING] = fmod_studio_system:get_event("event:/kaching")

   soundfx[M.RAT_BITE_MISS] = fmod_studio_system:get_event("event:/bite1")
   soundfx[M.RAT_BITE_HIT] = fmod_studio_system:get_event("event:/bite2")

   -- soundfx[M.ALICE_VORPAL_SLASH_01] = fmod_studio_system:get_event("event:/vorpal_slash01")

   soundfx[M.FATE_SLICE_FLESH_1] = fmod_studio_system:get_event("event:/fate_battle_SliceFlesh1")
   soundfx[M.FATE_SLICE_FLESH_2] = fmod_studio_system:get_event("event:/fate_battle_SliceFlesh2")
   soundfx[M.FATE_SLICE_FLESH_3] = fmod_studio_system:get_event("event:/fate_battle_SliceFlesh3")

   soundfx[M.FATE_RAT_DIE1] = fmod_studio_system:get_event("event:/fate_rat_die1")
   soundfx[M.FATE_RAT_DIE2] = fmod_studio_system:get_event("event:/fate_rat_die2")

end -- init_sound

local hit_sound = {
   [DAMAGE_TYPE.SLASH] = {
      [TARGET_TYPE.FLESH] = { M.FATE_SLICE_FLESH_1, M.FATE_SLICE_FLESH_2, M.FATE_SLICE_FLESH_3, },
   },
}

local function get_hit_sound(damage_type, target_type)
   return hit_sound[damage_type][target_type]
end -- get_hit_sound

local function play_sound(key, volume, attr)
   local instance = soundfx[key]:create_instance()
   if volume then
      instance:set_volume(volume)
   end
   if attr then
      instance:set_3d_attributes(attr)
   end
   instance:start()
end -- play_sound

M.init_sound = init_sound
M.play_sound = play_sound
M.get_hit_sound = get_hit_sound

-- export
return M
