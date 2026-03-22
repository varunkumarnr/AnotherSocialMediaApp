class_name GamePopup
extends CanvasLayer

signal button_pressed(button_id: String)
signal checkbox_changed(index: int, checked: bool)
signal grid_button_pressed(button_id: String)
signal closed

const ASSET_PATH = "res://assets/ui/"
const FONT_PATH  = "res://assets/fonts/JetBrainsMono-Regular.ttf"

@onready var title_label:       Label         = $Control/CenterContainer/Panel/VBoxContainer/TitleBar/TopMargin/TitleHBox/TitleLabel
@onready var close_btn:         Button        = $Control/CenterContainer/Panel/VBoxContainer/TitleBar/TopMargin/TitleHBox/CloseButton
@onready var title_bar:         Panel         = $Control/CenterContainer/Panel/VBoxContainer/TitleBar
@onready var content_container: VBoxContainer = $Control/CenterContainer/Panel/VBoxContainer/ContentMargin/ContentContainer
@onready var button_bar:        HBoxContainer = $Control/CenterContainer/Panel/VBoxContainer/ButtonMargin/ButtonBar
@onready var main_panel:        Panel         = $Control/CenterContainer/Panel

# ── Colors ────────────────────────────────────────────────────────────────────
const C_BG       := Color(0.039, 0.047, 0.063, 1)
const C_BG2      := Color(0.059, 0.071, 0.094, 1)
const C_BG3      := Color(0.082, 0.102, 0.133, 1)
const C_BORDER   := Color(0.118, 0.137, 0.176, 1)
const C_CYAN     := Color(0.0,   0.831, 1.0,   1)
const C_GREEN    := Color(0.0,   1.0,   0.533, 1)
const C_RED      := Color(0.9,   0.2,   0.1,   1)
const C_AMBER    := Color(1.0,   0.67,  0.0,   1)
const C_MUTED    := Color(0.29,  0.353, 0.439, 1)
const C_TEXT     := Color(0.784, 0.831, 0.910, 1)

# Panel color → accent color mapping
const PANEL_COLORS := {
	"green":  Color(0.0,   0.831, 1.0,   1),   # cyan accent
	"red":    Color(0.9,   0.2,   0.1,   1),   # red accent
	"blue":   Color(0.0,   0.831, 1.0,   1),   # cyan accent
	"grey":   Color(0.29,  0.353, 0.439, 1),   # muted accent
	"yellow": Color(1.0,   0.67,  0.0,   1),   # amber accent
}

# Button color → fill color mapping
const BTN_COLORS := {
	"green":  Color(0.0,   0.6,   0.9,   1),
	"red":    Color(0.7,   0.1,   0.1,   1),
	"blue":   Color(0.3,   0.5,   0.9,   1),
	"grey":   Color(0.12,  0.15,  0.20,  1),
	"yellow": Color(0.7,   0.5,   0.0,   1),
}

var custom_font: FontFile = null
var checkbox_states: Dictionary = {}

func _ready() -> void:
	if ResourceLoader.exists(FONT_PATH):
		custom_font = load(FONT_PATH)
	if custom_font and title_label:
		title_label.add_theme_font_override("font", custom_font)
		title_label.add_theme_font_size_override("font_size", 32)

func configure(config: PopupConfig) -> void:
	_style_main_panel(config)
	_style_title_bar(config.panel_color)

	title_label.text = config.title
	if custom_font:
		title_label.add_theme_font_override("font", custom_font)

	close_btn.visible = config.show_close_button
	if config.show_close_button:
		if not close_btn.pressed.is_connected(func(): pass):
			close_btn.pressed.connect(func(): closed.emit(); queue_free())

	for child in content_container.get_children():
		child.queue_free()
	for child in button_bar.get_children():
		child.queue_free()

	checkbox_states.clear()

	for row in config.content_rows:
		_add_content_row(row)

	for btn_data in config.buttons:
		_add_button(config, btn_data)

	_style_button_bar()
	content_container.add_theme_constant_override("separation", 14)

func _style_button_bar() -> void:
	button_bar.add_theme_constant_override("separation", 20)
	button_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	button_bar.custom_minimum_size = Vector2(0, 110)

func _style_main_panel(config: PopupConfig) -> void:
	# Background
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color                   = C_BG
	bg_sb.corner_radius_top_left     = 0
	bg_sb.corner_radius_top_right    = 0
	bg_sb.corner_radius_bottom_left  = 0
	bg_sb.corner_radius_bottom_right = 0
	bg_sb.border_width_left          = 1
	bg_sb.border_width_right         = 1
	bg_sb.border_width_top           = 1
	bg_sb.border_width_bottom        = 1
	bg_sb.border_color               = C_BORDER
	main_panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	main_panel.custom_minimum_size   = Vector2(config.popup_width, config.popup_height)
	main_panel.add_theme_stylebox_override("panel", bg_sb)

