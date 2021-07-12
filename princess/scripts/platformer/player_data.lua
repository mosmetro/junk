-- import
local application = require("scripts.shared.application")
local utils = require("scripts.shared.utils")
local ui = require("scripts.shared.ui.ui")

-- localization
local clamp = utils.clamp
local url = msg.url
local tostring = tostring
local hash = hash

-- functions
local load
local save
local append_currency
local subtract_currency
local append_health
local subtract_health
local get_currency
local get_health
local get_max_health
local set_current_sector
local get_current_region
local set_current_region
local get_current_sector
local get_current_sector_url
local set_look_direction
local get_look_direction
local set_move_direction
local get_move_direction
local set_entry_point
local get_entry_point
local set_primary_action
local get_primary_action
local set_secondary_action
local get_secondary_action
local get_soundfx_volume
local set_exit_velocity
local get_exit_velocity

-- constants
local ZERO = vmath.vector3()
local MAX_CURRENCY = 999
local MAX_HEALTH = 16
local string_to_hash = {
  ["left"] = hash("left"),
  ["right"] = hash("right"),
  ["down"] = hash("down"),
  [""] = hash(""),
}
local hash_to_string

-- stage data
local currency = 0
local health = 0
local max_health = 0

local player_data = nil

---------------------------------------
-- load
---------------------------------------

function load()
  player_data = application.load_player_data()
  hash_to_string = utils.inverted(string_to_hash)
  currency = clamp(player_data.currency or 0, 0, MAX_CURRENCY)
  max_health = clamp(player_data.max_health or 8, 8, MAX_HEALTH)
  health = clamp(player_data.health or 5, 1, max_health)
end -- load

---------------------------------------
-- save
---------------------------------------

function save()
  player_data.currency = currency
  player_data.health = health
  player_data.max_health = max_health
  application.save_player_data(player_data)
end -- save

function get_soundfx_volume()
  return player_data.soundfx_volume or 1
end

function set_current_region(number)
	player_data.current_region = number
end

function get_current_region()
	return player_data.current_region
end

function set_current_sector(number)
	player_data.current_sector = number
end

function get_current_sector()
	return player_data.current_sector
end

function set_entry_point(number)
	player_data.entry_point = number
end

function get_entry_point()
  return "player_entry_point" .. tostring(player_data.entry_point or 1)
  -- return player_data.entry_point or 1
end

function set_primary_action(action_id) -- hash
	player_data.primary_action = hash_to_string[action_id]
end

function get_primary_action()
  return string_to_hash[player_data.primary_action] or ui.RIGHT
end

function set_secondary_action(action_id)
	player_data.secondary_action = hash_to_string[action_id]
end

function get_secondary_action()
  return string_to_hash[player_data.secondary_action]
end

function set_exit_velocity(v)
  player_data.exit_velocity = v
end

function get_exit_velocity()
  return player_data.exit_velocity or ZERO
end

function get_current_sector_url()
  -- if (player_data.current_region and player_data.current_sector) then
    return url(("main:/region%s#sector%s"):format(tostring(player_data.current_region or 1), tostring(player_data.current_sector or 1)))
  -- else
    -- return nil
  -- end
end

function set_look_direction(look_direction)
	player_data.look_direction = look_direction
end

function get_look_direction()
	return player_data.look_direction or 1
end

function set_move_direction(move_direction)
	player_data.move_direction = move_direction
end

function get_move_direction()
	return player_data.move_direction or 0
end

---------------------------------------
-- append_currency
---------------------------------------

function append_currency(value)
  currency = currency + value
  if currency > MAX_CURRENCY then
    currency = MAX_CURRENCY
  end
  return currency
end -- append_currency

---------------------------------------
-- subtract_currency
---------------------------------------

function subtract_currency(value)
  local remainder = currency - value
  if remainder >= 0 then
    currency = remainder
    return remainder
  else
    return nil
  end
end -- subtract_currency

---------------------------------------
-- get_currency
---------------------------------------

function get_currency()
  return currency
end -- get_currency

---------------------------------------
-- append_health
---------------------------------------

function append_health(value)
  health = health + value
  if health > max_health then
    health = max_health
  end
  return health
end -- append_health

---------------------------------------
-- subtract_health
---------------------------------------

function subtract_health(value)
  local remainder = health - value
  if remainder > 0 then
    health = remainder
    return remainder
  else
    return nil
  end
end -- subtract_health

---------------------------------------
-- get_health
---------------------------------------

function get_health()
  return health
end -- get_health

---------------------------------------
-- get_health
---------------------------------------

function get_max_health()
  return max_health
end -- get_max_health

-- export
return {
  get_currency = get_currency,
  get_health = get_health,
  get_max_health = get_max_health,

  load = load, -- required to call first
  save = save,
  get_soundfx_volume = get_soundfx_volume,
  set_current_region = set_current_region,
  get_current_region = get_current_region,
  set_current_sector = set_current_sector,
  get_current_sector = get_current_sector,
  get_current_sector_url = get_current_sector_url,
  set_look_direction = set_look_direction,
  get_look_direction = get_look_direction,
  set_move_direction = set_move_direction,
  get_move_direction = get_move_direction,
  set_entry_point = set_entry_point,
  get_entry_point = get_entry_point,
  set_primary_action = set_primary_action,
  get_primary_action = get_primary_action,
  set_secondary_action = set_secondary_action,
  get_secondary_action = get_secondary_action,
  set_exit_velocity = set_exit_velocity,
  get_exit_velocity = get_exit_velocity,
  append_currency = append_currency,
  subtract_currency = subtract_currency,
  append_health = append_health,
  subtract_health = subtract_health,
}
