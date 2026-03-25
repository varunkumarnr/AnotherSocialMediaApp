extends MiniGamesTemplate
class_name TicTacToeGame

# ═══════════════════════════════════════════════════════════════════
# CONSTANTS
# ═══════════════════════════════════════════════════════════════════
const ROUNDS_TO_WIN := 3

# Deep obsidian base — championship bracket feel
const C_BG       := Color(0.028, 0.028, 0.040, 1)
const C_SURFACE  := Color(0.043, 0.047, 0.067, 1)
const C_SURFACE2 := Color(0.059, 0.067, 0.094, 1)
const C_EDGE     := Color(0.098, 0.110, 0.157, 1)
const C_TEXT     := Color(0.925, 0.937, 0.965, 1)
const C_MUTED    := Color(0.357, 0.396, 0.490, 1)

# Accent palette
const C_ELECTRIC := Color(0.055, 0.847, 1.000, 1)   # cyan — active borders
const C_LIME     := Color(0.298, 0.953, 0.400, 1)   # lime — correct / survive
const C_CRIMSON  := Color(0.949, 0.200, 0.157, 1)   # red — CPU / wrong
const C_GOLD     := Color(1.000, 0.800, 0.100, 1)   # gold — winning line
const C_AMBER    := Color(0.980, 0.620, 0.080, 1)   # amber — draw

# Player colours
const C_X := Color(0.200, 0.780, 1.000, 1)   # sky blue — player X
const C_O := Color(0.980, 0.310, 0.220, 1)   # hot coral — CPU O

# Board values
const EMPTY  :=  0
const PLAYER :=  1
const CPU    := -1

# ═══════════════════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════════════════
var board             : Array  = []
var rounds_survived   : int    = 0
var current_round     : int    = 1
var player_goes_first : bool   = true
var is_player_turn    : bool   = true
var game_over_flag    : bool   = false
var accepting_input   : bool   = false
var rng               := RandomNumberGenerator.new()

# ═══════════════════════════════════════════════════════════════════
# UI REFS
# ═══════════════════════════════════════════════════════════════════
var popup         : GamePopup
var shield_panels : Array = []   # 3 shield/round indicator panels
var shield_labels : Array = []   # inner text labels
var round_label   : Label
var status_label  : Label
var turn_badge    : Panel        # coloured badge next to status
var turn_badge_lbl: Label
var cell_buttons  : Array = []
var cell_labels   : Array = []   # separate labels for X / O symbols

# ═══════════════════════════════════════════════════════════════════
# ENTRY
# ═══════════════════════════════════════════════════════════════════
func on_game_started() -> void:
	rng.randomize()
	play_game_music()
	await _build_ui()
	add_child(TCBackground.new())
	_start_round()

# ═══════════════════════════════════════════════════════════════════
# UI BUILD
# ═══════════════════════════════════════════════════════════════════
func _build_ui() -> void:
	var config               := PopupConfig.new()
	config.title             = "TIC  TAC  TOE"
	config.panel_color       = "blue"
	config.show_close_button = false
	config.popup_width       = 430
	config.popup_height      = 0
	config.content_rows      = [{type = "separator"}]
	config.buttons           = []

	popup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)
	popup.title_label.add_theme_font_size_override("font_size", 36)
	popup.title_label.add_theme_color_override("font_color", C_TEXT)

	await get_tree().process_frame
	await get_tree().process_frame

	var cc : VBoxContainer = popup.get_node(
		"Control/CenterContainer/Panel/VBoxContainer/ContentMargin/ContentContainer"
	)
	cc.add_theme_constant_override("separation", 0)

	_build_round_tracker(cc)
	_add_divider(cc, 6, 10)
	_build_status_row(cc)
	_add_spacer(cc, 10)
	_build_board(cc)
	_add_spacer(cc, 10)
	_build_legend(cc)
	_add_spacer(cc, 8)

# ── helpers ────────────────────────────────────────────────────────
func _add_spacer(cc: VBoxContainer, h: int) -> void:
	var s := Control.new(); s.custom_minimum_size = Vector2(0, h); cc.add_child(s)

