local hash = hash
local select = select

-- notifications
local LANGUAGE_DID_CHANGE_NOTIFICATION = hash("LANGUAGE_DID_CHANGE_NOTIFICATION")

---------------------------------------

-- keys

---------------------------------------

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

-- audio options
local OPTIONS_AUDIO_TITLE = hash("OPTIONS_AUDIO_TITLE")
local OPTIONS_AUDIO_SLIDER_MUSIC_TITLE = hash("OPTIONS_AUDIO_BUTTON_MUSIC_TITLE")
local OPTIONS_AUDIO_SLIDER_SOUND_TITLE = hash("OPTIONS_AUDIO_BUTTON_SOUND_TITLE")
local OPTIONS_AUDIO_SLIDER_MUSIC_MIN_VALUE = hash("OPTIONS_AUDIO_BUTTON_MUSIC_MIN_VALUE")
local OPTIONS_AUDIO_SLIDER_SOUND_MIN_VALUE = hash("OPTIONS_AUDIO_BUTTON_SOUND_MIN_VALUE")

-- language options
local OPTIONS_LANGUAGE_TITLE = hash("OPTIONS_LANGUAGE_TITLE")

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

} -- english

---------------------------------------

-- russian

---------------------------------------

local russian = {
	-- pause
	[GAME_RESUME] = "Продолжить",
	[GAME_START] = "Начать игру",
	[GAME_RESTART] = "Начать заново",
	[GAME_QUIT] = "Выйти",
	[GAME_SELECT_FILE] = "Сменить файл",
	[GAME_OPTIONS] = "Настройки",

	-- options
	[OPTIONS_TITLE] = "Настройки",
	[OPTIONS_BUTTON_AUDIO] = "Музыка и Звук",
	[OPTIONS_BUTTON_LANGUAGE] = "Язык",
	[OPTIONS_COMMON_BUTTON_BACK] = "Назад",
	[OPTIONS_COMMON_BUTTON_CLOSE] = "Закрыть",

	-- audio options
	[OPTIONS_AUDIO_TITLE] = "Музыка и Звук",
	[OPTIONS_AUDIO_SLIDER_MUSIC_TITLE] = "Музыка",
	[OPTIONS_AUDIO_SLIDER_SOUND_TITLE] = "Звук",
	[OPTIONS_AUDIO_SLIDER_MUSIC_MIN_VALUE] = "Выключена",
	[OPTIONS_AUDIO_SLIDER_SOUND_MIN_VALUE] = "Выключен",

	-- language options
	[OPTIONS_LANGUAGE_TITLE] = "Язык",

	-- select save file screen
	[CHOOSE_FILE] = "Выберите файл сохранения",
	[NEW_GAME] = "Новая игра",
	[FILE1] = "Файл 1",
	[FILE2] = "Файл 2",
	[FILE3] = "Файл 3",

	-- manage_file
	[USE_FILE] = "Использовать",
	[SAVE_TO_CLOUD] = "Сохранить в облако",
	[LOAD_FROM_CLOUD] = "Загрузить из облака",
	[ERASE_FILE] = "Стереть",
}

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
	-- [OPTIONS_TITLE] = "Настройки",
	-- [OPTIONS_BUTTON_AUDIO] = "Музыка и Звук",
	-- [OPTIONS_BUTTON_LANGUAGE] = "Язык",
	-- [OPTIONS_COMMON_BUTTON_BACK] = "Назад",
	-- [OPTIONS_COMMON_BUTTON_CLOSE] = "Закрыть",
	--
	-- -- audio options
	-- [OPTIONS_AUDIO_TITLE] = "Музыка и Звук",
	-- [OPTIONS_AUDIO_SLIDER_MUSIC_TITLE] = "Музыка",
	-- [OPTIONS_AUDIO_SLIDER_SOUND_TITLE] = "Звук",
	-- [OPTIONS_AUDIO_SLIDER_MUSIC_MIN_VALUE] = "Выключена",
	-- [OPTIONS_AUDIO_SLIDER_SOUND_MIN_VALUE] = "Выключен",
	--
	-- -- language options
	-- [OPTIONS_LANGUAGE_TITLE] = "Язык",

	-- select save file screen
	[CHOOSE_FILE] = "Välj spara fil",
	[NEW_GAME] = "Nytt spel",
	[FILE1] = "Fil 1",
	[FILE2] = "Fil 2",
	[FILE3] = "Fil 3",
}

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

---------------------------------------

-- set_language

---------------------------------------

function set_language (lang_code)
	current = lookup[lang_code] or english
end -- set_language

---------------------------------------

-- get_language_code

---------------------------------------

function get_language_code ()
	return reverse[current]
end -- set_language

---------------------------------------

-- translate

---------------------------------------

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

	set_language = set_language,
	get_language_code = get_language_code,
	translate = translate,
}
