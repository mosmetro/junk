local COLOR = require("scripts.shared.colors")

local sin = math.sin
local cos = math.cos
local rad = math.rad
local post = msg.post
local vector3 = vmath.vector3

local circle

---------------------------------------

-- draw_circle

---------------------------------------

function circle (position, radius, segment_count)
	segment_count = segment_count or 36
	local step = rad(360) / segment_count
	local point_a = vector3(position.x + radius, position.y, 0)
	for i = 1, segment_count do
		local angle = i * step
		local point_b = vector3(position.x + radius * cos(angle), position.y + radius * sin(angle), 0)
		post("@render:", "draw_line", { start_point = point_a, end_point = point_b, color = COLOR.WHITE } )
		point_a = point_b
	end
end -- draw_circle

return {
	circle = circle,
}
