class_name GamePopup
extends CanvasLayer

signal button_pressed(button_id: String)
signal checkbox_changed(index: int, checked: bool)
signal grid_button_pressed(button_id: String) 
signal closed

const ASSET_PATH = "res://assets/ui/"

@onready var title_label: Label    = $Control/CenterContainer/Panel/VBoxContainer/TitleBar/TopMargin/TitleHBox/TitleLabel
@onready var close_btn: Button     = $Control/CenterContainer/Panel/VBoxContainer/TitleBar/TopMargin/TitleHBox/CloseButton
@onready var title_bar: Panel      = $Control/CenterContainer/Panel/VBoxContainer/TitleBar
@onready var content_container: VBoxContainer = $Control/CenterContainer/Panel/VBoxContainer/ContentMargin/ContentContainer
@onready var button_bar: HBoxContainer = $Control/CenterContainer/Panel/VBoxContainer/ButtonMargin/ButtonBar
@onready var main_panel: Panel     = $Control/CenterContainer/Panel

const CUSTOM_FONT_PATH = "res://font/Kenney Future.ttf"
var custom_font: FontFile = preload(CUSTOM_FONT_PATH)

var checkbox_states : Dictionary = {}

func _ready() -> void:
	var font_variation := FontVariation.new()
	font_variation.base_font = custom_font
	title_label.add_theme_font_override("font", font_variation)
	title_label.add_theme_font_size_override("font_size", 36)

func configure(config: PopupConfig) -> void:
	_style_main_panel(config)
	_style_title_bar(config.panel_color)

	title_label.text = config.title

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
	var style := StyleBoxFlat.new()
	style.bg_color                   = Color(0.92, 0.92, 0.92, 1)
	style.corner_radius_top_left     = 12
	style.corner_radius_top_right    = 12
	style.corner_radius_bottom_left  = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left          = 1
	style.border_width_right         = 1
	style.border_width_top           = 1
	style.border_width_bottom        = 1
	style.border_color               = Color(0, 0, 0, 0.08)
	style.shadow_size                = 8
	style.shadow_color               = Color(0, 0, 0, 0.18)
	style.shadow_offset              = Vector2(0, 3)

	main_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_panel.custom_minimum_size = Vector2(config.popup_width, config.popup_height)

	main_panel.set("theme_override_styles/panel", style)

func _style_title_bar(color: String) -> void:
	var colors := {
		"green":  Color(0.20, 0.64, 0.40),
		"red":    Color(0.80, 0.28, 0.28),
		"blue":   Color(0.26, 0.50, 0.80),
		"grey":   Color(0.55, 0.55, 0.55),
		"yellow": Color(0.85, 0.70, 0.15),
	}
	var c : Color = colors.get(color, Color(0.20, 0.64, 0.40))

	var style := StyleBoxFlat.new()
	style.bg_color               = c
	style.corner_radius_top_left = 12
	style.corner_radius_top_right= 12
	style.border_width_bottom    = 1
	style.border_color           = Color(0, 0, 0, 0.15)

	title_bar.set("theme_override_styles/panel", style)

