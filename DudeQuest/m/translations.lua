local hash = hash
local select = select

-- notifications
local LANGUAGE_DID_CHANGE_NOTIFICATION = hash("LANGUAGE_DID_CHANGE_NOTIFICATION")

-- main
local GAME_RESUME      = hash("GAME_RESUME")
local GAME_START       = hash("GAME_START")
local GAME_RESTART     = hash("GAME_RESTART")
local GAME_QUIT        = hash("GAME_QUIT")
local GAME_SELECT_FILE = hash("GAME_SELECT_FILE")
local GAME_OPTIONS     = hash("GAME_OPTIONS")

-- options
local OPTIONS_TITLE = hash("OPTIONS_TITLE")
local OPTIONS_BUTTON_AUDIO = hash("OPTIONS_BUTTON_AUDIO")
local OPTIONS_BUTTON_LANGUAGE = hash("OPTIONS_BUTTON_LANGUAGE")
local OPTIONS_COMMON_BUTTON_BACK = hash("OPTIONS_COMMON_BUTTON_BACK")
local OPTIONS_COMMON_BUTTON_CLOSE = hash("OPTIONS_COMMON_BUTTON_CLOSE")
local OPTIONS_COMMON_BUTTON_OK = hash("OPTIONS_COMMON_BUTTON_OK")
local OPTIONS_COMMON_BUTTON_CANCEL = hash("OPTIONS_COMMON_BUTTON_CANCEL")
local OPTIONS_WARNINIG_TITLE = hash("OPTIONS_WARNINIG_TITLE")
local OPTIONS_WARNINIG_MESSAGE = hash("OPTIONS_WARNINIG_MESSAGE")

-- audio options
local OPTIONS_AUDIO_TITLE = hash("OPTIONS_AUDIO_TITLE")
local OPTIONS_AUDIO_SLIDER_MUSIC_TITLE = hash("OPTIONS_AUDIO_BUTTON_MUSIC_TITLE")
local OPTIONS_AUDIO_SLIDER_SOUND_TITLE = hash("OPTIONS_AUDIO_BUTTON_SOUND_TITLE")
local OPTIONS_AUDIO_SLIDER_MUSIC_MIN_VALUE = hash("OPTIONS_AUDIO_BUTTON_MUSIC_MIN_VALUE")
local OPTIONS_AUDIO_SLIDER_SOUND_MIN_VALUE = hash("OPTIONS_AUDIO_BUTTON_SOUND_MIN_VALUE")

-- language options
local OPTIONS_LANGUAGE_TITLE = hash("OPTIONS_LANGUAGE_TITLE")

local OPTIONS_MAIN_MENU = hash("OPTIONS_MAIN_MENU")

-- select save file screen
local CHOOSE_FILE = hash("CHOOSE_FILE")
local NEW_GAME = hash("NEW_GAME")
local FILE1 = hash("FILE1")
local FILE2 = hash("FILE2")
local FILE3 = hash("FILE3")

-- manage file
local USE_FILE = hash("USE_FILE")
local SAVE_TO_CLOUD = hash("SAVE_TO_CLOUD")
local LOAD_FROM_CLOUD = hash("LOAD_FROM_CLOUD")
local ERASE_FILE = hash("ERASE_FILE")

-- select season
local SEASON1 = hash("SEASON1")
local SEASON2 = hash("SEASON2")
local SEASON3 = hash("SEASON3")
local SEASON4 = hash("SEASON4")

-- save dialog
local SAVE_DIALOG_OFFER = hash("SAVE_DIALOG_OFFER")
local SAVE_DIALOG_COME_BACK = hash("SAVE_DIALOG_COME_BACK")
local CONFIRM = hash("CONFIRM")
local CANCEL= hash("CANCEL")
local SAVE_DIALOG_SAVING = hash("SAVE_DIALOG_SAVING")
local SAVE_DIALOG_COMPLETE = hash("SAVE_DIALOG_COMPLETE")

-- loader
local LOADER_LOADING = hash("LOADER_LOADING")

---------------------------------------
-- english
---------------------------------------

