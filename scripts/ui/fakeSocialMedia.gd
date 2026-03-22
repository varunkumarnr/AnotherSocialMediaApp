extends Control

# ── Colors ────────────────────────────────────────────────────────────────────
const COLOR_BG     := Color(0.039, 0.047, 0.063, 1)
const COLOR_BG2    := Color(0.059, 0.071, 0.094, 1)
const COLOR_BORDER := Color(0.118, 0.137, 0.176, 1)
const COLOR_CYAN   := Color(0.0,   0.831, 1.0,   1)
const COLOR_GREEN  := Color(0.0,   1.0,   0.533, 1)
const COLOR_MUTED  := Color(0.29,  0.353, 0.439, 1)
const COLOR_TEXT   := Color(0.784, 0.831, 0.910, 1)

# ── Font ──────────────────────────────────────────────────────────────────────
const FONT_PATH := "res://assets/fonts/JetBrainsMono-Regular.ttf"
var mono_font: FontFile = null

func load_font() -> void:
	if ResourceLoader.exists(FONT_PATH):
		mono_font = load(FONT_PATH)
	else:
		push_warning("Font not found at: " + FONT_PATH)

func af(label: Label) -> void:
	if mono_font:
		label.add_theme_font_override("font", mono_font)

# ── Node refs ─────────────────────────────────────────────────────────────────
@onready var click_blocker = $ClickBlocker
@onready var post_feed     = $MarginContainer/VBoxContainer/Posts/ScrollContainer/PostFeed
@onready var scroll        = $MarginContainer/VBoxContainer/Posts/ScrollContainer
@onready var top_bar       = $MarginContainer/VBoxContainer/TopBar
@onready var top_hbox      = $MarginContainer/VBoxContainer/TopBar/HBoxContainer
@onready var posts_panel   = $MarginContainer/VBoxContainer/Posts
@onready var vbox          = $MarginContainer/VBoxContainer

var login_popup_scene = preload("res://scenes/core/login.tscn")
var post_card_scene   = preload("res://scenes/core/postCard.tscn")

var posts_data: Array = []
var nav_panels: Array = []
var active_nav: int   = 0

const USERS := [
	{ "name": "YOU",     "active": true  },
	{ "name": "A_NULL",  "active": false },
	{ "name": "SYS_ADM", "active": false },
	{ "name": "ROOT_X",  "active": false },
]
const NAV_TABS := ["ENCRYPT", "BREACH", "LOGS", "SYS_CTL"]

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	load_font()
	setup_ui()
	build_user_strip()
	build_bottom_nav()
	load_posts_data()
	generate_posts()
	setup_click_blocker()
	animate_posts_in()

# ── Top Bar ───────────────────────────────────────────────────────────────────

