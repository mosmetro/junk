-- local utils = require("m.utils")

local hash = hash
local select = select
local next = next
local fastmath = fastmath

---------------------------------------
-- keys
---------------------------------------

local SELECT_PROFILE_LABEL_HEADING = hash("SELECT_PROFILE_LABEL_HEADING")
local SELECT_PROFILE_BUTTON_SLOT1 = hash("SELECT_PROFILE_BUTTON_SLOT1")
local SELECT_PROFILE_BUTTON_SLOT2 = hash("SELECT_PROFILE_BUTTON_SLOT2")
local SELECT_PROFILE_BUTTON_SLOT3 = hash("SELECT_PROFILE_BUTTON_SLOT3")
local SELECT_PROFILE_BUTTON_SLOT4 = hash("SELECT_PROFILE_BUTTON_SLOT4")
local SELECT_PROFILE_BUTTON_USE = hash("SELECT_PROFILE_BUTTON_USE")
local SELECT_PROFILE_BUTTON_COPY = hash("SELECT_PROFILE_BUTTON_COPY")
local SELECT_PROFILE_BUTTON_PASTE = hash("SELECT_PROFILE_BUTTON_PASTE")
local SELECT_PROFILE_BUTTON_CLEAR = hash("SELECT_PROFILE_BUTTON_CLEAR")

local HOME_BUTTON_START_GAME = hash("HOME_BUTTON_START_GAME")
local HOME_BUTTON_OPTIONS = hash("HOME_BUTTON_OPTIONS")
local HOME_BUTTON_SELECT_PROFILE = hash("HOME_BUTTON_SELECT_PROFILE")

local OPTIONS_LABEL_HEADING = hash("OPTIONS_LABEL_HEADING")
local OPTIONS_BUTTON_GAME = hash("OPTIONS_BUTTON_GAME")
local OPTIONS_BUTTON_AUDIO = hash("OPTIONS_BUTTON_AUDIO")
local OPTIONS_BUTTON_CONTROLS = hash("OPTIONS_BUTTON_CONTROLS")

local GAME_OPTIONS_LABEL_HEADING = hash("GAME_OPTIONS_LABEL_HEADING")
local GAME_OPTIONS_LABEL_LANGUAGE = hash("GAME_OPTIONS_LABEL_LANGUAGE")
local GAME_OPTIONS_LABEL_CURRENT_LANGUAGE = hash("GAME_OPTIONS_LABEL_CURRENT_LANGUAGE")

local AUDIO_OPTIONS_LABEL_HEADING = hash("AUDIO_OPTIONS_LABEL_HEADING")
local AUDIO_OPTIONS_LABEL_SOUND = hash("AUDIO_OPTIONS_LABEL_SOUND")
local AUDIO_OPTIONS_LABEL_MUSIC = hash("AUDIO_OPTIONS_LABEL_MUSIC")

local TOUCH_CONTROLS_OPTIONS_LABEL_HEADING = hash("TOUCH_CONTROLS_OPTIONS_LABEL_HEADING")
local TOUCH_CONTROLS_OPTIONS_LABEL_HINT = hash("TOUCH_CONTROLS_OPTIONS_LABEL_HINT")
local TOUCH_CONTROLS_OPTIONS_LABEL_HUE = hash("TOUCH_CONTROLS_OPTIONS_LABEL_HUE")
local TOUCH_CONTROLS_OPTIONS_LABEL_SATURATION = hash("TOUCH_CONTROLS_OPTIONS_LABEL_SATURATION")
local TOUCH_CONTROLS_OPTIONS_LABEL_VALUE = hash("TOUCH_CONTROLS_OPTIONS_LABEL_VALUE")
local TOUCH_CONTROLS_OPTIONS_LABEL_ALPHA = hash("TOUCH_CONTROLS_OPTIONS_LABEL_ALPHA")

