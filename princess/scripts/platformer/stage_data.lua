-- import
local application = require("scripts.shared.application")
local utils = require("scripts.shared.utils")

-- localization
local clamp = utils.clamp

-- functions
local load
local save
local append_currency
local subtract_currency
local get_currency
local get_health
-- local append_health
-- local subtract_health

-- constants
local MAX_CURRENCY = 999
local MAX_HEALTH = 16

-- stage data
local currency = 0
local health = 0
local max_health = 0

local player_data = nil

---------------------------------------
-- initialize
---------------------------------------

function load()
  utils.log("stage data load")
  player_data = application.load_player_data()
  currency = clamp(player_data.currency or 0, 0, MAX_CURRENCY)
  max_health = clamp(player_data.max_health or 4, 4, MAX_HEALTH)
  health = clamp(player_data.health or 4, 1, max_health)
end -- initialize

---------------------------------------
-- finalize
---------------------------------------

function save()
  utils.log("stage data save")
  player_data.currency = currency
  player_data.health = health
  application.save_player_data(player_data)
  player_data = nil
end -- finalize

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
-- get_health
---------------------------------------

function get_health()
  return health
end -- get_health


-- export
return {
  get_currency = get_currency,
  get_health = get_health,

  load = load, -- required to call first
  save = save,
  append_currency = append_currency,
  subtract_currency = subtract_currency,
}