func _style_title_bar(color: String) -> void:
	var accent :Color = PANEL_COLORS.get(color, C_CYAN)
	var is_red  := (color == "red")

	var bg_color := Color(0.18, 0.04, 0.04, 1) if is_red else C_BG2

	var sb := StyleBoxFlat.new()
	sb.bg_color               = bg_color
	sb.border_width_bottom    = 2
	sb.border_color           = accent
	sb.border_width_left      = 0
	sb.border_width_right     = 0
	sb.border_width_top       = 0
	title_bar.add_theme_stylebox_override("panel", sb)

	# Title label color
	if title_label:
		title_label.add_theme_color_override("font_color", accent)

	# Close button
	if close_btn:
		close_btn.add_theme_color_override("font_color", C_MUTED)

# ── Content rows ──────────────────────────────────────────────────────────────

func _add_content_row(row: Dictionary) -> void:
	match row.get("type", "text"):

		"text":
			var lbl := Label.new()
			lbl.text          = row.get("value", "")
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl.add_theme_font_size_override("font_size", 30)
			if custom_font:
				lbl.add_theme_font_override("font", custom_font)
			lbl.add_theme_color_override("font_color", C_TEXT)
			content_container.add_child(lbl)

		"label_value":
			var hbox    := HBoxContainer.new()
			var key_lbl := Label.new()
			key_lbl.text = row.get("label", "")
			key_lbl.custom_minimum_size.x = 200
			key_lbl.add_theme_color_override("font_color", C_MUTED)
			key_lbl.add_theme_font_size_override("font_size", 26)
			if custom_font:
				key_lbl.add_theme_font_override("font", custom_font)
			var val_lbl := Label.new()
			val_lbl.text = row.get("value", "")
			val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			val_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
			val_lbl.add_theme_color_override("font_color", C_TEXT)
			val_lbl.add_theme_font_size_override("font_size", 26)
			if custom_font:
				val_lbl.add_theme_font_override("font", custom_font)
			hbox.add_child(key_lbl)
			hbox.add_child(val_lbl)
			content_container.add_child(hbox)

		"separator":
			var sep := ColorRect.new()
			sep.custom_minimum_size = Vector2(0, 1)
			sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sep.color = C_BORDER
			content_container.add_child(sep)
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(0, 10)
			content_container.add_child(spacer)

		"button_list":
			var btns      : Array  = row.get("buttons", [])
			var columns   : int    = row.get("columns", btns.size())
			var btn_w     : int    = row.get("btn_w",   180)
			var btn_h     : int    = row.get("btn_h",   70)
			var font_size : int    = row.get("font_size", 26)
			var all_off   : bool   = row.get("disabled", false)

			var grid := GridContainer.new()
			grid.columns = max(1, columns)
			grid.add_theme_constant_override("h_separation", 12)
			grid.add_theme_constant_override("v_separation", 12)
			grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content_container.add_child(grid)

			for btn_data in btns:
				var btn         := Button.new()
				var bid  : String = btn_data.get("id",    "btn")
				var blbl : String = btn_data.get("label", bid)
				var bcol : String = btn_data.get("color", "grey")

				btn.text                = blbl
				btn.custom_minimum_size = Vector2(btn_w, btn_h)
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				btn.name                = "GridBtn_" + bid
				btn.disabled            = all_off
				btn.add_theme_font_size_override("font_size", font_size)
				if custom_font:
					btn.add_theme_font_override("font", custom_font)
				_style_grid_button_flat(btn, bcol)
				btn.add_theme_color_override("font_color", Color(1, 1, 1))
				btn.add_theme_color_override("font_disabled_color", C_MUTED)
				btn.pressed.connect(func(): grid_button_pressed.emit(bid))
				grid.add_child(btn)

		"checkbox_list":
			var items        : Array  = row.get("items", [])
			var index_offset : int    = row.get("index_offset", 0)
			var columns      : int    = row.get("columns", items.size())

			var grid := GridContainer.new()
			grid.columns = max(1, columns)
			grid.add_theme_constant_override("h_separation", 16)
			grid.add_theme_constant_override("v_separation", 12)
			content_container.add_child(grid)

			for i in range(items.size()):
				var global_idx : int = index_offset + i
				checkbox_states[global_idx] = false

				var hbox := HBoxContainer.new()
				hbox.add_theme_constant_override("separation", 8)
				hbox.alignment = BoxContainer.ALIGNMENT_CENTER

				var cb := TextureButton.new()
				cb.toggle_mode         = true
				cb.button_pressed      = false
				cb.texture_normal      = _load_checkbox_tex(false)
				cb.texture_pressed     = _load_checkbox_tex(true)
				cb.texture_hover       = _load_checkbox_tex(false)
				cb.texture_focused     = _load_checkbox_tex(false)
				cb.custom_minimum_size = Vector2(48, 48)
				cb.stretch_mode        = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
				cb.ignore_texture_size = true

				if items[i] != "":
					var lbl := Label.new()
					lbl.text = items[i]
					if custom_font:
						lbl.add_theme_font_override("font", custom_font)
					lbl.add_theme_font_size_override("font_size", 26)
					lbl.add_theme_color_override("font_color", C_TEXT)
					lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
					lbl.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
					hbox.add_child(lbl)

				hbox.add_child(cb)
				grid.add_child(hbox)

				cb.toggled.connect(func(pressed: bool):
					checkbox_states[global_idx] = pressed
					cb.texture_normal = _load_checkbox_tex(pressed)
					cb.texture_hover  = _load_checkbox_tex(pressed)
					checkbox_changed.emit(global_idx, pressed)
				)

		"timer_display":
			var initial: String = row.get("initial_text", "")
			var fsize  : int    = row.get("font_size", 72)

			var timer_lbl := Label.new()
			timer_lbl.name                  = "TimerDisplay"
			timer_lbl.text                  = initial
			timer_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
			timer_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if custom_font:
				timer_lbl.add_theme_font_override("font", custom_font)
			timer_lbl.add_theme_font_size_override("font_size", fsize)
			timer_lbl.add_theme_color_override("font_color", C_CYAN)
			content_container.add_child(timer_lbl)

		"coin_display":
			var coin_size : int   = row.get("size", 160)
			var r         : float = coin_size / 2.0

			var wrapper := CenterContainer.new()
			wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			wrapper.custom_minimum_size   = Vector2(0, coin_size + 24)
			content_container.add_child(wrapper)

			var coin := Control.new()
			coin.name                = "CoinFace"
			coin.custom_minimum_size = Vector2(coin_size, coin_size)
			coin.set_meta("coin_color", Color(0.94, 0.78, 0.22))
			coin.set_meta("coin_radius", r)

			coin.draw.connect(func():
				var col    : Color = coin.get_meta("coin_color")
				var rx     : float = coin.get_meta("coin_radius") * coin.get_meta("coin_spin_x", 1.0)
				var ry     : float = coin.get_meta("coin_radius")
				var center : Vector2 = Vector2(r, r)
				var pts    : PackedVector2Array = PackedVector2Array()
				var steps  : int = 48
				for s in range(steps + 1):
					var a : float = s * TAU / steps
					pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
				coin.draw_colored_polygon(pts, col.darkened(0.25))
				var pts2 : PackedVector2Array = PackedVector2Array()
				for s in range(steps + 1):
					var a : float = s * TAU / steps
					pts2.append(center + Vector2(cos(a) * rx * 0.88, sin(a) * ry * 0.88))
				coin.draw_colored_polygon(pts2, col)
				if rx > 4.0:
					coin.draw_arc(center, min(rx, ry) * 0.65,
						deg_to_rad(200), deg_to_rad(280), 24,
						Color(1, 1, 1, 0.28), min(rx, ry) * 0.10)
			)
			wrapper.add_child(coin)

			var lbl := Label.new()
			lbl.name                 = "CoinLabel"
			lbl.size                 = Vector2(coin_size, coin_size)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
			if custom_font:
				lbl.add_theme_font_override("font", custom_font)
			lbl.add_theme_font_size_override("font_size", 28)
			lbl.add_theme_color_override("font_color", Color(0.25, 0.18, 0.02))
			lbl.text = "TOSS?"
			coin.add_child(lbl)

		"progress_icons":
			var count      : int    = row.get("count", 3)
			var check_path : String = row.get("check_path", "")
			var cross_path : String = row.get("cross_path", "")
			var icon_size  : int    = row.get("icon_size", 72)

			var hbox := HBoxContainer.new()
			hbox.name                  = "ProgressIconRow"
			hbox.alignment             = BoxContainer.ALIGNMENT_CENTER
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_theme_constant_override("separation", 20)
			content_container.add_child(hbox)

			for i in range(count):
				var slot := Control.new()
				slot.name                = "ProgSlot_%d" % i
				slot.custom_minimum_size = Vector2(icon_size, icon_size)

				var bg := ColorRect.new()
				bg.name  = "SlotBG"
				bg.color = C_BG3
				bg.size  = Vector2(icon_size, icon_size)
				slot.add_child(bg)

				var lbl := Label.new()
				lbl.name                 = "SlotLabel"
				lbl.size                 = Vector2(icon_size, icon_size)
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
				lbl.add_theme_font_size_override("font_size", int(icon_size * 0.5))
				lbl.add_theme_color_override("font_color", C_MUTED)

				var path : String = "res://assets/ui/Red/Double/star_outline.png"
				if path != "" and ResourceLoader.exists(path):
					_set_slot_texture(slot, path, icon_size)

				slot.set_meta("check_path", check_path)
				slot.set_meta("cross_path", cross_path)
				slot.set_meta("icon_size",  icon_size)
				hbox.add_child(slot)

		"image_grid":
			var cells     : Array = row.get("cells", [])
			var cell_size : int   = row.get("cell_size", 140)
			var cols      : int   = row.get("columns", 2)

			var grid := GridContainer.new()
			grid.name                  = "ImageGrid"
			grid.columns               = cols
			grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_theme_constant_override("h_separation", 12)
			grid.add_theme_constant_override("v_separation", 12)
			content_container.add_child(grid)

			for cell_data in cells:
				var cid   : String = cell_data.get("id",    "cell")
				var clbl  : String = cell_data.get("label", cid.to_upper())
				var cimg  : String = cell_data.get("image", "")
				var ccol  : String = cell_data.get("color", "grey")

				var btn := Button.new()
				btn.name                  = "ImgCell_" + cid
				btn.custom_minimum_size   = Vector2(cell_size, cell_size)
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				btn.clip_contents         = true
				_style_button_enabled(btn, ccol, true)

				if cimg != "" and ResourceLoader.exists(cimg):
					var tr := TextureRect.new()
					tr.texture      = load(cimg)
					tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					tr.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
					tr.set_anchors_preset(Control.PRESET_FULL_RECT)
					tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
					btn.add_child(tr)
				else:
					var ph := Label.new()
					ph.text                 = clbl[0]
					ph.set_anchors_preset(Control.PRESET_FULL_RECT)
					ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					ph.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
					ph.add_theme_font_size_override("font_size", int(cell_size * 0.35))
					ph.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
					ph.mouse_filter         = Control.MOUSE_FILTER_IGNORE
					btn.add_child(ph)

				var lbl := Label.new()
				lbl.text                 = clbl
				lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
				lbl.custom_minimum_size  = Vector2(0, 36)
				lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
				if custom_font:
					lbl.add_theme_font_override("font", custom_font)
				lbl.add_theme_font_size_override("font_size", 20)
				lbl.add_theme_color_override("font_color", Color(1, 1, 1))
				btn.add_child(lbl)

				btn.pressed.connect(func(): grid_button_pressed.emit(cid))
				grid.add_child(btn)

		"big_display":
			var h : int = row.get("height", 160)

			var panel := PanelContainer.new()
			panel.name                  = "BigDisplay"
			panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			panel.custom_minimum_size   = Vector2(0, h)

			var style := StyleBoxFlat.new()
			style.bg_color = C_BG3
			style.border_color = C_BORDER
			style.border_width_left   = 1
			style.border_width_right  = 1
			style.border_width_top    = 1
			style.border_width_bottom = 1
			style.set_corner_radius_all(4)
			panel.add_theme_stylebox_override("panel", style)

			var centre_lbl := Label.new()
			centre_lbl.name                 = "BigDisplayLabel"
			centre_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			centre_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			centre_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			if custom_font:
				centre_lbl.add_theme_font_override("font", custom_font)
			centre_lbl.add_theme_font_size_override("font_size", int(h * 0.38))
			centre_lbl.add_theme_color_override("font_color", C_TEXT)
			centre_lbl.text = ""
			centre_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(centre_lbl)

			var step_lbl := Label.new()
			step_lbl.name                 = "BigDisplayStep"
			step_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			step_lbl.grow_horizontal      = Control.GROW_DIRECTION_BEGIN
			step_lbl.grow_vertical        = Control.GROW_DIRECTION_BEGIN
			step_lbl.offset_left          = -90
			step_lbl.offset_top           = -36
			step_lbl.offset_right         = -12
			step_lbl.offset_bottom        = -8
			step_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			step_lbl.add_theme_font_size_override("font_size", 20)
			step_lbl.add_theme_color_override("font_color", C_MUTED)
			step_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
			step_lbl.text = ""
			panel.add_child(step_lbl)

			content_container.add_child(panel)

		"sequence_display":
			var slot_count : int = row.get("slots",     10)
			var slot_size  : int = row.get("slot_size", 52)

			var wrapper := HBoxContainer.new()
			wrapper.name                  = "SeqDisplay"
			wrapper.alignment             = BoxContainer.ALIGNMENT_CENTER
			wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			wrapper.add_theme_constant_override("separation", 6)
			content_container.add_child(wrapper)

			for i in range(slot_count):
				var slot := PanelContainer.new()
				slot.name                = "SeqSlot_%d" % i
				slot.custom_minimum_size = Vector2(slot_size, slot_size)

				var style := StyleBoxFlat.new()
				style.bg_color = C_BG3
				style.set_corner_radius_all(4)
				style.set_border_width_all(1)
				style.border_color = C_BORDER
				slot.add_theme_stylebox_override("panel", style)

				var lbl := Label.new()
				lbl.name                 = "SeqSlotLabel"
				lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
				lbl.add_theme_font_size_override("font_size", int(slot_size * 0.4))
				lbl.add_theme_color_override("font_color", C_TEXT)
				lbl.text = ""
				slot.add_child(lbl)
				wrapper.add_child(slot)

		"input_grid":
			var items    : Array = row.get("items",    [])
			var columns  : int   = row.get("columns",  3)
			var btn_size : int   = row.get("btn_size", 110)

			var grid := GridContainer.new()
			grid.name                  = "InputGrid"
			grid.columns               = columns
			grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.size_flags_vertical   = Control.SIZE_SHRINK_BEGIN
			grid.add_theme_constant_override("h_separation", 10)
			grid.add_theme_constant_override("v_separation", 10)
			content_container.add_child(grid)

			for item in items:
				var iid   : String = item.get("id",    "cell")
				var ilbl  : String = item.get("label", "")
				var icolor        = item.get("color",  Color(0.12, 0.15, 0.20))

				var btn := Button.new()
				btn.name                = "InputCell_" + iid
				btn.custom_minimum_size = Vector2(btn_size, btn_size)
				btn.clip_contents       = true

				var style := StyleBoxFlat.new()
				style.bg_color = icolor if icolor is Color else Color(icolor)
				style.set_corner_radius_all(6)
				style.set_border_width_all(1)
				style.border_color = C_BORDER
				btn.add_theme_stylebox_override("normal", style)

				var hover_style := style.duplicate()
				hover_style.bg_color = style.bg_color.lightened(0.2)
				btn.add_theme_stylebox_override("hover", hover_style)

				var press_style := style.duplicate()
				press_style.bg_color = style.bg_color.darkened(0.2)
				btn.add_theme_stylebox_override("pressed", press_style)

				var dis_style := style.duplicate()
				dis_style.bg_color = C_BG3
				btn.add_theme_stylebox_override("disabled", dis_style)

				if ilbl != "":
					var lbl := Label.new()
					lbl.text                 = ilbl
					lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
					lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
					if custom_font:
						lbl.add_theme_font_override("font", custom_font)
					lbl.add_theme_font_size_override("font_size", int(btn_size * 0.28))
					lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
					lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
					btn.add_child(lbl)

				btn.pressed.connect(grid_button_pressed.emit.bind(iid))
				grid.add_child(btn)

		"slot_reels":
			var col_count    : int   = row.get("col_count",    3)
			var symbol_size  : float = row.get("symbol_size",  90.0)
			var visible_rows : int   = row.get("visible_rows", 3)
			var window_h     : float = symbol_size * visible_rows
			var gap          : float = 6.0

			var hbox := HBoxContainer.new()
			hbox.name                  = "ReelContainer"
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_theme_constant_override("separation", int(gap))
			content_container.add_child(hbox)

			for i in range(col_count):
				var window := Control.new()
				window.name                  = "Reel_%d" % i
				window.custom_minimum_size   = Vector2(symbol_size, window_h)
				window.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				window.clip_contents         = true

				var border_rect := ColorRect.new()
				border_rect.color    = C_BORDER
				border_rect.size     = Vector2(symbol_size, window_h)
				border_rect.position = Vector2.ZERO
				border_rect.z_index  = -1
				window.add_child(border_rect)

				var mid_bar := ColorRect.new()
				mid_bar.name         = "MidBar_%d" % i
				mid_bar.color        = Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, 0.12)
				mid_bar.size         = Vector2(symbol_size, symbol_size)
				mid_bar.position     = Vector2(0, symbol_size)
				mid_bar.z_index      = 10
				mid_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
				window.add_child(mid_bar)

				hbox.add_child(window)

		"slot_stops":
			var col_count : int = row.get("col_count", 3)

			var hbox := HBoxContainer.new()
			hbox.name                  = "StopBtnRow"
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_theme_constant_override("separation", 6)
			content_container.add_child(hbox)

			var result_lbl := Label.new()
			result_lbl.name                  = "SlotResultLabel"
			result_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			result_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
			if custom_font:
				result_lbl.add_theme_font_override("font", custom_font)
			result_lbl.add_theme_font_size_override("font_size", 26)
			result_lbl.add_theme_color_override("font_color", C_MUTED)
			result_lbl.text = ""

			var vbox := VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var btn_row := HBoxContainer.new()
			btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn_row.add_theme_constant_override("separation", 6)

			for i in range(col_count):
				var btn := Button.new()
				btn.name                  = "StopBtn_%d" % i
				btn.text                  = "STOP"
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				btn.custom_minimum_size   = Vector2(0, 70)
				_style_button_enabled(btn, "red", true)
				btn.add_theme_color_override("font_color", Color(1, 1, 1))
				if custom_font:
					btn.add_theme_font_override("font", custom_font)
				btn.add_theme_font_size_override("font_size", 26)
				btn_row.add_child(btn)

			vbox.add_child(btn_row)
			vbox.add_child(result_lbl)
			hbox.add_child(vbox)