func _add_content_row(row: Dictionary) -> void:
	match row.get("type", "text"):

		"text":
			var lbl := Label.new()
			lbl.text          = row.get("value", "")
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl.add_theme_font_size_override("font_size", 28)
			lbl.add_theme_font_override("font", custom_font)
			lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
			content_container.add_child(lbl)

		"label_value":
			var hbox    := HBoxContainer.new()
			var key_lbl := Label.new()
			key_lbl.text = row.get("label", "")
			key_lbl.custom_minimum_size.x = 150
			key_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
			key_lbl.add_theme_font_size_override("font_size", 28)
			key_lbl.add_theme_font_override("font", custom_font)
			var val_lbl := Label.new()
			val_lbl.text = row.get("value", "")
			val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			val_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
			val_lbl.add_theme_font_size_override("font_size", 28)
			val_lbl.add_theme_font_override("font", custom_font)
			hbox.add_child(key_lbl)
			hbox.add_child(val_lbl)
			content_container.add_child(hbox)

		"separator":
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(0, 12)
			content_container.add_child(spacer)

		"button_list":
			var btns      : Array  = row.get("buttons", [])
			var columns   : int    = row.get("columns", btns.size())
			var btn_w     : int    = row.get("btn_w",   180)
			var btn_h     : int    = row.get("btn_h",   70)
			var font_size : int    = row.get("font_size", 20)
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
				btn.name                = "GridBtn_" + bid   # lets you find it later
				btn.disabled            = all_off
				btn.add_theme_font_size_override("font_size", font_size)
				_style_grid_button_with_asset(btn, bcol)
				btn.add_theme_color_override("font_color", Color(1, 1, 1))
				btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1))

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
					lbl.add_theme_font_override("font", custom_font)
					lbl.add_theme_font_size_override("font_size", 22)
					lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
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
			var fsize : int = row.get("font_size", 72)

			var timer_lbl = Label.new() 
			timer_lbl.name = "TimerDisplay" 
			timer_lbl.text                = initial
			timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			timer_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			timer_lbl.add_theme_font_override("font", custom_font)
			timer_lbl.add_theme_font_size_override("font_size", fsize)
			timer_lbl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
			content_container.add_child(timer_lbl)
			
		"coin_display":
			var coin_size : int = row.get("size", 160)
			var r         : float = coin_size / 2.0

			var wrapper := CenterContainer.new()
			wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			wrapper.custom_minimum_size   = Vector2(0, coin_size + 24)
			content_container.add_child(wrapper)

			# Use a custom draw Control so we can draw a true circle
			var coin := Control.new()
			coin.name                = "CoinFace"
			coin.custom_minimum_size = Vector2(coin_size, coin_size)
			coin.set_meta("coin_color", Color(0.94, 0.78, 0.22))
			coin.set_meta("coin_radius", r)

			# Draw circle via _draw
			# Instead of scaling the node (which clips), we draw an ellipse
			# by scaling x-radius only — gives the spinning perspective effect
			coin.draw.connect(func():
				var col    : Color = coin.get_meta("coin_color")
				var rx     : float = coin.get_meta("coin_radius") * coin.get_meta("coin_spin_x", 1.0)
				var ry     : float = coin.get_meta("coin_radius")
				var center : Vector2 = Vector2(r, r)
				# Draw ellipse as polyline fill
				var pts    : PackedVector2Array = PackedVector2Array()
				var steps  : int = 48
				for s in range(steps + 1):
					var a : float = s * TAU / steps
					pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
				# Outer ring
				coin.draw_colored_polygon(pts, col.darkened(0.25))
				# Shrink for inner face
				var pts2 : PackedVector2Array = PackedVector2Array()
				for s in range(steps + 1):
					var a : float = s * TAU / steps
					pts2.append(center + Vector2(cos(a) * rx * 0.88, sin(a) * ry * 0.88))
				coin.draw_colored_polygon(pts2, col)
				# Shine
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
			hbox.name                   = "ProgressIconRow"
			hbox.alignment              = BoxContainer.ALIGNMENT_CENTER
			hbox.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
			hbox.add_theme_constant_override("separation", 20)
			content_container.add_child(hbox)

			for i in range(count):
				var slot := Control.new()
				slot.name                = "ProgSlot_%d" % i
				slot.custom_minimum_size = Vector2(icon_size, icon_size)

				var bg := ColorRect.new()
				bg.name     = "SlotBG"
				bg.color    = Color(0.78, 0.78, 0.78, 0.4)
				bg.size     = Vector2(icon_size, icon_size)
				slot.add_child(bg)

				var lbl := Label.new()
				lbl.name                 = "SlotLabel"
				lbl.size                 = Vector2(icon_size, icon_size)
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
				lbl.add_theme_font_size_override("font_size", int(icon_size * 0.5))
				lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
				var path : String = "res://assets/ui/Red/Double/star_outline.png"
				if path != "" and ResourceLoader.exists(path): 
					_set_slot_texture(slot, path, icon_size)

				slot.set_meta("check_path", check_path)
				slot.set_meta("cross_path", cross_path)
				slot.set_meta("icon_size",  icon_size)
				hbox.add_child(slot)


func _load_checkbox_tex(checked: bool) -> Texture2D:
	var path : String
	if checked:
		path = ASSET_PATH + "Green/Double/check_square_color.png"
	else:
		path = ASSET_PATH + "Grey/Double/check_square_color.png"

	if ResourceLoader.exists(path):
		return load(path)

	var img := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.7, 0.3) if checked else Color(0.6, 0.6, 0.6))
	for x in range(40):
		for y in range(40):
			if x == 0 or x == 39 or y == 0 or y == 39:
				img.set_pixel(x, y, Color(0.2, 0.2, 0.2))
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
		_style_grid_button_with_asset(btn, color)
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1))