local english = {
   -- pause
   [GAME_RESUME] = "Resume",
   [GAME_START] = "Start Game",
   [GAME_RESTART] = "Restart",
   [GAME_QUIT] = "Quit",
   [GAME_SELECT_FILE] = "Change File",
   [GAME_OPTIONS] = "Options",

   -- options
   [OPTIONS_TITLE] = "Options",
   [OPTIONS_BUTTON_AUDIO] = "Music and Sound",
   [OPTIONS_BUTTON_LANGUAGE] = "Language",
   [OPTIONS_COMMON_BUTTON_BACK] = "Back",
   [OPTIONS_COMMON_BUTTON_CLOSE] = "Close",
   [OPTIONS_COMMON_BUTTON_OK] = "Ok",
   [OPTIONS_COMMON_BUTTON_CANCEL] = "Cancel",
   [OPTIONS_MAIN_MENU] = "Main Menu",
   [OPTIONS_WARNINIG_TITLE] = "Return to the main menu?",
   [OPTIONS_WARNINIG_MESSAGE] = "Any unsaved progress will be lost!",

   -- audio options
   [OPTIONS_AUDIO_TITLE] = "Music and Sound",
   [OPTIONS_AUDIO_SLIDER_MUSIC_TITLE] = "Music",
   [OPTIONS_AUDIO_SLIDER_SOUND_TITLE] = "Sound",
   [OPTIONS_AUDIO_SLIDER_MUSIC_MIN_VALUE] = "Off",
   [OPTIONS_AUDIO_SLIDER_SOUND_MIN_VALUE] = "Off",

   -- language options
   [OPTIONS_LANGUAGE_TITLE] = "Language",

   -- select save file screen
   [CHOOSE_FILE] = "Choose a file to play",
   [NEW_GAME] = "New Game",
   [FILE1] = "File 1",
   [FILE2] = "File 2",
   [FILE3] = "File 3",

   -- manage file
   [USE_FILE] = "Use",
   [SAVE_TO_CLOUD] = "Save to Cloud",
   [LOAD_FROM_CLOUD] = "Load from Cloud",
   [ERASE_FILE] = "Erase",

   -- select season
   [SEASON1] = "Season 1",
   [SEASON2] = "Season 2",
   [SEASON3] = "Season 3",
   [SEASON4] = "Season 4",

   -- save dialog
   [SAVE_DIALOG_OFFER] = "Would you like to <color=yellow>SAVE</color> a record of\nyour journey?",
   [SAVE_DIALOG_COME_BACK] = "Come back if you change your mind.",
   [CONFIRM] = "<color=yellow>Yes</color> please!",
   [CANCEL] = "<color=yellow>No</color> thanks.",
   [SAVE_DIALOG_SAVING] = "Saving... please wait.",
   [SAVE_DIALOG_COMPLETE] = "Save complete!",

   -- loader
   [LOADER_LOADING] = "NOW LOADING",

} -- english

---------------------------------------
-- russian
---------------------------------------