# ── Buttons ───────────────────────────────────────────────────────────────────

func _add_button(config: PopupConfig, btn_data: Dictionary) -> void:
	var btn := Button.new()
	btn.text                = btn_data.get("label", "OK")
	btn.custom_minimum_size = Vector2(220, 90)
	if custom_font:
		btn.add_theme_font_override("font", custom_font)

	var color : String = btn_data.get("color", "grey")
	_style_popup_button(btn, color)

	var id           : String = btn_data.get("id", "ok")
	var should_close : bool   = btn_data.get("shouldClose", true)
	btn.set_meta("shouldClose", should_close)

	if btn_data.get("requires_all_checked", false):
		btn.disabled = true
		checkbox_changed.connect(func(_idx, _val):
			btn.disabled = not all_checked()
			_style_popup_button(btn, color)
		)

	btn.pressed.connect(func():
		button_pressed.emit(id)
		if btn.get_meta("shouldClose", true):
			queue_free()
	)
	button_bar.add_child(btn)

func _style_popup_button(btn: Button, color: String) -> void:
	var fill :Color = BTN_COLORS.get(color, BTN_COLORS["grey"])
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb := StyleBoxFlat.new()
		match state:
			"normal":   sb.bg_color = fill
			"hover":    sb.bg_color = fill.lightened(0.15)
			"pressed":  sb.bg_color = fill.darkened(0.2)
			"disabled": sb.bg_color = C_BG3
			"focus":    sb.bg_color = fill
		sb.set_corner_radius_all(4)
		sb.border_color = fill.lightened(0.2) if state != "disabled" else C_BORDER
		sb.set_border_width_all(1)
		sb.content_margin_left   = 24
		sb.content_margin_right  = 24
		sb.content_margin_top    = 14
		sb.content_margin_bottom = 14
		btn.add_theme_stylebox_override(state, sb)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", C_MUTED)
	btn.add_theme_font_size_override("font_size", 28)

