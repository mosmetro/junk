local hash = hash

-- export
return {
	---------------------------------------

	-- system messages. We can't add payload to system messages,
	-- every custom key in 'message' table will be ignored.

	---------------------------------------
	CLEAR_COLOR            = hash("clear_color"),

	TRIGGER_RESPONSE       = hash("trigger_response"),
	CONTACT_POINT_RESPONSE = hash("contact_point_response"),
	COLLISION_RESPONSE     = hash("collision_response"),
	RAY_CAST_RESPONSE      = hash("ray_cast_response"),
	RAY_CAST_MISSED        = hash("ray_cast_missed"),

	LOAD                   = hash("load"),
	ASYNC_LOAD             = hash("async_load"),
	UNLOAD                 = hash("unload"),
	PROXY_LOADED           = hash("proxy_loaded"),
	PROXY_UNLOADED         = hash("proxy_unloaded"),

	ENABLE                 = hash("enable"),
	DISABLE                = hash("disable"),
	INIT                   = hash("init"),
	FINAL                  = hash("final"),

	ACQUIRE_INPUT_FOCUS    = hash("acquire_input_focus"),
	RELEASE_INPUT_FOCUS    = hash("release_input_focus"),

	PLAY_ANIMATION         = hash("play_animation"),
	ANIMATION_DONE         = hash("animation_done"),

	PLAY_SOUND             = hash("play_sound"),
	STOP_SOUND             = hash("stop_sound"),

	SET_TIME_STEP          = hash("set_time_step"),

	LAYOUT_CHANGED         = hash("layout_changed"),

	ACQUIRE_CAMERA_FOCUS   = hash("acquire_camera_focus"),
	RELEASE_CAMERA_FOCUS   = hash("release_camera_focus"),
	SET_VIEW_PROJECTION    = hash("set_view_projection"),

	SET_PARENT             = hash("set_parent"),

	---------------------------------------
	-- custom messages
	---------------------------------------

	APPLICATION_START      = hash("application_start_"),
	APPLICATION_EXITED     = hash("application_exited_"),
	RESTART_LEVEL          = hash("restart_level_"),

	READY                  = hash("ready_"),

	FADEIN                 = hash("fadein_"),
	FADEOUT                = hash("fadeout_"),

	SHOW                   = hash("show_"),
	HIDE                   = hash("hide_"),

	MOUSE_DOWN             = hash("mouse_down_"),
	MOUSE_DRAGGED          = hash("mouse_dragged_"),
	MOUSE_UP               = hash("mouse_up_"),
	MOUSE_CANCELLED        = hash("mouse_cancelled_"),
	KEY_DOWN               = hash("key_down_"),
	KEY_UP                 = hash("key_up_"),
	KEY_PRESSED            = hash("key_pressed_"),

	-- ENABLE_INGAME_CONTROLS  = hash("enable_ingame_controls_"),
	-- DISABLE_INGAME_CONTROLS = hash("disable_ingame_controls_"),
	-- ENABLE_GUI_CONTROLS     = hash("enable_gui_controls_"),
	-- DISABLE_GUI_CONTROLS    = hash("disable_gui_controls_"),

	SET_WAYPOINT           = hash("set_waypoint_"),
	SET_PIVOT              = hash("set_pivot_"),
	START                  = hash("start_"),

	RAY_CAST_REQUEST       = hash("ray_cast_request_"),

	EXIT_FRAME             = hash("exit_frame_"),

	SET_VIEW               = hash("set_view_"),

	MOVE_LEFT              = hash("move_left_"),
	MOVE_RIGHT             = hash("move_right_"),
	JUMP                   = hash("jump_"),
	ABORT_JUMP             = hash("abort_jump_"),
	JUMP_OFF               = hash("jump_off_"),
	STOP                   = hash("stop_"),
	ATTACK                 = hash("attack_"),

	SET_GOLD               = hash("set_gold_"),
	COME_IN                = hash('come_in_'),
	GET_OUT                = hash('get_out_'),
	SELECT_WORLD           = hash("select_world_"),

	-- WHIP_STRIKE            = hash("whip_strike_"),
	TAKE_DAMAGE            = hash("take_damage_"),
	APPLY_DAMAGE           = hash("apply_damage_"),
	ACQUIRE_MAGIC          = hash("acquire_magic_"),

	SET_CAMERA_LOOK_AT     = hash("set_camera_look_at_"),
	SET_CAMERA_POSITION    = hash("set_camera_position_"),
	SET_CAMERA_TARGET      = hash("set_camera_target_"),
	CAMERA_READY           = hash("camera_ready_"),

	ON_HOOK                = hash("on_hook_"),

	ADD_ACTION             = hash("add_action_"),

	ON_LEFT_EDGE           = hash("on_left_edge_"),
	ON_RIGHT_EDGE          = hash("on_right_edge_"),

	DELETE                 = hash("delete_"),

	SET_UI_CONTEXT         = hash("set_ui_context_"),

	INIT_COMPLETE          = hash("init_complete_"),
}