local russian = {
   -- pause
   [GAME_RESUME] = "????????????????????",
   [GAME_START] = "???????????? ????????",
   [GAME_RESTART] = "???????????? ????????????",
   [GAME_QUIT] = "??????????",
   [GAME_SELECT_FILE] = "?????????????? ????????",
   [GAME_OPTIONS] = "??????????????????",

   -- options
   [OPTIONS_TITLE] = "??????????????????",
   [OPTIONS_BUTTON_AUDIO] = "???????????? ?? ????????",
   [OPTIONS_BUTTON_LANGUAGE] = "?????????????? ????????",
   [OPTIONS_COMMON_BUTTON_BACK] = "??????????",
   [OPTIONS_COMMON_BUTTON_CLOSE] = "??????????????",
   [OPTIONS_COMMON_BUTTON_OK] = "????",
   [OPTIONS_COMMON_BUTTON_CANCEL] = "????????????????",
   [OPTIONS_MAIN_MENU] = "?? ?????????????? ????????",
   [OPTIONS_WARNINIG_TITLE] = "?????????????????? ?? ???????????????? ?????????",
   [OPTIONS_WARNINIG_MESSAGE] = "???? ?????????????????????? ?????????????????????? ?????????? ??????????????!",
   -- audio options
   [OPTIONS_AUDIO_TITLE] = "???????????? ?? ????????",
   [OPTIONS_AUDIO_SLIDER_MUSIC_TITLE] = "????????????",
   [OPTIONS_AUDIO_SLIDER_SOUND_TITLE] = "????????",
   [OPTIONS_AUDIO_SLIDER_MUSIC_MIN_VALUE] = "??????????????????",
   [OPTIONS_AUDIO_SLIDER_SOUND_MIN_VALUE] = "????????????????",

   -- language options
   [OPTIONS_LANGUAGE_TITLE] = "????????",

   -- select save file screen
   [CHOOSE_FILE] = "???????????????? ???????? ????????????????????",
   [NEW_GAME] = "?????????? ????????",
   [FILE1] = "???????? 1",
   [FILE2] = "???????? 2",
   [FILE3] = "???????? 3",

   -- manage file
   [USE_FILE] = "????????????????????????",
   [SAVE_TO_CLOUD] = "?????????????????? ?? ????????????",
   [LOAD_FROM_CLOUD] = "?????????????????? ???? ????????????",
   [ERASE_FILE] = "??????????????",

   -- select season
   [SEASON1] = "?????????? 1",
   [SEASON2] = "?????????? 2",
   [SEASON3] = "?????????? 3",
   [SEASON4] = "?????????? 4",

   -- save dialog
   [SAVE_DIALOG_OFFER] = "???????????? <color=yellow>??????????????????</color> ??????????????\n?????????? ???????????????????????",
   [SAVE_DIALOG_COME_BACK] = "??????????????????????????, ???????? ??????????????????????.",
   [CONFIRM] = "<color=yellow>????</color>, ????????????????????!",
   [CANCEL] = "<color=yellow>??????</color>, ??????????????.",
   [SAVE_DIALOG_SAVING] = "????????????????... ????????????????????, ??????????????????.",
   [SAVE_DIALOG_COMPLETE] = "????????????!",

   -- loader
   [LOADER_LOADING] = "????????????????",
} -- russian

---------------------------------------
-- swedish
---------------------------------------

local swedish = {
   -- pause
   -- [GAME_RESUME] = "Resume",
   -- [GAME_START] = "Start Game",
   -- [GAME_RESTART] = "Restart",
   -- [GAME_QUIT] = "Quit",
   -- [GAME_SELECT_FILE] = "Change File",
   -- [GAME_OPTIONS] = "Options",
   --
   -- -- options
   -- [OPTIONS_TITLE] = "??????????????????",
   -- [OPTIONS_BUTTON_AUDIO] = "???????????? ?? ????????",
   -- [OPTIONS_BUTTON_LANGUAGE] = "????????",
   -- [OPTIONS_COMMON_BUTTON_BACK] = "??????????",
   -- [OPTIONS_COMMON_BUTTON_CLOSE] = "??????????????",
   --
   -- -- audio options
   -- [OPTIONS_AUDIO_TITLE] = "???????????? ?? ????????",
   -- [OPTIONS_AUDIO_SLIDER_MUSIC_TITLE] = "????????????",
   -- [OPTIONS_AUDIO_SLIDER_SOUND_TITLE] = "????????",
   -- [OPTIONS_AUDIO_SLIDER_MUSIC_MIN_VALUE] = "??????????????????",
   -- [OPTIONS_AUDIO_SLIDER_SOUND_MIN_VALUE] = "????????????????",
   --
   -- -- language options
   -- [OPTIONS_LANGUAGE_TITLE] = "????????",

   -- select save file screen
   [CHOOSE_FILE] = "V??lj spara fil",
   [NEW_GAME] = "Nytt spel",
   [FILE1] = "Fil 1",
   [FILE2] = "Fil 2",
   [FILE3] = "Fil 3",
} -- swedish

local lookup = {
   en = english,
   ru = russian,
   sv = swedish,
}

local reverse = {}
for k, v in next, lookup do
   reverse[v] = k
end

-- functions
local translate
local set_language
local get_language_code

