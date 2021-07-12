-- local utils = require("m.utils")

local gamestate = require("pixelfrog.game.gamestate")

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
   SHANTAE_JUMP = hash("SHANTAE_JUMP"),
   SHANTAE_JUMP2 = hash("SHANTAE_JUMP2"),
   SHANTAE_FOOT_STEP_CEMENT_1 = hash("SHANTAE_FOOT_STEP_CEMENT_1"),
   SHANTAE_FOOT_STEP_CEMENT_2 = hash("SHANTAE_FOOT_STEP_CEMENT_2"),
   SHANTAE_FOOT_STEP_CEMENT_3 = hash("SHANTAE_FOOT_STEP_CEMENT_3"),
   SHANTAE_FOOT_STEP_CEMENT_4 = hash("SHANTAE_FOOT_STEP_CEMENT_4"),
   SHANTAE_FOOT_STEP_CEMENT_5 = hash("SHANTAE_FOOT_STEP_CEMENT_5"),
   SHANTAE_FOOT_STEP_CEMENT_6 = hash("SHANTAE_FOOT_STEP_CEMENT_6"),
   SHANTAE_FOOT_STEP_CEMENT_7 = hash("SHANTAE_FOOT_STEP_CEMENT_7"),
   SHANTAE_FOOT_STEP_CEMENT_8 = hash("SHANTAE_FOOT_STEP_CEMENT_8"),

   SHANTAE_FOOT_STEP_GRASS_1 = hash("SHANTAE_FOOT_STEP_GRASS_1"),
   SHANTAE_FOOT_STEP_GRASS_2 = hash("SHANTAE_FOOT_STEP_GRASS_2"),
   SHANTAE_FOOT_STEP_GRASS_3 = hash("SHANTAE_FOOT_STEP_GRASS_3"),
   SHANTAE_FOOT_STEP_GRASS_4 = hash("SHANTAE_FOOT_STEP_GRASS_4"),
   SHANTAE_FOOT_STEP_GRASS_5 = hash("SHANTAE_FOOT_STEP_GRASS_5"),

   -- general
   SHANTAE_EXPLOSION_LARGE_FLANGE = hash("explosion_large_flange_01"),
   SHANTAE_ENEMY_EXPLODE = hash("SHANTAE_ENEMY_EXPLODE"),
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

   SHANTAE_GETHIT = hash("SHANTAE_GETHIT"),
   SHANTAE_DEATH = hash("SHANTAE_DEATH"),

   SHANTAE_PICKUP_GEM = {
      [1] = hash("SHANTAE_PICKUP_GEM_SMALL"),
      [2] = hash("SHANTAE_PICKUP_GEM_MEDIUM"),
      [3] = hash("SHANTAE_PICKUP_GEM_LARGE"),
   },

   KAHO_JUMP = hash("KAHO_JUMP"),
   KAHO_STONE_FOOTSTEP = hash("KAHO_STONE_FOOTSTEP"),
   KAHO_GRASS_FOOTSTEP = hash("KAHO_GRASS_FOOTSTEP"),
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
   THIEF_SWORD_FLESH1 = hash("THIEF_SWORD_FLESH1"),

   THIEF_DOOR_USE_KEY = hash("THIEF_DOOR_USE_KEY"),

   RAT_BITE_MISS = hash("RAT_BITE_MISS"),
   RAT_BITE_HIT = hash("RAT_BITE_HIT"),

   -- ALICE_VORPAL_SLASH_01 = hash("ALICE_VORPAL_SLASH_01"),

   FATE_SWORD_SWING = hash("FATE_SWORD_SWING"),

   FATE_METAL_FLESH_1 = hash("FATE_METAL_FLESH_1"),
   FATE_METAL_FLESH_2 = hash("FATE_METAL_FLESH_2"),
   FATE_METAL_FLESH_3 = hash("FATE_METAL_FLESH_3"),

   FATE_SLICE_FLESH_1 = hash("FATE_SLICE_FLESH_1"),
   FATE_SLICE_FLESH_2 = hash("FATE_SLICE_FLESH_2"),
   FATE_SLICE_FLESH_3 = hash("FATE_SLICE_FLESH_3"),

   FATE_WOOD_FLESH_1 = hash("FATE_WOOD_FLESH_1"),
   FATE_WOOD_FLESH_2 = hash("FATE_WOOD_FLESH_2"),
   FATE_WOOD_FLESH_3 = hash("FATE_WOOD_FLESH_3"),

   FATE_RAT_DIE1 = hash("FATE_RAT_DIE1"),
   FATE_RAT_DIE2 = hash("FATE_RAT_DIE2"),
   FATE_DEMON_DIE1 = hash("FATE_DEMON_DIE1"),
   FATE_DEMON_DIE2 = hash("FATE_DEMON_DIE2"),
   FATE_DEMON_DIE3 = hash("FATE_DEMON_DIE3"),

   FATE_SWORD_GET = hash("FATE_SWORD_GET"),
   FATE_SWORD_DROP = hash("FATE_SWORD_DROP"),

   FATE_DOOR_CLOSED = hash("FATE_DOOR_CLOSED"),

   BARREL_BREAK = hash("BARREL_BREAK"),
   TRAMPOLINE_JUMP = hash("TRAMPOLINE_JUMP"),
   VERTICAL_WIND = hash("VERTICAL_WIND"),

   FATE_BOWMISS = hash("FATE_BOWMISS"),

   PICKUP_GOLD_00 = hash("PICKUP_GOLD_00"),
   PICKUP_GOLD_02 = hash("PICKUP_GOLD_02"),

   BLOCK_BREAK = hash("BLOCK_BREAK"),

   DOOR_OPEN = hash("DOOR_OPEN"),
   DOOR_CLOSE = hash("DOOR_CLOSE"),

   PLAYER_USE_KEY = hash("PLAYER_USE_KEY"),
   PLAYER_GET_KEY = hash("PLAYER_GET_KEY"),

   COINS_SINGLE_O1 = hash("COINS_SINGLE_O1"),

   PICKUP_COIN_COLLECT_01 = hash("PICKUP_COIN_COLLECT_01"),

   PICKUP_COIN_SMALL = hash("PICKUP_COIN_SMALL"),

   PICKUP_COIN_BOUNCE_SMALL = hash("PICKUP_COIN_BOUNCE_SMALL"),

   TP_RUPEE_LAND = hash("TP_RUPEE_LAND"),

   PICK_KEY = hash("PICK_KEY"),
   PICK_KEY1 = hash("PICK_KEY1"),
   PICK_KEY2 = hash("PICK_KEY2"),
   PICK_KEY3 = hash("PICK_KEY3"),

   TP_BOTTLE_POP = hash("TP_BOTTLE_POP"),

   TP_GET_HEART = hash("TP_GET_HEART"),

   PICK_LOOT = hash("PICK_LOOT"),

   SHIELD01 = hash("SHIELD01"),

   MALE_SCREAM_1 = hash("MALE_SCREAM_1"),

   MAGICAL_CHEST_OPENING_2 = hash("MAGICAL_CHEST_OPENING_2"),

   POP_SOUNDS_8 = hash("POP_SOUNDS_8"),
} -- keys

