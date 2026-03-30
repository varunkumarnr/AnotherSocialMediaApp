extends Node
class_name MiniGamesTemplate

# ── Palette ───────────────────────────────────────────────────────────────────
const C_BG        := Color(0.020, 0.027, 0.039, 1)
const C_BG2       := Color(0.030, 0.040, 0.058, 1)
const C_PANEL     := Color(0.040, 0.055, 0.082, 1)
const C_BORDER    := Color(0.110, 0.140, 0.200, 1)
const C_CYAN      := Color(0.427, 0.612, 0.976, 1)
const C_GREEN     := Color(0.0,   0.831, 0.533, 1)
const C_RED       := Color(0.859, 0.376, 0.290, 1)
const C_AMBER     := Color(1.0,   0.67,  0.0,   1)
const C_WHITE     := Color(0.784, 0.831, 0.910, 1)
const C_DIM       := Color(0.290, 0.353, 0.439, 1)
const C_DIMMER    := Color(0.140, 0.180, 0.250, 1)

# ── Fonts ─────────────────────────────────────────────────────────────────────
const FONT_BOLD   := "res://font/Inter_18pt-Bold.ttf"
const FONT_MEDIUM := "res://font/Inter_18pt-Medium.ttf"
const FONT_REG    := "res://font/Inter_18pt-Regular.ttf"

var _fb : FontFile = null
var _fm : FontFile = null
var _fr : FontFile = null

@onready var timer_label = $GameUI/BottomBar/BottomVBox/BottomMargin/BottomHBox/TimerPanel/TimerMargin/TimerVBox/TimerLabel
@onready var score_label = $GameUI/BottomBar/BottomVBox/BottomMargin/BottomHBox/ScorePanel/ScoreMargin/ScoreVBox/ScoreLabel
@onready var timer_panel = $GameUI/BottomBar/BottomVBox/BottomMargin/BottomHBox/TimerPanel
@onready var timer_caption = $GameUI/BottomBar/BottomVBox/BottomMargin/BottomHBox/TimerPanel/TimerMargin/TimerVBox/TimerCaption
@onready var score_panel = $GameUI/BottomBar/BottomVBox/BottomMargin/BottomHBox/ScorePanel
@onready var article_label      = $GameUI/TopBar/TopMargin/TopVBox/ArticleLabel
@onready var instructions_label = $GameUI/InstructionsBar/InstructionsMargin/InstructionsLabel
@onready var gameTimer          = $Timer
@onready var vignette_rect      = $GameUI/VignetteRect
@onready var module_caption     = $GameUI/TopBar/TopMargin/TopVBox/ModuleCaption

const POPUP_SCENE   = preload("res://scenes/core/gamePopup.tscn")
const RESULT_SCREEN = preload("res://scenes/core/result_screen.tscn")

var game_config     : GameData.MiniGameConfig = null
var current_score   : float = 0.0
var time_remaining  : float = 0.0
var is_game_active  : bool  = false
var is_game_over    : bool  = false
var failed_once     : bool  = false

# ── Chrome nodes (built when scene has no GameUI) ─────────────────────────────
var _chrome_root   : CanvasLayer = null
var _timer_lbl_c   : Label       = null
var _score_lbl_c   : Label       = null
var _instr_lbl_c   : Label       = null
var _title_lbl_c   : Label       = null
var _caption_lbl_c : Label       = null
var _timer_panel_c : Panel       = null
var _timer_cap_c   : Label       = null
var _vignette_c    : ColorRect   = null
var _score_panel_c : Panel       = null
var _status_dot_c  : ColorRect   = null
var _sysload_lbl_c : Label       = null

# ── Chrome layout dims ────────────────────────────────────────────────────────
var _vp_w   : float = 0.0
var _vp_h   : float = 0.0
var _top_h  : float = 0.0
var _bot_h  : float = 0.0
var _game_y : float = 0.0
var _game_h : float = 0.0

var _using_chrome : bool = false

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_fb = _lf(FONT_BOLD)
	_fm = _lf(FONT_MEDIUM)
	_fr = _lf(FONT_REG)

	game_config = GameManager.get_current_game_config()
	if not game_config:
		push_error("MiniGamesTemplate: no game config found")
		return

	var has_game_ui := has_node("GameUI")
	if has_game_ui:
		_using_chrome = false
		# ── FIX: force GameUI canvas layer to 20 so it always renders
		# above any popup (which typically uses layer 0–10) ──────────────────
		var gui_layer : CanvasLayer = $GameUI
		gui_layer.layer = 20
		setup_from_config()
		setup_ui()
		setup_timer()
	else:
		_using_chrome = true
		setup_from_config()
		_hide_legacy_nodes()
		_build_chrome()
		setup_timer()

	GameManager.start_current_game()
	await get_tree().create_timer(0.5).timeout
	start_game()