func setup_ui() -> void:
	$ColorRect.color = COLOR_BG

	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical    = Control.SIZE_EXPAND_FILL

	var topbar_sb := StyleBoxFlat.new()
	topbar_sb.bg_color            = COLOR_BG2
	topbar_sb.border_color        = COLOR_BORDER
	topbar_sb.border_width_bottom = 2
	top_bar.add_theme_stylebox_override("panel", topbar_sb)
	top_bar.custom_minimum_size = Vector2(0, 140)

	for child in top_hbox.get_children():
		child.queue_free()
	await get_tree().process_frame

	top_hbox.add_theme_constant_override("separation", 20)

	# ">_" logo box
	var logo_panel := Panel.new()
	logo_panel.custom_minimum_size   = Vector2(90, 90)
	logo_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	logo_panel.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	var logo_sb := StyleBoxFlat.new()
	logo_sb.bg_color                   = Color(0, 0, 0, 0)
	logo_sb.border_color               = COLOR_CYAN
	logo_sb.border_width_left          = 2
	logo_sb.border_width_right         = 2
	logo_sb.border_width_top           = 2
	logo_sb.border_width_bottom        = 2
	logo_sb.corner_radius_top_left     = 8
	logo_sb.corner_radius_top_right    = 8
	logo_sb.corner_radius_bottom_left  = 8
	logo_sb.corner_radius_bottom_right = 8
	logo_panel.add_theme_stylebox_override("panel", logo_sb)
	top_hbox.add_child(logo_panel)

	var logo_lbl := Label.new()
	logo_lbl.text                 = ">_<"
	logo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	logo_lbl.layout_mode          = 1
	logo_lbl.anchors_preset       = Control.PRESET_FULL_RECT
	logo_lbl.add_theme_color_override("font_color", COLOR_CYAN)
	logo_lbl.add_theme_font_size_override("font_size", 32)
	af(logo_lbl)
	logo_panel.add_child(logo_lbl)

	# Title + status vbox
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tv.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	tv.add_theme_constant_override("separation", 6)
	top_hbox.add_child(tv)

	var title_lbl := Label.new()
	title_lbl.text = "CODERAGE_OS_V.4.2"
	title_lbl.add_theme_color_override("font_color", COLOR_CYAN)
	title_lbl.add_theme_font_size_override("font_size", 38)
	af(title_lbl)
	tv.add_child(title_lbl)

	var status_panel := Panel.new()
	status_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	status_panel.custom_minimum_size   = Vector2(280, 44)
	var st_sb := StyleBoxFlat.new()
	st_sb.bg_color                   = Color(0, 0, 0, 0)
	st_sb.border_color               = COLOR_GREEN
	st_sb.border_width_left          = 2
	st_sb.border_width_right         = 2
	st_sb.border_width_top           = 2
	st_sb.border_width_bottom        = 2
	st_sb.corner_radius_top_left     = 4
	st_sb.corner_radius_top_right    = 4
	st_sb.corner_radius_bottom_left  = 4
	st_sb.corner_radius_bottom_right = 4
	status_panel.add_theme_stylebox_override("panel", st_sb)
	tv.add_child(status_panel)

	var st_lbl := Label.new()
	st_lbl.text                 = "STATUS: NOMINAL"
	st_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	st_lbl.layout_mode          = 1
	st_lbl.anchors_preset       = Control.PRESET_FULL_RECT
	st_lbl.add_theme_color_override("font_color", COLOR_GREEN)
	st_lbl.add_theme_font_size_override("font_size", 22)
	af(st_lbl)
	status_panel.add_child(st_lbl)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)

	# Right icons
	var icon_paths := [
		"res://assets/SocialMedia/magnifying-glass-solid-full.svg",
		"res://assets/SocialMedia/heart-regular-full.svg",
		"res://assets/SocialMedia/message-regular-full.svg",
	]
	for path in icon_paths:
		if not ResourceLoader.exists(path):
			continue
		var icon := TextureRect.new()
		icon.texture             = load(path)
		icon.custom_minimum_size = Vector2(60, 60)
		icon.expand_mode         = 1
		icon.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.modulate            = COLOR_MUTED
		top_hbox.add_child(icon)

	var posts_sb := StyleBoxFlat.new()
	posts_sb.bg_color = COLOR_BG
	posts_panel.add_theme_stylebox_override("panel", posts_sb)

# ── User Strip ────────────────────────────────────────────────────────────────

func build_user_strip() -> void:
	var strip := Panel.new()
	strip.custom_minimum_size   = Vector2(0, 180)
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color            = COLOR_BG2
	sb.border_color        = COLOR_BORDER
	sb.border_width_bottom = 2
	strip.add_theme_stylebox_override("panel", sb)

	var sc := ScrollContainer.new()
	sc.layout_mode            = 1
	sc.anchors_preset         = Control.PRESET_FULL_RECT
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sc.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
	strip.add_child(sc)

	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 30)
	mc.add_theme_constant_override("margin_right", 30)
	mc.add_theme_constant_override("margin_top", 16)
	mc.add_theme_constant_override("margin_bottom", 16)
	sc.add_child(mc)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 40)
	hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mc.add_child(hbox)

	for user in USERS:
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 8)
		hbox.add_child(vb)

		var av := Panel.new()
		av.custom_minimum_size = Vector2(100, 100)
		var av_sb := StyleBoxFlat.new()
		av_sb.bg_color                   = Color(0.082, 0.102, 0.133, 1)
		av_sb.border_width_left          = 3
		av_sb.border_width_right         = 3
		av_sb.border_width_top           = 3
		av_sb.border_width_bottom        = 3
		av_sb.border_color               = COLOR_CYAN if user["active"] else COLOR_BORDER
		av_sb.corner_radius_top_left     = 50
		av_sb.corner_radius_top_right    = 50
		av_sb.corner_radius_bottom_left  = 50
		av_sb.corner_radius_bottom_right = 50
		av.add_theme_stylebox_override("panel", av_sb)
		vb.add_child(av)

		var init_lbl := Label.new()
		init_lbl.text                 = user["name"].left(2)
		init_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		init_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		init_lbl.layout_mode          = 1
		init_lbl.anchors_preset       = Control.PRESET_FULL_RECT
		init_lbl.add_theme_color_override("font_color", COLOR_CYAN if user["active"] else COLOR_MUTED)
		init_lbl.add_theme_font_size_override("font_size", 28)
		af(init_lbl)
		av.add_child(init_lbl)

		var name_lbl := Label.new()
		name_lbl.text                 = user["name"]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_color_override("font_color", COLOR_CYAN if user["active"] else COLOR_MUTED)
		name_lbl.add_theme_font_size_override("font_size", 22)
		af(name_lbl)
		vb.add_child(name_lbl)

	vbox.add_child(strip)
	vbox.move_child(strip, 1)

