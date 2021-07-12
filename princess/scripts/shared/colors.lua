local utils = require("scripts.shared.utils")

local tocolor = utils.tocolor
local vector4 = vmath.vector4

return {
	MAGENTA           = vector4(1, 0, 1, 1),
	WHITE             = vector4(1, 1, 1, 1),
	BLACK             = vector4(0, 0, 0, 1),
	TRANSPARENT_WHITE = vector4(1, 1, 1, 0),
	RED               = vector4(1, 0, 0, 1),
	GREY              = vector4(tocolor("999999")),

	-- https://material.io/guidelines/style/color.html#color-color-palette
	BLUE_500 = vector4(tocolor("2196F3")),

	GREY_100 = vector4(tocolor("F5F5F5")),
	GREY_200 = vector4(tocolor("EEEEEE")),
	GREY_300 = vector4(tocolor("E0E0E0")),
	GREY_400 = vector4(tocolor("BDBDBD")),
	GREY_500 = vector4(tocolor("9E9E9E")),
	GREY_600 = vector4(tocolor("757575")),
	GREY_700 = vector4(tocolor("616161")),
	GREY_800 = vector4(tocolor("424242")),
	GREY_900 = vector4(tocolor("212121")),

	YELLOW_500 = vector4(tocolor("FFEB3B")),
}
