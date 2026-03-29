extends "res://scripts/core/miniGamesTemplate.gd"
class_name SlidingTileGame

# ── CONFIG ────────────────────────────────────────────────────────────────────
const GRID_SIZE   := 3
const TILE_SIZE   := 180.0
const GAP         := 6.0
const TILE_COUNT  := GRID_SIZE * GRID_SIZE   # 9 (tile 0 = empty)
const SHUFFLE_MOVES := 80

# ── PALETTE — warm wood ───────────────────────────────────────────────────────
const C_BOARD     := Color(0.52, 0.32, 0.16)   # dark walnut board
const C_BOARD_SH  := Color(0.38, 0.22, 0.10)   # board shadow edge
const C_TILE      := Color(0.90, 0.78, 0.52)   # light maple tile face
const C_TILE_TOP  := Color(0.96, 0.86, 0.62)   # tile highlight top
const C_TILE_SH   := Color(0.62, 0.46, 0.26)   # tile shadow bottom
const C_TILE_DN   := Color(0.72, 0.58, 0.36)   # tile pressed
const C_HOLE      := Color(0.28, 0.16, 0.07)   # empty slot — deep hole
const C_NUM       := Color(0.38, 0.22, 0.08)   # number colour — carved brown
const C_NUM_SH    := Color(0.22, 0.12, 0.04)   # number shadow
const C_ACCENT    := Color(0.82, 0.48, 0.18)   # orange-gold accent
const C_PANEL     := Color(0.62, 0.40, 0.20)   # panel background
const C_TEXT      := Color(0.95, 0.88, 0.72)   # light cream text
const C_MUTED     := Color(0.68, 0.52, 0.35)   # muted cream

# ── STATE ─────────────────────────────────────────────────────────────────────
var popup       : GamePopup
var tiles       : Array = []   # tiles[idx] = value (0 = empty)
var empty_idx   : int   = TILE_COUNT - 1
var move_count  : int   = 0
var game_active : bool  = false

var tile_btns   : Array = []   # Button nodes
var _move_lbl   : Label
var _status_lbl : Label

var rng := RandomNumberGenerator.new()

# ── ENTRY ─────────────────────────────────────────────────────────────────────
func on_game_started() -> void:
	rng.randomize()
	_init_tiles()
	_shuffle()
	await _build_ui()
	game_active = true

# ── TILE LOGIC ────────────────────────────────────────────────────────────────
func _init_tiles() -> void:
	tiles.clear()
	for i in range(TILE_COUNT):
		tiles.append(i)   # 0=empty, 1-8=numbers
	empty_idx = 0   # 0 value is at index 0 initially

func _shuffle() -> void:
	# Shuffle via random valid moves (guarantees solvability)
	for _i in range(SHUFFLE_MOVES):
		var neighbors := _get_movable_neighbors()
		var pick      :int= neighbors[rng.randi() % neighbors.size()]
		_swap(pick, empty_idx)

func _get_movable_neighbors() -> Array:
	var row : int = empty_idx / GRID_SIZE
	var col : int = empty_idx % GRID_SIZE
	var result : Array = []
	if row > 0:              result.append(empty_idx - GRID_SIZE)
	if row < GRID_SIZE - 1: result.append(empty_idx + GRID_SIZE)
	if col > 0:              result.append(empty_idx - 1)
	if col < GRID_SIZE - 1: result.append(empty_idx + 1)
	return result

func _swap(a: int, b: int) -> void:
	var tmp  : int = tiles[a]
	tiles[a]       = tiles[b]
	tiles[b]       = tmp
	if tiles[a] == 0: empty_idx = a
	if tiles[b] == 0: empty_idx = b

func _can_move(idx: int) -> bool:
	var tr : int = idx / GRID_SIZE;   var tc : int = idx % GRID_SIZE
	var er : int = empty_idx / GRID_SIZE; var ec : int = empty_idx % GRID_SIZE
	return (abs(tr - er) + abs(tc - ec)) == 1

func _is_solved() -> bool:
	# Solved = tiles[0]=0(empty at top-left? no — standard: empty at end)
	# Standard win: 1,2,3,4,5,6,7,8,0
	for i in range(TILE_COUNT - 1):
		if tiles[i] != i + 1: return false
	return tiles[TILE_COUNT - 1] == 0