func _style_grid_button_flat(btn: Button, color: String) -> void:
	# Try asset first, fall back to flat style
	var cap      : String = _capitalize(color)
	var tex_path : String = ASSET_PATH + cap + "/Double/button_rectangle_depth_flat.png"
	if ResourceLoader.exists(tex_path):
		var state_files := {
			"normal":   ASSET_PATH + cap + "/Double/button_rectangle_depth_flat.png",
			"hover":    ASSET_PATH + cap + "/Double/button_rectangle_depth_gloss.png",
			"pressed":  ASSET_PATH + cap + "/Double/button_rectangle_flat.png",
			"disabled": ASSET_PATH + cap + "/Double/button_rectangle_depth_flat.png",
		}
		for state in state_files:
			var path : String = state_files[state]
			if ResourceLoader.exists(path):
				var style := StyleBoxTexture.new()
				style.texture               = load(path)
				style.texture_margin_left   = 12
				style.texture_margin_right  = 12
				style.texture_margin_top    = 12
				style.texture_margin_bottom = 12
				btn.add_theme_stylebox_override(state, style)
		if custom_font:
			btn.add_theme_font_override("font", custom_font)
	else:
		_style_button_enabled(btn, color, not btn.disabled)

# Keep original _style_button and _style_grid_button_with_asset for backward compat
func _style_button(config: PopupConfig, btn: Button, color: String) -> void:
	_style_popup_button(btn, color)