func set_all_grid_buttons_disabled(disabled: bool) -> void:
	for child in find_children("GridBtn_*", "Button", true, false):
		(child as Button).disabled = disabled

# ── BUTTONS ───────────────────────────────────────────────────────────────────
func _add_button(config: PopupConfig, btn_data: Dictionary) -> void:
	var btn := Button.new()
	btn.text = btn_data.get("label", "OK")
	btn.custom_minimum_size = Vector2(220, 70)

	var color : String = btn_data.get("color", "grey")
	_style_button(config, btn, color)

	var id : String = btn_data.get("id", "ok")
	var should_close : bool = btn_data.get("shouldClose", true)
	btn.set_meta("shouldClose", should_close)
	# If this button has requires_all_checked = true, disable it until all boxes ticked
	if btn_data.get("requires_all_checked", false):
		btn.disabled = true
		# Connect checkbox_changed to re-evaluate
		checkbox_changed.connect(func(_idx, _val):
			btn.disabled = not all_checked()
			_style_button_enabled(btn, color, not btn.disabled)
		)

	btn.pressed.connect(func():
		button_pressed.emit(id)
		if btn.get_meta("shouldClose", true):
			queue_free()

	)	
	button_bar.add_child(btn)

func _style_button(config: PopupConfig, btn: Button, color: String) -> void:
	var tex_path := ASSET_PATH + _capitalize(color) + "/Double/button_rectangle_depth_flat.png"
	if ResourceLoader.exists(tex_path):
		var state_files := {
			"normal":  "Double/button_rectangle_depth_flat.png",
			"hover":   "Double/button_rectangle_depth_gloss.png",
			"pressed": "Double/button_rectangle_flat.png",
		}
		for state in state_files:
			var path : String = ASSET_PATH + _capitalize(color) + "/" + state_files[state]
			if ResourceLoader.exists(path):
				var style := StyleBoxTexture.new()
				style.texture = load(path)
				style.texture_margin_left   = config.popup_margin_left
				style.texture_margin_right  = config.popup_margin_right
				style.texture_margin_top    = config.popup_margin_top
				style.texture_margin_bottom = config.popup_margin_bottom
				btn.add_theme_stylebox_override(state, style)
				btn.add_theme_font_override("font", custom_font)
		btn.add_theme_font_size_override("font_size", 26)
	else:
		_style_button_enabled(btn, color, true)

	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_font_size_override("font_size", 22)

