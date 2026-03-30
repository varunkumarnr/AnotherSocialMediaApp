extends "res://scripts/core/miniGamesTemplate.gd"
class_name MinesweeperGame

# ── CONFIG ────────────────────────────────────────────────────────────────────
const GRID_SIZE   := 9
const MINE_COUNT  := 10
const CELL_SIZE   := 96.0
const GAP         := 2.0

# ── PALETTE ───────────────────────────────────────────────────────────────────
const C_DARK      := Color(0.020, 0.027, 0.039, 1)
const C_PANELS    := Color(0.030, 0.040, 0.058, 1)
const C_CELL_UP   := Color(0.040, 0.055, 0.082, 1)
const C_CELL_HI   := Color(0.055, 0.075, 0.115, 1)
const C_CELL_DN   := Color(0.022, 0.030, 0.045, 1)
const C_BORDER_UP := Color(0.110, 0.140, 0.200, 1)
const C_BORDER_DN := Color(0.055, 0.075, 0.110, 1)
const C_ACCENT    := Color(0.427, 0.612, 0.976, 1)
const C_WARN      := Color(0.859, 0.376, 0.290, 1)
const C_DANGER    := Color(0.859, 0.376, 0.290, 1)
const C_TEXT      := Color(0.784, 0.831, 0.910, 1)
const C_MUTED     := Color(0.200, 0.260, 0.360, 1)

const NUM_COLORS := [
	Color(0, 0, 0, 0),
	Color(0.427, 0.749, 0.976, 1),
	Color(0.0,   0.831, 0.533, 1),
	Color(0.427, 0.612, 0.976, 1),
	Color(1.0,   0.67,  0.0,   1),
	Color(0.859, 0.376, 0.290, 1),
	Color(0.0,   0.831, 1.0,   1),
	Color(0.784, 0.831, 0.910, 1),
	Color(0.380, 0.450, 0.560, 1),
]

# ── ICON PATHS — replace with your actual asset paths ────────────────────────
const ICON_FLAG_PATH := "res://assets/icons/flag.png"   # TODO: replace
const ICON_MINE_PATH := "res://assets/icons/mine.png"   # TODO: replace

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

var cell_btns      : Array = []
var _flag_count_lbl: Label
var _mine_count_lbl: Label
var _status_bar    : ColorRect
var _status_lbl    : Label

var rng := RandomNumberGenerator.new()

# ── Fonts ─────────────────────────────────────────────────────────────────────
const FONT_BOLD_PATH   := "res://font/Inter_18pt-Bold.ttf"
const FONT_MEDIUM_PATH := "res://font/Inter_18pt-Medium.ttf"
const FONT_REG_PATH    := "res://font/Inter_18pt-Regular.ttf"
var _font_bold   : FontFile = null
var _font_medium : FontFile = null
var _font_reg    : FontFile = null

func _load_fonts() -> void:
	if ResourceLoader.exists(FONT_BOLD_PATH):   _font_bold   = load(FONT_BOLD_PATH)
	if ResourceLoader.exists(FONT_MEDIUM_PATH): _font_medium = load(FONT_MEDIUM_PATH)
	if ResourceLoader.exists(FONT_REG_PATH):    _font_reg    = load(FONT_REG_PATH)

func _apply_font(node: Label, bold: bool = false, medium: bool = false) -> void:
	if bold and _font_bold:         node.add_theme_font_override("font", _font_bold)
	elif medium and _font_medium:   node.add_theme_font_override("font", _font_medium)
	elif _font_reg:                 node.add_theme_font_override("font", _font_reg)

