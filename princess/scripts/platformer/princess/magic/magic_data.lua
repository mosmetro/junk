local data = require("scripts.shared.data")
local game = require("scripts.platformer.game")

local MAGIC1 = game.MAGIC1
local MAGIC2 = game.MAGIC2
local MAGIC3 = game.MAGIC3
local MAGIC4 = game.MAGIC4
local MAGIC5 = game.MAGIC5
local MAGIC6 = game.MAGIC6

local magic_data = {
	filename = "magic_data",

	items = {
		[MAGIC1] = {
			basic = {
				title = "magic_arrow",
				cost = 2,
			},
			advanced = {
				title = "",
				cost = 8,
			},
			image = "ui_magic1",
		},

		[MAGIC2] = {
			basic = {
				title = "lollypop",
				cost = 4,
			},
			advanced = {
				title = "",
				cost = 12,
			},
			image = "ui_magic2",
		},

		[MAGIC3] = {
			title = "hook",
			cost = 0,
			image = "ui_magic3",
		},

		[MAGIC4] = {
			title = "ice_arrow",
			cost = 3,
			image = "ui_magic4",
		},

		[MAGIC5] = {
			title = "fire_arrow",
			cost = 3,
			image = "ui_magic5",
		},

		[MAGIC6] = {
			title = "sonic",
			cost = 2,
			image = "ui_magic6",
		},
	},

	default_data = {
		[MAGIC1] = {
			discovered = true,
		},

		[MAGIC2] = {
			discovered = false,
		},

		[MAGIC3] = {
			discovered = false,
		},

		[MAGIC4] = {
			discovered = false,
		},

		[MAGIC5] = {
			discovered = false,
		},

		[MAGIC6] = {
			discovered = false,
		},
	}
}

setmetatable(magic_data, data)
