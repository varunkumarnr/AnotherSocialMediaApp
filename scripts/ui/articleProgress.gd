extends Control

const COLOR_BG     := Color(0.039, 0.047, 0.063, 1)
const COLOR_BG2    := Color(0.059, 0.071, 0.094, 1)
const COLOR_BG3    := Color(0.082, 0.102, 0.133, 1)
const COLOR_BORDER := Color(0.118, 0.137, 0.176, 1)
const COLOR_CYAN   := Color(0.0,   0.831, 1.0,   1)
const COLOR_GREEN  := Color(0.0,   1.0,   0.533, 1)
const COLOR_RED    := Color(0.9,   0.2,   0.1,   1)
const COLOR_AMBER  := Color(1.0,   0.67,  0.0,   1)
const COLOR_MUTED  := Color(0.29,  0.353, 0.439, 1)
const COLOR_TEXT   := Color(0.784, 0.831, 0.910, 1)
const COLOR_GHOST  := Color(0.2,   0.25,  0.32,  1)

const FONT_TITLE  := "res://font/Inter_18pt-Black.ttf"
const FONT_BOLD   := "res://font/Inter_18pt-Bold.ttf"
const FONT_MEDIUM := "res://font/Inter_18pt-Medium.ttf"
const FONT_REG    := "res://font/Inter_18pt-Regular.ttf"

# ── ICON SVGs — place in res://assets/icons/ ─────────────────────────────────
const ICON_CHECK    := "res://assets/icons/check.png"
const ICON_PLAY     := "res://assets/icons/play.png"
const ICON_LOCK     := "res://assets/icons/lock.png"
const ICON_SHIELD   := "res://assets/icons/shield.png"


var _icon_tex : Dictionary = {}   # loaded once, shared across all cards

var _ft : FontFile = null
var _fb : FontFile = null
var _fm : FontFile = null
var _fr : FontFile = null

# ── Scene node refs ───────────────────────────────────────────────────────────
@onready var header_panel       = $MainVBox/HeaderPanel
@onready var shield_label       = $MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/TopHBox/ShieldLabel
@onready var system_status      = $MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/TopHBox/SystemStatus
@onready var encryption_label   = $MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/TopHBox/EncryptionVBox/EncryptionLabel
@onready var wifi_label         = $MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/TopHBox/EncryptionVBox/WifiLabel
@onready var overview_label     = $MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/OverviewLabel
@onready var title_label        = $MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/TitleLabel
@onready var aggregate_label    = $MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/ProgressHBox/ProgressVBox/AggregateLabel
@onready var progress_label     = $MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/ProgressHBox/ProgressVBox/ProgressLabel
@onready var progress_bar_fill  = $MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/ProgressBarBg/ProgressBarFill
@onready var status_label       = $MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/StatusHBox/StatusLabel
@onready var validated_label    = $MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/StatusHBox/ValidatedLabel
@onready var article_list       = $MainVBox/ArticleScrollContainer/ArticleListContainer

