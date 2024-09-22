local alexgames = require("alexgames")

local translations = {
	en = {
		new_game = "New Game",
		draw_dropdown_label = "Draw",
		draw_type_one = "One",
		draw_type_three = "Three",
		start_game = "Start game",
		cancel = "Cancel",

		move_fmt_str = 'Moves: %d',
	
		undo = "Undo",
		new_game = "New Game",
		autocomplete = "Auto-Complete",
	
		loaded_state = "Loaded previous state",
		loaded_state_str = "Can not load previous state, not found",
		started_new_game_w_seed = "Generated new grame with seed %x %x",
		loaded_saved_state_bytes = "Loading saved state: %d bytes",
		no_saved_state_found = "No saved state found, starting new game",

		game_option_show_elapsed_time_and_move_count = "Show elapsed time and move count",
	},

    fr = { 
        new_game = "Nouvelle Partie",
        draw_dropdown_label = "Tirer",
        draw_type_one = "Un",
        draw_type_three = "Trois",
        start_game = "Commencer le jeu",
        cancel = "Annuler",

		move_fmt_str = 'Mouvements : %d',
        
        undo = "Annuler",
        new_game = "Nouvelle Partie",
        autocomplete = "Auto-Compléter",
        
        loaded_state = "État précédent chargé",
        loaded_state_str = "Impossible de charger l'état précédent, non trouvé",
        started_new_game_w_seed = "Nouvelle partie générée avec la graine %x %x",
        loaded_saved_state_bytes = "Chargement de l'état enregistré : %d octets",
        no_saved_state_found = "Aucun état enregistré trouvé, démarrage d'une nouvelle partie",

		game_option_show_elapsed_time_and_move_count = "Afficher le temps écoulé et le nombre de mouvements",
    },

    ["zh-hans"] = { 
        new_game = "新游戏",
        draw_dropdown_label = "抽牌",
        draw_type_one = "一张",
        draw_type_three = "三张",
        start_game = "开始游戏",
        cancel = "取消",

		move_fmt_str = '移动次数：%d',
        
        undo = "撤销",
        new_game = "新游戏",
        autocomplete = "自动完成",
        
        loaded_state = "加载了先前的状态",
        loaded_state_str = "无法加载先前的状态，未找到",
        started_new_game_w_seed = "使用种子 %x %x 生成了新游戏",
        loaded_saved_state_bytes = "加载保存的状态：%d 字节",
        no_saved_state_found = "未找到保存的状态，开始新游戏",

		game_option_show_elapsed_time_and_move_count = "显示经过的时间和移动次数",
    }, 
}

local lang = alexgames.get_language_code()

print("solitaire lang: ", lang)

return translations[lang]
