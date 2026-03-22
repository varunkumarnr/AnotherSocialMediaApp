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

const FONT_PATH := "res://assets/fonts/JetBrainsMono-Regular.ttf"
var mono_font: FontFile = null

@onready var progress_label    = $MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/ProgressHBox/ProgressVBox/ProgressLabel
@onready var validated_label   = $MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/StatusHBox/ValidatedLabel
@onready var progress_bar_fill = $MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/ProgressBarBg/ProgressBarFill
@onready var article_list      = $MainVBox/ArticleScrollContainer/ArticleListContainer

var article_data = [
	{ "number": "01", "title": "SOVEREIGNTY WAIVER",        "tag": "STABLE",        "tag_color": "green",  "subject": "SUBJECT ID: #4401-X" },
	{ "number": "02", "title": "BIOMETRIC EXTRACTION",      "tag": "CRITICAL RISK", "tag_color": "red",    "subject": "SIGNAL INTERFERENCE DETECTED" },
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
	_load_font()
	if GameManager.game_sequence.is_empty():
		GameManager.start_new_game()
	generate_article_cards()
	update_progress_display()
	block_escape()

func _load_font() -> void:
	if ResourceLoader.exists(FONT_PATH):
		mono_font = load(FONT_PATH)

func _af(node: Node) -> void:
	if mono_font == null:
		return
	if node is Label or node is Button:
		node.add_theme_font_override("font", mono_font)
	for child in node.get_children():
		_af(child)

func generate_article_cards() -> void:
	for child in article_list.get_children():
		child.queue_free()
	for i in range(article_data.size()):
		article_list.add_child(_create_card(i))
	_af(article_list)

func _create_card(index: int) -> Panel:
	var data        = article_data[index]
	var is_current  = (index == GameManager.current_article_index)
	var is_done     = (index < GameManager.current_article_index)
	var is_locked   = (index > GameManager.current_article_index)
	var is_critical = is_current and data["tag_color"] == "red"

	# ── Card ────────────────────────────────────────────────────
	var card := Panel.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size   = Vector2(0, 220)

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

	# ── Margin ──────────────────────────────────────────────────
	var mc := MarginContainer.new()
	mc.layout_mode    = 1
	mc.anchors_preset = Control.PRESET_FULL_RECT
	mc.add_theme_constant_override("margin_left",   50)
	mc.add_theme_constant_override("margin_right",  44)
	mc.add_theme_constant_override("margin_top",    28)
	mc.add_theme_constant_override("margin_bottom", 28)
	card.add_child(mc)

	# ── Row ─────────────────────────────────────────────────────
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	mc.add_child(row)

	# Number
	var num_lbl := Label.new()
	num_lbl.text                = data["number"]
	num_lbl.custom_minimum_size = Vector2(80, 0)
	num_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	num_lbl.add_theme_font_size_override("font_size", 48)
	num_lbl.add_theme_color_override("font_color",
		COLOR_GHOST if is_locked else (COLOR_MUTED if is_done else COLOR_TEXT))
	row.add_child(num_lbl)

	# Accent bar for current card only
	if is_current:
		var bar := ColorRect.new()
		bar.custom_minimum_size = Vector2(5, 0)
		bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bar.color = COLOR_RED if is_critical else COLOR_CYAN
		row.add_child(bar)

	# Content vbox
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	row.add_child(vb)

	# Title
	var title_lbl := Label.new()
	title_lbl.text          = data["title"]
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	title_lbl.add_theme_font_size_override("font_size", 40)
	title_lbl.add_theme_color_override("font_color",
		COLOR_GHOST if is_locked else (COLOR_MUTED if is_done else COLOR_TEXT))
	vb.add_child(title_lbl)

	# ── Tag row — status-driven ──────────────────────────────────
	# Determine what tag and color to actually show
	var show_tag: String
	var show_tag_color: String
	var show_subject: String = ""

	if is_done:
		show_tag       = "COMPLETED"
		show_tag_color = "green"
	elif is_current:
		# Use the flavour tag from article_data
		show_tag       = data["tag"]
		show_tag_color = data["tag_color"]
		show_subject   = data["subject"]
	else:
		show_tag       = "LOCKED"
		show_tag_color = "locked"

	# Subject text — only for current card
	if show_subject != "":
		var subj_lbl := Label.new()
		subj_lbl.text = show_subject
		subj_lbl.add_theme_font_size_override("font_size", 26)
		subj_lbl.add_theme_color_override("font_color", COLOR_MUTED)
		vb.add_child(subj_lbl)

	# Badge
	var tag_row := HBoxContainer.new()
	tag_row.add_theme_constant_override("separation", 0)
	vb.add_child(tag_row)

	var badge := Panel.new()
	badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	badge.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	var badge_sb := StyleBoxFlat.new()
	badge_sb.corner_radius_top_left     = 4
	badge_sb.corner_radius_top_right    = 4
	badge_sb.corner_radius_bottom_left  = 4
	badge_sb.corner_radius_bottom_right = 4
	match show_tag_color:
		"green":  badge_sb.bg_color = Color(0.0,  0.35, 0.15, 1)
		"red":    badge_sb.bg_color = Color(0.45, 0.05, 0.05, 1)
		_:        badge_sb.bg_color = Color(0.10, 0.12, 0.16, 1)
	badge.add_theme_stylebox_override("panel", badge_sb)
	tag_row.add_child(badge)

	var badge_mc := MarginContainer.new()
	badge_mc.add_theme_constant_override("margin_left",   16)
	badge_mc.add_theme_constant_override("margin_right",  16)
	badge_mc.add_theme_constant_override("margin_top",     8)
	badge_mc.add_theme_constant_override("margin_bottom",  8)
	badge.add_child(badge_mc)

	var tag_lbl := Label.new()
	tag_lbl.text = show_tag
	tag_lbl.add_theme_font_size_override("font_size", 26)
	match show_tag_color:
		"green":  tag_lbl.add_theme_color_override("font_color", COLOR_GREEN)
		"red":    tag_lbl.add_theme_color_override("font_color", COLOR_RED)
		_:        tag_lbl.add_theme_color_override("font_color", COLOR_GHOST)
	badge_mc.add_child(tag_lbl)

	# Right icon
	var icon_lbl := Label.new()
	icon_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 40)
	if is_done:
		icon_lbl.text = "✓"
		icon_lbl.add_theme_color_override("font_color", COLOR_GREEN)
	elif is_critical:
		icon_lbl.text = "⚠"
		icon_lbl.add_theme_color_override("font_color", COLOR_AMBER)
	elif is_current:
		icon_lbl.text = "▶"
		icon_lbl.add_theme_color_override("font_color", COLOR_CYAN)
	else:
		icon_lbl.text = "🔒"
		icon_lbl.add_theme_color_override("font_color", COLOR_GHOST)
	row.add_child(icon_lbl)

	if is_current:
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(_on_card_clicked.bind(index))

	return card
	
func _on_card_clicked(event: InputEvent, _index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file("res://scenes/core/articleView.tscn")
	elif event is InputEventScreenTouch and event.pressed:
		get_tree().change_scene_to_file("res://scenes/core/articleView.tscn")

func update_progress_display() -> void:
	var completed := GameManager.current_article_index
	var pct       := int((float(completed) / 15.0) * 100.0)
	if progress_label:
		progress_label.text = str(pct) + "%"
	if validated_label:
		validated_label.text = str(completed) + " / 15 VALIDATED"
	if progress_bar_fill:
		progress_bar_fill.anchor_right = float(completed) / 15.0
	_af(self)

func block_escape() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		shake_screen()

func shake_screen() -> void:
	var original_pos = position
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	for i in range(3):
		tween.tween_property(self, "position:x", original_pos.x + 20, 0.05)
		tween.tween_property(self, "position:x", original_pos.x - 20, 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)