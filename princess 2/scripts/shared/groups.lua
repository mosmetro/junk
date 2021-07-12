local hash = hash

-- export
return {
	-- collision
	CRATE              = hash("crate"),

	PLAYER             = hash("player"), -- for raycasts
	PLAYER_HITBOX      = hash("player_hitbox"),

	PIN                = hash("pin"),
	HOOK               = hash("hook"),

	ENEMY              = hash("enemy"),
	ENEMY_HITBOX       = hash("enemy_hitbox"),

	TRIGGER_TURN_LEFT  = hash("trigger_turn_left"),
	TRIGGER_TURN_RIGHT = hash("trigger_turn_right"),
	TRIGGER_JUMP       = hash("trigger_jump"),

	STATIC             = hash("static"),
	ONE_WAY_STATIC     = hash("one_way_static"),

	CAMERA             = hash("camera"),
	PLATFORM           = hash("platform"),
	ONE_WAY_PLATFORM   = hash("one_way_platform"),
	MACHINERY          = hash("machinery"),


	-- sound
	BACKGROUND_MUSIC   = hash("music"),
	SOUND_FX           = hash("soundfx"),
}
