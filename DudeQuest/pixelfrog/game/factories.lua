local GEM_BLUE = msg.url("game:/collectable#gem_blue")
local GEM_GREEN = msg.url("game:/collectable#gem_green")
local GEM_RED = msg.url("game:/collectable#gem_red")
local GEM_ORANGE = msg.url("game:/collectable#gem_orange")
local GEM_BLACK = msg.url("game:/collectable#gem_black")

return {
   CAPTAIN_JUMP_DUST = msg.url("game:/characters#captain_jump_dust"),
   CAPTAIN_AIR_JUMP_DUST = msg.url("game:/characters#captain_jump_dust2"),
   CAPTAIN_LAND_DUST = msg.url("game:/characters#captain_fall_dust"),
   CAPTAIN_RUN_DUST = msg.url("game:/characters#captain_run_dust"),
   CAPTAIN_SWORD_SPINNING = msg.url("game:/characters#sword_spinning"),
   CAPTAIN_SWORD_HIT = msg.url("game:/characters#sword_hit"),

   EFFECT_SWORD_HIT = msg.url("game:/effects#effect_sword_hit"),
   EFFECT_EXPLOSION = msg.url("game:/effects#effect_explosion"),
   EFFECT_SMALL_PUFF = msg.url("game:/effects#effect_small_puff"),
   EFFECT_CIRCLE_PUFF = msg.url("game:/effects#circle_puff"),

   COIN_GOLD = msg.url("game:/collectable#coin_gold"),
   COIN_SILVER = msg.url("game:/collectable#coin_silver"),
   GEM_BLUE = GEM_BLUE,
   GEM_GREEN = GEM_GREEN,
   GEM_RED = GEM_RED,
   GEM_ORANGE = GEM_ORANGE,
   GEM_BLACK = GEM_BLACK,

   GEMS = {
      GEM_BLUE,
      GEM_GREEN,
      GEM_RED,
      GEM_ORANGE,
      GEM_BLACK,
   },

   HEART = msg.url("game:/collectable#heart"),

   SWORD_PICKUP = msg.url("game:/collectable#sword_pickup"),

   KEY_IRON = msg.url("game:/collectable#key_iron"),
   KEY_GOLD = msg.url("game:/collectable#key_gold"),

   CAPTAIN = msg.url("game:/characters#captain"),

   AMMO_BOX = msg.url("game:/enemies#ammo_box"),
   AMMO_BOX_DESTROYED = msg.url("game:/enemies#ammo_box_destroyed"),

   AMMO_BOMB = msg.url("game:/enemies#ammo_bomb"),
   AMMO_BOMB_EXPLODE = msg.url("game:/enemies#ammo_bomb_explode"),

   CANNON_BALL = msg.url("game:/props#cannon_ball"),
   CANNON_BALL_EXPLOSION = msg.url("game:/props#cannon_ball_explosion"),
}
