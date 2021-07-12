local utils = require("m.utils")
local ACTIVE = hash("active")
local INACTIVE = hash("inactive")
local COMPLETED = hash("completed")
local FAILED = hash("failed")


local function process(goal)
   utils.log("test ok", goal.status, goal.process)
end


local function new(goal)

   goal.status = INACTIVE

   goal.process = process

   return goal
end

return {
   new = new,
}