-- storage
local soundfx = {}

local current_music
local music_playing

local function init_sound()
   music_playing = false
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
   soundfx[M.SHANTAE_JUMP] = fmod_studio_system:get_event("event:/shantae_player_jump")
   soundfx[M.SHANTAE_JUMP2] = fmod_studio_system:get_event("event:/shantae_hgh_player_monkey_jump")

   soundfx[M.SHANTAE_FOOT_STEP_CEMENT_1] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_cement_01")
   soundfx[M.SHANTAE_FOOT_STEP_CEMENT_2] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_cement_02")
   soundfx[M.SHANTAE_FOOT_STEP_CEMENT_3] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_cement_03")
   soundfx[M.SHANTAE_FOOT_STEP_CEMENT_4] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_cement_04")
   soundfx[M.SHANTAE_FOOT_STEP_CEMENT_5] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_cement_05")
   soundfx[M.SHANTAE_FOOT_STEP_CEMENT_6] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_cement_06")
   soundfx[M.SHANTAE_FOOT_STEP_CEMENT_7] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_cement_07")
   soundfx[M.SHANTAE_FOOT_STEP_CEMENT_8] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_cement_08")

   soundfx[M.SHANTAE_FOOT_STEP_GRASS_1] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_grass_01")
   soundfx[M.SHANTAE_FOOT_STEP_GRASS_2] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_grass_02")
   soundfx[M.SHANTAE_FOOT_STEP_GRASS_3] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_grass_03")
   soundfx[M.SHANTAE_FOOT_STEP_GRASS_4] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_grass_04")
   soundfx[M.SHANTAE_FOOT_STEP_GRASS_5] = fmod_studio_system:get_event("event:/shantae_hgh_footstep_grass_05")

   soundfx[M.SHANTAE_EXPLOSION_LARGE_FLANGE] = fmod_studio_system:get_event("event:/explosion_large_flange_01")
   soundfx[M.SHANTAE_ENEMY_EXPLODE] = fmod_studio_system:get_event("event:/shantae_explode_brief")
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
   soundfx[M.SHANTAE_GETHIT] = fmod_studio_system:get_event("event:/shantae_hgh_enemy_technogrunt_gethit_03")
   soundfx[M.SHANTAE_DEATH] = fmod_studio_system:get_event("event:/shantae_hgh_enemy_technogrunt_gethit_death_01")

   soundfx[M.KAHO_JUMP] = fmod_studio_system:get_event("event:/kaho_sndJump")
   soundfx[M.KAHO_STONE_FOOTSTEP] = fmod_studio_system:get_event("event:/kaho_sndstone_footstep")
   soundfx[M.KAHO_GRASS_FOOTSTEP] = fmod_studio_system:get_event("event:/kaho_sndgrass_footstep")
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
   soundfx[M.THIEF_SWORD_FLESH1] = fmod_studio_system:get_event("event:/thief_gold_sw_armr1")

   soundfx[M.THIEF_DOOR_USE_KEY] = fmod_studio_system:get_event("event:/thief_doorw1c")

   soundfx[M.RAT_BITE_MISS] = fmod_studio_system:get_event("event:/bite1")
   soundfx[M.RAT_BITE_HIT] = fmod_studio_system:get_event("event:/bite2")

   -- soundfx[M.ALICE_VORPAL_SLASH_01] = fmod_studio_system:get_event("event:/vorpal_slash01")

   soundfx[M.FATE_SWORD_SWING] = fmod_studio_system:get_event("event:/fate_battle_swordswing")

   soundfx[M.FATE_METAL_FLESH_1] = fmod_studio_system:get_event("event:/fate_battle_metalflesh1")
   soundfx[M.FATE_METAL_FLESH_2] = fmod_studio_system:get_event("event:/fate_battle_metalflesh2")
   soundfx[M.FATE_METAL_FLESH_3] = fmod_studio_system:get_event("event:/fate_battle_metalflesh3")

   soundfx[M.FATE_SLICE_FLESH_1] = fmod_studio_system:get_event("event:/fate_battle_SliceFlesh1")
   soundfx[M.FATE_SLICE_FLESH_2] = fmod_studio_system:get_event("event:/fate_battle_SliceFlesh2")
   soundfx[M.FATE_SLICE_FLESH_3] = fmod_studio_system:get_event("event:/fate_battle_SliceFlesh3")

   soundfx[M.FATE_WOOD_FLESH_1] = fmod_studio_system:get_event("event:/fate_battle_woodFlesh1")
   soundfx[M.FATE_WOOD_FLESH_2] = fmod_studio_system:get_event("event:/fate_battle_woodFlesh2")
   soundfx[M.FATE_WOOD_FLESH_3] = fmod_studio_system:get_event("event:/fate_battle_woodFlesh3")

   soundfx[M.FATE_RAT_DIE1] = fmod_studio_system:get_event("event:/fate_rat_die1")
   soundfx[M.FATE_RAT_DIE2] = fmod_studio_system:get_event("event:/fate_rat_die2")
   soundfx[M.FATE_DEMON_DIE1] = fmod_studio_system:get_event("event:/fate_demon_die1")
   soundfx[M.FATE_DEMON_DIE2] = fmod_studio_system:get_event("event:/fate_demon_die2")
   soundfx[M.FATE_DEMON_DIE3] = fmod_studio_system:get_event("event:/fate_demon_die3")

   soundfx[M.FATE_SWORD_GET] = fmod_studio_system:get_event("event:/fate_swordget")
   soundfx[M.FATE_SWORD_DROP] = fmod_studio_system:get_event("event:/fate_sworddrop")

   soundfx[M.FATE_DOOR_CLOSED] = fmod_studio_system:get_event("event:/fate_doorclose")

   soundfx[M.BARREL_BREAK] = fmod_studio_system:get_event("event:/barrel_break")
   soundfx[M.TRAMPOLINE_JUMP] = fmod_studio_system:get_event("event:/mushroom_jump01")
   soundfx[M.VERTICAL_WIND] = fmod_studio_system:get_event("event:/mushroom_wind01")

   soundfx[M.FATE_BOWMISS] = fmod_studio_system:get_event("event:/fate_bowmiss")

   soundfx[M.PICKUP_GOLD_00] = fmod_studio_system:get_event("event:/Pickup_Gold_00")
   soundfx[M.PICKUP_GOLD_02] = fmod_studio_system:get_event("event:/Pickup_Gold_02")

   soundfx[M.BLOCK_BREAK] = fmod_studio_system:get_event("event:/block_break")

   soundfx[M.DOOR_OPEN] = fmod_studio_system:get_event("event:/london_l4_door_open01")
   soundfx[M.DOOR_CLOSE] = fmod_studio_system:get_event("event:/london_l3_door_close_b")
   soundfx[M.PLAYER_USE_KEY] = fmod_studio_system:get_event("event:/player_use_key")
   soundfx[M.PLAYER_GET_KEY] = fmod_studio_system:get_event("event:/itm_key_up")

   soundfx[M.COINS_SINGLE_O1] = fmod_studio_system:get_event("event:/Coins_Single_01")

   soundfx[M.PICKUP_COIN_COLLECT_01] = fmod_studio_system:get_event("event:/pickup_coin_collect_01")

   soundfx[M.PICKUP_COIN_SMALL] = fmod_studio_system:get_event("event:/pickup_coin_small")

   soundfx[M.PICKUP_COIN_BOUNCE_SMALL] = fmod_studio_system:get_event("event:/pickup_coin_bounce_small")

   soundfx[M.TP_RUPEE_LAND] = fmod_studio_system:get_event("event:/TP_Rupee_Land")

   soundfx[M.PICK_KEY] = fmod_studio_system:get_event("event:/pickkey")
   soundfx[M.PICK_KEY1] = fmod_studio_system:get_event("event:/pickkey1")
   soundfx[M.PICK_KEY2] = fmod_studio_system:get_event("event:/pickkey2")
   soundfx[M.PICK_KEY3] = fmod_studio_system:get_event("event:/pickkey3")

   soundfx[M.TP_BOTTLE_POP] = fmod_studio_system:get_event("event:/TP_Bottle_Pop")

   soundfx[M.TP_GET_HEART] = fmod_studio_system:get_event("event:/TP_Get_Heart")

   soundfx[M.PICK_LOOT] = fmod_studio_system:get_event("event:/pickloot")

   soundfx[M.SHIELD01] = fmod_studio_system:get_event("event:/shield01")

   soundfx[M.MALE_SCREAM_1] = fmod_studio_system:get_event("event:/Male_screams_1")

   soundfx[M.MAGICAL_CHEST_OPENING_2] = fmod_studio_system:get_event("event:/magical_chest_opening_2")

   soundfx[M.POP_SOUNDS_8] = fmod_studio_system:get_event("event:/pop_sounds_8")
end -- init_sound

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

local function start_music(key)
   if music_playing then return end
   if key then current_music = soundfx[key]:create_instance() end
   if gamestate.get(nil, gamestate.player, "music_volume", 100) == 0 then return end
   if current_music then
      current_music:start()
      music_playing = true
   end
end -- start_music

local function stop_music(mode)
   music_playing = false
   if current_music then current_music:stop(mode or fmod.STUDIO_STOP_ALLOWFADEOUT) end
end -- stop_music

M.init_sound = init_sound
M.play_sound = play_sound
M.start_music = start_music
M.stop_music = stop_music

-- export
return M
