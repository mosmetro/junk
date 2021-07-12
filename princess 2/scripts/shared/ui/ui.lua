-- local utils = require("scripts.shared.utils")

-- event types
local POINTER_DOWN      = hash("pointer_down")
local POINTER_UP        = hash("pointer_up")
local POINTER_DRAGGED   = hash("pointer_dragged")
local POINTER_CANCELLED = hash("pointer_cancelled")

-- export
return {
	POINTER_DOWN = POINTER_DOWN,
	POINTER_UP = POINTER_UP,
	POINTER_DRAGGED = POINTER_DRAGGED,
	POINTER_CANCELLED = POINTER_CANCELLED,
}