func _style_grid_button_with_asset(btn: Button, color: String) -> void:
	_style_grid_button_flat(btn, color)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", C_MUTED)

func _style_button_enabled(btn: Button, color: String, enabled: bool) -> void:
	var fill : Color = BTN_COLORS.get(color, BTN_COLORS["grey"]) as Color
	var display_c : Color = fill if enabled else C_BG3

	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		match state:
			"normal":   sb.bg_color = display_c
			"hover":    sb.bg_color = display_c.lightened(0.15)
			"pressed":  sb.bg_color = display_c.darkened(0.2)
			"disabled": sb.bg_color = C_BG3
		sb.set_corner_radius_all(4)
		sb.border_color = display_c.lightened(0.15) if enabled else C_BORDER
		sb.set_border_width_all(1)
		sb.content_margin_left   = 16
		sb.content_margin_right  = 16
		sb.content_margin_top    = 10
		sb.content_margin_bottom = 10
		btn.add_theme_stylebox_override(state, sb)

# ── All helper methods preserved exactly ─────────────────────────────────────

func _load_checkbox_tex(checked: bool) -> Texture2D:
	var path : String
	if checked:
		path = ASSET_PATH + "Green/Double/check_square_color.png"
	else:
		path = ASSET_PATH + "Grey/Double/check_square_color.png"

	if ResourceLoader.exists(path):
		return load(path)

	var img := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.6, 0.9) if checked else C_BG3)
	for x in range(40):
		for y in range(40):
			if x == 0 or x == 39 or y == 0 or y == 39:
				img.set_pixel(x, y, C_BORDER)
	return ImageTexture.create_from_image(img)