local PAUSE_BUTTON_CONTINUE_GAME = hash("PAUSE_BUTTON_CONTINUE_GAME")
local PAUSE_BUTTON_OPTIONS = hash("PAUSE_BUTTON_OPTIONS")
local PAUSE_BUTTON_QUIT_TO_MENU = hash("PAUSE_BUTTON_QUIT_TO_MENU")

local BUTTON_RESET_DEFAULTS = hash("BUTTON_RESET_DEFAULTS")
local BUTTON_BACK = hash("BUTTON_BACK")

---------------------------------------
-- english
---------------------------------------

local english = {
   [SELECT_PROFILE_LABEL_HEADING] = "Select Profile",
   [SELECT_PROFILE_BUTTON_SLOT1] = "Save1",
   [SELECT_PROFILE_BUTTON_SLOT2] = "Save2",
   [SELECT_PROFILE_BUTTON_SLOT3] = "Save3",
   [SELECT_PROFILE_BUTTON_SLOT4] = "Cloud",
   [SELECT_PROFILE_BUTTON_USE] = "Use",
   [SELECT_PROFILE_BUTTON_COPY] = "Copy",
   [SELECT_PROFILE_BUTTON_PASTE] = "Paste",
   [SELECT_PROFILE_BUTTON_CLEAR] = "Clear",

   [HOME_BUTTON_START_GAME] = "Start Game",
   [HOME_BUTTON_OPTIONS] = "Options",
   [HOME_BUTTON_SELECT_PROFILE] = "Select Profile",

   [OPTIONS_LABEL_HEADING] = "Options",
   [OPTIONS_BUTTON_GAME] = "Game",
   [OPTIONS_BUTTON_AUDIO] = "Audio",
   [OPTIONS_BUTTON_CONTROLS] = "Controls",

   [GAME_OPTIONS_LABEL_HEADING] = "Game Options",
   [GAME_OPTIONS_LABEL_LANGUAGE] = "Language:",
   [GAME_OPTIONS_LABEL_CURRENT_LANGUAGE] = "English",

   [AUDIO_OPTIONS_LABEL_HEADING] = "Audio",
   [AUDIO_OPTIONS_LABEL_SOUND] = "Sound Volume:",
   [AUDIO_OPTIONS_LABEL_MUSIC] = "Music Volume:",

   [TOUCH_CONTROLS_OPTIONS_LABEL_HEADING] = "Controls",
   [TOUCH_CONTROLS_OPTIONS_LABEL_HINT] = "Move touch controls around as needed",
   [TOUCH_CONTROLS_OPTIONS_LABEL_HUE] = "Hue",
   [TOUCH_CONTROLS_OPTIONS_LABEL_SATURATION] = "Saturation",
   [TOUCH_CONTROLS_OPTIONS_LABEL_VALUE] = "Brightness",
   [TOUCH_CONTROLS_OPTIONS_LABEL_ALPHA] = "Transparency",

   [PAUSE_BUTTON_CONTINUE_GAME] = "Continue",
   [PAUSE_BUTTON_OPTIONS] = "Options",
   [PAUSE_BUTTON_QUIT_TO_MENU] = "Quit To Menu",

   [BUTTON_RESET_DEFAULTS] = "Reset Defaults",
   [BUTTON_BACK] = "Back",
} -- english

---------------------------------------
-- russian
---------------------------------------

