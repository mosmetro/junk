-- local ui = require("m.ui.ui")
local utils = require("m.utils")

local tostring = tostring
local concat = table.concat
local get_save_file = sys.get_save_file
local sys_load = sys.load
local sys_save = sys.save

local gamestate = {}

local names = {
   "player",

   "pink_star",
   "fierce_tooth",
   "crabby",

   "chest_gold",
   "chest_iron",

   "/passage1",
   "/passage2",
   "/passage3",
   "/passage4",

   "/teleport1/root",

   "checkpoint1",
   "checkpoint2",
   "checkpoint3",
   "checkpoint4",

   "door1",
   "door2",
   "door3",
   "door4",

   "sword_spawner",
   "key_spawner",

   "level101",
   "level1",
   "level2",
   "level3",

   -- kind
   "currency",
   "projectile",
   "key",
   "health",

   -- variant
   "coin_silver",
   "coin_gold",
   "gem_blue",
   "gem_green",
   "gem_red",
   "gem_orange",
   "gem_black",
   "sword",
   "key_iron",
   "key_gold",
   "heart",

   -- configurable onscreen controls
   -- "a", "b", "x", "y", "left", "right", "up", "down"

   -- "/checkpoint1/root",
   -- "/checkpoint2/root",
   -- "/checkpoint3/root",
}

for i = 1, #names do
   local name = names[i]
   local hashed_name = hash(name)
   gamestate[name] = hashed_name
   gamestate[hashed_name] = name
end

local COMMON = hash("common")
local storage = {}

local slot_names = { "slot1", "slot2", "slot3", "slot4" }
-- local slot_indexes = {}
-- for i, n in next, slot_names do
--    slot_indexes[n] = i
-- end

local location_components = {
   "com.anything.pixelfrog", -- application
   "", -- slot
   "", -- map
}

local function get_app_id()
   return location_components[1]
end -- get_app_id

local function get_save_slot()
   local slot = location_components[2]
   if slot == "slot1" then return 1 end
   if slot == "slot2" then return 2 end
   if slot == "slot3" then return 3 end
   if slot == "slot4" then return nil end
   return nil
end

local function reset_slot()
   location_components[2] = ""
end --reset_slot

local function get_metadata(map_hash, entity_hash)
   map_hash = map_hash or COMMON
   local map = storage[map_hash] or {}
   local metadata = map[entity_hash]
   if not metadata then
      -- utils.log("reading from file", map_hash, entity_hash)
      metadata = {
         path_to_file = 0,
         payload = 0,
         dirty = false,
      }
      location_components[3] = gamestate[map_hash]
      local location = concat(location_components, "/")
      -- utils.log(map_hash, map, location_components[1], location_components[2], location_components[3], location)
      -- utils.log(location_components[1])
      -- utils.log(location_components[2])
      -- utils.log(location_components[3])
      local save_file = get_save_file(location, gamestate[entity_hash])
      metadata.payload = sys_load(save_file)
      metadata.path_to_file = save_file
      map[entity_hash] = metadata
      storage[map_hash] = map
   end
   return metadata
end -- get_metadata

local function get(map_hash, entity_hash, key_string, default_value)
   local metadata = get_metadata(map_hash, entity_hash)
   local value = metadata.payload[key_string]
   return (value == nil) and default_value or value
end -- get

local function set(map_hash, entity_hash, key_string, value)
   local metadata = get_metadata(map_hash, entity_hash)
   metadata.payload[key_string] = value
   metadata.dirty = true
   -- utils.log("saving", map_hash, entity_hash)
   -- sys_save(metadata.path_to_file, metadata.payload)
end -- set

local function save()
   -- utils.log("saving game data...")
   for _, map in next, storage do
      for _, metadata in next, map do
         if metadata.dirty then
            -- utils.log(metadata.path_to_file, metadata.payload)
            -- pprint(metadata.payload)
            sys_save(metadata.path_to_file, metadata.payload)
            metadata.dirty = false
         end
      end
   end
   -- utils.log("..done.")
