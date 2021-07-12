-- localization
local get_save_file = sys.get_save_file
local load = sys.load
local save = sys.save
local format = string.format
local floor = math.floor

-- functions
local get_path
local load_table
local save_table
local play_time_from_seconds
local get_play_time
local set_id
local get_id

local APPLICATION_ID = nil

function set_id(id)
	APPLICATION_ID = id
end -- set_id

function get_id()
	return APPLICATION_ID
end

function get_path(file)
	return get_save_file(APPLICATION_ID, file)
end -- get_path

function load_table(file)
	return load(get_path(file))
end -- load_table

function save_table(tbl, file)
	save(get_path(file), tbl)
end -- save_table

function play_time_from_seconds(seconds)
	local hours = floor(seconds / 3600)
	local mins  = floor(seconds / 60 - hours * 60)
	local secs  = floor(seconds - hours * 3600 - mins * 60)
	return format("%02.f:%02.f:%02.f", hours, mins, secs)
end -- play_time_from_seconds

function get_play_time(file)
	local data = load_table(file)
	return data.play_time and play_time_from_seconds(data.play_time) or nil
end -- get_play_time

-- export
return {
	set_id = set_id,
	get_id = get_id,
	load_table = load_table,
	save_table = save_table,
	get_play_time = get_play_time,
	play_time_from_seconds = play_time_from_seconds,
}
