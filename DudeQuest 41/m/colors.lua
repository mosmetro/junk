local floor = math.floor
local tonumber = tonumber
local vector4 = vmath.vector4

local function tocolor (hex, alpha)
   local r, g, b = hex:match("(%w%w)(%w%w)(%w%w)")
   r = (tonumber(r, 16) or 0) / 255
   g = (tonumber(g, 16) or 0) / 255
   b = (tonumber(b, 16) or 0) / 255
   return r, g, b, alpha or 1
end -- tocolor

-- https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua
local function hsv2rgb(h, s, v, a)
   local r, g, b

   local i = floor(h * 6);
   local f = h * 6 - i;
   local p = v * (1 - s);
   local q = v * (1 - f * s);
   local t = v * (1 - (1 - f) * s);

   i = i % 6

   if i == 0 then r, g, b = v, t, p
   elseif i == 1 then r, g, b = q, v, p
   elseif i == 2 then r, g, b = p, v, t
   elseif i == 3 then r, g, b = p, q, v
   elseif i == 4 then r, g, b = t, p, v
   elseif i == 5 then r, g, b = v, p, q
   end

   return r, g, b, a or 1
end

-- export
return {

   tocolor = tocolor,
   hsv2rgb = hsv2rgb,

   MAGENTA           = vector4(1, 0, 1, 1),
   BLACK             = vector4(0, 0, 0, 1),
   TRANSPARENT_BLACK = vector4(0, 0, 0, 0),
   WHITE             = vector4(1),
   EXAGGERATED_WHITE = vector4(1000),
   TRANSPARENT_WHITE = vector4(1, 1, 1, 0),
   RED               = vector4(1, 0, 0, 1),
   GREEN             = vector4(0, 1, 0, 1),
   BLUE              = vector4(0, 0, 1, 1),
   GREY              = vector4(tocolor("999999")),

   -- https://material.io/guidelines/style/color.html#color-color-palette
   BLUE_500 = vector4(tocolor("2196F3")),

   CYAN_A100 = vector4(tocolor("84FFFF")),
   CYAN_A200 = vector4(tocolor("18FFFF")),

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

   LIGHT_BLUE_A100 = vector4(tocolor("80D8FF")),
   LIGHT_BLUE_A200 = vector4(tocolor("40C4FF")),
   LIGHT_BLUE_A400 = vector4(tocolor("00B0FF")),
   LIGHT_BLUE_A700 = vector4(tocolor("0091EA")),

   -- SKY = vector4(tocolor("CFEFFC")),
   SKY = vector4(tocolor("C2EDFF")),

   CONTROL_COLOR = vector4(tocolor("94b0c2")),
   CONTROL_SELECTED_COLOR =  vector4(tocolor("f4f4f4")),
   CONTROL_DISABLED_COLOR = vector4(tocolor("333c57")),
   LABEL_COLOR = vector4(tocolor("f4f4f4")),
}
