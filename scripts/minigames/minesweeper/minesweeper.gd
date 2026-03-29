extends "res://scripts/core/miniGamesTemplate.gd"
class_name MinesweeperGame

# ── CONFIG ────────────────────────────────────────────────────────────────────
const GRID_SIZE   := 9
const MINE_COUNT  := 10
const CELL_SIZE   := 96.0
const GAP         := 2.0

# ── PALETTE — minimal monochrome  ───────────────────────────
const C_DARK      := Color(0.082, 0.082, 0.082)   # deepest bg / revealed cell
const C_PANEL     := Color(0.100, 0.100, 0.100)   # panel bg
const C_CELL_UP   := Color(0.65, 0.82, 0.29) # unrevealed cell — mid grey
const C_CELL_HI   := Color(0.210, 0.210, 0.210)   # hover
const C_CELL_DN   := Color(0.76, 0.70, 0.54) # revealed cell — near black
const C_BORDER_UP := Color(0.260, 0.260, 0.260)   # subtle border on unrevealed
const C_BORDER_DN := Color(0.130, 0.130, 0.130)   # barely visible on revealed
const C_ACCENT    := Color(0.820, 0.740, 0.440)   # gold — used sparingly
const C_WARN      := Color(0.88, 0.20, 0.18)   # muted gold for flag
const C_DANGER    := Color(0.880, 0.320, 0.240)   # red only for explosion
const C_TEXT      := Color(0.960, 0.960, 0.960)   # near-white numbers
const C_MUTED     := Color(0.380, 0.380, 0.380)   # dimmed text

# All numbers white — like reference. Slight size differentiation only.
const NUM_COLORS := [
	Color(0,0,0,0),
	Color(0.95, 0.95, 0.95),   # 1 — white
	Color(0.95, 0.95, 0.95),   # 2 — white
	Color(0.95, 0.95, 0.95),   # 3 — white
	Color(0.95, 0.95, 0.95),   # 4 — white
	Color(0.95, 0.95, 0.95),   # 5 — white
	Color(0.95, 0.95, 0.95),   # 6 — white
	Color(0.55, 0.55, 0.55),   # 7 — dimmer
	Color(0.40, 0.40, 0.40),   # 8 — dimmest
]

# ── STATE ─────────────────────────────────────────────────────────────────────
var popup          : GamePopup
var mines          : Array = []
var revealed       : Array = []
var flagged        : Array = []
var adj_counts     : Array = []
var first_click    : bool  = true
var game_over_f    : bool  = false
var flags_left     : int   = MINE_COUNT
var cells_revealed : int   = 0
var safe_cells     : int   = GRID_SIZE * GRID_SIZE - MINE_COUNT

var cell_btns      : Array = []
var _flag_count_lbl: Label
var _mine_count_lbl: Label
var _status_bar    : ColorRect
var _status_lbl    : Label

var rng := RandomNumberGenerator.new()

# ── ENTRY ─────────────────────────────────────────────────────────────────────
func on_game_started() -> void:
	rng.randomize()
	_init_arrays()
	add_child(TCBackground.new())
	await _build_ui()

func _init_arrays() -> void:
	for r in range(GRID_SIZE):
		mines.append([])
		revealed.append([])
		flagged.append([])
		adj_counts.append([])
		for _c in range(GRID_SIZE):
			mines[r].append(false)
			revealed[r].append(false)
			flagged[r].append(false)
			adj_counts[r].append(0)

# ── UI ────────────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var grid_px : float = GRID_SIZE * CELL_SIZE + (GRID_SIZE - 1) * GAP
	var pw      : int   = int(grid_px) + 56

	var config               := PopupConfig.new()
	config.title             = "MINESWEEPER  ·  9×9  ·  10"
	config.show_close_button = false
	config.popup_width       = pw
	config.popup_height      = 0
	config.content_rows      = []
	config.buttons           = []

	
	popup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)
	
	# Override panel bg to dark military
	var main_panel : Panel = popup.get_node("Control/CenterContainer/Panel")
	# var bg_sb := StyleBoxFlat.new()
	# bg_sb.bg_color = C_PANEL
	# bg_sb.set_corner_radius_all(0)
	# bg_sb.set_border_width_all(0)
	# main_panel.add_theme_stylebox_override("panel", bg_sb)

	await get_tree().process_frame
	await get_tree().process_frame

	var cc : VBoxContainer = popup.get_node(
		"Control/CenterContainer/Panel/VBoxContainer/ContentMargin/ContentContainer"
	)

	_build_hud(cc)
	_build_grid(cc)
	_build_status_bar(cc)