func _add_divider(cc: VBoxContainer, before: int, after: int) -> void:
	_add_spacer(cc, before)
	var l := ColorRect.new()
	l.color = C_EDGE; l.custom_minimum_size = Vector2(0, 1)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL; cc.add_child(l)
	_add_spacer(cc, after)

# ─── Round tracker (3 shield tiles) ──────────────────────────────
func _build_round_tracker(cc: VBoxContainer) -> void:
	_add_spacer(cc, 8)

	# subtitle
	var sub_center := CenterContainer.new()
	sub_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(sub_center)
	var sub := Label.new()
	sub.text = "SURVIVE  ALL  3  ROUNDS"
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", C_MUTED)
	sub_center.add_child(sub)

	_add_spacer(cc, 10)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(center)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	center.add_child(row)

	for i in range(ROUNDS_TO_WIN):
		var shield := Panel.new()
		shield.custom_minimum_size = Vector2(80, 54)
		var sb := StyleBoxFlat.new()
		sb.bg_color = C_SURFACE2
		sb.set_corner_radius_all(8)
		sb.set_border_width_all(2)
		sb.border_color = C_EDGE
		shield.add_theme_stylebox_override("panel", sb)
		row.add_child(shield)
		shield_panels.append(shield)

		var inner := VBoxContainer.new()
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.add_theme_constant_override("separation", 0)
		shield.add_child(inner)

		var num_lbl := Label.new()
		num_lbl.text                 = "R%d" % (i + 1)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_size_override("font_size", 14)
		num_lbl.add_theme_color_override("font_color", C_MUTED)
		num_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(num_lbl)

		var sym_lbl := Label.new()
		sym_lbl.text                 = "·"
		sym_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sym_lbl.add_theme_font_size_override("font_size", 28)
		sym_lbl.add_theme_color_override("font_color", C_MUTED)
		sym_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(sym_lbl)
		shield_labels.append(sym_lbl)

# ─── Status row ───────────────────────────────────────────────────
func _build_status_row(cc: VBoxContainer) -> void:
	# Round counter
	var rc := CenterContainer.new()
	rc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(rc)

	round_label = Label.new()
	round_label.text = "ROUND  1"
	round_label.add_theme_font_size_override("font_size", 34)
	round_label.add_theme_color_override("font_color", C_ELECTRIC)
	rc.add_child(round_label)

	_add_spacer(cc, 6)

	# Turn badge + status text
	var sc := CenterContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(sc)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sc.add_child(hbox)

	turn_badge = Panel.new()
	turn_badge.custom_minimum_size = Vector2(42, 42)
	var badge_sb := StyleBoxFlat.new()
	badge_sb.bg_color = C_X.darkened(0.45)
	badge_sb.set_corner_radius_all(8)
	badge_sb.set_border_width_all(2)
	badge_sb.border_color = C_X
	turn_badge.add_theme_stylebox_override("panel", badge_sb)
	hbox.add_child(turn_badge)

	turn_badge_lbl = Label.new()
	turn_badge_lbl.text = "X"
	turn_badge_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	turn_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_badge_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	turn_badge_lbl.add_theme_font_size_override("font_size", 24)
	turn_badge_lbl.add_theme_color_override("font_color", C_X)
	turn_badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turn_badge.add_child(turn_badge_lbl)

	status_label = Label.new()
	status_label.text = "Your turn"
	status_label.add_theme_font_size_override("font_size", 28)
	status_label.add_theme_color_override("font_color", C_TEXT)
	hbox.add_child(status_label)

# ─── 3×3 board ────────────────────────────────────────────────────
func _build_board(cc: VBoxContainer) -> void:
	const CELL : float = 116.0
	const GAP  : float = 8.0

	var board_center := CenterContainer.new()
	board_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(board_center)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", int(GAP))
	grid.add_theme_constant_override("v_separation", int(GAP))
	board_center.add_child(grid)

	for i in range(9):
		# Outer wrapper for border glow effect
		var wrapper := Control.new()
		wrapper.custom_minimum_size = Vector2(CELL, CELL)

		var cell := Button.new()
		cell.set_anchors_preset(Control.PRESET_FULL_RECT)
		cell.focus_mode = Control.FOCUS_NONE
		_style_cell_empty(cell)
		cell.pressed.connect(_on_cell_pressed.bind(i))
		wrapper.add_child(cell)

		# Floating symbol label (drawn on top of the button)
		var sym := Label.new()
		sym.set_anchors_preset(Control.PRESET_FULL_RECT)
		sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sym.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		sym.add_theme_font_size_override("font_size", 64)
		sym.add_theme_color_override("font_color", C_TEXT)
		sym.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sym.text = ""
		wrapper.add_child(sym)

		grid.add_child(wrapper)
		cell_buttons.append(cell)
		cell_labels.append(sym)