# ── BUILD UI ──────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var board_px : float = GRID_SIZE * TILE_SIZE + (GRID_SIZE + 1) * GAP
	var pw       : int   = int(board_px) + 48

	var config               := PopupConfig.new()
	config.title             = "SLIDE PUZZLE  ·  3×3"
	config.panel_color       = "yellow"
	config.show_close_button = false
	config.popup_width       = pw
	config.popup_height      = 0
	config.content_rows      = []
	config.buttons           = []

	popup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)

	# Override panel style to warm wood
	var main_panel : Panel = popup.get_node("Control/CenterContainer/Panel")
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = C_PANEL
	bg_sb.set_corner_radius_all(0)
	bg_sb.set_border_width_all(0)
	main_panel.add_theme_stylebox_override("panel", bg_sb)

	# Title label colour
	popup.title_label.add_theme_color_override("font_color", C_TEXT)

	await get_tree().process_frame
	await get_tree().process_frame

	var cc : VBoxContainer = popup.get_node(
		"Control/CenterContainer/Panel/VBoxContainer/ContentMargin/ContentContainer"
	)

	_build_hud(cc)
	_build_board(cc)
	_build_status(cc)
	_refresh_all_tiles()

# ── HUD ───────────────────────────────────────────────────────────────────────
func _build_hud(cc: VBoxContainer) -> void:
	var hud := HBoxContainer.new()
	hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_theme_constant_override("separation", 0)
	cc.add_child(hud)

	var left_lbl := Label.new()
	left_lbl.text = "MOVES"
	left_lbl.add_theme_font_size_override("font_size", 18)
	left_lbl.add_theme_color_override("font_color", C_MUTED)
	left_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(left_lbl)

	_move_lbl = Label.new()
	_move_lbl.text = "0"
	_move_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_move_lbl.add_theme_font_size_override("font_size", 32)
	_move_lbl.add_theme_color_override("font_color", C_TEXT)
	_move_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(_move_lbl)

	var sep := ColorRect.new()
	sep.custom_minimum_size   = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep.color                 = C_BOARD_SH
	cc.add_child(sep)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	cc.add_child(sp)

# ── BOARD ─────────────────────────────────────────────────────────────────────
func _build_board(cc: VBoxContainer) -> void:
	var board_px : float = GRID_SIZE * TILE_SIZE + (GRID_SIZE + 1) * GAP

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(center)

	# Board background — PanelContainer handles both bg draw AND layout
	var board_panel := PanelContainer.new()
	var board_sb    := StyleBoxFlat.new()
	board_sb.bg_color = C_BOARD
	board_sb.set_border_width_all(0)
	board_sb.set_corner_radius_all(8)
	board_sb.content_margin_left   = int(GAP)
	board_sb.content_margin_right  = int(GAP)
	board_sb.content_margin_top    = int(GAP)
	board_sb.content_margin_bottom = int(GAP)
	board_panel.add_theme_stylebox_override("panel", board_sb)
	center.add_child(board_panel)

	var grid := GridContainer.new()
	grid.columns = GRID_SIZE
	grid.add_theme_constant_override("h_separation", int(GAP))
	grid.add_theme_constant_override("v_separation", int(GAP))
	board_panel.add_child(grid)

	for idx in range(TILE_COUNT):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
		btn.focus_mode          = Control.FOCUS_NONE
		btn.clip_contents       = true
		btn.mouse_filter        = Control.MOUSE_FILTER_STOP
		grid.add_child(btn)
		tile_btns.append(btn)
		btn.pressed.connect(_on_tile_pressed.bind(idx))

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	cc.add_child(sp)

# ── STATUS ────────────────────────────────────────────────────────────────────
func _build_status(cc: VBoxContainer) -> void:
	var sep := ColorRect.new()
	sep.custom_minimum_size   = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep.color                 = C_BOARD_SH
	cc.add_child(sep)

	var bar := ColorRect.new()
	bar.color                = C_BOARD.darkened(0.2)
	bar.custom_minimum_size  = Vector2(0, 40)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(bar)

	_status_lbl = Label.new()
	_status_lbl.text                  = "TAP A TILE NEXT TO THE GAP TO SLIDE IT"
	_status_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_status_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_size_override("font_size", 16)
	_status_lbl.add_theme_color_override("font_color", C_MUTED)
	bar.add_child(_status_lbl)

# ── TILE RENDERING ────────────────────────────────────────────────────────────
func _refresh_all_tiles() -> void:
	for idx in range(TILE_COUNT):
		_draw_tile(idx)