# ── HUD ───────────────────────────────────────────────────────────────────────
func _build_hud(cc: VBoxContainer) -> void:
	var hud := HBoxContainer.new()
	hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_theme_constant_override("separation", 0)
	cc.add_child(hud)

	# Left: flag counter
	var flag_box := _make_hud_panel(true)
	hud.add_child(flag_box)

	var flag_inner := HBoxContainer.new()
	flag_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	flag_inner.add_theme_constant_override("separation", 8)
	flag_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	flag_box.add_child(flag_inner)

	# Flag icon drawn
	var flag_icon := Control.new()
	flag_icon.custom_minimum_size = Vector2(22, 28)
	flag_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flag_icon.draw.connect(func():
		# Pole
		flag_icon.draw_rect(Rect2(10, 4, 2, 22), C_TEXT)
		# Flag triangle
		var pts := PackedVector2Array([Vector2(12,4), Vector2(22,9), Vector2(12,14)])
		flag_icon.draw_colored_polygon(pts, C_WARN)
		# Base
		flag_icon.draw_rect(Rect2(6, 24, 10, 2), C_TEXT.darkened(0.3))
	)
	flag_inner.add_child(flag_icon)

	_flag_count_lbl = Label.new()
	_flag_count_lbl.text = "%02d" % flags_left
	_flag_count_lbl.add_theme_font_size_override("font_size", 32)
	_flag_count_lbl.add_theme_color_override("font_color", C_ACCENT)
	flag_inner.add_child(_flag_count_lbl)

	# Spacer
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(sp)

	# Right: mine counter
	var mine_box := _make_hud_panel(false)
	hud.add_child(mine_box)

	var mine_inner := HBoxContainer.new()
	mine_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	mine_inner.add_theme_constant_override("separation", 8)
	mine_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	mine_box.add_child(mine_inner)

	_mine_count_lbl = Label.new()
	_mine_count_lbl.text = "%02d" % MINE_COUNT
	_mine_count_lbl.add_theme_font_size_override("font_size", 32)
	_mine_count_lbl.add_theme_color_override("font_color", C_DANGER)
	mine_inner.add_child(_mine_count_lbl)

	# Mine icon drawn
	var mine_icon := Control.new()
	mine_icon.custom_minimum_size = Vector2(26, 26)
	mine_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mine_icon.draw.connect(func():
		var c := Vector2(13, 13)
		# Body
		mine_icon.draw_circle(c, 9, C_DANGER)
		# Spikes
		for i in range(8):
			var angle : float = i * TAU / 8.0
			var inner : Vector2 = c + Vector2(cos(angle), sin(angle)) * 9
			var outer : Vector2 = c + Vector2(cos(angle), sin(angle)) * 14
			mine_icon.draw_line(inner, outer, C_DANGER, 2.5)
		# Shine
		mine_icon.draw_circle(c + Vector2(-3, -3), 2.5, Color(1,1,1,0.35))
	)
	mine_inner.add_child(mine_icon)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep.color = Color(0.18, 0.18, 0.18)
	cc.add_child(sep)

