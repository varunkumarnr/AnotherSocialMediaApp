extends "res://scripts/core/miniGamesTemplate.gd"
class_name Game2048

# ── CONFIG ────────────────────────────────────────────────────────────────────
const GRID_SIZE   := 4
const TILE_SIZE   := 200.0
const GAP         := 10.0
const WIN_VALUE   := 512

# ── PALETTE — warm cream/terracotta like reference ────────────────────────────
const C_BG        := Color(0.937, 0.922, 0.898)   # warm cream page bg
const C_BOARD     := Color(0.718, 0.671, 0.631)   # tan board
const C_EMPTY     := Color(0.800, 0.757, 0.718)   # empty cell — slightly darker tan
const C_TEXT_DARK := Color(0.357, 0.322, 0.298)   # dark brown for small numbers
const C_TEXT_LT   := Color(0.976, 0.969, 0.953)   # near-white for large numbers
const C_MUTED     := Color(0.576, 0.533, 0.502)   # muted label colour
const C_ACCENT    := Color(0.929, 0.506, 0.278)   # orange accent (title)

# Tile colours per power-of-2 level (index = log2(value))
const TILE_COLORS := [
	Color(0.800, 0.757, 0.718),   # 0    — empty
	Color(0.929, 0.894, 0.859),   # 2
	Color(0.929, 0.878, 0.788),   # 4
	Color(0.941, 0.694, 0.478),   # 8
	Color(0.957, 0.584, 0.388),   # 16
	Color(0.957, 0.490, 0.322),   # 32
	Color(0.957, 0.424, 0.255),   # 64
	Color(0.937, 0.812, 0.447),   # 128
	Color(0.937, 0.800, 0.388),   # 256
	Color(0.937, 0.784, 0.329),   # 512
	Color(0.937, 0.769, 0.271),   # 1024
	Color(0.937, 0.753, 0.212),   # 2048
]

# ── STATE ─────────────────────────────────────────────────────────────────────
var popup       : GamePopup
var board       : Array = []   # board[r][c] = value (0 = empty)
var score       : int   = 0
var best        : int   = 0
var game_over_f : bool  = false
var won         : bool  = false

# Swipe detection
var _touch_start : Vector2 = Vector2.ZERO
var _touch_down  : bool    = false
const SWIPE_MIN  := 40.0

# Nodes
var _tile_nodes  : Array = []   # _tile_nodes[r][c] = Control
var _score_lbl   : Label
var _best_lbl    : Label
var _status_lbl  : Label

var rng := RandomNumberGenerator.new()

# ── ENTRY ─────────────────────────────────────────────────────────────────────
func on_game_started() -> void:
	rng.randomize()
	_init_board()
	_spawn_tile()
	_spawn_tile()
	await _build_ui()
	_refresh_board()

func _init_board() -> void:
	board.clear()
	for _r in range(GRID_SIZE):
		var row : Array = []
		for _c in range(GRID_SIZE):
			row.append(0)
		board.append(row)

# ── SPAWN ─────────────────────────────────────────────────────────────────────
func _spawn_tile() -> void:
	var empties : Array = []
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if board[r][c] == 0:
				empties.append(Vector2i(r, c))
	if empties.is_empty(): return
	var pos : Vector2i = empties[rng.randi() % empties.size()]
	board[pos.x][pos.y] = 4 if rng.randf() < 0.1 else 2

# ── BUILD UI ──────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var board_px : float = GRID_SIZE * TILE_SIZE + (GRID_SIZE + 1) * GAP
	var pw       : int   = int(board_px) + 32

	var config               := PopupConfig.new()
	config.title             = "2048"
	config.panel_color       = "yellow"
	config.show_close_button = false
	config.popup_width       = pw
	config.popup_height      = 0
	config.content_rows      = []
	config.buttons           = []

	popup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)

	# Warm cream panel
	var main_panel : Panel = popup.get_node("Control/CenterContainer/Panel")
	var bg := StyleBoxFlat.new()
	bg.bg_color = C_BG
	bg.set_border_width_all(0)
	bg.set_corner_radius_all(0)
	main_panel.add_theme_stylebox_override("panel", bg)

	# Title colour
	popup.title_label.add_theme_color_override("font_color", C_ACCENT)
	popup.title_label.add_theme_font_size_override("font_size", 42)

	await get_tree().process_frame
	await get_tree().process_frame

	var cc : VBoxContainer = popup.get_node(
		"Control/CenterContainer/Panel/VBoxContainer/ContentMargin/ContentContainer"
	)

	_build_score_row(cc)
	_build_grid(cc)
	_build_controls(cc)

# ── SCORE ROW ─────────────────────────────────────────────────────────────────
func _build_score_row(cc: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 8)
	cc.add_child(hbox)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(sp)

	_score_lbl = _make_score_box(hbox, "SCORE", "0")
	_best_lbl  = _make_score_box(hbox, "BEST",  "0")

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 10)
	cc.add_child(sep)