# ─── Legend ───────────────────────────────────────────────────────
func _build_legend(cc: VBoxContainer) -> void:
	var line := ColorRect.new()
	line.color = C_EDGE; line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL; cc.add_child(line)
	_add_spacer(cc, 8)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(center)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	center.add_child(row)

	for pair in [["X", C_X, "YOU"], ["O", C_O, "CPU"]]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		row.add_child(h)

		var badge := Panel.new()
		badge.custom_minimum_size = Vector2(34, 34)
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = (pair[1] as Color).darkened(0.5)
		bsb.set_corner_radius_all(6)
		bsb.set_border_width_all(2)
		bsb.border_color = pair[1]
		badge.add_theme_stylebox_override("panel", bsb)
		h.add_child(badge)

		var bl := Label.new()
		bl.text = pair[0]
		bl.set_anchors_preset(Control.PRESET_FULL_RECT)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		bl.add_theme_font_size_override("font_size", 20)
		bl.add_theme_color_override("font_color", pair[1])
		bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(bl)

		var nl := Label.new()
		nl.text = "=  " + str(pair[2])
		nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nl.custom_minimum_size = Vector2(0, 34)
		nl.add_theme_font_size_override("font_size", 22)
		nl.add_theme_color_override("font_color", C_MUTED)
		h.add_child(nl)

# ═══════════════════════════════════════════════════════════════════
# CELL STYLING
# ═══════════════════════════════════════════════════════════════════
func _style_cell_empty(btn: Button) -> void:
	for s in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		match s:
			"normal":
				sb.bg_color   = C_SURFACE2
				sb.border_color = C_EDGE
			"hover":
				sb.bg_color   = C_SURFACE2.lightened(0.1)
				sb.border_color = C_ELECTRIC.darkened(0.4)
			"pressed":
				sb.bg_color   = C_SURFACE2.darkened(0.15)
				sb.border_color = C_ELECTRIC
			_:
				sb.bg_color   = C_SURFACE
				sb.border_color = C_EDGE
		sb.set_corner_radius_all(12)
		sb.set_border_width_all(2)
		btn.add_theme_stylebox_override(s, sb)
	btn.text = ""

func _style_cell_player(btn: Button, win: bool) -> void:
	var border_c : Color = C_GOLD if win else C_X
	for s in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color   = C_X.darkened(0.72)
		sb.border_color = border_c
		sb.set_corner_radius_all(12)
		sb.border_width_left   = 3 if win else 2
		sb.border_width_right  = 3 if win else 2
		sb.border_width_top    = 3 if win else 2
		sb.border_width_bottom = 3 if win else 2
		btn.add_theme_stylebox_override(s, sb)

func _style_cell_cpu(btn: Button, win: bool) -> void:
	var border_c : Color = C_GOLD if win else C_O
	for s in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color   = C_O.darkened(0.72)
		sb.border_color = border_c
		sb.set_corner_radius_all(12)
		sb.border_width_left   = 3 if win else 2
		sb.border_width_right  = 3 if win else 2
		sb.border_width_top    = 3 if win else 2
		sb.border_width_bottom = 3 if win else 2
		btn.add_theme_stylebox_override(s, sb)