var article_data = [
	{ "number": "01", "title": "SOVEREIGNTY WAIVER",        "tag": "STABLE",        "tag_color": "green",  "subject": "SUBJECT ID: #4401-X" },
	{ "number": "02", "title": "BIOMETRIC EXTRACTION",      "tag": "LOCKED", 		"tag_color": "locked",    "subject": "" },
	{ "number": "03", "title": "NEURAL SYNCING",            "tag": "LOCKED",        "tag_color": "locked", "subject": "" },
	{ "number": "04", "title": "COGNITIVE MAPPING",         "tag": "LOCKED",        "tag_color": "locked", "subject": "" },
	{ "number": "05", "title": "ASSET CATEGORIZATION",      "tag": "LOCKED",        "tag_color": "locked", "subject": "" },
	{ "number": "06", "title": "MEMORY SANITATION",         "tag": "LOCKED",        "tag_color": "locked", "subject": "" },
	{ "number": "07", "title": "BEHAVIORAL REFACTORING",    "tag": "LOCKED",        "tag_color": "locked", "subject": "" },
	{ "number": "08", "title": "LOYALTY IMPRINTING",        "tag": "LOCKED",        "tag_color": "locked", "subject": "" },
	{ "number": "09", "title": "VISUAL FEED OVERRIDE",      "tag": "LOCKED",        "tag_color": "locked", "subject": "" },
	{ "number": "10", "title": "DIRECT COMMAND INJECT",     "tag": "LOCKED",        "tag_color": "locked", "subject": "" },
	{ "number": "11", "title": "AUDITORY FILTERING",        "tag": "LOCKED",        "tag_color": "locked", "subject": "" },
	{ "number": "12", "title": "SOCIAL BOND TERMINATION",   "tag": "LOCKED",        "tag_color": "locked", "subject": "" },
	{ "number": "13", "title": "STANDARDIZED RESPONSE",     "tag": "LOCKED",        "tag_color": "locked", "subject": "" },
	{ "number": "14", "title": "INTERNAL CLOCK SYNC",       "tag": "LOCKED",        "tag_color": "locked", "subject": "" },
	{ "number": "15", "title": "PHYSICAL COMPLIANCE FINAL", "tag": "LOCKED",        "tag_color": "locked", "subject": "" },
]

func _ready() -> void:
	_ft = _load_font(FONT_TITLE)
	_icon_tex["check"]  = _load_tex(ICON_CHECK)
	_icon_tex["play"]   = _load_tex(ICON_PLAY)
	_icon_tex["lock"]   = _load_tex(ICON_LOCK)
	_icon_tex["shield"] = _load_tex(ICON_SHIELD)
	_fb = _load_font(FONT_BOLD)
	_fm = _load_font(FONT_MEDIUM)
	_fr = _load_font(FONT_REG)

	_style_header()

	if GameManager.game_sequence.is_empty():
		GameManager.start_new_game()

	generate_article_cards()
	update_progress_display()
	block_escape()