func _make_score_box(parent: HBoxContainer, title: String, val: String) -> Label:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(90, 56)
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_BOARD
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(0)
	box.add_theme_stylebox_override("panel", sb)
	parent.add_child(box)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 0)
	box.add_child(vb)

	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 14)
	t.add_theme_color_override("font_color", C_BG)
	vb.add_child(t)

	var v := Label.new()
	v.text = val
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_theme_font_size_override("font_size", 22)
	v.add_theme_color_override("font_color", Color(1, 1, 1))
	vb.add_child(v)
	return v

# ── GRID ──────────────────────────────────────────────────────────────────────
func _build_grid(cc: VBoxContainer) -> void:
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(center)

	var board_panel := PanelContainer.new()
	var bp_sb := StyleBoxFlat.new()
	bp_sb.bg_color = C_BOARD
	bp_sb.set_corner_radius_all(8)
	bp_sb.set_border_width_all(0)
	bp_sb.content_margin_left   = GAP
	bp_sb.content_margin_right  = GAP
	bp_sb.content_margin_top    = GAP
	bp_sb.content_margin_bottom = GAP
	board_panel.add_theme_stylebox_override("panel", bp_sb)
	center.add_child(board_panel)

	var grid := GridContainer.new()
	grid.columns = GRID_SIZE
	grid.add_theme_constant_override("h_separation", int(GAP))
	grid.add_theme_constant_override("v_separation", int(GAP))
	board_panel.add_child(grid)

	_tile_nodes.clear()
	for r in range(GRID_SIZE):
		var row_nodes : Array = []
		for c in range(GRID_SIZE):
			var cell := Control.new()
			cell.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
			cell.mouse_filter        = Control.MOUSE_FILTER_IGNORE
			grid.add_child(cell)
			row_nodes.append(cell)
		_tile_nodes.append(row_nodes)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 10)
	cc.add_child(sep)

# ── CONTROLS ROW ──────────────────────────────────────────────────────────────
func _build_controls(cc: VBoxContainer) -> void:
	var sep := ColorRect.new()
	sep.custom_minimum_size   = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep.color                 = C_EMPTY
	cc.add_child(sep)

	var bar := ColorRect.new()
	bar.color                = C_BG
	bar.custom_minimum_size  = Vector2(0, 40)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(bar)

	_status_lbl = Label.new()
	_status_lbl.text                 = "SWIPE TO MERGE TILES  ·  REACH 2048"
	_status_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_size_override("font_size", 16)
	_status_lbl.add_theme_color_override("font_color", C_MUTED)
	bar.add_child(_status_lbl)

# ── TILE RENDERING ────────────────────────────────────────────────────────────
func _refresh_board() -> void:
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			_draw_cell(r, c)

func _draw_cell(r: int, c: int) -> void:
	var cell  : Control = _tile_nodes[r][c]
	var value : int     = board[r][c]

	# Clear previous draw child
	for ch in cell.get_children():
		ch.queue_free()

	var draw := Control.new()
	draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(draw)

	var v := value
	draw.draw.connect(func():
		var sz  : Vector2 = draw.size
		if sz.x <= 0 or sz.y <= 0: return
		var cx  : float   = sz.x / 2.0
		var cy  : float   = sz.y / 2.0

		# Tile background
		var level   : int   = 0
		if v > 0: level = int(log(v) / log(2))
		level = clamp(level, 0, TILE_COLORS.size() - 1)
		var tile_col : Color = TILE_COLORS[level]

		# Rounded rect
		draw.draw_rect(Rect2(0, 0, sz.x, sz.y), tile_col)
		# Subtle inner shadow on empty
		if v == 0:
			draw.draw_rect(Rect2(0, 0, sz.x, sz.y),
				Color(0, 0, 0, 0.06), false, 2.0)
			return

		# Number
		var num_str : String = str(v)
		var font_size : int
		match num_str.length():
			1: font_size = 48
			2: font_size = 42
			3: font_size = 34
			_: font_size = 26

		var text_col : Color = C_TEXT_DARK if level <= 2 else C_TEXT_LT
		var font     := ThemeDB.fallback_font
		var txt_size : Vector2 = font.get_string_size(num_str, HORIZONTAL_ALIGNMENT_LEFT,
			-1, font_size)
		var tx : float = cx - txt_size.x / 2.0
		var ty : float = cy + txt_size.y / 4.0

		# Bold effect — draw twice offset by 1px
		draw.draw_string(font, Vector2(tx+1, ty+1), num_str,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
			Color(text_col.r, text_col.g, text_col.b, 0.3))
		draw.draw_string(font, Vector2(tx, ty), num_str,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_col)
	)

# ── INPUT — swipe ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if game_over_f or is_game_over: return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_touch_start = st.position
			_touch_down  = true
		else:
			if _touch_down:
				_handle_swipe(st.position - _touch_start)
			_touch_down = false

	elif event is InputEventScreenDrag:
		pass   # handled on release

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_touch_start = mb.global_position
				_touch_down  = true
			else:
				if _touch_down:
					_handle_swipe(mb.global_position - _touch_start)
				_touch_down = false

func _handle_swipe_raw(delta: Vector2) -> void:
	pass   # replaced by _handle_swipe below