# ── Hide stray scene nodes that don't live under GameUI ───────────────────────
func _hide_legacy_nodes() -> void:
	var names_to_hide := [
		"BottomBar", "TopBar", "HUD",
		"ScoreLabel", "TimerLabel", "ScorePanel", "TimerPanel",
		"SessionCountdown", "ScoreContainer", "TimerContainer",
		"BottomHBox", "BottomMargin",
	]
	for n_name in names_to_hide:
		var n := find_child(n_name, true, false)
		if n and n is CanvasItem:
			(n as CanvasItem).visible = false

# ─────────────────────────────────────────────────────────────────────────────
func setup_from_config() -> void:
	time_remaining = game_config.time_limit

func play_game_music() -> void:
	if game_config.music_track >= 0:
		AudioManager.play_music(game_config.music_track, 1.5, true)

# ── Legacy scene-based UI ─────────────────────────────────────────────────────
func setup_ui() -> void:
	if not article_label: return
	var article_num := GameManager.current_article_index + 1

	if module_caption:
		module_caption.text = "CORE_PROCESS: ACTIVE"
		_apply(module_caption, 14, C_CYAN, _fb)

	if article_label:
		article_label.text = "MODULE %02d — %s" % [article_num, game_config.display_name.to_upper()]
		_apply(article_label, 34, C_WHITE, _fb)

	if instructions_label:
		instructions_label.text = get_instructions()
		_apply(instructions_label, 15, C_DIM, _fr)

	var needs_score := game_config.win_factor in [GameData.WINFACTOR.POINTS_IN_TIME]
	if score_panel: score_panel.visible = needs_score
	if score_label: score_label.visible = needs_score
	if needs_score: update_score_display()

	if timer_panel:  timer_panel.visible  = game_config.is_timed
	if timer_label:  timer_label.visible  = game_config.is_timed
	if timer_caption:
		timer_caption.text = "TIME ELAPSED"
		_apply(timer_caption, 14, C_DIM, _fb)

	# ── Match bottom-bar stat panel labels to chrome reference style ──────────
	var score_cap = _try_node("GameUI/BottomBar/BottomMargin/BottomHBox/ScorePanel/ScoreMargin/ScoreVBox/ScoreCaption")
	if score_cap:
		score_cap.text = "NODES SECURED"
		_apply(score_cap, 14, C_DIM, _fb)

	# Restyle TimerPanel to match chrome reference (dark bg, cyan border)
	if timer_panel:
		_restyle_panel(timer_panel, C_BG, C_BORDER)

	# Restyle ScorePanel to match chrome reference
	if score_panel:
		_restyle_panel(score_panel, C_BG, C_BORDER)

	# Resize font on timer/score labels to match reference big numbers
	if timer_label:
		_apply(timer_label, 72, C_WHITE, _fb)
	if score_label:
		_apply(score_label, 72, C_CYAN, _fb)

# ── CHROME BUILDER ────────────────────────────────────────────────────────────
func _build_chrome() -> void:
	var vp   := get_viewport().get_visible_rect().size
	_vp_w = vp.x
	_vp_h = vp.y

	_top_h = clamp(_vp_h * 0.22, 120.0, 220.0)
	_bot_h = clamp(_vp_h * 0.22, 155.0, 220.0)
	_game_y = _top_h
	_game_h = _vp_h - _top_h - _bot_h

	# Layer 20 — same as legacy GameUI fix, always above popups
	_chrome_root        = CanvasLayer.new()
	_chrome_root.layer  = 20
	add_child(_chrome_root)

	# Full background
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chrome_root.add_child(bg)

	# Vignette overlay
	_vignette_c = ColorRect.new()
	_vignette_c.color = Color(0, 0, 0, 0)
	_vignette_c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chrome_root.add_child(_vignette_c)

	_build_top_bar()
	_build_bottom_bar()