# ── Helper: TextureRect icon with placeholder path ────────────────────────────
func _make_icon(path: String, size: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.custom_minimum_size = size
	tr.expand_mode         = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tr.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(path):
		tr.texture = load(path)
	return tr

# ── ENTRY ─────────────────────────────────────────────────────────────────────
func on_game_started() -> void:
	rng.randomize()
	_load_fonts()
	_init_arrays()
	await _build_ui()

func _init_arrays() -> void:
	for r in range(GRID_SIZE):
		mines.append([]);      revealed.append([])
		flagged.append([]);    adj_counts.append([])
		for _c in range(GRID_SIZE):
			mines[r].append(false);     revealed[r].append(false)
			flagged[r].append(false);   adj_counts[r].append(0)

# ── UI ────────────────────────────────────────────────────────────────────────
# Popup lives on CanvasLayer 9 — below the chrome/GameUI which is on layer 20.
# When _using_chrome it is also clipped to the game area so bars stay visible.
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

	# Layer 9 — always below the HUD chrome (layer 20)
	var cl      := CanvasLayer.new()
	cl.layer    = 9
	add_child(cl)

	if _using_chrome:
		# Clip to game area only so top/bottom chrome bars are never covered
		var clip              := Control.new()
		clip.position         = Vector2(0.0, _game_y)
		clip.size             = Vector2(_vp_w, _game_h)
		clip.clip_contents    = true
		clip.mouse_filter     = Control.MOUSE_FILTER_PASS
		cl.add_child(clip)

		var cc2 := CenterContainer.new()
		cc2.set_anchors_preset(Control.PRESET_FULL_RECT)
		cc2.mouse_filter = Control.MOUSE_FILTER_PASS
		clip.add_child(cc2)
		cc2.add_child(popup)
	else:
		# Legacy GameUI scene — centre in the full canvas layer
		var cc2 := CenterContainer.new()
		cc2.set_anchors_preset(Control.PRESET_FULL_RECT)
		cc2.mouse_filter = Control.MOUSE_FILTER_PASS
		cl.add_child(cc2)
		cc2.add_child(popup)

	popup.configure(config)

	# Dark matrix panel style
	var main_panel : Panel = popup.get_node("Control/CenterContainer/Panel")
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color     = C_PANELS
	bg_sb.set_corner_radius_all(0)
	bg_sb.set_border_width_all(1)
	bg_sb.border_color = C_BORDER_UP
	main_panel.add_theme_stylebox_override("panel", bg_sb)

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
	var flag_box := _make_hud_panel()
	hud.add_child(flag_box)

	var flag_inner := HBoxContainer.new()
	flag_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	flag_inner.add_theme_constant_override("separation", 8)
	flag_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	flag_box.add_child(flag_inner)

	var flag_icon      := _make_icon(ICON_FLAG_PATH, Vector2(24, 28))
	flag_icon.modulate = C_WARN
	flag_inner.add_child(flag_icon)

	_flag_count_lbl = Label.new()
	_flag_count_lbl.text = "%02d" % flags_left
	_flag_count_lbl.add_theme_font_size_override("font_size", 32)
	_flag_count_lbl.add_theme_color_override("font_color", C_ACCENT)
	_apply_font(_flag_count_lbl, true)
	flag_inner.add_child(_flag_count_lbl)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(sp)

	# Right: mine counter
	var mine_box := _make_hud_panel()
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
	_apply_font(_mine_count_lbl, true)
	mine_inner.add_child(_mine_count_lbl)

	var mine_icon      := _make_icon(ICON_MINE_PATH, Vector2(26, 26))
	mine_icon.modulate = C_DANGER
	mine_inner.add_child(mine_icon)

	var sep := ColorRect.new()
	sep.custom_minimum_size   = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep.color                 = C_BORDER_UP
	cc.add_child(sep)

func _make_hud_panel() -> PanelContainer:
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

	var scan := Control.new()
	scan.set_anchors_preset(Control.PRESET_FULL_RECT)
	scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scan.z_index      = 10
	scan.draw.connect(func():
		var h := wrapper.size.y; var w := wrapper.size.x; var i := 0
		while i < h:
			scan.draw_line(Vector2(0, i), Vector2(w, i), Color(0, 0, 0, 0.06)); i += 4
	)
	wrapper.add_child(scan)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(center)

	var grid_w : float = GRID_SIZE * (CELL_SIZE + GAP) - GAP
	var frame  := PanelContainer.new()
	frame.custom_minimum_size = Vector2(grid_w + 8, GRID_SIZE * (CELL_SIZE + GAP) - GAP + 8)
	var frame_sb := StyleBoxFlat.new()
	frame_sb.bg_color              = C_DARK
	frame_sb.set_border_width_all(1)
	frame_sb.border_color          = C_BORDER_UP
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

			var hold_timer := Timer.new()
			hold_timer.wait_time = 0.42
			hold_timer.one_shot  = true
			btn.add_child(hold_timer)

			var row := r; var col := c
			var did_hold := [false]
			btn.button_down.connect(func():
				did_hold[0] = false; hold_timer.start()
			)
			btn.button_up.connect(func():
				if hold_timer.time_left > 0.0:
					hold_timer.stop()
					if not did_hold[0]: _on_reveal(row, col)
				did_hold[0] = false
			)
			hold_timer.timeout.connect(func():
				did_hold[0] = true; _on_flag(row, col)
			)
			grid.add_child(btn)
			cell_btns.append(btn)

# ── STATUS BAR ────────────────────────────────────────────────────────────────
func _build_status_bar(cc: VBoxContainer) -> void:
	var sep := ColorRect.new()
	sep.custom_minimum_size   = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep.color                 = C_BORDER_UP
	cc.add_child(sep)

	_status_bar                       = ColorRect.new()
	_status_bar.color                 = C_DARK
	_status_bar.custom_minimum_size   = Vector2(0, 44)
	_status_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(_status_bar)

	var row_ctrl := HBoxContainer.new()
	row_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	row_ctrl.alignment = BoxContainer.ALIGNMENT_CENTER
	row_ctrl.add_theme_constant_override("separation", 10)
	_status_bar.add_child(row_ctrl)

	var diamond := Control.new()
	diamond.custom_minimum_size = Vector2(14, 14)
	diamond.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	diamond.draw.connect(func():
		diamond.draw_colored_polygon(
			PackedVector2Array([Vector2(7,0), Vector2(14,7), Vector2(7,14), Vector2(0,7)]),
			C_ACCENT)
	)
	row_ctrl.add_child(diamond)

	_status_lbl                      = Label.new()
	_status_lbl.text                 = "TAP TO REVEAL  ·  HOLD TO FLAG"
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_size_override("font_size", 16)
	_status_lbl.add_theme_color_override("font_color", C_MUTED)
	_apply_font(_status_lbl, false, true)
	row_ctrl.add_child(_status_lbl)

# ── CELL STYLES ───────────────────────────────────────────────────────────────
func _style_cell_up(btn: Button) -> void:
	_clear_cell_draw(btn)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var sb := StyleBoxFlat.new()
		match state:
			"normal":  sb.bg_color = C_CELL_UP; sb.border_color = C_BORDER_UP
			"hover":   sb.bg_color = C_CELL_HI; sb.border_color = C_ACCENT.darkened(0.2)
			"pressed": sb.bg_color = C_CELL_DN; sb.border_color = C_BORDER_DN
			_:         sb.bg_color = C_CELL_UP; sb.border_color = C_BORDER_UP
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(2)
		btn.add_theme_stylebox_override(state, sb)
	btn.add_theme_color_override("font_color", C_TEXT)
	btn.add_theme_font_size_override("font_size", 24)
	btn.text = ""

func _style_cell_revealed(btn: Button, count: int) -> void:
	for state in ["normal","hover","pressed","disabled","focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = C_CELL_DN; sb.border_color = C_BORDER_DN
		sb.set_border_width_all(1); sb.set_corner_radius_all(2)
		btn.add_theme_stylebox_override(state, sb)
	btn.disabled = true; btn.text = ""
	_clear_cell_draw(btn)
	if count > 0:
		var num_node := Control.new()
		num_node.set_anchors_preset(Control.PRESET_FULL_RECT)
		num_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var col : Color = NUM_COLORS[count]; var txt := str(count)
		num_node.draw.connect(func():
			var sz := num_node.size
			num_node.draw_circle(sz/2.0, 16.0, Color(col.r,col.g,col.b,0.08))
			num_node.draw_string(ThemeDB.fallback_font,
				Vector2(sz.x/2.0-8, sz.y/2.0+10), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 42, col)
		)
		btn.add_child(num_node)

func _style_cell_flagged(btn: Button) -> void:
	for state in ["normal","hover","pressed","disabled","focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = C_CELL_UP
		sb.border_color = Color(C_WARN.r, C_WARN.g, C_WARN.b, 0.6)
		sb.set_border_width_all(1); sb.set_corner_radius_all(2)
		btn.add_theme_stylebox_override(state, sb)
	btn.text = ""
	_clear_cell_draw(btn)
	# Flag image icon centred in cell — swap ICON_FLAG_PATH for your asset
	var icon      := _make_icon(ICON_FLAG_PATH, Vector2(CELL_SIZE * 0.45, CELL_SIZE * 0.45))
	icon.modulate = C_WARN
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left   = -CELL_SIZE * 0.225; icon.offset_top    = -CELL_SIZE * 0.225
	icon.offset_right  =  CELL_SIZE * 0.225; icon.offset_bottom =  CELL_SIZE * 0.225
	btn.add_child(icon)

func _style_cell_mine(btn: Button, exploded: bool) -> void:
	for state in ["normal","hover","pressed","disabled","focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color     = Color(C_DANGER.r, C_DANGER.g, C_DANGER.b, 0.22) if exploded else C_CELL_DN
		sb.border_color = C_DANGER if exploded else C_BORDER_DN
		sb.set_border_width_all(1); sb.set_corner_radius_all(2)
		btn.add_theme_stylebox_override(state, sb)
	btn.text = ""; btn.disabled = true
	_clear_cell_draw(btn)
	# Mine image icon centred in cell — swap ICON_MINE_PATH for your asset
	var icon      := _make_icon(ICON_MINE_PATH, Vector2(CELL_SIZE * 0.45, CELL_SIZE * 0.45))
	icon.modulate = C_DANGER if exploded else C_MUTED
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left   = -CELL_SIZE * 0.225; icon.offset_top    = -CELL_SIZE * 0.225
	icon.offset_right  =  CELL_SIZE * 0.225; icon.offset_bottom =  CELL_SIZE * 0.225
	btn.add_child(icon)

func _clear_cell_draw(btn: Button) -> void:
	for child in btn.get_children():
		if not child is Timer: child.queue_free()

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
		var r := rng.randi() % GRID_SIZE; var c := rng.randi() % GRID_SIZE
		if mines[r][c] or Vector2i(r, c) in forbidden: continue
		mines[r][c] = true; placed += 1
	_compute_adj()

func _compute_adj() -> void:
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if mines[r][c]: adj_counts[r][c] = -1; continue
			var count := 0
			for dr in range(-1, 2):
				for dc in range(-1, 2):
					if dr == 0 and dc == 0: continue
					var nr := r+dr; var nc := c+dc
					if nr >= 0 and nr < GRID_SIZE and nc >= 0 and nc < GRID_SIZE:
						if mines[nr][nc]: count += 1
			adj_counts[r][c] = count

# ── ACTIONS ───────────────────────────────────────────────────────────────────
func _on_reveal(r: int, c: int) -> void:
	if game_over_f or revealed[r][c] or flagged[r][c]: return
	if first_click:
		first_click = false
		_place_mines(r, c)
		_set_status("SECURE NODES TO PREVENT SYSTEM BREACH", C_ACCENT)
	if mines[r][c]: _explode(r, c); return
	_flood_reveal(r, c)
	_check_win()

func _on_flag(r: int, c: int) -> void:
	if game_over_f or revealed[r][c]: return
	var btn : Button = cell_btns[r * GRID_SIZE + c]
	if flagged[r][c]:
		flagged[r][c] = false; flags_left += 1; _style_cell_up(btn)
	else:
		if flags_left <= 0: _set_status("NO FLAGS REMAINING", C_DANGER); return
		flagged[r][c] = true; flags_left -= 1
		_style_cell_flagged(btn)
		AudioManager.play_sfx(AudioManager.SFX.CLICK)
	_flag_count_lbl.text = "%02d" % flags_left
	_check_win()

func _flood_reveal(r: int, c: int) -> void:
	if r < 0 or r >= GRID_SIZE or c < 0 or c >= GRID_SIZE: return
	if revealed[r][c] or flagged[r][c] or mines[r][c]: return
	revealed[r][c] = true; cells_revealed += 1
	_style_cell_revealed(cell_btns[r * GRID_SIZE + c], adj_counts[r][c])
	if adj_counts[r][c] == 0:
		for dr in range(-1, 2):
			for dc in range(-1, 2):
				if dr == 0 and dc == 0: continue
				_flood_reveal(r+dr, c+dc)

func _set_status(msg: String, col: Color) -> void:
	if _status_lbl:
		_status_lbl.text = msg
		_status_lbl.add_theme_color_override("font_color", col)

# ── WIN / LOSE ────────────────────────────────────────────────────────────────
func _check_win() -> void:
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if not revealed[r][c] and not mines[r][c]: return
	game_over_f            = true
	popup.title_label.text = "FIELD CLEARED"
	_set_status("ALL MINES AVOIDED  ·  MISSION COMPLETE", C_ACCENT)
	AudioManager.play_sfx(AudioManager.SFX.CORRECT)
	await get_tree().create_timer(1.0).timeout
	win_game()

func _explode(r: int, c: int) -> void:
	game_over_f            = true
	popup.title_label.text = "DETONATION"
	_set_status("MINE TRIGGERED  ·  MISSION FAILED", C_DANGER)
	AudioManager.play_sfx(AudioManager.SFX.WRONG)
	for mr in range(GRID_SIZE):
		for mc in range(GRID_SIZE):
			if mines[mr][mc]:
				_style_cell_mine(cell_btns[mr * GRID_SIZE + mc], mr == r and mc == c)
	for btn in cell_btns: btn.disabled = true
	await get_tree().create_timer(1.2).timeout
	fail_game("Mine detonated!")