# ── MOVE LOGIC ────────────────────────────────────────────────────────────────
func _move_left() -> bool:
	var moved := false
	for r in range(GRID_SIZE):
		var merged : Array = [false, false, false, false]
		for c in range(1, GRID_SIZE):
			if board[r][c] == 0: continue
			var tc := c
			while tc > 0 and board[r][tc-1] == 0:
				tc -= 1
			if tc > 0 and board[r][tc-1] == board[r][c] and not merged[tc-1]:
				board[r][tc-1] *= 2
				_add_score(board[r][tc-1])
				board[r][c] = 0
				merged[tc-1] = true
				moved = true
			elif tc != c:
				board[r][tc] = board[r][c]
				board[r][c]  = 0
				moved = true
	return moved

func _move_right() -> bool:
	var moved := false
	for r in range(GRID_SIZE):
		var merged : Array = [false, false, false, false]
		for c in range(GRID_SIZE - 2, -1, -1):
			if board[r][c] == 0: continue
			var tc := c
			while tc < GRID_SIZE - 1 and board[r][tc+1] == 0:
				tc += 1
			if tc < GRID_SIZE-1 and board[r][tc+1] == board[r][c] and not merged[tc+1]:
				board[r][tc+1] *= 2
				_add_score(board[r][tc+1])
				board[r][c] = 0
				merged[tc+1] = true
				moved = true
			elif tc != c:
				board[r][tc] = board[r][c]
				board[r][c]  = 0
				moved = true
	return moved

func _move_up() -> bool:
	var moved := false
	for c in range(GRID_SIZE):
		var merged : Array = [false, false, false, false]
		for r in range(1, GRID_SIZE):
			if board[r][c] == 0: continue
			var tr := r
			while tr > 0 and board[tr-1][c] == 0:
				tr -= 1
			if tr > 0 and board[tr-1][c] == board[r][c] and not merged[tr-1]:
				board[tr-1][c] *= 2
				_add_score(board[tr-1][c])
				board[r][c] = 0
				merged[tr-1] = true
				moved = true
			elif tr != r:
				board[tr][c] = board[r][c]
				board[r][c]  = 0
				moved = true
	return moved

func _move_down() -> bool:
	var moved := false
	for c in range(GRID_SIZE):
		var merged : Array = [false, false, false, false]
		for r in range(GRID_SIZE - 2, -1, -1):
			if board[r][c] == 0: continue
			var tr := r
			while tr < GRID_SIZE - 1 and board[tr+1][c] == 0:
				tr += 1
			if tr < GRID_SIZE-1 and board[tr+1][c] == board[r][c] and not merged[tr+1]:
				board[tr+1][c] *= 2
				_add_score(board[tr+1][c])
				board[r][c] = 0
				merged[tr+1] = true
				moved = true
			elif tr != r:
				board[tr][c] = board[r][c]
				board[r][c]  = 0
				moved = true
	return moved

func _after_move(moved: bool) -> void:
	if not moved: return
	_spawn_tile()
	_refresh_board()
	AudioManager.play_sfx(AudioManager.SFX.CLICK)
	if _check_win(): return
	if _check_lose():
		game_over_f = true
		popup.title_label.text = "GAME OVER"
		_set_status("NO MORE MOVES", C_MUTED)
		await get_tree().create_timer(0.8).timeout
		fail_game("No more moves! Score: %d" % score)

# Override move functions to call _after_move
func _move_left_do()  -> void: _after_move(_move_left())
func _move_right_do() -> void: _after_move(_move_right())
func _move_up_do()    -> void: _after_move(_move_up())
func _move_down_do()  -> void: _after_move(_move_down())

func _add_score(val: int) -> void:
	score += val
	if score > best: best = score
	if _score_lbl: _score_lbl.text = str(score)
	if _best_lbl:  _best_lbl.text  = str(best)

func _check_win() -> bool:
	if won: return false
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if board[r][c] >= WIN_VALUE:
				won         = true
				game_over_f = true
				popup.title_label.text = "YOU WIN!"
				_set_status("REACHED 2048!", C_ACCENT)
				AudioManager.play_sfx(AudioManager.SFX.CORRECT)
				get_tree().create_timer(1.0).timeout.connect(func(): win_game())
				return true
	return false

func _check_lose() -> bool:
	# Any empty cell = not lost
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if board[r][c] == 0: return false
	# Any adjacent merge possible?
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if c < GRID_SIZE-1 and board[r][c] == board[r][c+1]: return false
			if r < GRID_SIZE-1 and board[r][c] == board[r+1][c]: return false
	return true

func _set_status(msg: String, col: Color) -> void:
	if _status_lbl:
		_status_lbl.text = msg
		_status_lbl.add_theme_color_override("font_color", col)

# ── OVERRIDE swipe to call _do versions ──────────────────────────────────────
func _handle_swipe(delta: Vector2) -> void:
	if delta.length() < SWIPE_MIN: return
	if abs(delta.x) > abs(delta.y):
		if delta.x > 0: _move_right_do()
		else:           _move_left_do()
	else:
		if delta.y > 0: _move_down_do()
		else:           _move_up_do()