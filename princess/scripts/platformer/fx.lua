-- import
local LAYER = require("scripts.shared.layers")
-- local SND = require("scripts.platformer.sound")

-- localization
local hash = hash
local vector3 = vmath.vector3

local GEM_LARGE_ANIMATION = {
  hash("shantae_gem_large_blue"),
  hash("shantae_gem_large_green"),
  hash("shantae_gem_large_purple"),
  hash("shantae_gem_large_red"),
  hash("shantae_gem_large_yellow"),
}

local GEM_MEDIUM_ANIMATION = {
  hash("shantae_gem_medium_blue"),
  hash("shantae_gem_medium_green"),
  hash("shantae_gem_medium_purple"),
  hash("shantae_gem_medium_red"),
  hash("shantae_gem_medium_yellow"),
}

local GEM_SMALL_ANIMATION = {
  hash("shantae_gem_small_blue"),
  hash("shantae_gem_small_green"),
  hash("shantae_gem_small_purple"),
  hash("shantae_gem_small_red"),
  hash("shantae_gem_small_yellow"),
}

local GEM_LARGE_BLINK_ANIMATION = {
  hash("shantae_gem_large_blue_blink"),
  hash("shantae_gem_large_green_blink"),
  hash("shantae_gem_large_purple_blink"),
  hash("shantae_gem_large_red_blink"),
  hash("shantae_gem_large_yellow_blink"),
}

local GEM_MEDIUM_BLINK_ANIMATION = {
  hash("shantae_gem_medium_blue_blink"),
  hash("shantae_gem_medium_green_blink"),
  hash("shantae_gem_medium_purple_blink"),
  hash("shantae_gem_medium_red_blink"),
  hash("shantae_gem_medium_yellow_blink"),
}

local GEM_SMALL_BLINK_ANIMATION = {
  hash("shantae_gem_small_blue_blink"),
  hash("shantae_gem_small_green_blink"),
  hash("shantae_gem_small_purple_blink"),
  hash("shantae_gem_small_red_blink"),
  hash("shantae_gem_small_yellow_blink"),
}





-- export
return {
  PRINCESS_HOOK       = { animation = hash("princess_chain_hook"), offset = vector3( 0.0, 0.0, LAYER.FX_A) },
  PRINCESS_CHAIN_A    = { animation = hash("princess_chain_a"), offset = vector3( 0.0, 0.0, LAYER.FX_A) },
  PRINCESS_CHAIN_B    = { animation = hash("princess_chain_b"), offset = vector3( 0.0, 0.0, LAYER.FX_A) },
  IMPACT_SMALL        = { animation = hash("impact_small"), offset = vector3( 0.0, 0.0, LAYER.FX_A) },
  DESTROY             = { animation = hash("goblin-sword-fx-destroy"), offset = vector3( 1.0, 5.5, LAYER.FX_A) },
  HERO_GET_HIT        = { animation = hash("goblin-sword-fx-hero-get-hit"), offset = vector3( 0.0, - 1.0, LAYER.FX_A) },
  DUDE_JUMP_DUST      = { animation = hash("fx_dude_jump_dust"), offset = vector3(0, 0, LAYER.FX_1) },
  DUDE_RUN_DUST_RIGHT = { animation = hash("fx_dude_run_dust_right"), offset = vector3(-4, 4, LAYER.FX_1) },
  DUDE_RUN_DUST_LEFT  = { animation = hash("fx_dude_run_dust_left"), offset = vector3(4, 4, LAYER.FX_1) },
  SHANTAE_EXPLOSION   = { animation = hash("shantae_explosion"), offset = vector3( 0.0, 0.0, LAYER.FX_A) },

  SHANTAE_CLAY_JUG_LARGE_IMPACT = hash("shantae_clay_jug_large_impact"),
  SHANTAE_CLAY_JUG_MEDIUM_A_IMPACT = hash("shantae_clay_jug_medium_a_impact"),
  SHANTAE_CLAY_JUG_MEDIUM_B_IMPACT = hash("shantae_clay_jug_medium_b_impact"),
  SHANTAE_CLAY_JUG_SMALL_IMPACT = hash("shantae_clay_jug_small_impact"),

  GEM_ANIMATION = {
    [1] = GEM_SMALL_ANIMATION,
    [2] = GEM_MEDIUM_ANIMATION,
    [3] = GEM_LARGE_ANIMATION,
  },

  GEM_BLINK_ANIMATION = {
    [1] = GEM_SMALL_BLINK_ANIMATION,
    [2] = GEM_MEDIUM_BLINK_ANIMATION,
    [3] = GEM_LARGE_BLINK_ANIMATION,
  },
}