func all_checked() -> bool:
	for key in checkbox_states:
		if not checkbox_states[key]:
			return false
	return checkbox_states.size() > 0

func checked_count() -> int:
	var n := 0
	for key in checkbox_states:
		if checkbox_states[key]:
			n += 1
	return n

func get_grid_button(bid: String) -> Button:
	return find_child("GridBtn_" + bid, true, false) as Button

func set_grid_button_disabled(bid: String, disabled: bool) -> void:
	var btn := get_grid_button(bid)
	if btn:
		btn.disabled = disabled

func set_grid_button_color(bid: String, color: String) -> void:
	var btn := get_grid_button(bid)
	if btn:
		_style_grid_button_flat(btn, color)
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.add_theme_color_override("font_disabled_color", C_MUTED)

func set_all_grid_buttons_disabled(disabled: bool) -> void:
	for child in find_children("GridBtn_*", "Button", true, false):
		(child as Button).disabled = disabled

func set_timer_text(text: String) -> void:
	var lbl := find_child("TimerDisplay", true, false) as Label
	if lbl: lbl.text = text

func set_timer_visible(visiblal: bool) -> void:
	var lbl := find_child("TimerDisplay", true, false) as Label
	if lbl: lbl.visible = visiblal

func set_timer_color(color: Color) -> void:
	var lbl := find_child("TimerDisplay", true, false) as Label
	if lbl: lbl.add_theme_color_override("font_color", color)