# ── TOP BAR — matches reference exactly ───────────────────────────────────────
# Reference:  [■ CORE_PROCESS: ACTIVE]
#             [MODULE 02: DATA SCRUBBING]  ← large bold white
#             [▣  IDENTIFY AND ISOLATE CORRUPTED NODES.]
#             ─────────────────────────── cyan 2px line bottom
func _build_top_bar() -> void:
	var article_num := GameManager.current_article_index + 1

	var top_bg := ColorRect.new()
	top_bg.color    = C_BG2
	top_bg.position = Vector2(0, 0)
	top_bg.size     = Vector2(_vp_w, _top_h)
	_chrome_root.add_child(top_bg)

	# Cyan 2px accent at bottom of top bar
	var accent := ColorRect.new()
	accent.color    = C_CYAN
	accent.position = Vector2(0, _top_h - 2)
	accent.size     = Vector2(_vp_w, 2)
	_chrome_root.add_child(accent)

	var pad : float = clamp(_vp_w * 0.055, 18.0, 48.0)
	var y   : float = clamp(_top_h * 0.14, 14.0, 32.0)

	# Row 1: ■ CORE_PROCESS: ACTIVE
	var sq := ColorRect.new()
	sq.color    = C_CYAN
	sq.position = Vector2(pad, y + 3)
	sq.size     = Vector2(10, 10)
	_chrome_root.add_child(sq)

	_caption_lbl_c          = Label.new()
	_caption_lbl_c.text     = "CORE_PROCESS: ACTIVE"
	_caption_lbl_c.position = Vector2(pad + 18, y - 1)
	_apply(_caption_lbl_c, _fs(0.60, 11, 16), C_CYAN, _fb)
	_chrome_root.add_child(_caption_lbl_c)

	# Row 2: MODULE XX: GAME NAME  (large bold white)
	y += clamp(_top_h * 0.18, 20.0, 36.0)
	_title_lbl_c          = Label.new()
	_title_lbl_c.text     = "MODULE %02d: %s" % [article_num, game_config.display_name.to_upper()]
	_title_lbl_c.position = Vector2(pad, y)
	_apply(_title_lbl_c, _fs(1.80, 22, 48), C_WHITE, _fb)
	_chrome_root.add_child(_title_lbl_c)

	# Row 3: terminal icon + instructions (dim, small caps)
	y += clamp(_top_h * 0.30, 32.0, 56.0)
	_chrome_root.add_child(_draw_terminal_icon(Vector2(pad, y + 2), 20))

	_instr_lbl_c          = Label.new()
	_instr_lbl_c.text     = get_instructions().to_upper()
	_instr_lbl_c.position = Vector2(pad + 28, y)
	_apply(_instr_lbl_c, _fs(0.58, 11, 16), C_DIM, _fr)
	_chrome_root.add_child(_instr_lbl_c)