local russian = {
   [SELECT_PROFILE_LABEL_HEADING] = "Выбор профиля",
   [SELECT_PROFILE_BUTTON_SLOT1] = "Файл1",
   [SELECT_PROFILE_BUTTON_SLOT2] = "Файл2",
   [SELECT_PROFILE_BUTTON_SLOT3] = "Файл3",
   [SELECT_PROFILE_BUTTON_SLOT4] = "Облако",
   [SELECT_PROFILE_BUTTON_USE] = "Использовать",
   [SELECT_PROFILE_BUTTON_COPY] = "Скопировать",
   [SELECT_PROFILE_BUTTON_PASTE] = "Вставить",
   [SELECT_PROFILE_BUTTON_CLEAR] = "Стереть",

   [HOME_BUTTON_START_GAME] = "Начать игру",
   [HOME_BUTTON_OPTIONS] = "Настройки",
   [HOME_BUTTON_SELECT_PROFILE] = "Сменить профиль",

   [OPTIONS_LABEL_HEADING] = "Настройки",
   [OPTIONS_BUTTON_GAME] = "Настройки игры",
   [OPTIONS_BUTTON_AUDIO] = "Звук",
   [OPTIONS_BUTTON_CONTROLS] = "Управление",

   [GAME_OPTIONS_LABEL_HEADING] = "Настройки игры",
   [GAME_OPTIONS_LABEL_LANGUAGE] = "Язык:",
   [GAME_OPTIONS_LABEL_CURRENT_LANGUAGE] = "Русский",

   [AUDIO_OPTIONS_LABEL_HEADING] = "Звук",
   [AUDIO_OPTIONS_LABEL_SOUND] = "Громкость звуков:",
   [AUDIO_OPTIONS_LABEL_MUSIC] = "Громкость музыки:",

   [TOUCH_CONTROLS_OPTIONS_LABEL_HEADING] = "Управление",
   [TOUCH_CONTROLS_OPTIONS_LABEL_HINT] = "Переместите элементы управления как вам нравится",
   [TOUCH_CONTROLS_OPTIONS_LABEL_HUE] = "Цветовой тон",
   [TOUCH_CONTROLS_OPTIONS_LABEL_SATURATION] = "Насыщенность",
   [TOUCH_CONTROLS_OPTIONS_LABEL_VALUE] = "Яркость",
   [TOUCH_CONTROLS_OPTIONS_LABEL_ALPHA] = "Прозрачность",

   [PAUSE_BUTTON_CONTINUE_GAME] = "Продолжить",
   [PAUSE_BUTTON_OPTIONS] = "Настройки",
   [PAUSE_BUTTON_QUIT_TO_MENU] = "Выйти в меню",

   [BUTTON_RESET_DEFAULTS] = "Поставить по умолчанию",
   [BUTTON_BACK] = "Назад",
} -- russian

---------------------------------------
-- swedish
---------------------------------------

local swedish = {
   [SELECT_PROFILE_BUTTON_SLOT1] = "Fil 1",
   [SELECT_PROFILE_BUTTON_SLOT2] = "Fil 2",
   [SELECT_PROFILE_BUTTON_SLOT3] = "Fil 3",
   [SELECT_PROFILE_BUTTON_SLOT4] = "Fil 4",

   [GAME_OPTIONS_LABEL_LANGUAGE] = "Språk:",
   [GAME_OPTIONS_LABEL_CURRENT_LANGUAGE] = "Svenska",
} -- swedish

local lang_codes = {
   "en", "ru", "sv",
}

local indexes = {}
for k, v in next, lang_codes do
   indexes[v] = k
end

local lookup = {
   en = english,
   ru = russian,
   sv = swedish,
}

local reverse = {}
for k, v in next, lookup do
   reverse[v] = k
end

local current = english
local ERROR = "Missing translation for key %s"

local function set_language(lang_code)
   current = lookup[lang_code] or english
end -- set_language

local function get_language_code()
   return reverse[current]
end -- set_language