func _style_grid_button_with_asset(btn: Button, color: String) -> void:
	var cap      : String = _capitalize(color)
	var tex_path : String = ASSET_PATH + cap + "/Double/button_rectangle_depth_flat.png"
	print(btn.size)
	if ResourceLoader.exists(tex_path):
		var state_files := {
			"normal":  ASSET_PATH + cap + "/Double/button_rectangle_depth_flat.png",
			"hover":   ASSET_PATH + cap + "/Double/button_rectangle_depth_gloss.png",
			"pressed": ASSET_PATH + cap + "/Double/button_rectangle_flat.png",
			"disabled":ASSET_PATH + cap + "/Double/button_rectangle_depth_flat.png",
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
		btn.add_theme_font_override("font", custom_font)
		btn.add_theme_font_size_override("font_size", 22)
	else:
		_style_button_enabled(btn, color, true)

func _style_button_enabled(btn: Button, color: String, enabled: bool) -> void:
	var colors := {
		"green":  Color(0.18, 0.62, 0.37),
		"red":    Color(0.75, 0.22, 0.22),
		"blue":   Color(0.22, 0.45, 0.75),
		"grey":   Color(0.55, 0.55, 0.55),
		"yellow": Color(0.8,  0.65, 0.1),
	}
	var c : Color = colors.get(color, Color(0.55, 0.55, 0.55))
	var display_c : Color = c if enabled else Color(0.45, 0.45, 0.45)

	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		match state:
			"normal":   style.bg_color = display_c
			"hover":    style.bg_color = display_c.lightened(0.2)
			"pressed":  style.bg_color = display_c.darkened(0.2)
			"disabled": style.bg_color = c
		style.set_corner_radius_all(6)
		style.content_margin_left   = 16
		style.content_margin_right  = 16
		style.content_margin_top    = 10
		style.content_margin_bottom = 10
		btn.add_theme_stylebox_override(state, style)

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

func set_bottom_button_should_close(idx: int, value: bool) -> void:
	var children := button_bar.get_children()
	if idx < children.size():
		(children[idx] as Button).set_meta("shouldClose", value)

func set_bottom_button_color(idx: int, color: String) -> void:
	var children := button_bar.get_children()
	if idx < children.size():
		var btn := children[idx] as Button
		_style_grid_button_with_asset(btn, color)
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

	var bg  : ColorRect = slot.get_node_or_null("SlotBG")  as ColorRect
	var lbl : Label     = slot.get_node_or_null("SlotLabel") as Label
	var icon_size : int = int(slot.get_meta("icon_size", 72))

	match state:
		"pass":
			var path : String = slot.get_meta("check_path", "")
			if path != "" and ResourceLoader.exists(path):
				_set_slot_texture(slot, path, icon_size)
			else:
				if bg:  bg.color  = Color(0.18, 0.65, 0.35)
				if lbl: lbl.text  = "✓"
				if lbl: lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		"fail":
			var path : String = slot.get_meta("cross_path", "")
			if path != "" and ResourceLoader.exists(path):
				_set_slot_texture(slot, path, icon_size)
			else:
				if bg:  bg.color  = Color(0.75, 0.18, 0.18)
				if lbl: lbl.text  = "✗"
				if lbl: lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		_: 
			var path : String = "res://assets/ui/Red/Double/star_outline.png"
			if path != "" and ResourceLoader.exists(path): 
				_set_slot_texture(slot, path, icon_size)
			else: 
				if bg:  bg.color  = Color(0.78, 0.78, 0.78, 0.4)
				if lbl: lbl.text  = "?"
				if lbl: lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

func _set_slot_texture(slot: Control, path: String, icon_size: int) -> void:
	# Remove old texture if any
	var old := slot.get_node_or_null("SlotTex")
	if old: old.queue_free()
	var tex_rect           := TextureRect.new()
	tex_rect.name          = "SlotTex"
	tex_rect.texture       = load(path)
	tex_rect.size          = Vector2(icon_size, icon_size)
	tex_rect.expand_mode   = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex_rect.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(tex_rect)
	# Hide bg/label when texture is shown
	var bg  := slot.get_node_or_null("SlotBG")   as ColorRect
	var lbl := slot.get_node_or_null("SlotLabel") as Label
	if bg:  bg.visible  = false
	if lbl: lbl.visible = false