# ── Bottom Nav ────────────────────────────────────────────────────────────────

func build_bottom_nav() -> void:
	var nav := Panel.new()
	nav.custom_minimum_size   = Vector2(0, 130)
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nav_sb := StyleBoxFlat.new()
	nav_sb.bg_color         = COLOR_BG2
	nav_sb.border_color     = COLOR_BORDER
	nav_sb.border_width_top = 2
	nav.add_theme_stylebox_override("panel", nav_sb)

	var hbox := HBoxContainer.new()
	hbox.layout_mode    = 1
	hbox.anchors_preset = Control.PRESET_FULL_RECT
	hbox.add_theme_constant_override("separation", 0)
	nav.add_child(hbox)

	nav_panels.clear()
	for i in range(NAV_TABS.size()):
		var tab := Panel.new()
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav_panels.append(tab)
		hbox.add_child(tab)

		var tv := VBoxContainer.new()
		tv.layout_mode    = 1
		tv.anchors_preset = Control.PRESET_FULL_RECT
		tv.add_theme_constant_override("separation", 0)
		tab.add_child(tv)

		var lbl := Label.new()
		lbl.text                  = NAV_TABS[i]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 26)
		af(lbl)
		tv.add_child(lbl)

		tab.gui_input.connect(_on_nav_pressed.bind(i))

	_set_active_nav(0)
	vbox.add_child(nav)

func _on_nav_pressed(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_active_nav(index)
	elif event is InputEventScreenTouch and event.pressed:
		_set_active_nav(index)

func _set_active_nav(index: int) -> void:
	active_nav = index
	for i in range(nav_panels.size()):
		var panel: Panel = nav_panels[i]
		var is_active    := (i == index)
		var sb           := StyleBoxFlat.new()
		sb.bg_color         = COLOR_BG2
		sb.border_color     = COLOR_CYAN if is_active else Color(0, 0, 0, 0)
		sb.border_width_top = 3
		panel.add_theme_stylebox_override("panel", sb)
		var lbl := panel.get_child(0).get_child(0) as Label
		if lbl:
			lbl.add_theme_color_override("font_color", COLOR_CYAN if is_active else COLOR_MUTED)

# ── Posts ─────────────────────────────────────────────────────────────────────

func load_posts_data() -> void:
	var file_path := "res://assets/data/fake_posts.json"
	if not FileAccess.file_exists(file_path):
		push_error("Posts JSON not found: " + file_path)
		return
	var file := FileAccess.open(file_path, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_string) == OK:
		var data = json.data
		if data.has("posts"):
			posts_data = data["posts"]
	else:
		push_error("JSON parse error: " + json.get_error_message())

func generate_posts() -> void:
	for child in post_feed.get_children():
		child.queue_free()
	for i in range(posts_data.size()):
		var post_card = post_card_scene.instantiate()
		post_feed.add_child(post_card)
		await get_tree().process_frame
		if post_card.has_method("setup"):
			post_card.setup(posts_data[i])

# ── Click blocker ─────────────────────────────────────────────────────────────

func setup_click_blocker() -> void:
	click_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	click_blocker.gui_input.connect(_on_screen_clicked)
	click_blocker.color = Color(0, 0, 0, 0.01)

func _on_screen_clicked(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		show_login_popup()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		show_login_popup()

func show_login_popup() -> void:
	var login_popup = login_popup_scene.instantiate()
	add_child(login_popup)
	click_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_login_popup_closed() -> void:
	click_blocker.mouse_filter = Control.MOUSE_FILTER_STOP

# ── Entrance animation ────────────────────────────────────────────────────────

func animate_posts_in() -> void:
	var posts := post_feed.get_children()
	for i in range(posts.size()):
		var post = posts[i]
		post.modulate.a = 0
		await get_tree().create_timer(i * 0.1).timeout
		var tween := create_tween()
		tween.tween_property(post, "modulate:a", 1.0, 0.3)