return {
   ROOT = hash("/root"),
   EMPTY = hash(""),

   LANGUAGE_DID_CHANGE_NOTIFICATION = hash("language_did_change_notification"),

   POST_INIT_NOTIFICATION = hash("post_init_notification"),

   LEVEL_WILL_APPEAR_NOTIFICATION      = hash("level_will_appear_notification"),
   LEVEL_DID_APPEAR_NOTIFICATION       = hash("level_did_appear_notification"),

   LEVEL_WILL_DISAPPEAR_NOTIFICATION   = hash("level_will_disappear_notification"),
   LEVEL_DID_DISAPPEAR_NOTIFICATION    = hash("level_did_disappear_notification"),

   ENTITY_DID_LEAVE_LEVEL_NOTIFICATION = hash("entity_did_leave_level_notification"),

   PLATFORM_READY_NOTIFICATION = hash("platform_ready_notification"),
   READY_NOTIFICATION = hash("ready_notification"),

   CAMERA_SHAKE_REQUEST_NOTIFICATION = hash("camera_shake_request_notification"),

   START_GAME = hash("start_game"),
   END_GAME = hash("end_game"),
   GAME_WILL_END_NOTIFICATION = hash("game_will_end_notification"),

   TRIGGER_ENTER_NOTIFICATION = hash("trigger_enter_notification"),
   TRIGGER_EXIT_NOTIFICATION = hash("trigger_exit_notification"),

   ACTIVATE_NOTIFICATION = hash("activate_notification"),
   DEACTIVATE_NOTIFICATION = hash("deactivate_notification"),

   LEVEL_START_NOTIFICATION = hash("level_start_notification"),
   LEVEL_RESTART_NOTIFICATION = hash("level_restart_notification"),
   EXIT_GAME_NOTIFICATION = hash("exit_game_notification"),

   EULER_Y = hash("euler.y"),
   EULER_Z = hash("euler.z"),

   CURSOR = hash("cursor"),
   PLAYBACK_RATE = hash("playback_rate"),

   TINT = hash("tint"),
   TINT_W = hash("tint.w"),

   ROTATION = hash("rotation"),
   SCALE = hash("scale"),
   SCALE_X = hash("scale.x"),
   SCALE_Y = hash("scale.y"),

   POSITION = hash("position"),
   POSITION_X = hash("position.x"),
   POSITION_Y = hash("position.y"),

   MATERIAL = hash("material"),

   INFINITY = 1 / 0,

   VECTOR3_ZERO = vmath.vector3(0),
   VECTOR3_ONE  = vmath.vector3(1),
   VECTOR3_TWO  = vmath.vector3(2),

   QUAT_IDENTITY = vmath.quat(),
   QUAT_Y_0 = vmath.quat_rotation_y(0),
   QUAT_Y_180 = vmath.quat_rotation_y(180 * fastmath.TO_RAD),
   QUAT_Z_180 = vmath.quat_rotation_z(180 * fastmath.TO_RAD),
}