end -- save

local function set_save_slot(slot)
   save()
   location_components[2] = "slot" .. tostring(slot)
   local filename = sys.get_save_file(gamestate.get_app_id(), "meta")
   local meta = sys.load(filename)
   meta.current_slot = slot
   sys.save(filename, meta)
   -- clear cache
   storage = {}
   fmod.studio.system:get_bus("bus:/soundfx"):set_volume(get(nil, gamestate.player, "sound_volume", 100) / 100)
   fmod.studio.system:get_bus("bus:/music"):set_volume(get(nil, gamestate.player, "music_volume", 100) / 100)
end -- set_save_slot

local function delete_directory(path)
   for name in lfs.dir(path) do
      utils.log("\t "..name)
      if (name ~= ".") and (name ~= "..") then
         local file = path.. "/" .. name
         local attr = lfs.attributes(file)
         if attr.mode == "directory" then
            delete_directory(file)
         else
            os.remove(file)
         end
      end
   end
   utils.log(os.remove(path))
end -- delete_directory

local function copy_directory(from, to)
   lfs.mkdir(to)
   for name in lfs.dir(from) do
      if (name ~= ".") and (name ~= "..") then
         local from_file = from.. "/" .. name
         local attr = lfs.attributes(from_file)
         local to_file = to.. "/" .. name
         if attr.mode == "directory" then
            lfs.mkdir(to_file)
            copy_directory(from_file, to_file)
         else
            local handle, err = io.open(from_file, "rb")
            if err then
               utils.log(err)
            end
            local content = handle:read("*a")
            handle:close()
            handle, err = io.open(to_file, "w")
            if err then
               utils.log(err)
            end
            handle:write(content)
            handle:close()
         end
      end
   end
end -- copy_directory

local function copy_slot(from_slot, to_slot)
   local from_path = sys.get_save_file(gamestate.get_app_id(), slot_names[from_slot])
   local to_path = sys.get_save_file(gamestate.get_app_id(), slot_names[to_slot])
   copy_directory(from_path, to_path)
   -- clear cache
   storage = {}
   fmod.studio.system:get_bus("bus:/soundfx"):set_volume(get(nil, gamestate.player, "sound_volume", 100) / 100)
   fmod.studio.system:get_bus("bus:/music"):set_volume(get(nil, gamestate.player, "music_volume", 100) / 100)
end -- copy_slot

local function clear_slot(slot_index)
   local path = sys.get_save_file(gamestate.get_app_id(), slot_names[slot_index])
   delete_directory(path)
   -- clear cache
   storage = {}
   fmod.studio.system:get_bus("bus:/soundfx"):set_volume(get(nil, gamestate.player, "sound_volume", 100) / 100)
   fmod.studio.system:get_bus("bus:/music"):set_volume(get(nil, gamestate.player, "music_volume", 100) / 100)
end -- clear_slot

local function file_exists(file)
   local ok, _, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return true
      end
   end
   return ok
end -- file_exists

local function slot_exists(slot_index)
   local file = sys.get_save_file(get_app_id(), slot_names[slot_index]) .. "/"
   return file_exists(file)
   -- local ok, _, code = os.rename(file, file)
   -- if not ok then
   --    if code == 13 then
   --       -- Permission denied, but it exists
   --       return true
   --    end
   -- end
   -- return ok
end -- slot_exists

local function get_slot_name(slot_index)
   return slot_names[slot_index]
end -- get_slot_name

gamestate.file_exists = file_exists
gamestate.get_slot_name = get_slot_name
gamestate.copy_slot = copy_slot
gamestate.slot_exists = slot_exists
gamestate.get_app_id = get_app_id
gamestate.get_save_slot = get_save_slot
gamestate.set_save_slot = set_save_slot
gamestate.clear_slot = clear_slot
gamestate.reset_slot = reset_slot
gamestate.get = get
gamestate.set = set
gamestate.save = save

return gamestate
