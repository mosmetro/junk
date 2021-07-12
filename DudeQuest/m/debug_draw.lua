-- import
local COLOR = require("m.colors")

-- localization
local post = msg.post
local vector3 = vmath.vector3
local vector3_set_xy = fastmath.vector3_set_xy
local cosnsin = fastmath.cosnsin

local TWO_PI = math.pi * 2
local p1 = vector3()
local p2 = vector3()
local params = {
   start_point = p1,
   end_point = p2,
}
local DRAW_LINE = hash("draw_line")
local RENDER = msg.url("@render:")

---------------------------------------
-- draw_circle
---------------------------------------

local function circle(x, y, radius, segment_count, color)
	segment_count = segment_count or 16
   params.color = color or COLOR.WHITE
	local step = TWO_PI / segment_count
   local x1 = x + radius
   local y1 = y
	for i = 1, segment_count do
		local angle = i * step
      local cs, sn = cosnsin(angle)
      local x2 = x + radius * cs
      local y2 = y + radius * sn
      vector3_set_xy(p1, x1, y1)
      vector3_set_xy(p2, x2, y2)
		post(RENDER, DRAW_LINE, params)
		x1, y1 = x2, y2
	end
end -- circle

local function line(x1, y1, x2, y2, color)
   params.color = color or COLOR.WHITE
   vector3_set_xy(p1, x1, y1)
   vector3_set_xy(p2, x2, y2)
   post(RENDER, DRAW_LINE, params)
end -- line

local function rect(x, y, w, h, color) -- from bottom left clockwise
   params.color = color or COLOR.WHITE
   vector3_set_xy(p1, x, y)
   vector3_set_xy(p2, x, y + h)
   post(RENDER, DRAW_LINE, params)
   vector3_set_xy(p1, x, y + h)
   vector3_set_xy(p2, x + w, y + h)
   post(RENDER, DRAW_LINE, params)
   vector3_set_xy(p1, x + w, y + h)
   vector3_set_xy(p2, x + w, y)
   post(RENDER, DRAW_LINE, params)
   vector3_set_xy(p1, x + w, y)
   vector3_set_xy(p2, x, y)
   post(RENDER, DRAW_LINE, params)
end -- rect

local function rect_minmax(x1, y1, x2, y2, color)
   params.color = color or COLOR.WHITE
   vector3_set_xy(p1, x1, y1)
   vector3_set_xy(p2, x1, y2)
   post(RENDER, DRAW_LINE, params)
   vector3_set_xy(p1, x1, y2)
   vector3_set_xy(p2, x2, y2)
   post(RENDER, DRAW_LINE, params)
   vector3_set_xy(p1, x2, y2)
   vector3_set_xy(p2, x2, y1)
   post(RENDER, DRAW_LINE, params)
   vector3_set_xy(p1, x2, y1)
   vector3_set_xy(p2, x1, y1)
   post(RENDER, DRAW_LINE, params)
end -- rect_minmax

local function aabb(box, color)
   rect_minmax(box[1], box[2], box[3], box[4], color)
end -- aabb

-- export
return {
	circle = circle,
   line = line,
   rect = rect,
   rect_minmax = rect_minmax,
   aabb = aabb,
}