func _refresh_board_display(win_line: Array = []) -> void:
	for i in range(9):
		var val  : int  = board[i]
		var w    : bool = win_line.has(i)
		var btn  : Button = cell_buttons[i]
		var sym  : Label  = cell_labels[i]

		match val:
			PLAYER:
				_style_cell_player(btn, w)
				sym.text = "X"
				sym.add_theme_color_override("font_color", C_GOLD if w else C_X)
				sym.add_theme_font_size_override("font_size", 72 if w else 64)
			CPU:
				_style_cell_cpu(btn, w)
				sym.text = "O"
				sym.add_theme_color_override("font_color", C_GOLD if w else C_O)
				sym.add_theme_font_size_override("font_size", 72 if w else 64)
			_:
				_style_cell_empty(btn)
				sym.text = ""

# ═══════════════════════════════════════════════════════════════════
# SHIELD TRACKER
# ═══════════════════════════════════════════════════════════════════
func _update_shields() -> void:
	for i in range(ROUNDS_TO_WIN):
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(8)
		sb.set_border_width_all(2)
		var sym : Label= shield_labels[i]

		if i < rounds_survived:
			# Survived — bright lime fill
			sb.bg_color   = C_LIME.darkened(0.55)
			sb.border_color = C_LIME
			sym.text = ""
			sym.add_theme_color_override("font_color", C_LIME)
			sym.add_theme_font_size_override("font_size", 26)
		elif i == current_round - 1:
			# Current — electric border
			sb.bg_color   = C_SURFACE2
			sb.border_color = C_ELECTRIC
			sym.text = str(current_round)
			sym.add_theme_color_override("font_color", C_ELECTRIC)
			sym.add_theme_font_size_override("font_size", 28)
		else:
			# Future — dim
			sb.bg_color   = C_SURFACE
			sb.border_color = C_EDGE
			sym.text = "·"
			sym.add_theme_color_override("font_color", C_MUTED)
			sym.add_theme_font_size_override("font_size", 28)

		shield_panels[i].add_theme_stylebox_override("panel", sb)

# ═══════════════════════════════════════════════════════════════════
# TURN BADGE
# ═══════════════════════════════════════════════════════════════════
func _set_turn_badge(who: int) -> void:
	# who: PLAYER or CPU or 0 for neutral
	var c : Color = C_X if who == PLAYER else C_O if who == CPU else C_MUTED
	var sb := StyleBoxFlat.new()
	sb.bg_color = c.darkened(0.48)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(2)
	sb.border_color = c
	turn_badge.add_theme_stylebox_override("panel", sb)
	turn_badge_lbl.text = "X" if who == PLAYER else "O" if who == CPU else "—"
	turn_badge_lbl.add_theme_color_override("font_color", c)

# ═══════════════════════════════════════════════════════════════════
# GAME LOGIC
# ═══════════════════════════════════════════════════════════════════
func _start_round() -> void:
	board = [0, 0, 0, 0, 0, 0, 0, 0, 0]
	accepting_input = false

	is_player_turn    = player_goes_first
	player_goes_first = !player_goes_first

	round_label.text = "ROUND  %d" % current_round
	_refresh_board_display()
	_update_shields()

	await get_tree().process_frame
	await get_tree().process_frame

	if is_player_turn:
		_set_turn_badge(PLAYER)
		status_label.text = "Your turn"
		status_label.add_theme_color_override("font_color", C_X)
		accepting_input = true
	else:
		_set_turn_badge(CPU)
		status_label.text = "CPU thinking…"
		status_label.add_theme_color_override("font_color", C_O)
		await get_tree().create_timer(0.55).timeout
		_cpu_move()

func _on_cell_pressed(idx: int) -> void:
	if not accepting_input or not is_player_turn or game_over_flag:
		return
	if board[idx] != EMPTY:
		return

	board[idx] = PLAYER
	_refresh_board_display()

	var win_line := _check_winner(board)
	if win_line.size() > 0:
		_end_round(PLAYER, win_line)
		return
	if _is_draw(board):
		_end_round(EMPTY, [])
		return

	is_player_turn  = false
	accepting_input = false
	_set_turn_badge(CPU)
	status_label.text = "CPU thinking…"
	status_label.add_theme_color_override("font_color", C_O)

	await get_tree().create_timer(0.42).timeout
	_cpu_move()