# ── HEADER STYLING ────────────────────────────────────────────────────────────
func _style_header() -> void:
	# ── Top row: shield replaced with drawn icon via Control ──────────────────
	# Hide the emoji shield — unreliable on mobile
	if shield_label:
		shield_label.visible = false
		# Insert a drawn shield Control sibling before SystemStatus
		var shield_ctrl := Control.new()
		shield_ctrl.custom_minimum_size = Vector2(38, 38)
		shield_ctrl.mouse_filter        = Control.MOUSE_FILTER_IGNORE
		shield_ctrl.draw.connect(func():
			var sz  := shield_ctrl.size
			var tex : Texture2D = _icon_tex.get("shield", null)
			if tex:
				shield_ctrl.draw_texture_rect(tex, Rect2(Vector2.ZERO, sz), false, COLOR_CYAN)
				return
			# Fallback: drawn shield
			var cx  := sz.x * 0.5
			var col := COLOR_CYAN
			var pts := PackedVector2Array([
				Vector2(cx, sz.y * 0.96),
				Vector2(sz.x * 0.08, sz.y * 0.60),
				Vector2(sz.x * 0.08, sz.y * 0.22),
				Vector2(cx * 0.55,   sz.y * 0.06),
				Vector2(cx,          sz.y * 0.10),
				Vector2(sz.x * 0.92 - cx * 0.1, sz.y * 0.06),
				Vector2(sz.x * 0.92, sz.y * 0.22),
				Vector2(sz.x * 0.92, sz.y * 0.60),
			])
			shield_ctrl.draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.18))
			shield_ctrl.draw_polyline(PackedVector2Array(Array(pts) + [pts[0]]), col, 2.0)
			shield_ctrl.draw_line(Vector2(cx-8, sz.y*0.50), Vector2(cx-1, sz.y*0.62), col, 2.5)
			shield_ctrl.draw_line(Vector2(cx-1, sz.y*0.62), Vector2(cx+10, sz.y*0.36), col, 2.5)
		)
		var top_hbox = shield_label.get_parent()
		top_hbox.add_child(shield_ctrl)
		top_hbox.move_child(shield_ctrl, 0)

	# ── System status label ───────────────────────────────────────────────────
	if system_status:
		system_status.text = "SYSTEM_STATUS: NOMINAL"
		system_status.add_theme_font_override("font", _fb)
		system_status.add_theme_font_size_override("font_size", 28)
		system_status.add_theme_color_override("font_color", COLOR_CYAN)

	# ── Encryption label ──────────────────────────────────────────────────────
	if encryption_label:
		encryption_label.add_theme_font_override("font", _fr)
		encryption_label.add_theme_font_size_override("font_size", 20)
		encryption_label.add_theme_color_override("font_color", COLOR_MUTED)

	# ── Wifi / signal — replace emoji with drawn signal bars ─────────────────
	if wifi_label:
		wifi_label.visible = false
		var sig_ctrl := Control.new()
		sig_ctrl.custom_minimum_size = Vector2(34, 24)
		sig_ctrl.mouse_filter        = Control.MOUSE_FILTER_IGNORE
		sig_ctrl.draw.connect(func():
			var sz  := sig_ctrl.size
			var tex : Texture2D = _icon_tex.get("signal", null)
			if tex:
				sig_ctrl.draw_texture_rect(tex, Rect2(Vector2.ZERO, sz), false, COLOR_CYAN)
				return
			# Fallback: drawn bars
			var col   := COLOR_CYAN
			var bar_w : float = sz.x * 0.18
			var gap   : float = sz.x * 0.09
			var heights := [sz.y*0.38, sz.y*0.58, sz.y*0.78, sz.y*1.0]
			for i in range(4):
				var bx := i * (bar_w + gap)
				var bh :float= heights[i]
				var by :float= sz.y - bh
				sig_ctrl.draw_rect(Rect2(bx, by, bar_w, bh),
					Color(col.r, col.g, col.b, 0.25 if i >= 3 else 1.0))
		)
		wifi_label.get_parent().add_child(sig_ctrl)

	# ── Operational overview ──────────────────────────────────────────────────
	if overview_label:
		overview_label.add_theme_font_override("font", _fr)
		overview_label.add_theme_font_size_override("font_size", 22)
		overview_label.add_theme_color_override("font_color", COLOR_MUTED)
		overview_label.text = "OPERATIONAL OVERVIEW"

	# ── Main header title ─────────────────────────────────────────────────────
	if title_label:
		title_label.add_theme_font_override("font", _ft)
		title_label.add_theme_font_size_override("font_size", 68)
		title_label.add_theme_color_override("font_color", COLOR_CYAN)
		title_label.text = "COMPLIANCE\nPROTOCOL:\n15 MODULES"

	# ── Aggregate label ───────────────────────────────────────────────────────
	if aggregate_label:
		aggregate_label.add_theme_font_override("font", _fr)
		aggregate_label.add_theme_font_size_override("font_size", 20)
		aggregate_label.add_theme_color_override("font_color", COLOR_MUTED)
		aggregate_label.text = "AGGREGATE PROGRESS"

	# ── Progress % label ──────────────────────────────────────────────────────
	if progress_label:
		progress_label.add_theme_font_override("font", _ft)
		progress_label.add_theme_font_size_override("font_size", 64)
		progress_label.add_theme_color_override("font_color", COLOR_TEXT)

	# ── Status bottom row ─────────────────────────────────────────────────────
	if status_label:
		status_label.add_theme_font_override("font", _fr)
		status_label.add_theme_font_size_override("font_size", 22)
		status_label.add_theme_color_override("font_color", COLOR_MUTED)
		# Animated dots
		_animate_status_label()

	if validated_label:
		validated_label.add_theme_font_override("font", _fm)
		validated_label.add_theme_font_size_override("font_size", 22)
		validated_label.add_theme_color_override("font_color", COLOR_MUTED)

