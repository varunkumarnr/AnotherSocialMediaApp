extends MiniGamesTemplate
class_name  checkBox

# ── CONFIG ────────────────────────────────────────────────────────────────────
const ROW_SPEED_SLOW := 140.0
const ROW_SPEED_SLOW_2: float = 500.0
const ROW_SPEED_FAST := 600.0
const ROW_SPEED_FAST_2 := 800
const CB_SIZE        := 48.0

# ── STATE ─────────────────────────────────────────────────────────────────────
var checked_state : Array[bool] = []

# Each moving row: {cb: TextureButton, direction, speed, min_x, max_x}
var moving_rows : Array = []

var popup        : GamePopup
var agree_btn    : Button
var ui_canvas    : CanvasLayer

# ── ENTRY POINT ───────────────────────────────────────────────────────────────
func on_game_started() -> void:
	play_game_music()
	add_child(TCBackground.new()) 
	for i in range(9):
		checked_state.append(false)
	_build_popup()

# ── BUILD THE SINGLE POPUP ────────────────────────────────────────────────────
func _build_popup() -> void:
	ui_canvas = CanvasLayer.new()
	ui_canvas.layer = 2
	add_child(ui_canvas)

	# Config: checkbox_list for row 1, placeholder text rows for rows 2-5
	# (we'll inject the moving checkboxes manually after configure())
	# Size the popup to fill most of the viewport width
	var vp2 : Vector2 = get_viewport().get_visible_rect().size
	var popup_w : float = clamp(vp2.x - 80.0, 400.0, 900.0)

	var config               := PopupConfig.new()
	config.title             = "Fill Checkboxes"
	config.panel_color       = "blue"
	config.popup_height = 750
	config.show_close_button = false
	config.popup_margin_top = 0
	config.content_rows      = [
		# Row 1: 5 static checkboxes side by side
		{type = "text", value = "You have to know how to press checkboxs"},
		{type = "checkbox_list", items = ["", "", "", "", ""], index_offset = 0, columns = 5},
	]
	config.buttons = [
		{id = "agree", label = "Agree to All", color = "grey", requires_all_checked = true},
	]

	popup = POPUP_SCENE.instantiate()
	ui_canvas.add_child(popup)

	# Strip dark overlay — we want the popup visible but not blocking
	popup.get_node("Control/Overlay").visible = false

	# Apply dynamic width to panel BEFORE configure so layout is correct from start
	await get_tree().process_frame
	var pre_panel : Panel = popup.get_node("Control/CenterContainer/Panel")
	pre_panel.custom_minimum_size = Vector2(popup_w, 100)

	# Keep centered (don't strip the CenterContainer anchors)
	popup.configure(config)

	# Connect the agree button
	popup.button_pressed.connect(func(id: String):
		AudioManager.play_sfx(AudioManager.SFX.CORRECT)
		if id == "agree":
			win_game()
	)

	# Connect static checkbox signals (indices 0-4)
	popup.checkbox_changed.connect(func(index: int, val: bool):
		AudioManager.play_sfx(AudioManager.SFX.CLICK)
		checked_state[index] = val
		_refresh_agree()
	)

	await get_tree().process_frame
	await get_tree().process_frame

	# ── Inject moving checkboxes into the text rows ───────────────────────────
	# The content_container children are:
	#  0 = GridContainer (row1 checkboxes)
	#  1 = spacer (separator)
	#  2 = Label "Allow background..."   ← replace with moving CB row
	#  3 = Label "Enable crash..."
	#  4 = Label "Share analytics..."
	#  5 = Label "Opt in..."
	var cc : VBoxContainer = popup.get_node(
		"Control/CenterContainer/Panel/VBoxContainer/ContentMargin/ContentContainer"
	)

	var moving_configs := [
		{idx=5, speed=ROW_SPEED_SLOW, dir=+1.0},
		{idx=6, speed=ROW_SPEED_SLOW_2, dir=-1.0},
		{idx=7, speed=ROW_SPEED_FAST, dir=+1.0},
		{idx=8, speed=ROW_SPEED_FAST_2, dir=-1.0},
	]

	# Replace the 4 placeholder labels (children 2,3,4,5) with moving CB rows
	for i in range(4):
		var child_idx : int = 2 + i   # offset past grid + separator
		var cfg = moving_configs[i]

		# Remove the placeholder label
		var old_label : Node = cc.get_child(child_idx)
		if old_label: 
			old_label.queue_free()

		# Build a row: HBox with [moving TextureButton] + [label]
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		# Height = CB size. Width fills popup panel — gives the CB room to travel
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.custom_minimum_size   = Vector2(0, CB_SIZE + 16)

		var cb := TextureButton.new()
		cb.toggle_mode         = true
		cb.button_pressed      = false
		cb.texture_normal      = _load_cb_tex(false)
		cb.texture_pressed     = _load_cb_tex(true)
		cb.texture_hover       = _load_cb_tex(false)
		cb.texture_focused     = _load_cb_tex(false)
		cb.custom_minimum_size = Vector2(CB_SIZE, CB_SIZE)
		cb.stretch_mode        = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		cb.ignore_texture_size = true

		hbox.add_child(cb)
		cc.add_child(hbox)
		cc.move_child(hbox, child_idx)

		var g_idx : int = cfg.idx
		cb.toggled.connect(func(pressed: bool):
			checked_state[g_idx] = pressed
			AudioManager.play_sfx(AudioManager.SFX.CLICK)
			cb.texture_normal = _load_cb_tex(pressed)
			cb.texture_hover  = _load_cb_tex(pressed)
			_refresh_agree()
		)

		# Store for _process movement
		# min/max x are relative to the hbox — cb moves within the hbox width
		moving_rows.append({
			"cb":        cb,
			"hbox":      hbox,
			"index":     g_idx,
			"speed":     cfg.speed,
			"direction": cfg.dir,
		})

	# Cache agree button reference for styling
	var bb : HBoxContainer = popup.get_node(
		"Control/CenterContainer/Panel/VBoxContainer/ButtonMargin/ButtonBar"
	)
	for child in bb.get_children():
		if child is Button:
			agree_btn = child
			break

