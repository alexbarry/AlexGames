local alexgames = require("alexgames")

local common_strings = require("libs/translation_strings")

local translations = {
	en = {
		choose_piece_colour_title = "Choose piece colour",
		white_moves_first = "White moves first",
		other_player_not_yet_chosen = "The other player has not yet chosen.",
		x_chosen_by_y = "%s is chosen by %s",

		game_over_title = "Game Over",
		new_game = "New Game",

		success = "Success",
		not_your_piece        = "Not your piece",
		not_your_turn         = "Not your turn",
		cant_move_into_check  = "Can not move into check",
		must_resolve_check    = "Must move out of check",
		game_over_msg         = "Game over!",

		your_move = "Your move",
		loading_saved_state_session = "Loading saved state session %d",


		other_player_invalid_move = "Other player invalid move",

		-- "Check" referring to chess  
		x_is_in_check = "%s is in check!",

		x_is_in_checkmate_y_wins = "%s is in checkmate! Game over, %s wins.",

		select_a_piece_to_move = "select a piece to move",
		select_a_destination   = "select a destination",
	},

	fr = {
	    choose_piece_colour_title = "Choisissez la couleur des pièces",
	    white_moves_first = "Les blancs commencent",
	    other_player_not_yet_chosen = "L'autre joueur n'a pas encore choisi.",
	    x_chosen_by_y = "%s est choisi par %s",

		game_over_title = "Fin de partie",
		new_game = "Nouvelle partie",

		success = "Succès",
		not_your_piece        = "Ce n'est pas votre pièce",
		not_your_turn         = "Ce n'est pas votre tour",
		cant_move_into_check  = "Ne peut pas se déplacer dans un échec",
		must_resolve_check    = "Doit sortir de l'échec",
		game_over_msg         = "Partie terminée!",

		your_move = "Votre coup",
		loading_saved_state_session = "Chargement de l'état sauvegardé de la session %d",


		other_player_invalid_move = "Mouvement invalide de l'autre joueur",

		-- "Check" referring to chess  
		x_is_in_check = "%s est en échec!",

		x_is_in_checkmate_y_wins = "%s est en échec et mat! Partie terminée, %s gagne.",

		select_a_piece_to_move = "sélectionnez une pièce à déplacer",
		select_a_destination   = "sélectionnez une destination",
	},

	es = {

		choose_piece_colour_title = "Elige el color de las piezas",
		white_moves_first = "Las blancas se mueven primero",
		other_player_not_yet_chosen = "El otro jugador aún no ha elegido.",
		x_chosen_by_y = "%s es elegido por %s",

		game_over_title = "Fin del juego",
		new_game = "Nuevo juego",

		success = "Éxito",
		not_your_piece        = "No es tu pieza",
		not_your_turn         = "No es tu turno",
		cant_move_into_check  = "No puedes moverte a jaque",
		must_resolve_check    = "Debes salir del jaque",
		game_over_msg         = "¡Juego terminado!",

		your_move = "Tu turno",
		loading_saved_state_session = "Cargando el estado guardado de la sesión %d",


		other_player_invalid_move = "Movimiento inválido del otro jugador",

		-- "Check" referring to chess  
		x_is_in_check = "¡%s está en jaque!",

		x_is_in_checkmate_y_wins = "¡%s está en jaque mate! Juego terminado, %s gana.",

		select_a_piece_to_move = "selecciona una pieza para mover",
		select_a_destination   = "selecciona un destino",
	},

	pt = {

		choose_piece_colour_title = "Escolha a cor das peças",
		white_moves_first = "Brancas jogam primeiro",
		other_player_not_yet_chosen = "O outro jogador ainda não escolheu.",
		x_chosen_by_y = "%s é escolhido por %s",

		game_over_title = "Fim de jogo",
		new_game = "Novo jogo",

		success = "Sucesso",
		not_your_piece        = "Essa não é sua peça",
		not_your_turn         = "Não é sua vez",
		cant_move_into_check  = "Não pode se mover para o xeque",
		must_resolve_check    = "Deve sair do xeque",
		game_over_msg         = "Fim de jogo!",

		your_move = "Sua vez",
		loading_saved_state_session = "Carregando estado salvo da sessão %d",


		other_player_invalid_move = "Movimento inválido do outro jogador",

		-- "Check" referring to chess  
		x_is_in_check = "%s está em xeque!",

		x_is_in_checkmate_y_wins = "%s está em xeque-mate! Fim de jogo, %s vence.",

		select_a_piece_to_move = "selecione uma peça para mover",
		select_a_destination   = "selecione um destino",
	},

	it = {

		choose_piece_colour_title = "Scegli il colore dei pezzi",
		white_moves_first = "Il bianco muove per primo",
		other_player_not_yet_chosen = "L'altro giocatore non ha ancora scelto.",
		x_chosen_by_y = "%s è scelto da %s",

		game_over_title = "Fine della partita",
		new_game = "Nuova partita",

		success = "Successo",
		not_your_piece        = "Non è il tuo pezzo",
		not_your_turn         = "Non è il tuo turno",
		cant_move_into_check  = "Non puoi muoverti in scacco",
		must_resolve_check    = "Devi uscire dallo scacco",
		game_over_msg         = "Partita finita!",

		your_move = "Il tuo turno",
		loading_saved_state_session = "Caricamento stato salvato della sessione %d",


		other_player_invalid_move = "Mossa invalida dell'altro giocatore",

		-- "Check" referring to chess  
		x_is_in_check = "%s è sotto scacco!",

		x_is_in_checkmate_y_wins = "%s è sotto scacco matto! Fine della partita, %s vince.",

		select_a_piece_to_move = "seleziona un pezzo da muovere",
		select_a_destination   = "seleziona una destinazione",
	},

	de = {

		choose_piece_colour_title = "Wähle die Farbe der Figuren",
		white_moves_first = "Weiß zieht zuerst",
		other_player_not_yet_chosen = "Der andere Spieler hat noch nicht gewählt.",
		x_chosen_by_y = "%s wurde von %s gewählt",

		game_over_title = "Spiel beendet",
		new_game = "Neues Spiel",

		success = "Erfolg",
		not_your_piece        = "Das ist nicht deine Figur",
		not_your_turn         = "Du bist nicht am Zug",
		cant_move_into_check  = "Kann nicht ins Schach ziehen",
		must_resolve_check    = "Muss aus dem Schach ziehen",
		game_over_msg         = "Spiel vorbei!",

		your_move = "Du bist am Zug",
		loading_saved_state_session = "Lade gespeicherten Zustand der Sitzung %d",


		other_player_invalid_move = "Ungültiger Zug des anderen Spielers",

		-- "Check" referring to chess  
		x_is_in_check = "%s steht im Schach!",

		x_is_in_checkmate_y_wins = "%s ist schachmatt! Spiel vorbei, %s gewinnt.",

		select_a_piece_to_move = "Wähle eine Figur zum Ziehen aus",
		select_a_destination   = "Wähle ein Ziel aus",
	},

	["zh-hans"] = {

		choose_piece_colour_title = "选择棋子颜色",
		white_moves_first = "白方先走",
		other_player_not_yet_chosen = "另一位玩家尚未选择。",
		x_chosen_by_y = "%s 由 %s 选择",

		game_over_title = "游戏结束",
		new_game = "新游戏",

		success = "成功",
		not_your_piece        = "这不是你的棋子",
		not_your_turn         = "还没轮到你",
		cant_move_into_check  = "不能移动到被将军的位置",
		must_resolve_check    = "必须解除将军",
		game_over_msg         = "游戏结束！",

		your_move = "轮到你了",
		loading_saved_state_session = "加载保存的会话状态 %d",


		other_player_invalid_move = "对方无效的移动",

		-- "Check" referring to chess  
		x_is_in_check = "%s 被将军！",

		x_is_in_checkmate_y_wins = "%s 被将死！游戏结束，%s 赢了。",

		select_a_piece_to_move = "选择一个棋子移动",
		select_a_destination   = "选择一个目的地",
	},

	ja = {

		choose_piece_colour_title = "駒の色を選択",
		white_moves_first = "白が先手です",
		other_player_not_yet_chosen = "他のプレイヤーはまだ選んでいません。",
		x_chosen_by_y = "%s は %s によって選ばれました",

		game_over_title = "ゲームオーバー",
		new_game = "新しいゲーム",

		success = "成功",
		not_your_piece        = "あなたの駒ではありません",
		not_your_turn         = "あなたの番ではありません",
		cant_move_into_check  = "王手の状態には動けません",
		must_resolve_check    = "王手を解除しなければなりません",
		game_over_msg         = "ゲーム終了！",

		your_move = "あなたの番です",
		loading_saved_state_session = "保存されたセッション状態 %d を読み込んでいます",


		other_player_invalid_move = "相手の無効な動き",

		-- "Check" referring to chess  
		x_is_in_check = "%s は王手です！",

		x_is_in_checkmate_y_wins = "%s は詰みです！ゲーム終了、%s の勝ちです。",

		select_a_piece_to_move = "動かす駒を選んでください",
		select_a_destination   = "移動先を選んでください",
	},

	ko = {

		choose_piece_colour_title = "말 색상을 선택하세요",
		white_moves_first = "백이 먼저 움직입니다",
		other_player_not_yet_chosen = "다른 플레이어가 아직 선택하지 않았습니다.",
		x_chosen_by_y = "%s은(는) %s에 의해 선택되었습니다",

		game_over_title = "게임 오버",
		new_game = "새 게임",

		success = "성공",
		not_your_piece        = "당신의 말이 아닙니다",
		not_your_turn         = "당신의 차례가 아닙니다",
		cant_move_into_check  = "체크 상태로 이동할 수 없습니다",
		must_resolve_check    = "체크를 해제해야 합니다",
		game_over_msg         = "게임 종료!",

		your_move = "당신의 차례입니다",
		loading_saved_state_session = "저장된 세션 상태 %d을(를) 로드 중",


		other_player_invalid_move = "상대의 잘못된 움직임",

		-- "Check" referring to chess  
		x_is_in_check = "%s이(가) 체크되었습니다!",

		x_is_in_checkmate_y_wins = "%s이(가) 체크메이트! 게임 종료, %s 승리.",

		select_a_piece_to_move = "이동할 말을 선택하세요",
		select_a_destination   = "목적지를 선택하세요",
	},


	ru = {
	    choose_piece_colour_title = "Выберите цвет фигур",
	    white_moves_first = "Белые ходят первыми",
	    other_player_not_yet_chosen = "Другой игрок ещё не выбрал.",
	    x_chosen_by_y = "%s выбран %s",

		game_over_title = "Игра окончена",
		new_game = "Новая игра",

		success = "Успех",
		not_your_piece        = "Это не ваша фигура",
		not_your_turn         = "Сейчас не ваш ход",
		cant_move_into_check  = "Нельзя ходить под шах",
		must_resolve_check    = "Нужно выйти из-под шаха",
		game_over_msg         = "Игра окончена!",

		your_move = "Ваш ход",
		loading_saved_state_session = "Загрузка сохранённого состояния сеанса %d",


		other_player_invalid_move = "Неверный ход другого игрока",

		-- "Check" referring to chess  
		x_is_in_check = "%s под шахом!",

		x_is_in_checkmate_y_wins = "%s под шах и матом! Игра окончена, %s победил.",

		select_a_piece_to_move = "Выберите фигуру для хода",
		select_a_destination   = "Выберите место назначения",
	},

}


local lang = alexgames.get_language_code()

if translations[lang] == nil then
	local msg = string.format("Language %s not handled in this game, sorry.", lang)
	print(msg)
	alexgames.set_status_err(msg)
	lang = 'en'
end

local strings = translations[lang]
strings['undo'] = common_strings.undo
strings['redo'] = common_strings.redo
strings['white'] = common_strings.white
strings['black'] = common_strings.black

return strings
