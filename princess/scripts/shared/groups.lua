local hash = hash

-- export
return {
  -- physics
  CAMERA             = hash("camera"),
  ACTIVATOR          = hash("activator"),
  TRIGGER            = hash("trigger"),
  CRATE              = hash("crate"),
  BREAKABLE          = hash("breakable"),
	PLAYER             = hash("player"), -- for raycasts
  DEBRIS             = hash("debris"),
  BORDER             = hash("border"),
  STATIC             = hash("static"),
  ONE_WAY_STATIC     = hash("one_way_static"),
  PLATFORM           = hash("platform"),
  ONE_WAY_PLATFORM   = hash("one_way_platform"),


	-- sound
	BACKGROUND_MUSIC   = hash("music"),
	SOUND_FX           = hash("soundfx"),
}