func set_bottom_button_label(idx: int, label: String) -> void:
	var children := button_bar.get_children()
	if idx < children.size():
		(children[idx] as Button).text = label

func set_bottom_button_label_color(idx: int, color: Color) -> void:
	var children := button_bar.get_children()
	if idx < children.size():
		var btn := children[idx] as Button
		btn.add_theme_color_override("font_pressed_color", color)

func set_bottom_button_label_font_size(idx: int, size: int) -> void:
	var children := button_bar.get_children()
	if idx < children.size():
		(children[idx] as Button).add_theme_font_size_override("font_size", size)

func set_bottom_button_should_close(idx: int, value: bool) -> void:
	var children := button_bar.get_children()
	if idx < children.size():
		(children[idx] as Button).set_meta("shouldClose", value)

func set_bottom_button_color(idx: int, color: String) -> void:
	var children := button_bar.get_children()
	if idx < children.size():
		var btn := children[idx] as Button
		_style_grid_button_flat(btn, color)
		btn.add_theme_color_override("font_color", Color(1, 1, 1))

func set_bottom_button_disabled(idx: int, disabled: bool) -> void:
	var children := button_bar.get_children()
	if idx < children.size():
		(children[idx] as Button).disabled = disabled

func _capitalize(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)

func get_coin_face() -> ColorRect:
	return find_child("CoinFace", true, false) as ColorRect

func get_coin_label() -> Label:
	return find_child("CoinLabel", true, false) as Label

func set_coin_color(color: Color) -> void:
	var c := get_coin_face()
	if c:
		c.set_meta("coin_color", color)
		c.queue_redraw()

func set_coin_text(text: String) -> void:
	var l := get_coin_label()
	if l: l.text = text

func set_coin_scale(sx: float) -> void:
	var c := get_coin_face()
	var l := get_coin_label()
	if c:
		c.set_meta("coin_spin_x", sx)
		c.queue_redraw()
	if l:
		l.pivot_offset = l.size / 2.0
		l.scale        = Vector2(sx, 1.0)

func set_progress_icon(idx: int, state: String) -> void:
	var row := find_child("ProgressIconRow", true, false)
	if row == null: return
	var slot := row.get_node_or_null("ProgSlot_%d" % idx) as Control
	if slot == null: return

	var bg        : ColorRect = slot.get_node_or_null("SlotBG")    as ColorRect
	var lbl       : Label     = slot.get_node_or_null("SlotLabel") as Label
	var icon_size : int       = int(slot.get_meta("icon_size", 72))

	match state:
		"pass":
			var path : String = slot.get_meta("check_path", "")
			if path != "" and ResourceLoader.exists(path):
				_set_slot_texture(slot, path, icon_size)
			else:
				if bg:  bg.color = C_GREEN
				if lbl: lbl.text = "✓"
				if lbl: lbl.add_theme_color_override("font_color", Color(0, 0, 0))
		"fail":
			var path : String = slot.get_meta("cross_path", "")
			if path != "" and ResourceLoader.exists(path):
				_set_slot_texture(slot, path, icon_size)
			else:
				if bg:  bg.color = C_RED
				if lbl: lbl.text = "✗"
				if lbl: lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		_:
			var path : String = "res://assets/ui/Red/Double/star_outline.png"
			if path != "" and ResourceLoader.exists(path):
				_set_slot_texture(slot, path, icon_size)
			else:
				if bg:  bg.color = C_BG3
				if lbl: lbl.text = "?"
				if lbl: lbl.add_theme_color_override("font_color", C_MUTED)