local current = english
local ERROR = "Missing translation for key %s"

function set_language (lang_code)
   current = lookup[lang_code] or english
end -- set_language

function get_language_code ()
   return reverse[current]
end -- set_language

function translate (key, ...) -- key is a hash
   local text = current[key] or english[key] or ERROR:format(key)
   if select("#", ...) > 0 then
      return text:format(...)
   else
      return text
   end
end -- translate

-- export
return {
   -- notifications
   LANGUAGE_DID_CHANGE_NOTIFICATION = LANGUAGE_DID_CHANGE_NOTIFICATION,

   -- pause
   GAME_RESUME = GAME_RESUME,
   GAME_START = GAME_START,
   GAME_RESTART = GAME_RESTART,
   GAME_QUIT = GAME_QUIT,
   GAME_SELECT_FILE = GAME_SELECT_FILE,
   GAME_OPTIONS = GAME_OPTIONS,

   -- options
   OPTIONS_TITLE = OPTIONS_TITLE,
   OPTIONS_BUTTON_AUDIO = OPTIONS_BUTTON_AUDIO,
   OPTIONS_BUTTON_LANGUAGE = OPTIONS_BUTTON_LANGUAGE,
   OPTIONS_COMMON_BUTTON_BACK = OPTIONS_COMMON_BUTTON_BACK,
   OPTIONS_COMMON_BUTTON_CLOSE = OPTIONS_COMMON_BUTTON_CLOSE,
   OPTIONS_COMMON_BUTTON_OK = OPTIONS_COMMON_BUTTON_OK,
   OPTIONS_COMMON_BUTTON_CANCEL = OPTIONS_COMMON_BUTTON_CANCEL,
   OPTIONS_MAIN_MENU = OPTIONS_MAIN_MENU,
   OPTIONS_WARNINIG_TITLE = OPTIONS_WARNINIG_TITLE,
   OPTIONS_WARNINIG_MESSAGE = OPTIONS_WARNINIG_MESSAGE,

   -- audio options
   OPTIONS_AUDIO_TITLE = OPTIONS_AUDIO_TITLE,
   OPTIONS_AUDIO_SLIDER_MUSIC_TITLE = OPTIONS_AUDIO_SLIDER_MUSIC_TITLE,
   OPTIONS_AUDIO_SLIDER_SOUND_TITLE = OPTIONS_AUDIO_SLIDER_SOUND_TITLE,
   OPTIONS_AUDIO_SLIDER_MUSIC_MIN_VALUE = OPTIONS_AUDIO_SLIDER_MUSIC_MIN_VALUE,
   OPTIONS_AUDIO_SLIDER_SOUND_MIN_VALUE = OPTIONS_AUDIO_SLIDER_SOUND_MIN_VALUE,

   -- language options
   OPTIONS_LANGUAGE_TITLE = OPTIONS_LANGUAGE_TITLE,

   -- select file
   CHOOSE_FILE = CHOOSE_FILE,
   NEW_GAME = NEW_GAME,
   FILE1 = FILE1,
   FILE2 = FILE2,
   FILE3 = FILE3,

   -- manage file
   USE_FILE = USE_FILE,
   SAVE_TO_CLOUD = SAVE_TO_CLOUD,
   LOAD_FROM_CLOUD = LOAD_FROM_CLOUD,
   ERASE_FILE = ERASE_FILE,

   -- select season
   SEASON1 = SEASON1,
   SEASON2 = SEASON2,
   SEASON3 = SEASON3,
   SEASON4 = SEASON4,

   -- save_dialog
   SAVE_DIALOG_OFFER = SAVE_DIALOG_OFFER,
   SAVE_DIALOG_COME_BACK = SAVE_DIALOG_COME_BACK,
   SAVE_DIALOG_SAVING = SAVE_DIALOG_SAVING,
   SAVE_DIALOG_COMPLETE = SAVE_DIALOG_COMPLETE,

   CONFIRM = CONFIRM,
   CANCEL = CANCEL,

   LOADER_LOADING = LOADER_LOADING,

   set_language = set_language,
   get_language_code = get_language_code,
   translate = translate,
}