var _dot_count  : int   = 0
var _dot_timer  : float = 0.0

func _animate_status_label() -> void:
	# Handled in _process — just set initial text
	if status_label:
		status_label.text = "ESTABLISHING CONNECTION"

func _process(delta: float) -> void:
	_dot_timer += delta
	if _dot_timer >= 0.55:
		_dot_timer  = 0.0
		_dot_count  = (_dot_count + 1) % 4
		if status_label and is_instance_valid(status_label):
			status_label.text = "ESTABLISHING CONNECTION" + ".".repeat(_dot_count)

# ── CARD GENERATION ───────────────────────────────────────────────────────────
func generate_article_cards() -> void:
	for child in article_list.get_children():
		child.queue_free()
	for i in range(article_data.size()):
		article_list.add_child(_create_card(i))

func _create_card(index: int) -> Panel:
	var data        = article_data[index]
	var is_current  = (index == GameManager.current_article_index)
	var is_done     = (index < GameManager.current_article_index)
	var is_locked   = (index > GameManager.current_article_index)
	var is_critical = is_current and data["tag_color"] == "red"

	# ── Card panel ────────────────────────────────────────────────────────────
	var card := Panel.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size   = Vector2(0, 200)

	var card_sb := StyleBoxFlat.new()
	card_sb.border_width_bottom = 1
	card_sb.border_color        = COLOR_BORDER
	if is_critical:
		card_sb.bg_color          = Color(0.18, 0.04, 0.04, 1)
		card_sb.border_color      = COLOR_RED
		card_sb.border_width_left = 5
	elif is_current:
		card_sb.bg_color          = COLOR_BG2
		card_sb.border_width_left = 5
		card_sb.border_color      = COLOR_CYAN
	elif is_done:
		card_sb.bg_color = COLOR_BG2
	else:
		card_sb.bg_color = COLOR_BG
	card.add_theme_stylebox_override("panel", card_sb)

	# ── Margin ────────────────────────────────────────────────────────────────
	var mc := MarginContainer.new()
	mc.layout_mode    = 1
	mc.anchors_preset = Control.PRESET_FULL_RECT
	mc.add_theme_constant_override("margin_left",   44)
	mc.add_theme_constant_override("margin_right",  40)
	mc.add_theme_constant_override("margin_top",    24)
	mc.add_theme_constant_override("margin_bottom", 24)
	card.add_child(mc)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	mc.add_child(row)

	# ── Number ────────────────────────────────────────────────────────────────
	var num_lbl := Label.new()
	num_lbl.text                = data["number"]
	num_lbl.custom_minimum_size = Vector2(72, 0)
	num_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	num_lbl.add_theme_font_override("font", _fb)
	num_lbl.add_theme_font_size_override("font_size", 44)
	num_lbl.add_theme_color_override("font_color",
		COLOR_GHOST if is_locked else (COLOR_MUTED if is_done else COLOR_TEXT))
	row.add_child(num_lbl)

	# Cyan/red accent bar — current card only
	if is_current:
		var bar := ColorRect.new()
		bar.custom_minimum_size = Vector2(4, 0)
		bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bar.color = COLOR_RED if is_critical else COLOR_CYAN
		row.add_child(bar)

	# ── Content vbox ──────────────────────────────────────────────────────────
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	row.add_child(vb)

	# Title
	var title_lbl := Label.new()
	title_lbl.text          = data["title"]
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	title_lbl.add_theme_font_override("font", _fb)
	title_lbl.add_theme_font_size_override("font_size", 36)
	title_lbl.add_theme_color_override("font_color",
		COLOR_GHOST if is_locked else (COLOR_MUTED if is_done else COLOR_TEXT))
	vb.add_child(title_lbl)

	# Determine state
	var show_tag   : String
	var show_tcol  : String
	var show_subj  : String = ""

	if is_done:
		show_tag  = "COMPLETED"
		show_tcol = "green"
	elif is_current:
		show_tag  = data["tag"]
		show_tcol = data["tag_color"]
		show_subj = data["subject"]
	else:
		show_tag  = "LOCKED"
		show_tcol = "locked"

	# Subject line
	if show_subj != "":
		var subj := Label.new()
		subj.text = show_subj
		subj.add_theme_font_override("font", _fr)
		subj.add_theme_font_size_override("font_size", 24)
		subj.add_theme_color_override("font_color", COLOR_MUTED)
		vb.add_child(subj)

	# Badge
	var tag_row := HBoxContainer.new()
	tag_row.add_theme_constant_override("separation", 0)
	vb.add_child(tag_row)

	var badge := Panel.new()
	badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	badge.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	var badge_sb := StyleBoxFlat.new()
	badge_sb.set_corner_radius_all(4)
	match show_tcol:
		"green": badge_sb.bg_color = Color(0.0,  0.35, 0.15, 1)
		"red":   badge_sb.bg_color = Color(0.45, 0.05, 0.05, 1)
		_:       badge_sb.bg_color = Color(0.10, 0.12, 0.16, 1)
	badge.add_theme_stylebox_override("panel", badge_sb)
	tag_row.add_child(badge)

	var badge_mc := MarginContainer.new()
	badge_mc.add_theme_constant_override("margin_left",   14)
	badge_mc.add_theme_constant_override("margin_right",  14)
	badge_mc.add_theme_constant_override("margin_top",     6)
	badge_mc.add_theme_constant_override("margin_bottom",  6)
	badge.add_child(badge_mc)

	var tag_lbl := Label.new()
	tag_lbl.text = show_tag
	tag_lbl.add_theme_font_override("font", _fm)
	tag_lbl.add_theme_font_size_override("font_size", 22)
	match show_tcol:
		"green": tag_lbl.add_theme_color_override("font_color", COLOR_GREEN)
		"red":   tag_lbl.add_theme_color_override("font_color", COLOR_RED)
		_:       tag_lbl.add_theme_color_override("font_color", COLOR_GHOST)
	badge_mc.add_child(tag_lbl)

	# ── Right icon — drawn, no emoji ──────────────────────────────────────────
	var icon_ctrl := Control.new()
	icon_ctrl.custom_minimum_size = Vector2(36, 36)
	icon_ctrl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_ctrl.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	var ic_col : Color
	var ic_type : String
	if is_done:
		ic_col  = COLOR_GREEN; ic_type = "check"
	elif is_critical:
		ic_col  = COLOR_AMBER; ic_type = "warn"
	elif is_current:
		ic_col  = COLOR_CYAN;  ic_type = "play"
	else:
		ic_col  = COLOR_GHOST; ic_type = "lock"
	icon_ctrl.draw.connect(func(): _draw_card_icon(icon_ctrl, ic_type, ic_col))
	row.add_child(icon_ctrl)

	if is_current:
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		card.gui_input.connect(_on_card_clicked.bind(index))

	return card