func _cpu_move() -> void:
	if game_over_flag: return

	var best_idx := _minimax_best_move()
	board[best_idx] = CPU
	_refresh_board_display()

	var win_line := _check_winner(board)
	if win_line.size() > 0:
		_end_round(CPU, win_line)
		return
	if _is_draw(board):
		_end_round(EMPTY, [])
		return

	is_player_turn  = true
	accepting_input = true
	_set_turn_badge(PLAYER)
	status_label.text = "Your turn"
	status_label.add_theme_color_override("font_color", C_X)

func _end_round(winner: int, win_line: Array) -> void:
	accepting_input = false
	_refresh_board_display(win_line)

	match winner:
		PLAYER:
			_set_turn_badge(0)
			status_label.text = "Survived!"
			status_label.add_theme_color_override("font_color", C_LIME)
			rounds_survived += 1
			_update_shields()
			if rounds_survived >= ROUNDS_TO_WIN:
				game_over_flag = true
				popup.title_label.text = "YOU  SURVIVED!"
				popup.title_label.add_theme_color_override("font_color", C_LIME)
				await get_tree().create_timer(1.4).timeout
				win_game()
			else:
				current_round += 1
				await get_tree().create_timer(1.8).timeout
				_start_round()
		CPU:
			_set_turn_badge(CPU)
			status_label.text = "CPU wins!"
			status_label.add_theme_color_override("font_color", C_CRIMSON)
			game_over_flag = true
			popup.title_label.text = "ELIMINATED  —  Round  %d" % current_round
			popup.title_label.add_theme_color_override("font_color", C_CRIMSON)
			await get_tree().create_timer(1.6).timeout
			fail_game("CPU won in round %d" % current_round)
		EMPTY:
			_set_turn_badge(0)
			status_label.text = "Draw — survived!"
			status_label.add_theme_color_override("font_color", C_AMBER)
			rounds_survived += 1
			_update_shields()
			if rounds_survived >= ROUNDS_TO_WIN:
				game_over_flag = true
				popup.title_label.text = "YOU  SURVIVED!"
				popup.title_label.add_theme_color_override("font_color", C_LIME)
				await get_tree().create_timer(1.4).timeout
				win_game()
			else:
				current_round += 1
				await get_tree().create_timer(1.5).timeout
				_start_round()

# ═══════════════════════════════════════════════════════════════════
# MINIMAX — PERFECT AI
# ═══════════════════════════════════════════════════════════════════
func _minimax_best_move() -> int:
	var best_score : int = -9999
	var best_idx   : int = -1
	for i in range(9):
		if board[i] == EMPTY:
			board[i] = CPU
			var score : int = _minimax(board, false, -9999, 9999)
			board[i] = EMPTY
			if score > best_score:
				best_score = score
				best_idx   = i
	return best_idx

func _minimax(b: Array, is_max: bool, alpha: int, beta: int) -> int:
	var wl := _check_winner(b)
	if wl.size() > 0:
		return 10 if b[wl[0]] == CPU else -10
	if _is_draw(b):
		return 0

	if is_max:
		var best : int = -9999
		for i in range(9):
			if b[i] == EMPTY:
				b[i] = CPU
				best  = max(best, _minimax(b, false, alpha, beta))
				b[i]  = EMPTY
				alpha = max(alpha, best)
				if beta <= alpha: break
		return best
	else:
		var best : int = 9999
		for i in range(9):
			if b[i] == EMPTY:
				b[i] = PLAYER
				best = min(best, _minimax(b, true, alpha, beta))
				b[i] = EMPTY
				beta = min(beta, best)
				if beta <= alpha: break
		return best

# ═══════════════════════════════════════════════════════════════════
# WIN / DRAW HELPERS
# ═══════════════════════════════════════════════════════════════════
const WIN_LINES := [
	[0,1,2],[3,4,5],[6,7,8],
	[0,3,6],[1,4,7],[2,5,8],
	[0,4,8],[2,4,6],
]

func _check_winner(b: Array) -> Array:
	for line in WIN_LINES:
		var a :int = b[line[0]]
		if a != EMPTY and a == b[line[1]] and a == b[line[2]]:
			return line
	return []

func _is_draw(b: Array) -> bool:
	for v in b:
		if v == EMPTY: return false
	return _check_winner(b).size() == 0