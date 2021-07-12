local url = msg.url

return {
	INPUT = url("main:/main#script"),

	MULTI_TOUCH_CONTROLS  = url("main:/main#multi_touch_controls"),
	KEYBOARD_CONTROLS     = url("main:/main#keyboard_controls"),
	SINGLE_TOUCH_CONTROLS = url("main:/main#single_touch_controls"),
	TEST_GUI = url("main:/main#test"),
}