# ── MOVING CHECKBOXES ─────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not is_game_active or is_game_over:
		return

	for row in moving_rows:
		if checked_state[row["index"]]:
			continue  # freeze once ticked

		var cb   : TextureButton  = row["cb"]
		var hbox : HBoxContainer  = row["hbox"]

		# Travel range = full hbox width minus the checkbox size
		var hbox_w : float = hbox.size.x
		var max_x  : float = maxf(0.0, hbox_w - CB_SIZE)

		cb.position.x += row["speed"] * row["direction"] * delta

		if cb.position.x <= 0.0:
			cb.position.x  = 0.0
			row["direction"] = +1.0
		elif cb.position.x >= max_x:
			cb.position.x  = max_x
			row["direction"] = -1.0

# ── AGREE REFRESH ─────────────────────────────────────────────────────────────
func _refresh_agree() -> void:
	if agree_btn == null:
		return
	var all_done := checked_state.all(func(v): return v == true)
	agree_btn.disabled = not all_done
	# Restyle
	var c : Color = Color(0.18, 0.62, 0.37) if all_done else Color(0.45, 0.45, 0.45)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		match state:
			"normal":   style.bg_color = c
			"hover":    style.bg_color = c.lightened(0.15)
			"pressed":  style.bg_color = c.darkened(0.2)
			"disabled": style.bg_color = Color(0.45, 0.45, 0.45, 0.5)
		style.set_corner_radius_all(8)
		style.content_margin_left   = 16
		style.content_margin_right  = 16
		style.content_margin_top    = 10
		style.content_margin_bottom = 10
		agree_btn.add_theme_stylebox_override(state, style)
	agree_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	agree_btn.add_theme_color_override("font_disabled_color", Color(0.8, 0.8, 0.8, 0.4))
	agree_btn.add_theme_font_size_override("font_size", 24)

# ── TEXTURE HELPER ────────────────────────────────────────────────────────────
func _load_cb_tex(checked: bool) -> Texture2D:
	var path := "res://assets/ui/Green/Double/check_square_color.png" if checked \
			else "res://assets/ui/Grey/Double/check_square_color.png"
	if ResourceLoader.exists(path):
		return load(path)
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.7, 0.3) if checked else Color(0.65, 0.65, 0.65))
	for x in range(48):
		for y in range(48):
			if x < 2 or x > 45 or y < 2 or y > 45:
				img.set_pixel(x, y, Color(0.15, 0.15, 0.15))
	return ImageTexture.create_from_image(img)