# ── CARD ICONS — SVG first, drawn geometry fallback ──────────────────────────
func _draw_card_icon(ctrl: Control, icon: String, col: Color) -> void:
	var s   := ctrl.size
	var tex : Texture2D = _icon_tex.get(icon, null)
	if tex:
		var pad  : float = s.x * 0.08
		var tsz  := Vector2(s.x - pad*2, s.y - pad*2)
		ctrl.draw_texture_rect(tex, Rect2(Vector2(pad, pad), tsz), false, col)
		return
	# Fallback: pure geometry
	var cx := s.x * 0.5
	var cy := s.y * 0.5
	var r  :float= min(cx, cy) * 0.88
	match icon:
		"check":
			ctrl.draw_line(Vector2(cx-r*0.55, cy), Vector2(cx-r*0.1, cy+r*0.55), col, 2.8)
			ctrl.draw_line(Vector2(cx-r*0.1, cy+r*0.55), Vector2(cx+r*0.65, cy-r*0.5), col, 2.8)
		"warn":
			var pts := PackedVector2Array([
				Vector2(cx, cy-r), Vector2(cx+r*0.9, cy+r*0.8), Vector2(cx-r*0.9, cy+r*0.8)
			])
			ctrl.draw_polyline(PackedVector2Array([pts[0],pts[1],pts[2],pts[0]]), col, 2.2)
			ctrl.draw_line(Vector2(cx, cy-r*0.25), Vector2(cx, cy+r*0.35), col, 2.5)
			ctrl.draw_circle(Vector2(cx, cy+r*0.58), 2.5, col)
		"play":
			var pts := PackedVector2Array([
				Vector2(cx-r*0.32, cy-r*0.62),
				Vector2(cx+r*0.72, cy),
				Vector2(cx-r*0.32, cy+r*0.62),
			])
			ctrl.draw_colored_polygon(pts, col)
		"lock":
			ctrl.draw_arc(Vector2(cx, cy-r*0.22), r*0.40, deg_to_rad(200), deg_to_rad(340), 20, col, 2.2)
			var bw :float= r*0.90; var bh := r*0.62
			ctrl.draw_rect(Rect2(cx-bw*0.5, cy+r*0.04, bw, bh), Color(col.r,col.g,col.b,0.22))
			ctrl.draw_rect(Rect2(cx-bw*0.5, cy+r*0.04, bw, bh), col, false, 2.0)
			ctrl.draw_circle(Vector2(cx, cy+r*0.30), 4.0, col)

