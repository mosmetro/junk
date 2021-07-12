local data = require("scripts.shared.data")
local game = require("scripts.platformer.game")
local magic_data = require("scripts.platformer.princess.magic.magic_data")

local princess_data = {
	filename = "princess_data",

	default_data = {
		lives = 2,
		hearts = 3,
		stars = 99,
		magic = game.MAGIC1,
	}
}

setmetatable(princess_data, data)

function princess_data:can_cast_magic ()
	local cost = magic_data:get_cost(self:get_magic())
end


return princess_data
