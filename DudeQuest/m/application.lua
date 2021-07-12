local tostring = tostring
local get_save_file = sys.get_save_file

local set_application_id
local get_application_id
local set_save_slot
local get_save_slot
local get_save_path

local app_id
local slot_id
local save_id

function get_save_path(file_name)
   return get_save_file(save_id, file_name)
end

function set_application_id(str)
   app_id = tostring(str)
   save_id = app_id .. tostring(slot_id)
end

function get_application_id()
   return app_id
end

function set_save_slot(number)
   slot_id = number
   save_id = app_id .. tostring(slot_id)
end

function get_save_slot()
   return slot_id
end

return {
   set_application_id = set_application_id,
   get_application_id = get_application_id,
   set_save_slot = set_save_slot,
   get_save_slot = get_save_slot,
   get_save_path = get_save_path,
}
