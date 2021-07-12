-- export
return {
	-- event types
	POINTER_DOWN = hash("pointer_down"),
	POINTER_UP = hash("pointer_up"),
	POINTER_DRAGGED = hash("pointer_dragged"),
	POINTER_CANCELLED = hash("pointer_cancelled"),

	-- actions
	LEFT = hash("left"),
	RIGHT = hash("right"),
	UP = hash("up"),
	DOWN = hash("down"),
	DOWN_LEFT = hash("down_left"),
	DOWN_RIGHT = hash("down_right"),
	A = hash("a"),
	B = hash("b"),
	X = hash("x"),
	Y = hash("y"),
	L = hash("l"),
	R = hash("r"),
	TOUCH = hash("touch"),
	MULTI_TOUCH = hash("multi_touch"),
	NO_ACTION = hash(""),
}
