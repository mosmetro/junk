local print = print
local getinfo = debug.getinfo

-- functions
local log

function log(...)
   local t = getinfo(2, "Sln")
   -- local s = t.short_src .. ":" .. t.currentline .. " [" .. (t.name or "") .. "]"
   -- local s = string.format("%s:%s [%s]", t.short_src, t.currentline, t.name or "")
   local s = ("%s:%s <%s>"):format(t.short_src, t.currentline, t.name or "")
   print(s, ...)
end -- log

-- export
return {
   log = log,
}
