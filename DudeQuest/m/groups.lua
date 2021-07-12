-- localization
local hash = hash

-- export
return {
   ENTITY         = hash("entity"),
   SLOPE          = hash("slope"),

   ENEMY          = hash("enemy"),
   ENEMY_HITBOX   = hash("enemy_hitbox"),
   ENEMY_HURTBOX  = hash("enemy_hurtbox"),

   PROPS_HITBOX   = hash("props_hitbox"),
   PROPS_HURTBOX  = hash("props_hurtbox"),

   PLAYER         = hash("player"),
   PLAYER_HITBOX  = hash("player_hitbox"),
   PLAYER_HURTBOX = hash("player_hurtbox"),

   SENSOR         = hash("sensor"),
   TRIGGER        = hash("trigger"),
   SOLID          = hash("solid"),
   ONEWAY         = hash("oneway"),
   BOX            = hash("box"),

   INVISIBLE_WALL = hash("invisible_wall"),
}