func _set_slot_texture(slot: Control, path: String, icon_size: int) -> void:
	var old := slot.get_node_or_null("SlotTex")
	if old: old.queue_free()
	var tex_rect           := TextureRect.new()
	tex_rect.name          = "SlotTex"
	tex_rect.texture       = load(path)
	tex_rect.size          = Vector2(icon_size, icon_size)
	tex_rect.expand_mode   = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex_rect.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(tex_rect)
	var bg  := slot.get_node_or_null("SlotBG")    as ColorRect
	var lbl := slot.get_node_or_null("SlotLabel") as Label
	if bg:  bg.visible  = false
	if lbl: lbl.visible = false

func get_image_cell(cid: String) -> Button:
	return find_child("ImgCell_" + cid, true, false) as Button

func set_image_cell_color(cid: String, color: String) -> void:
	var btn := get_image_cell(cid)
	if btn:
		_style_button_enabled(btn, color, not btn.disabled)
		btn.add_theme_color_override("font_color", Color(1, 1, 1))

func set_image_cell_disabled(cid: String, disabled: bool) -> void:
	var btn := get_image_cell(cid)
	if btn: btn.disabled = disabled

func set_all_image_cells_disabled(disabled: bool) -> void:
	for btn in find_children("ImgCell_*", "Button", true, false):
		(btn as Button).disabled = disabled

func flash_image_cell(cid: String, color: String, duration: float = 0.3) -> void:
	var btn := get_image_cell(cid)
	if not btn: return
	set_image_cell_color(cid, color)
	await get_tree().create_timer(duration).timeout
	set_image_cell_color(cid, "grey")

func clear_sequence_display() -> void:
	var row := find_child("SeqDisplay", true, false)
	if not row: return
	for slot in row.get_children():
		var style := StyleBoxFlat.new()
		style.bg_color = C_BG3
		style.set_corner_radius_all(4)
		style.set_border_width_all(1)
		style.border_color = C_BORDER
		slot.add_theme_stylebox_override("panel", style)
		var lbl := slot.get_node_or_null("SeqSlotLabel") as Label
		if lbl: lbl.text = ""

func show_sequence_slot(idx: int, color: Color, label: String = "") -> void:
	var row := find_child("SeqDisplay", true, false)
	if not row: return
	var slot := row.get_node_or_null("SeqSlot_%d" % idx) as PanelContainer
	if not slot: return
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	style.border_color = color.lightened(0.3)
	slot.add_theme_stylebox_override("panel", style)
	var lbl := slot.get_node_or_null("SeqSlotLabel") as Label
	if lbl: lbl.text = label

func pulse_sequence_slot(idx: int, color: Color, label: String = "", duration: float = 0.5) -> void:
	show_sequence_slot(idx, color, label)
	await get_tree().create_timer(duration).timeout
	var row := find_child("SeqDisplay", true, false)
	if not row: return
	var slot := row.get_node_or_null("SeqSlot_%d" % idx) as PanelContainer
	if not slot: return
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.5)
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	style.border_color = color.darkened(0.3)
	slot.add_theme_stylebox_override("panel", style)

func get_input_cell(iid: String) -> Button:
	return find_child("InputCell_" + iid, true, false) as Button

func set_input_cell_color(iid: String, color: Color) -> void:
	var btn := get_input_cell(iid)
	if not btn: return
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.set_border_width_all(1)
	style.border_color = C_BORDER
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate(); hover.bg_color = color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover)
	var press := style.duplicate(); press.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", press)

func flash_input_cell(iid: String, flash_color: Color, duration: float = 0.25) -> void:
	var btn := get_input_cell(iid)
	if not btn: return
	var orig := (btn.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
	set_input_cell_color(iid, flash_color)
	await get_tree().create_timer(duration).timeout
	set_input_cell_color(iid, orig)

func set_all_input_cells_disabled(disabled: bool) -> void:
	for btn in find_children("InputCell_*", "Button", true, false):
		(btn as Button).disabled = disabled

func set_big_display(color: Color, label: String, step: int = 0, total: int = 0) -> void:
	var panel := find_child("BigDisplay", true, false) as PanelContainer
	if not panel: return

	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	style.border_color = color.lightened(0.2)
	panel.add_theme_stylebox_override("panel", style)

	var lbl := panel.get_node_or_null("BigDisplayLabel") as Label
	if lbl: lbl.text = label

	var step_lbl := panel.get_node_or_null("BigDisplayStep") as Label
	if step_lbl:
		step_lbl.text = "%d / %d" % [step, total] if total > 0 else ""
