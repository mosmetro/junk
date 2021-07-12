-- this module is unused now
local getinfo = debug.getinfo
local print = print

local function log(...)
	local t = getinfo(2, "Sln")
	local s = ("%s:%s <%s>"):format(t.short_src, t.currentline, t.name or "")
	print(s, ...)
end

-- local function log()
-- end

return setmetatable({}, {
	__call = function(...)
		return log(...)
	end
})