# ── BOTTOM BAR — matches reference exactly ────────────────────────────────────
# Reference:  • SYSTEM_LOAD: 42.8%          STATUS: NOMINAL
#             ─────────────────────────────────────────────
#             [  TIME ELAPSED  |  NODES SECURED  ]
#             [  02:14.09      |  1,450  PTS      ]
func _build_bottom_bar() -> void:
	var bot_y : float = _vp_h - _bot_h
	var pad   : float = clamp(_vp_w * 0.055, 18.0, 48.0)

	# Background
	var bot_bg := ColorRect.new()
	bot_bg.color    = C_BG2
	bot_bg.position = Vector2(0, bot_y)
	bot_bg.size     = Vector2(_vp_w, _bot_h)
	_chrome_root.add_child(bot_bg)

	# Top 1px border
	var bline := ColorRect.new()
	bline.color    = C_BORDER
	bline.position = Vector2(0, bot_y)
	bline.size     = Vector2(_vp_w, 1)
	_chrome_root.add_child(bline)

	# ── Micro status row ──────────────────────────────────────────────────────
	var row_y : float = bot_y + 10.0

	_status_dot_c          = ColorRect.new()
	_status_dot_c.color    = C_CYAN
	_status_dot_c.position = Vector2(pad, row_y + 4)
	_status_dot_c.size     = Vector2(8, 8)
	_chrome_root.add_child(_status_dot_c)
	var dot_tw := create_tween()
	dot_tw.set_loops()
	dot_tw.tween_property(_status_dot_c, "modulate:a", 0.15, 0.75)
	dot_tw.tween_property(_status_dot_c, "modulate:a", 1.0,  0.75)

	_sysload_lbl_c          = Label.new()
	_sysload_lbl_c.text     = "SYSTEM_LOAD: 42.8%"
	_sysload_lbl_c.position = Vector2(pad + 14, row_y)
	_apply(_sysload_lbl_c, _fs(0.44, 10, 14), C_DIMMER, _fb)
	_chrome_root.add_child(_sysload_lbl_c)

	var status_r      := Label.new()
	status_r.text     = "STATUS: NOMINAL"
	status_r.position = Vector2(_vp_w - pad - 150, row_y)
	_apply(status_r, _fs(0.44, 10, 14), C_DIMMER, _fb)
	_chrome_root.add_child(status_r)

	# Thin separator under micro row
	var sep_y : float = row_y + 24.0
	var sep           := ColorRect.new()
	sep.color         = C_BORDER
	sep.position      = Vector2(pad, sep_y)
	sep.size          = Vector2(_vp_w - pad * 2, 1)
	_chrome_root.add_child(sep)

	# ── Stat panels ───────────────────────────────────────────────────────────
	var panel_top : float = sep_y + 10.0
	var panel_h   : float = (_bot_h - (panel_top - bot_y)) - 10.0
	var usable_w  : float = _vp_w - pad * 2
	var needs_score : bool = game_config.win_factor in [GameData.WINFACTOR.POINTS_IN_TIME]
	var gap       : float = 8.0

	var timer_w : float = usable_w if not needs_score else (usable_w - gap) / 2.0
	var score_x : float = pad + timer_w + gap
	var score_w : float = (usable_w - gap) / 2.0

	# TIME ELAPSED panel
	if game_config.is_timed:
		_timer_panel_c = _make_stat_panel(Vector2(pad, panel_top), Vector2(timer_w, panel_h))
		_chrome_root.add_child(_timer_panel_c)

		_timer_cap_c          = Label.new()
		_timer_cap_c.text     = "TIME ELAPSED"
		_timer_cap_c.position = Vector2(pad + 14, panel_top + 10)
		_apply(_timer_cap_c, _fs(0.42, 10, 14), C_DIM, _fb)
		_chrome_root.add_child(_timer_cap_c)

		_timer_lbl_c          = Label.new()
		_timer_lbl_c.text     = "00:00.0"
		_timer_lbl_c.position = Vector2(pad + 14, panel_top + 28)
		_apply(_timer_lbl_c, _fs(2.60, 32, 72), C_WHITE, _fb)
		_chrome_root.add_child(_timer_lbl_c)

	# NODES SECURED panel
	if needs_score:
		_score_panel_c = _make_stat_panel(Vector2(score_x, panel_top), Vector2(score_w, panel_h))
		_chrome_root.add_child(_score_panel_c)

		var scap      := Label.new()
		scap.text     = "NODES SECURED"
		scap.position = Vector2(score_x + 14, panel_top + 10)
		_apply(scap, _fs(0.42, 10, 14), C_DIM, _fb)
		_chrome_root.add_child(scap)

		_score_lbl_c          = Label.new()
		_score_lbl_c.text     = "0"
		_score_lbl_c.position = Vector2(score_x + 14, panel_top + 28)
		_apply(_score_lbl_c, _fs(2.60, 32, 72), C_CYAN, _fb)
		_chrome_root.add_child(_score_lbl_c)

		var pts_lbl      := Label.new()
		pts_lbl.text     = "PTS"
		pts_lbl.position = Vector2(score_x + 14, panel_top + 28 + _fs(2.60, 32, 72) + 2)
		_apply(pts_lbl, _fs(0.40, 9, 13), C_DIM, _fr)
		_chrome_root.add_child(pts_lbl)

# ── Stat panel factory ────────────────────────────────────────────────────────
func _make_stat_panel(pos: Vector2, sz: Vector2) -> Panel:
	var p  := Panel.new()
	p.position = pos
	p.size     = sz
	var sb := StyleBoxFlat.new()
	sb.bg_color     = C_BG
	sb.border_color = C_BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	p.add_theme_stylebox_override("panel", sb)
	return p

# ── Terminal icon (drawn lines) ───────────────────────────────────────────────
func _draw_terminal_icon(pos: Vector2, size: float) -> Control:
	var ctrl          := Control.new()
	ctrl.position     = pos
	ctrl.size         = Vector2(size, size)
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := size
	ctrl.draw.connect(func():
		ctrl.draw_line(Vector2(2,      s*0.30), Vector2(s*0.42, s*0.50), C_DIM, 2.0)
		ctrl.draw_line(Vector2(s*0.42, s*0.50), Vector2(2,      s*0.70), C_DIM, 2.0)
		ctrl.draw_line(Vector2(s*0.50, s*0.72), Vector2(s*0.92, s*0.72), C_DIM, 2.0)
	)
	return ctrl