local function set_next_language(step)
   local i = indexes[get_language_code()]
   i = fastmath.ring(i + (step or 1), 1, #lang_codes)
   local lang_code = lang_codes[i]
   set_language(lang_code)
   return lang_code
end -- set_next_language

local function set_prev_language()
   return set_next_language(-1)
end -- set_prev_language

local function translate (key, ...) -- key is a hash
   local text = current[key] or english[key] or ERROR:format(key)
   if select("#", ...) > 0 then
      return text:format(...)
   else
      return text
   end
end -- translate

-- export
return {
   SELECT_PROFILE_LABEL_HEADING = SELECT_PROFILE_LABEL_HEADING,
   SELECT_PROFILE_BUTTON_SLOT1 = SELECT_PROFILE_BUTTON_SLOT1,
   SELECT_PROFILE_BUTTON_SLOT2 = SELECT_PROFILE_BUTTON_SLOT2,
   SELECT_PROFILE_BUTTON_SLOT3 = SELECT_PROFILE_BUTTON_SLOT3,
   SELECT_PROFILE_BUTTON_SLOT4 = SELECT_PROFILE_BUTTON_SLOT4,
   SELECT_PROFILE_BUTTON_USE = SELECT_PROFILE_BUTTON_USE,
   SELECT_PROFILE_BUTTON_COPY = SELECT_PROFILE_BUTTON_COPY,
   SELECT_PROFILE_BUTTON_PASTE = SELECT_PROFILE_BUTTON_PASTE,
   SELECT_PROFILE_BUTTON_CLEAR = SELECT_PROFILE_BUTTON_CLEAR,

   HOME_BUTTON_START_GAME = HOME_BUTTON_START_GAME,
   HOME_BUTTON_OPTIONS = HOME_BUTTON_OPTIONS,
   HOME_BUTTON_SELECT_PROFILE = HOME_BUTTON_SELECT_PROFILE,

   OPTIONS_LABEL_HEADING = OPTIONS_LABEL_HEADING,
   OPTIONS_BUTTON_GAME = OPTIONS_BUTTON_GAME,
   OPTIONS_BUTTON_AUDIO = OPTIONS_BUTTON_AUDIO,
   OPTIONS_BUTTON_CONTROLS = OPTIONS_BUTTON_CONTROLS,

   GAME_OPTIONS_LABEL_HEADING = GAME_OPTIONS_LABEL_HEADING,
   GAME_OPTIONS_LABEL_LANGUAGE = GAME_OPTIONS_LABEL_LANGUAGE,
   GAME_OPTIONS_LABEL_CURRENT_LANGUAGE = GAME_OPTIONS_LABEL_CURRENT_LANGUAGE,

   AUDIO_OPTIONS_LABEL_HEADING = AUDIO_OPTIONS_LABEL_HEADING,
   AUDIO_OPTIONS_LABEL_SOUND = AUDIO_OPTIONS_LABEL_SOUND,
   AUDIO_OPTIONS_LABEL_MUSIC = AUDIO_OPTIONS_LABEL_MUSIC,

   TOUCH_CONTROLS_OPTIONS_LABEL_HEADING = TOUCH_CONTROLS_OPTIONS_LABEL_HEADING,
   TOUCH_CONTROLS_OPTIONS_LABEL_HINT = TOUCH_CONTROLS_OPTIONS_LABEL_HINT,
   TOUCH_CONTROLS_OPTIONS_LABEL_HUE = TOUCH_CONTROLS_OPTIONS_LABEL_HUE,
   TOUCH_CONTROLS_OPTIONS_LABEL_SATURATION = TOUCH_CONTROLS_OPTIONS_LABEL_SATURATION,
   TOUCH_CONTROLS_OPTIONS_LABEL_VALUE = TOUCH_CONTROLS_OPTIONS_LABEL_VALUE,
   TOUCH_CONTROLS_OPTIONS_LABEL_ALPHA = TOUCH_CONTROLS_OPTIONS_LABEL_ALPHA,

   PAUSE_BUTTON_CONTINUE_GAME = PAUSE_BUTTON_CONTINUE_GAME,
   PAUSE_BUTTON_OPTIONS = PAUSE_BUTTON_OPTIONS,
   PAUSE_BUTTON_QUIT_TO_MENU = PAUSE_BUTTON_QUIT_TO_MENU,

   BUTTON_RESET_DEFAULTS = BUTTON_RESET_DEFAULTS,
   BUTTON_BACK = BUTTON_BACK,

   set_language = set_language,
   set_next_language = set_next_language,
   set_prev_language = set_prev_language,
   get_language_code = get_language_code,
   translate = translate,
}
