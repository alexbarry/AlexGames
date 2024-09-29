local alexgames = require("alexgames")

local translations = {
	en = {
		undo = "Undo",
		redo = "Redo",
		white = "White",
		black = "Black",
	},

    fr = {
        undo = "Annuler",
        redo = "Rétablir",
		white = "Blanc",
		black = "Noir",
    },

    es = {
        undo = "Deshacer",
        redo = "Rehacer",
		white = "Blanco",
		black = "Negro",
    },

    pt = {
        undo = "Desfazer",
        redo = "Refazer",
		white = "Branco",
		black = "Preto",
    },

    it = {
        undo = "Annulla",
        redo = "Rifai",
		white = "Bianco",
		black = "Nero",
    },

    de = {
        undo = "Rückgängig",
        redo = "Wiederholen",
		white = "Weiß",
		black = "Schwarz",
    },

    ["zh-hans"] = {
        undo = "撤销",
        redo = "重做",
		white = "白色",
		black = "黑色",
    },

    ja = {
        undo = "元に戻す",
        redo = "やり直す",
		white = "白",
		black = "黒",
    },

    ko = {
        undo = "실행 취소",
        redo = "다시 실행",
		white = "백",
		black = "흑",
    },

    ru = {
        undo = "Отменить",
        redo = "Повторить",
		white = "Белые",
		black = "Чёрные",
    },
}


local lang = alexgames.get_language_code()

if translations[lang] == nil then
	local msg = string.format("Language '%s' not handled in 'translation_strings.lua', sorry.", lang)
	print(msg)
	alexgames.set_status_err(msg)
	lang = 'en'
end

return translations[lang]