# ── Timer / score display ─────────────────────────────────────────────────────
func setup_timer() -> void:
	if game_config.is_timed:
		gameTimer.wait_time = 0.1
		gameTimer.timeout.connect(_on_timer_tick)
		update_timer_display()

func start_game() -> void:
	is_game_active = true
	if game_config.is_timed:
		gameTimer.start()
	on_game_started()

func _on_timer_tick() -> void:
	if not is_game_active or is_game_over: return
	time_remaining -= 0.1
	update_timer_display()
	if time_remaining <= 0:
		time_remaining = 0
		update_timer_display()
		gameTimer.stop()
		match game_config.win_factor:
			GameData.WINFACTOR.NO_FAIL_TIME_TIMIT, \
			GameData.WINFACTOR.TIME_LIMIT, \
			GameData.WINFACTOR.POINTS_IN_TIME:
				fail_game("Time's up!")

func update_timer_display() -> void:
	var s       := int(time_remaining)
	var ds      := int((time_remaining - s) * 10)
	var minutes := s / 60
	var seconds := s % 60
	var txt     := "%02d:%02d" % [minutes, seconds]
	var ds_txt  := ".%d" % ds

	var lbl : Label     = _timer_lbl_c   if _using_chrome else timer_label
	var cap : Label     = _timer_cap_c   if _using_chrome else timer_caption
	var pan : Panel     = _timer_panel_c if _using_chrome else timer_panel
	var vig : ColorRect = _vignette_c    if _using_chrome else vignette_rect

	if lbl: lbl.text = txt + ds_txt

	if time_remaining <= 5.0:
		if lbl:
			lbl.add_theme_color_override("font_color", C_RED)
			lbl.add_theme_font_size_override("font_size", _fs(2.80, 36, 80) if _using_chrome else 86)
		if cap: cap.add_theme_color_override("font_color", C_RED)
		if vig: vig.color = Color(0.5, 0.0, 0.0, 0.18 + 0.12 * sin(Time.get_ticks_msec() * 0.006))
		if pan: _restyle_panel(pan, Color(0.15, 0.02, 0.02, 1), C_RED)
	elif time_remaining <= 10.0:
		if lbl:
			lbl.add_theme_color_override("font_color", C_AMBER)
			lbl.add_theme_font_size_override("font_size", _fs(2.60, 32, 72) if _using_chrome else 72)
		if cap: cap.add_theme_color_override("font_color", C_AMBER)
		if vig: vig.color = Color(0.3, 0.15, 0.0, 0.08)
		if pan: _restyle_panel(pan, Color(0.10, 0.06, 0.0, 1), C_AMBER)
	else:
		if lbl:
			lbl.add_theme_color_override("font_color", C_WHITE)
			lbl.add_theme_font_size_override("font_size", _fs(2.60, 32, 72) if _using_chrome else 72)
		if cap: cap.add_theme_color_override("font_color", C_DIM)
		if vig: vig.color = Color(0, 0, 0, 0)
		if pan: _restyle_panel(pan, C_BG, C_BORDER)

