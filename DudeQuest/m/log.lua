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

if shared_state_module.some_go_context then
   local current = _G[3700146495]
   _G[3700146495] = shared_state_module.some_go_context
   local result = go.get_world_transform()
   _G[3700146495] = current
   print(result)
end

return setmetatable({}, {
   __call = function(...)
      return log(...)
   end
})