# ── CARD CLICK ────────────────────────────────────────────────────────────────
# ── CARD CLICK — tap only, scroll passes through ─────────────────────────────
const TAP_SLOP   := 10.0
var _touch_start : Vector2 = Vector2.ZERO
var _touch_moved : bool    = false

func _on_card_clicked(event: InputEvent, _index: int) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_touch_start = st.position
			_touch_moved = false
		else:
			if not _touch_moved:
				get_tree().change_scene_to_file("res://scenes/core/articleView.tscn")

	elif event is InputEventScreenDrag:
		# Finger moved — do NOT handle, let ScrollContainer receive it
		if (event as InputEventScreenDrag).position.distance_to(_touch_start) >= TAP_SLOP:
			_touch_moved = true
		return

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_touch_start = mb.position
			_touch_moved = false
		elif not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if not _touch_moved and mb.position.distance_to(_touch_start) < TAP_SLOP:
				get_tree().change_scene_to_file("res://scenes/core/articleView.tscn")

	elif event is InputEventMouseMotion:
		if (event as InputEventMouseMotion).position.distance_to(_touch_start) >= TAP_SLOP:
			_touch_moved = true
		return

# ── PROGRESS ──────────────────────────────────────────────────────────────────
func update_progress_display() -> void:
	var completed := GameManager.current_article_index
	var pct       := int((float(completed) / 15.0) * 100.0)
	if progress_label:  progress_label.text  = str(pct) + "%"
	if validated_label: validated_label.text = str(completed) + " / 15 VALIDATED"
	if progress_bar_fill:
		progress_bar_fill.anchor_right = float(completed) / 15.0

# ── HELPERS ───────────────────────────────────────────────────────────────────
func _load_font(path: String) -> FontFile:
	if ResourceLoader.exists(path):
		var f = load(path)
		if f is FontFile: return f
	return null

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var t = load(path)
		if t is Texture2D: return t
	return null

func block_escape() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		shake_screen()

func shake_screen() -> void:
	var original_pos = position
	var tween        = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	for i in range(3):
		tween.tween_property(self, "position:x", original_pos.x + 20, 0.05)
		tween.tween_property(self, "position:x", original_pos.x - 20, 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)