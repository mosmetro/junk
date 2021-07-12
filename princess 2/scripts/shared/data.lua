local utils = require("scripts.shared.utils")

local deep_copy_table = utils.deep_copy_table
local next = next
local get_save_file = sys.get_save_file
local save_table = sys.save
local load_table = sys.load

local data = {
	appname = "princess"
}
data.__index = data

function data:get_path ()
	return get_save_file(self.appname, self.filename)
end

-- should be called first (or call reset), instead there is no current_data
function data:load ()
	local t = load_table(self:get_path())
	self.current_data = next(t) and t or deep_copy_table(self.default_data)
end

function data:save ()
	save_table(self:get_path(), self.current_data)
end

-- should be called first (or call load), instead there is no current_data
function data:reset ()
	save_table(self:get_path(), self.default_data)
	self:load()
end

return data
