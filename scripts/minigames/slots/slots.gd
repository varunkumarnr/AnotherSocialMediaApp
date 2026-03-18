extends MiniGamesTemplate
class_name SlotGame

const SYMBOLS : Array = [
	"res://assets/minigames/sprites/slots/yellow_star.png",
	"res://assets/minigames/sprites/slots/triangle_blue.png",
	"res://assets/minigames/sprites/slots/star_blue.png",
	"res://assets/minigames/sprites/slots/rect_blue.png",
	"res://assets/minigames/sprites/slots/pent_blue.png",
	"res://assets/minigames/sprites/slots/octa_blue.png",
	"res://assets/minigames/sprites/slots/ninja_blue.png",
	"res://assets/minigames/sprites/slots/heart_blue.png",
	"res://assets/minigames/sprites/slots/dia_blue.png",
	"res://assets/minigames/sprites/slots/diamond_blue.png",
]
const PLACEHOLDERS := ["★","♥","♦","♣","♠","●","■","▲","✕","☽"]

const TARGET_IDX   := 0
const SYMBOL_SIZE  := 100.0
const VISIBLE_ROWS := 4
const COL_COUNT    := 3
const SEQ_LEN      := 10
const BASE_SPEED   := 250.0
const SPEED_BUMP   := 50.0

var popup        : GamePopup
var attempts     : int          = 0
var stopped      : Array[bool]  = [false, false, false]
var reel_offsets : Array[float] = [0.0, 0.0, 0.0]
var reel_speeds  : Array[float] = [BASE_SPEED, BASE_SPEED, BASE_SPEED]
var reel_seqs    : Array        = []
var spinning     : bool         = false

var reel_slots   : Array = []
var reel_clips   : Array = []   # plain Control nodes used for clipping
var stop_buttons : Array = []
var result_label : Label

var _textures    : Array = []
var _use_tex     : bool  = false

var rng := RandomNumberGenerator.new()

func on_game_started() -> void:
	rng.randomize()
	play_game_music()
	add_child(TCBackground.new())
	_preload_textures()
	await _build_ui()
	_start_spin()

func _preload_textures() -> void:
	_textures.clear()
	_use_tex = true
	for path in SYMBOLS:
		if ResourceLoader.exists(path):
			_textures.append(load(path))
		else:
			_textures.append(null)
			_use_tex = false

func _build_ui() -> void:
	var config               := PopupConfig.new()
	config.title             = "Stop on the ★ Star!"
	config.panel_color       = "yellow"
	config.show_close_button = false
	config.popup_width       = 600
	config.popup_height      = 850
	config.content_rows      = [
		{type = "separator"},
		{type = "text", value = "Press STOP to freeze each reel on ★"},
		{type = "separator"},
	]
	config.buttons = []

	popup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)

	await get_tree().process_frame
	await get_tree().process_frame

	var cc : VBoxContainer = popup.get_node(
		"Control/CenterContainer/Panel/VBoxContainer/ContentMargin/ContentContainer"
	)

	var window_h : float = SYMBOL_SIZE * VISIBLE_ROWS

	var reel_hbox := HBoxContainer.new()
	reel_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reel_hbox.size_flags_vertical   = Control.SIZE_SHRINK_BEGIN
	reel_hbox.custom_minimum_size   = Vector2(0, window_h)
	reel_hbox.add_theme_constant_override("separation", 4)
	cc.add_child(reel_hbox)

	for col in range(COL_COUNT):
		var win := Control.new()
		win.custom_minimum_size   = Vector2(SYMBOL_SIZE, window_h)
		win.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		win.size_flags_vertical   = Control.SIZE_SHRINK_BEGIN
		win.clip_contents         = true

		# White background via ColorRect — not Panel stylebox
		var bg := ColorRect.new()
		bg.color        = Color(1, 1, 1, 0.3)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter      = Control.MOUSE_FILTER_IGNORE
		win.add_child(bg)

		# Middle highlight
		var mid_hl := ColorRect.new()
		mid_hl.color        = Color(1.0, 0.92, 0.1, 0.3)
		mid_hl.size         = Vector2(9999, SYMBOL_SIZE)
		mid_hl.position     = Vector2(0, SYMBOL_SIZE)
		mid_hl.z_index      = 8
		mid_hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		win.add_child(mid_hl)

		# Border lines
		for line_y in [SYMBOL_SIZE, SYMBOL_SIZE * 2]:
			var line := ColorRect.new()
			line.color        = Color(0.8, 0.6, 0.0)
			line.size         = Vector2(9999, 2)
			line.position     = Vector2(0, line_y)
			line.z_index      = 9
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			win.add_child(line)

		reel_hbox.add_child(win)
		reel_clips.append(win)

	await get_tree().process_frame
	await get_tree().process_frame

	for col in range(COL_COUNT):
		var slots : Array = []
		for s in range(VISIBLE_ROWS + 2):
			var slot_dict := _build_slot_node(reel_clips[col])
			slot_dict["root"].position = Vector2(0, s * SYMBOL_SIZE)
			slots.append(slot_dict)
		reel_slots.append(slots)

	# Stop buttons
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	cc.add_child(gap)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hbox.size_flags_vertical   = Control.SIZE_SHRINK_BEGIN
	btn_hbox.add_theme_constant_override("separation", 6)
	cc.add_child(btn_hbox)

	for col in range(COL_COUNT):
		var btn := Button.new()
		btn.text                  = "STOP"
		btn.custom_minimum_size   = Vector2(0, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_stop_btn(btn, false)
		btn.pressed.connect(_on_stop.bind(col))
		btn_hbox.add_child(btn)
		stop_buttons.append(btn)

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 4)
	cc.add_child(gap2)

	result_label = Label.new()
	result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_label.size_flags_vertical   = Control.SIZE_SHRINK_BEGIN
	result_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 20)
	result_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	result_label.text = ""
	cc.add_child(result_label)

