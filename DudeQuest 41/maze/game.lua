local utils = require("m.utils")

local tostring = tostring
local concat = table.concat
local get_save_file = sys.get_save_file
local sys_load = sys.load
local sys_save = sys.save

local names = {
   "player",
   "checkpoint",

   "e1m1",
   "e1m2",
   "e1m3",
   "e1m4",
   "e1m5",
   "e1m6",
   "e1t1",

   "e1s1",

   "box1",
   "box2",
   "box3",
   "box4",
   "box5",

   "pot1",
   "pot2",
   "pot3",
   "pot4",
   "pot5",
   "pot6",
   "pot7",
   "pot8",
   "pot9",
   "pot10",
   "pot11",
   "pot12",
   "pot13",
   "pot14",
   "pot15",
   "pot16",
   "pot17",
   "pot18",
   "pot19",
   "pot20",

   "platform1",
   "platform2",
   "platform3",
   "platform4",
   "platform5",

   "/checkpoint/root",
}

local M = {}
for i = 1, #names do
   local name = names[i]
   local hashed_name = hash(name)
   M[name] = hashed_name
   M[hashed_name] = name
end

local COMMON = hash("common")
local storage = {}

local location_components = {
   "com.anything.dudequest", -- application
   "", -- slot
   "", -- map
}

local function set_save_slot(arg)
   location_components[2] = "slot" .. tostring(arg)
end -- set_save_slot

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
      location_components[3] = M[map_hash]
      local location = concat(location_components, "/")
      local save_file = get_save_file(location, M[entity_hash])
      metadata.payload = sys_load(save_file)
      metadata.path_to_file = save_file
      map[entity_hash] = metadata
      storage[map_hash] = map
   end
   return metadata
end -- get_metadata

local function get(map_hash, entity_hash, key_string, default_value)
   local metadata = get_metadata(map_hash, entity_hash)
   return metadata.payload[key_string] or default_value
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

M.shadow_casters = {}

M.view_aabb = { 0, 0, 0, 0 }

M.set_save_slot = set_save_slot
M.set = set
M.get = get
M.save = save

return M