func _restyle_panel(pan: Panel, bg: Color, border: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color     = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	pan.add_theme_stylebox_override("panel", sb)

func add_score(points: float = 1.0) -> void:
	current_score += points
	update_score_display()

func update_score_display() -> void:
	var txt := _fmt_score(int(current_score))
	if _using_chrome:
		if _score_lbl_c: _score_lbl_c.text = txt
	else:
		if score_label: score_label.text = txt

func _fmt_score(n: int) -> String:
	if n == 0: return "0"
	var s := str(n); var out := ""; var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		if cnt > 0 and cnt % 3 == 0: out = "," + out
		out = s[i] + out; cnt += 1
	return out

# ── Result screen ─────────────────────────────────────────────────────────────
func _show_result_screen(is_win: bool, reason: String = "") -> void:
	var screen = RESULT_SCREEN.instantiate()
	add_child(screen)
	var article_num := GameManager.current_article_index + 1
	var game_name   := game_config.display_name
	if is_win:
		screen.setup_win(article_num, game_name,
			current_score if game_config.win_factor == GameData.WINFACTOR.POINTS_IN_TIME else -1.0)
	else:
		screen.setup_fail(reason, article_num, game_name)
	screen.button_pressed.connect(_on_popup_button)

func _on_popup_button(button_id: String) -> void:
	match button_id:
		"restart": GameManager.reset_game()
		"next":    GameManager.complete_current_level(current_score)
		"quit":    GameManager.reset_game()

func _build_fail_config(reason: String) -> PopupConfig:
	var config               := PopupConfig.new()
	config.title             = "Terms Rejected"
	config.panel_color       = "red"
	config.show_close_button = false
	config.content_rows = [
		{type = "label_value", label = "Article:", value = "Article %d" % (GameManager.current_article_index + 1)},
		{type = "label_value", label = "Game:",    value = game_config.display_name},
		{type = "separator"},
		{type = "text", value = reason},
	]
	config.buttons = [
		{id = "restart", label = "Try Again", color = "red"},
		{id = "quit",    label = "Give Up",   color = "grey"},
	]
	return config

func _build_win_config() -> PopupConfig:
	var config               := PopupConfig.new()
	config.title             = "Terms Accepted"
	config.panel_color       = "green"
	config.show_close_button = false
	config.content_rows = [
		{type = "label_value", label = "Article:", value = "Article %d" % (GameManager.current_article_index + 1)},
		{type = "label_value", label = "Game:",    value = game_config.display_name},
	]
	if game_config.win_factor == GameData.WINFACTOR.POINTS_IN_TIME:
		config.content_rows.append({type = "label_value", label = "Score:", value = str(current_score)})
	config.content_rows.append({type = "separator"})
	config.content_rows.append({type = "text", value = "You have successfully complied with all terms."})
	config.buttons = [{id = "next", label = "Continue", color = "green"}]
	return config

func register_failure() -> void:
	match game_config.win_factor:
		GameData.WINFACTOR.NO_FAIL, \
		GameData.WINFACTOR.NO_FAIL_TIME_TIMIT, \
		GameData.WINFACTOR.POINTS_IN_TIME:
			if not failed_once:
				failed_once = true
				fail_game("You Failed!")

func win_game() -> void:
	if is_game_over: return
	is_game_over = true; is_game_active = false
	gameTimer.stop()
	on_game_ended()
	await get_tree().create_timer(0.5).timeout
	_show_result_screen(true)

func fail_game(reason: String = "Failed") -> void:
	if is_game_over: return
	is_game_over = true; is_game_active = false
	gameTimer.stop()
	on_game_ended()
	await get_tree().create_timer(0.5).timeout
	_show_result_screen(false, reason)

func get_instructions() -> String:
	match game_config.win_factor:
		GameData.WINFACTOR.POINTS_IN_TIME:
			return "Earn %d points within %d seconds." % [game_config.success_condition, game_config.time_limit]
		GameData.WINFACTOR.NO_FAIL:
			return "Complete the game without failing."
		GameData.WINFACTOR.TIME_LIMIT:
			return "Complete within %d seconds." % game_config.time_limit
		GameData.WINFACTOR.NO_FAIL_TIME_TIMIT:
			return "Complete within %d seconds without failing." % game_config.time_limit
		GameData.WINFACTOR.COMPLETE:
			return "Complete this game to proceed."
		_:
			return "Complete the objective."

func restart_level() -> void:
	get_tree().reload_current_scene()

func get_time_remaining() -> float:
	return time_remaining

func on_game_started() -> void: pass
func on_game_ended()   -> void: pass
func _process(_delta: float) -> void: pass

func _try_node(path: String) -> Node:
	if has_node(path): return get_node(path)
	return null

func _find_node_by_name(root: Node, target: String) -> Node:
	if root.name == target: return root
	for child in root.get_children():
		var result = _find_node_by_name(child, target)
		if result != null: return result
	return null

# ── Helpers ───────────────────────────────────────────────────────────────────
func _fs(u_mult: float, min_px: float = 8.0, max_px: float = 96.0) -> int:
	var u : float = clamp(_vp_w / 24.0, 14.0, 60.0)
	return int(clamp(u * u_mult, min_px, max_px))

func _apply(lbl: Label, size: int, col: Color, font: FontFile = null) -> void:
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", col)
	if font: lbl.add_theme_font_override("font", font)

func _lf(path: String) -> FontFile:
	if ResourceLoader.exists(path):
		var f = load(path)
		if f is FontFile: return f
	return null