func _build_slot_node(parent: Control) -> Dictionary:
	var root := Control.new()
	root.custom_minimum_size = Vector2(SYMBOL_SIZE, SYMBOL_SIZE)
	root.size                = Vector2(SYMBOL_SIZE, SYMBOL_SIZE)

	var tr := TextureRect.new()
	tr.size         = Vector2(SYMBOL_SIZE - 10, SYMBOL_SIZE - 10)
	tr.position     = Vector2(5, 5)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.visible      = _use_tex
	root.add_child(tr)

	var lbl := Label.new()
	lbl.size                 = Vector2(SYMBOL_SIZE, SYMBOL_SIZE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", int(SYMBOL_SIZE * 0.45))
	lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	lbl.visible              = not _use_tex
	root.add_child(lbl)

	parent.add_child(root)
	return {"root": root, "tex": tr, "lbl": lbl}

func _set_slot_content(slot_dict: Dictionary, sym_id: int) -> void:
	if _use_tex and _textures[sym_id] != null:
		slot_dict["tex"].texture = _textures[sym_id]
		slot_dict["tex"].visible = true
		slot_dict["lbl"].visible = false
	else:
		slot_dict["lbl"].text    = PLACEHOLDERS[sym_id % PLACEHOLDERS.size()]
		slot_dict["lbl"].visible = true
		slot_dict["tex"].visible = false

func _style_stop_btn(btn: Button, done: bool) -> void:
	var c : Color = Color(0.3, 0.62, 0.3) if done else Color(0.82, 0.22, 0.22)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		match state:
			"normal":   style.bg_color = c
			"hover":    style.bg_color = c.lightened(0.15)
			"pressed":  style.bg_color = c.darkened(0.2)
			"disabled": style.bg_color = Color(0.3, 0.62, 0.3)
		style.set_corner_radius_all(8)
		style.content_margin_top    = 10
		style.content_margin_bottom = 10
		btn.add_theme_stylebox_override(state, style)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_font_size_override("font_size", 22)

func _generate_reels() -> void:
	reel_seqs.clear()
	for _i in range(COL_COUNT):
		var seq : Array = []
		for _j in range(SEQ_LEN):
			seq.append(rng.randi() % SYMBOLS.size())
		if not seq.has(TARGET_IDX):
			seq[rng.randi() % SEQ_LEN] = TARGET_IDX
		reel_seqs.append(seq)

func _start_spin() -> void:
	_generate_reels()
	stopped      = [false, false, false]
	reel_offsets = [0.0, 0.0, 0.0]
	var speed    : float = BASE_SPEED
	reel_speeds  = [speed * 1.2, speed * 1.8, speed * 2.5]

	for i in range(COL_COUNT):
		stop_buttons[i].disabled = false
		stop_buttons[i].text     = "STOP"
		_style_stop_btn(stop_buttons[i], false)

	if result_label: result_label.text = ""
	popup.title_label.text = "Stop on the ★ Star!"
	spinning = true

	for col in range(COL_COUNT):
		_update_reel(col)
	await get_tree().process_frame
	if reel_slots.size() > 0:
		var s0 = reel_slots[0][0]
		var clip0 = reel_clips[0]
		print("=== POSITIONS AFTER LAYOUT ===")
		print("Clip0 global_pos: %s  size: %s  visible: %s" % [clip0.global_position, clip0.size, clip0.visible])
		print("Slot0 global_pos: %s  visible: %s  text: '%s'" % [s0["root"].global_position, s0["root"].visible, s0["lbl"].text])
		print("Popup global_pos: %s" % popup.get_node("Control/CenterContainer/Panel").global_position)
		print("Content container global: %s" % popup.content_container.global_position)

func _on_stop(col: int) -> void:
	if stopped[col] or not spinning or is_game_over:
		return

	var total_h : float = SYMBOL_SIZE * SEQ_LEN
	var snapped : float = round(reel_offsets[col] / SYMBOL_SIZE) * SYMBOL_SIZE
	reel_offsets[col]   = fmod(snapped, total_h)
	stopped[col]        = true
	reel_speeds[col]    = 0.0
	stop_buttons[col].disabled = true
	_update_reel(col)

	var hit : bool = _get_middle_symbol(col) == TARGET_IDX

	if hit:
		stop_buttons[col].text = "✓"
		_style_stop_btn(stop_buttons[col], true)
		AudioManager.play_sfx(AudioManager.SFX.CLICK)
		if stopped.all(func(v): return v):
			spinning = false
			await get_tree().create_timer(0.4).timeout
			_check_result()
	else:
		stop_buttons[col].text = "✗"
		_style_stop_btn(stop_buttons[col], false)
		AudioManager.play_sfx(AudioManager.SFX.WRONG)
		spinning = false
		attempts += 1
		if result_label:
			result_label.text = "Wrong symbol! Attempt %d" % attempts
		popup.title_label.text = "Wrong! Resetting…"
		await get_tree().create_timer(0.8).timeout
		_start_spin()

func _check_result() -> void:
	popup.title_label.text = "★  JACKPOT!  ★"
	if result_label: result_label.text = "All stars — you win!"
	AudioManager.play_sfx(AudioManager.SFX.CORRECT)
	await get_tree().create_timer(1.0).timeout
	win_game()

func _get_middle_symbol(col: int) -> int:
	var seq     : Array = reel_seqs[col]
	var total_h : float = SYMBOL_SIZE * seq.size()
	var norm    : float = fmod(reel_offsets[col], total_h)
	if norm < 0: norm += total_h
	var mid_px  : float = norm + SYMBOL_SIZE
	return seq[int(mid_px / SYMBOL_SIZE) % seq.size()]

func _process(delta: float) -> void:
	if not spinning or is_game_over: return
	for col in range(COL_COUNT):
		if stopped[col]: continue
		var total_h : float = SYMBOL_SIZE * SEQ_LEN
		reel_offsets[col]   = fmod(reel_offsets[col] + reel_speeds[col] * delta, total_h)
		_update_reel(col)

func _update_reel(col: int) -> void:
	var seq      : Array = reel_seqs[col]
	var total_h  : float = SYMBOL_SIZE * seq.size()
	var offset   : float = fmod(reel_offsets[col], total_h)
	if offset < 0: offset += total_h

	var start_sym : int   = int(offset / SYMBOL_SIZE) % seq.size()
	var frac      : float = fmod(offset, SYMBOL_SIZE)
	var slots     : Array = reel_slots[col]

	for s in range(slots.size()):
		var sym_idx : int   = (start_sym + s) % seq.size()
		var y_pos   : float = s * SYMBOL_SIZE - frac
		slots[s]["root"].position = Vector2(0, y_pos)
		_set_slot_content(slots[s], seq[sym_idx])