func _draw_tile(idx: int) -> void:
	var btn   : Button = tile_btns[idx]
	var value : int    = tiles[idx]

	# Remove old draw children
	for child in btn.get_children():
		child.queue_free()

	if value == 0:
		# Empty hole
		btn.disabled = true
		for state in ["normal","hover","pressed","disabled","focus"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = C_HOLE
			sb.set_corner_radius_all(6)
			# Inner shadow — darker edges
			sb.shadow_size   = 0
			sb.set_border_width_all(0)
			btn.add_theme_stylebox_override(state, sb)
		btn.text = ""

		# Draw hole depth effect
		var hole := Control.new()
		hole.set_anchors_preset(Control.PRESET_FULL_RECT)
		hole.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hole.draw.connect(func():
			var sz := hole.size
			# Inner shadow rings to simulate depth
			for i in range(4):
				var margin : float = float(i) * 3.0
				var alpha  : float = 0.25 - i * 0.05
				hole.draw_rect(
					Rect2(margin, margin, sz.x - margin*2, sz.y - margin*2),
					Color(0, 0, 0, alpha), false, 1.5
				)
		)
		btn.add_child(hole)
		return

	# Tile face
	var movable : bool = _can_move(idx) and game_active

	for state in ["normal","hover","pressed","disabled","focus"]:
		var sb := StyleBoxFlat.new()
		match state:
			"normal":
				sb.bg_color = C_TILE
				# Bevel: top/left bright, bottom/right shadow
				sb.border_width_top    = 3
				sb.border_width_left   = 3
				sb.border_width_bottom = 4
				sb.border_width_right  = 4
				# We'll fake bevel with draw nodes instead
				sb.border_color = C_TILE
			"hover":
				sb.bg_color = C_TILE_TOP if movable else C_TILE
				sb.set_border_width_all(0)
			"pressed":
				sb.bg_color = C_TILE_DN
				sb.set_border_width_all(0)
			_:
				sb.bg_color = C_TILE
				sb.set_border_width_all(0)
		sb.set_corner_radius_all(6)
		btn.add_theme_stylebox_override(state, sb)
	btn.text = ""
	btn.disabled = false   # never disable — check movability in handler

	# Draw tile visuals
	var tile_draw := Control.new()
	tile_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := value
	var mv := movable
	tile_draw.draw.connect(func():
		var sz  : Vector2 = tile_draw.size
		var cx  : float   = sz.x / 2.0
		var cy  : float   = sz.y / 2.0

		# Wood grain texture (2-3 subtle lines)
		for gi in range(3):
			var gx : float = sz.x * (0.25 + gi * 0.25)
			tile_draw.draw_line(
				Vector2(gx, 8), Vector2(gx + rng.randf_range(-4, 4), sz.y - 8),
				Color(C_TILE_SH.r, C_TILE_SH.g, C_TILE_SH.b, 0.18), 1.0
			)

		# Bevel top edge (highlight)
		tile_draw.draw_line(Vector2(6, 4), Vector2(sz.x - 6, 4),
			Color(C_TILE_TOP.r, C_TILE_TOP.g, C_TILE_TOP.b, 0.9), 2.0)
		tile_draw.draw_line(Vector2(4, 4), Vector2(4, sz.y - 6),
			Color(C_TILE_TOP.r, C_TILE_TOP.g, C_TILE_TOP.b, 0.7), 2.0)

		# Bevel bottom edge (shadow)
		tile_draw.draw_line(Vector2(6, sz.y - 4), Vector2(sz.x - 6, sz.y - 4),
			Color(C_TILE_SH.r, C_TILE_SH.g, C_TILE_SH.b, 0.9), 3.0)
		tile_draw.draw_line(Vector2(sz.x - 4, 4), Vector2(sz.x - 4, sz.y - 6),
			Color(C_TILE_SH.r, C_TILE_SH.g, C_TILE_SH.b, 0.7), 3.0)

		# Number — carved into wood
		var num_str : String = str(v)
		var font_size : int  = 52
		var font := ThemeDB.fallback_font

		# Shadow (carved depth)
		tile_draw.draw_string(font,
			Vector2(cx - 16 + 2, cy + 18 + 2),
			num_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
			C_NUM_SH
		)
		# Main number
		tile_draw.draw_string(font,
			Vector2(cx - 16, cy + 18),
			num_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
			C_NUM
		)

		# Movable glow — subtle top edge glow
		if mv:
			tile_draw.draw_line(Vector2(6, 3), Vector2(sz.x - 6, 3),
				Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.55), 2.0)
	)
	btn.add_child(tile_draw)

# ── INPUT ─────────────────────────────────────────────────────────────────────
func _on_tile_pressed(idx: int) -> void:
	if not game_active or not _can_move(idx): return

	_swap(idx, empty_idx)
	move_count += 1
	_move_lbl.text = str(move_count)

	_refresh_all_tiles()
	AudioManager.play_sfx(AudioManager.SFX.CLICK)

	if _is_solved():
		game_active = false
		popup.title_label.text = "PUZZLE SOLVED!"
		_set_status("COMPLETED IN %d MOVES" % move_count, C_ACCENT)
		AudioManager.play_sfx(AudioManager.SFX.CORRECT)
		await get_tree().create_timer(0.8).timeout
		win_game()

func _set_status(msg: String, col: Color) -> void:
	if _status_lbl:
		_status_lbl.text = msg
		_status_lbl.add_theme_color_override("font_color", col)