func _make_hud_panel(_left: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(90, 52)
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_DARK
	sb.set_border_width_all(0)
	p.add_theme_stylebox_override("panel", sb)
	return p

# ── GRID ──────────────────────────────────────────────────────────────────────
func _build_grid(cc: VBoxContainer) -> void:
	var wrapper := Control.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.custom_minimum_size   = Vector2(0, GRID_SIZE * (CELL_SIZE + GAP) + 12)
	cc.add_child(wrapper)

	# Scanline overlay drawn on top of everything
	var scan := Control.new()
	scan.set_anchors_preset(Control.PRESET_FULL_RECT)
	scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scan.z_index      = 10
	scan.draw.connect(func():
		var h := wrapper.size.y
		var w := wrapper.size.x
		var i := 0
		while i < h:
			scan.draw_line(Vector2(0, i), Vector2(w, i), Color(0,0,0,0.04))
			i += 3
	)
	wrapper.add_child(scan)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(center)

	# Grid border frame
	var grid_w : float = GRID_SIZE * (CELL_SIZE + GAP) - GAP
	var frame  := PanelContainer.new()
	frame.custom_minimum_size = Vector2(grid_w + 8, GRID_SIZE * (CELL_SIZE + GAP) - GAP + 8)
	var frame_sb := StyleBoxFlat.new()
	frame_sb.bg_color = C_DARK   # this dark bg shows through GAP = the "border"
	frame_sb.set_border_width_all(0)
	frame_sb.content_margin_left   = 3
	frame_sb.content_margin_right  = 3
	frame_sb.content_margin_top    = 3
	frame_sb.content_margin_bottom = 3
	frame.add_theme_stylebox_override("panel", frame_sb)
	center.add_child(frame)

	var grid := GridContainer.new()
	grid.columns = GRID_SIZE
	grid.add_theme_constant_override("h_separation", int(GAP))
	grid.add_theme_constant_override("v_separation", int(GAP))
	frame.add_child(grid)

	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			btn.focus_mode          = Control.FOCUS_NONE
			btn.clip_contents       = true
			_style_cell_up(btn)

			# Long press = flag
			var hold_timer := Timer.new()
			hold_timer.wait_time = 0.42
			hold_timer.one_shot  = true
			btn.add_child(hold_timer)

			var row := r; var col := c
			var did_hold := [false]   # array so lambda can mutate it
			btn.button_down.connect(func():
				did_hold[0] = false
				hold_timer.start()
			)
			btn.button_up.connect(func():
				if hold_timer.time_left > 0.0:
					hold_timer.stop()
					if not did_hold[0]:
						_on_reveal(row, col)
				did_hold[0] = false
			)
			hold_timer.timeout.connect(func():
				did_hold[0] = true
				_on_flag(row, col)
			)

			grid.add_child(btn)
			cell_btns.append(btn)

# ── STATUS BAR ────────────────────────────────────────────────────────────────
func _build_status_bar(cc: VBoxContainer) -> void:
	var sep := ColorRect.new()
	sep.custom_minimum_size   = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep.color = Color(0.15, 0.15, 0.15)
	cc.add_child(sep)

	_status_bar = ColorRect.new()
	_status_bar.color                = C_DARK
	_status_bar.custom_minimum_size  = Vector2(0, 40)
	_status_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(_status_bar)

	_status_lbl = Label.new()
	_status_lbl.text                  = "TAP TO REVEAL  ·  HOLD TO FLAG"
	_status_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_status_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_size_override("font_size", 18)
	_status_lbl.add_theme_color_override("font_color", C_MUTED)
	_status_bar.add_child(_status_lbl)

# ── CELL STYLES ───────────────────────────────────────────────────────────────
func _style_cell_up(btn: Button) -> void:
	_clear_cell_draw(btn)   # remove flag/mine/number draw nodes
	for state in ["normal","hover","pressed","disabled","focus"]:
		var sb := StyleBoxFlat.new()
		match state:
			"normal":
				sb.bg_color = C_CELL_UP
				# Bevel effect: bright top-left, dark bottom-right
				sb.border_width_top    = 2; sb.border_width_left  = 2
				sb.border_width_bottom = 1; sb.border_width_right = 1
				sb.border_color = C_BORDER_UP
			"hover":
				sb.bg_color = C_CELL_HI
				sb.set_border_width_all(1)
				sb.border_color = C_ACCENT.darkened(0.3)
			"pressed":
				sb.bg_color = C_CELL_DN
				sb.set_border_width_all(1)
				sb.border_color = C_BORDER_DN
			_:
				sb.bg_color = C_CELL_UP
				sb.set_border_width_all(1)
				sb.border_color = C_BORDER_UP
		sb.set_corner_radius_all(3)
		btn.add_theme_stylebox_override(state, sb)
	btn.add_theme_color_override("font_color", C_TEXT)
	btn.add_theme_font_size_override("font_size", 24)
	btn.text = ""

func _style_cell_revealed(btn: Button, count: int) -> void:
	for state in ["normal","hover","pressed","disabled","focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = C_CELL_DN
		sb.set_border_width_all(0)
		sb.set_corner_radius_all(2)
		btn.add_theme_stylebox_override(state, sb)
	btn.disabled = true
	btn.text = ""
	# Draw number via child Control to use draw API
	_clear_cell_draw(btn)
	if count > 0:
		var num_node := Control.new()
		num_node.set_anchors_preset(Control.PRESET_FULL_RECT)
		num_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var col :Color= NUM_COLORS[count]
		var txt := str(count)
		num_node.draw.connect(func():
			var sz : Vector2 = num_node.size
			# Glow circle behind number
			# num_node.draw_circle(sz / 2.0, 14.0, Color(col.r, col.g, col.b, 0.12))
			# Use font rendering via Label trick — draw string
			num_node.draw_string(
				ThemeDB.fallback_font,
				Vector2(sz.x / 2.0 - 7, sz.y / 2.0 + 9),
				txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, col
			)
		)
		btn.add_child(num_node)

func _style_cell_flagged(btn: Button) -> void:
	# Same grey as unrevealed — flag is drawn inside, no cell color change
	for state in ["normal","hover","pressed","disabled","focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = C_CELL_UP
		sb.set_border_width_all(0)
		sb.set_corner_radius_all(2)
		btn.add_theme_stylebox_override(state, sb)
	btn.text = ""
	_clear_cell_draw(btn)
	var flag_node := Control.new()
	flag_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	flag_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flag_node.draw.connect(func():
		var sz  : Vector2 = flag_node.size
		var cx  : float   = sz.x / 2.0
		var cy  : float   = sz.y / 2.0
		
		# Scale factor based on cell size
		var s : float = min(sz.x, sz.y) / 48.0   # 48 was your original base
		
		var pole_h : float = 28.0 * s
		var pole_w : float = 3.0 * s
		var flag_w : float = 18.0 * s
		var flag_h : float = 12.0 * s
		var base_w : float = 20.0 * s
		var base_h : float = 4.0 * s

		var pole_x : float = cx - pole_w / 2.0

		# Pole
		flag_node.draw_rect(Rect2(pole_x, cy - pole_h * 0.6, pole_w, pole_h), C_TEXT.darkened(0.2))

		# Flag (bigger rectangle)
		flag_node.draw_rect(Rect2(pole_x + pole_w, cy - pole_h * 0.6, flag_w, flag_h), C_WARN)

		# Base
		flag_node.draw_rect(Rect2(cx - base_w / 2.0, cy + pole_h * 0.2, base_w, base_h), C_MUTED.darkened(0.3))
	)
	btn.add_child(flag_node)

func _style_cell_mine(btn: Button, exploded: bool) -> void:
	for state in ["normal","hover","pressed","disabled","focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(C_DANGER.r, C_DANGER.g, C_DANGER.b, 0.25) if exploded \
					  else C_CELL_DN
		sb.set_border_width_all(1)
		sb.border_color = C_DANGER if exploded else C_BORDER_DN
		sb.set_corner_radius_all(3)
		btn.add_theme_stylebox_override(state, sb)
	btn.text = ""
	btn.disabled = true
	_clear_cell_draw(btn)
	var mine_node := Control.new()
	mine_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	mine_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var is_exp := exploded
	mine_node.draw.connect(func():
		var sz : Vector2 = mine_node.size
		var c  : Vector2 = sz / 2.0
		var col : Color  = C_DANGER if is_exp else C_MUTED
		# Body
		mine_node.draw_circle(c, 10, col)
		# Spikes 8-way
		for i in range(8):
			var a : float = i * TAU / 8.0
			mine_node.draw_line(
				c + Vector2(cos(a), sin(a)) * 10,
				c + Vector2(cos(a), sin(a)) * 16,
				col, 2.0
			)
		# Shine
		mine_node.draw_circle(c + Vector2(-3.5, -3.5), 3.0,
			Color(1, 1, 1, 0.4 if is_exp else 0.2))
		# Explosion ring
		if is_exp:
			mine_node.draw_arc(c, 18, 0, TAU, 32, Color(1, 0.5, 0.1, 0.6), 2.0)
	)
	btn.add_child(mine_node)

func _clear_cell_draw(btn: Button) -> void:
	for child in btn.get_children():
		if not child is Timer:
			child.queue_free()

# ── MINE GENERATION ───────────────────────────────────────────────────────────
func _place_mines(safe_r: int, safe_c: int) -> void:
	var forbidden : Array = []
	for dr in range(-1, 2):
		for dc in range(-1, 2):
			var nr := safe_r + dr; var nc := safe_c + dc
			if nr >= 0 and nr < GRID_SIZE and nc >= 0 and nc < GRID_SIZE:
				forbidden.append(Vector2i(nr, nc))
	var placed := 0
	while placed < MINE_COUNT:
		var r := rng.randi() % GRID_SIZE
		var c := rng.randi() % GRID_SIZE
		if mines[r][c] or Vector2i(r, c) in forbidden: continue
		mines[r][c] = true
		placed += 1
	_compute_adj()

func _compute_adj() -> void:
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if mines[r][c]: adj_counts[r][c] = -1; continue
			var count := 0
			for dr in range(-1, 2):
				for dc in range(-1, 2):
					if dr == 0 and dc == 0: continue
					var nr := r + dr; var nc := c + dc
					if nr >= 0 and nr < GRID_SIZE and nc >= 0 and nc < GRID_SIZE:
						if mines[nr][nc]: count += 1
			adj_counts[r][c] = count

# ── ACTIONS ───────────────────────────────────────────────────────────────────
func _on_reveal(r: int, c: int) -> void:
	if game_over_f or revealed[r][c] or flagged[r][c]: return
	if first_click:
		first_click = false
		_place_mines(r, c)
		_set_status("GOOD LUCK, SOLDIER", C_ACCENT)
	if mines[r][c]:
		_explode(r, c); return
	_flood_reveal(r, c)
	_check_win()

func _on_flag(r: int, c: int) -> void:
	if game_over_f or revealed[r][c]: return
	var btn :Button= cell_btns[r * GRID_SIZE + c]
	if flagged[r][c]:
		flagged[r][c] = false
		flags_left += 1
		_style_cell_up(btn)
	else:
		if flags_left <= 0:
			_set_status("NO FLAGS REMAINING", C_DANGER)
			return
		flagged[r][c] = true
		flags_left   -= 1
		_style_cell_flagged(btn)
		AudioManager.play_sfx(AudioManager.SFX.CLICK)
	_flag_count_lbl.text = "%02d" % flags_left
	_check_win()

func _flood_reveal(r: int, c: int) -> void:
	if r < 0 or r >= GRID_SIZE or c < 0 or c >= GRID_SIZE: return
	if revealed[r][c] or flagged[r][c] or mines[r][c]: return
	revealed[r][c]  = true
	cells_revealed += 1
	_style_cell_revealed(cell_btns[r * GRID_SIZE + c], adj_counts[r][c])
	if adj_counts[r][c] == 0:
		for dr in range(-1, 2):
			for dc in range(-1, 2):
				if dr == 0 and dc == 0: continue
				_flood_reveal(r + dr, c + dc)

func _set_status(msg: String, col: Color) -> void:
	if _status_lbl:
		_status_lbl.text = msg
		_status_lbl.add_theme_color_override("font_color", col)

# ── WIN / LOSE ────────────────────────────────────────────────────────────────
func _check_win() -> void:
	var remaining := 0
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if not revealed[r][c] and not mines[r][c]:
				remaining += 1
	if remaining == 0:
		game_over_f = true
		popup.title_label.text = "FIELD CLEARED"
		_set_status("ALL MINES AVOIDED  ·  MISSION COMPLETE", C_ACCENT)
		AudioManager.play_sfx(AudioManager.SFX.CORRECT)
		await get_tree().create_timer(1.0).timeout
		win_game()

func _explode(r: int, c: int) -> void:
	game_over_f = true
	AudioManager.play_sfx(AudioManager.SFX.WRONG)
	popup.title_label.text = "DETONATION"
	_set_status("MINE TRIGGERED  ·  MISSION FAILED", C_DANGER)
	for mr in range(GRID_SIZE):
		for mc in range(GRID_SIZE):
			if mines[mr][mc]:
				_style_cell_mine(cell_btns[mr * GRID_SIZE + mc], mr == r and mc == c)
	for btn in cell_btns: btn.disabled = true
	await get_tree().create_timer(1.2).timeout
	fail_game("Mine detonated!")
