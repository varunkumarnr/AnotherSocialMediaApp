extends MiniGamesTemplate
class_name MathGame

# ── Constants ─────────────────────────────────────────────────────────────────
const QUESTIONS_TO_WIN  := 5
const TIME_ADDITION     := 7.0
const TIME_SUBTRACTION  := 7.0
const TIME_MULTIPLY     := 9.0

const C_BG       := Color(0.039, 0.047, 0.063, 1)
const C_BG2      := Color(0.059, 0.071, 0.094, 1)
const C_BG3      := Color(0.082, 0.102, 0.133, 1)
const C_BORDER   := Color(0.118, 0.137, 0.176, 1)
const C_TEXT     := Color(0.784, 0.831, 0.910, 1)
const C_CYAN     := Color(0.0,   0.831, 1.0,   1)
const C_GREEN    := Color(0.0,   0.6,   0.25,  1)
const C_RED      := Color(0.9,   0.2,   0.1,   1)
const C_AMBER    := Color(0.6,   0.5,   0.0,   1)
const C_MUTED    := Color(0.29,  0.353, 0.439, 1)

var current_question_index : int    = 0
var current_answer         : int    = 0
var current_input          : String = ""
var time_rem         : float  = 0.0
var timer_active           : bool   = false
var game_over_flag         : bool   = false

var op_a      : int    = 0
var op_b      : int    = 0
var operator  : String = "+"

var rng := RandomNumberGenerator.new()

# ── UI refs ───────────────────────────────────────────────────────────────────
var popup          : GamePopup
var timer_bar      : ColorRect
var time_lab    : Label
var question_label : Label
var answer_dashes  : Label
var feedback_label : Label
var progress_label : Label
var key_buttons    : Dictionary = {}

# ── Entry point ───────────────────────────────────────────────────────────────
func on_game_started() -> void:
	rng.randomize()
	play_game_music()
	await _build_ui()
	add_child(TCBackground.new())
	_next_question()

# ── UI Construction ───────────────────────────────────────────────────────────
func _build_ui() -> void:
	var config               := PopupConfig.new()
	config.title             = "Math Challenge — Solve 5 to Win!"
	config.panel_color       = "blue"
	config.show_close_button = false
	config.popup_width       = 440
	config.popup_height      = 0
	config.content_rows      = [{type = "separator"}]
	config.buttons           = []

	popup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)

	await get_tree().process_frame
	await get_tree().process_frame

	var cc : VBoxContainer = popup.get_node(
		"Control/CenterContainer/Panel/VBoxContainer/ContentMargin/ContentContainer"
	)

	_build_timer_section(cc)
	_build_question_section(cc)
	_build_answer_section(cc)
	_build_keyboard(cc)
	_build_progress(cc)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	cc.add_child(sp)

# ── Timer Section ─────────────────────────────────────────────────────────────
func _build_timer_section(cc: VBoxContainer) -> void:
	# Time remaining label
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(center)

	time_lab = Label.new()
	time_lab.text                 = "5.0s"
	time_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_lab.add_theme_font_size_override("font_size", 52)
	time_lab.add_theme_color_override("font_color", C_CYAN)
	center.add_child(time_lab)

	# Timer bar background
	var bar_bg := ColorRect.new()
	bar_bg.color              = C_BG3
	bar_bg.custom_minimum_size = Vector2(0, 10)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(bar_bg)

	# Timer bar fill — child of bar_bg container
	var bar_wrapper := Control.new()
	bar_wrapper.custom_minimum_size = Vector2(0, 10)
	bar_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(bar_wrapper)

	timer_bar = ColorRect.new()
	timer_bar.color    = C_CYAN
	timer_bar.size     = Vector2(400, 10)
	timer_bar.position = Vector2(0, 0)
	bar_wrapper.add_child(timer_bar)
	# Store wrapper for width reference
	timer_bar.set_meta("wrapper", bar_wrapper)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	cc.add_child(spacer)

# ── Question Section ──────────────────────────────────────────────────────────
func _build_question_section(cc: VBoxContainer) -> void:
	var sep := ColorRect.new()
	sep.color = C_BORDER
	sep.custom_minimum_size = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(sep)

	var sp1 := Control.new()
	sp1.custom_minimum_size = Vector2(0, 12)
	cc.add_child(sp1)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(center)

	question_label = Label.new()
	question_label.text                 = "? + ? = ?"
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.add_theme_font_size_override("font_size", 64)
	question_label.add_theme_color_override("font_color", C_TEXT)
	center.add_child(question_label)

	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 12)
	cc.add_child(sp2)

# ── Answer Section ────────────────────────────────────────────────────────────
func _build_answer_section(cc: VBoxContainer) -> void:
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	center.add_child(vbox)

	# Answer input display
	var answer_panel := StyleBoxFlat.new()
	answer_panel.bg_color = C_BG3
	answer_panel.set_border_width_all(2)
	answer_panel.border_color = C_BORDER
	answer_panel.set_corner_radius_all(6)

	answer_dashes = Label.new()
	answer_dashes.text                  = "___"
	answer_dashes.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	answer_dashes.add_theme_font_size_override("font_size", 56)
	answer_dashes.add_theme_color_override("font_color", C_CYAN)
	answer_dashes.custom_minimum_size   = Vector2(180, 80)
	vbox.add_child(answer_dashes)

	# Feedback label (correct / wrong / too slow)
	feedback_label = Label.new()
	feedback_label.text                 = ""
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 28)
	feedback_label.add_theme_color_override("font_color", C_GREEN)
	feedback_label.custom_minimum_size  = Vector2(0, 36)
	vbox.add_child(feedback_label)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 6)
	cc.add_child(sp)

# ── Number Keyboard ───────────────────────────────────────────────────────────
const KB_ROWS := [
	["7", "8", "9"],
	["4", "5", "6"],
	["1", "2", "3"],
	["⌫", "0", "↵"],
]

func _build_keyboard(cc: VBoxContainer) -> void:
	var sep := ColorRect.new()
	sep.color = C_BORDER
	sep.custom_minimum_size = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(sep)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	cc.add_child(sp)

	for kb_row in KB_ROWS:
		var hbox := HBoxContainer.new()
		hbox.alignment             = BoxContainer.ALIGNMENT_CENTER
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_theme_constant_override("separation", 8)
		cc.add_child(hbox)

		for key in kb_row:
			var btn       := Button.new()
			var is_action  : bool = (key == "⌫" or key == "↵")
			btn.custom_minimum_size = Vector2(100, 80)
			btn.text                = key
			btn.add_theme_font_size_override("font_size", 36)
			_style_key(btn, key)
			btn.pressed.connect(_on_key.bind(key))
			hbox.add_child(btn)
			key_buttons[key] = btn

		var row_sp := Control.new()
		row_sp.custom_minimum_size = Vector2(0, 4)
		cc.add_child(row_sp)

func _style_key(btn: Button, key: String) -> void:
	var is_enter  : bool = (key == "↵")
	var is_delete : bool = (key == "⌫")
	var base_color : Color
	if is_enter:
		base_color = Color(0.0, 0.45, 0.2, 1)
	elif is_delete:
		base_color = Color(0.35, 0.1, 0.1, 1)
	else:
		base_color = C_BG3

	for s in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		match s:
			"normal":  sb.bg_color = base_color
			"hover":   sb.bg_color = base_color.lightened(0.18)
			"pressed": sb.bg_color = base_color.darkened(0.2)
			_:         sb.bg_color = base_color.darkened(0.3)
		sb.set_corner_radius_all(6)
		sb.set_border_width_all(1)
		sb.border_color = base_color.lightened(0.2)
		btn.add_theme_stylebox_override(s, sb)
	btn.add_theme_color_override("font_color", C_TEXT)

# ── Progress ──────────────────────────────────────────────────────────────────
func _build_progress(cc: VBoxContainer) -> void:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 6)
	cc.add_child(sp)

	var sep := ColorRect.new()
	sep.color = C_BORDER
	sep.custom_minimum_size = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(sep)

	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 6)
	cc.add_child(sp2)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(center)

	progress_label = Label.new()
	progress_label.text                 = "Question 1 / %d" % QUESTIONS_TO_WIN
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 26)
	progress_label.add_theme_color_override("font_color", C_MUTED)
	center.add_child(progress_label)

# ── Question Generation ───────────────────────────────────────────────────────
func _next_question() -> void:
	if game_over_flag or is_game_over:
		return

	current_input = ""
	feedback_label.text = ""
	answer_dashes.text  = "___"

	# Pick random operation
	var ops := ["+", "-", "×"]
	operator = ops[rng.randi() % ops.size()]

	match operator:
		"+":
			op_a = rng.randi_range(1, 50)
			op_b = rng.randi_range(1, 50)
			current_answer = op_a + op_b
			time_rem = TIME_ADDITION
		"-":
			op_a = rng.randi_range(10, 60)
			op_b = rng.randi_range(1, op_a)   # ensure non-negative result
			current_answer = op_a - op_b
			time_rem = TIME_SUBTRACTION
		"×":
			op_a = rng.randi_range(2, 12)
			op_b = rng.randi_range(2, 12)
			current_answer = op_a * op_b
			time_rem = TIME_MULTIPLY

	question_label.text  = "%d  %s  %d  =  ?" % [op_a, operator, op_b]
	progress_label.text  = "Question %d / %d" % [current_question_index + 1, QUESTIONS_TO_WIN]
	time_lab.text     = "%.1fs" % time_rem
	time_lab.add_theme_color_override("font_color", C_CYAN)

	_update_timer_bar(1.0)
	timer_active = true

# ── Input Handling ────────────────────────────────────────────────────────────
func _on_key(key: String) -> void:
	if game_over_flag or is_game_over or not timer_active:
		return

	if key == "⌫":
		if current_input.length() > 0:
			current_input = current_input.left(current_input.length() - 1)
			_refresh_answer_display()
	elif key == "↵":
		_submit_answer()
	else:
		if current_input.length() < 4:   # max 4 digits
			current_input += key
			_refresh_answer_display()

func _refresh_answer_display() -> void:
	if current_input == "":
		answer_dashes.text = "___"
	else:
		answer_dashes.text = current_input

# ── Submit ────────────────────────────────────────────────────────────────────
func _submit_answer() -> void:
	if current_input == "":
		_shake_answer()
		return

	timer_active = false
	var guessed : int = int(current_input)

	if guessed == current_answer:
		_on_correct()
	else:
		_on_wrong("✗  Ans: %d" % current_answer)

func _on_correct() -> void:
	feedback_label.add_theme_color_override("font_color", C_GREEN)
	feedback_label.text = "Correct!"
	answer_dashes.add_theme_color_override("font_color", C_GREEN)
	current_question_index += 1

	if current_question_index >= QUESTIONS_TO_WIN:
		game_over_flag = true
		popup.title_label.text = "All correct — You Win!"
		await get_tree().create_timer(1.0).timeout
		win_game()
	else:
		await get_tree().create_timer(0.9).timeout
		answer_dashes.add_theme_color_override("font_color", C_CYAN)
		_next_question()

func _on_wrong(msg: String = "") -> void:
	feedback_label.add_theme_color_override("font_color", C_RED)
	feedback_label.text = msg if msg != "" else "✗  Wrong!"
	answer_dashes.add_theme_color_override("font_color", C_RED)
	_shake_answer()

	await get_tree().create_timer(1.2).timeout
	answer_dashes.add_theme_color_override("font_color", C_CYAN)
	game_over_flag = true
	popup.title_label.text = "Game Over — The answer was %d" % current_answer
	await get_tree().create_timer(0.8).timeout
	fail_game("The answer was %d" % current_answer)

func _shake_answer() -> void:
	var orig := answer_dashes.position
	var tw   := create_tween()
	tw.tween_property(answer_dashes, "position:x", orig.x + 8,  0.05)
	tw.tween_property(answer_dashes, "position:x", orig.x - 8,  0.05)
	tw.tween_property(answer_dashes, "position:x", orig.x + 5,  0.04)
	tw.tween_property(answer_dashes, "position:x", orig.x,      0.04)

func _update_timer_bar(fraction: float) -> void:
	var wrapper : Control = timer_bar.get_meta("wrapper") as Control
	var full_w  : float   = wrapper.size.x if wrapper.size.x > 0 else 400.0
	timer_bar.size.x      = full_w * clampf(fraction, 0.0, 1.0)
	if fraction > 0.5:
		timer_bar.color = C_CYAN.lerp(C_AMBER, (1.0 - fraction) * 2.0)
	else:
		timer_bar.color = C_AMBER.lerp(C_RED, (0.5 - fraction) * 2.0)

func _process(delta: float) -> void:
	if not timer_active or game_over_flag or is_game_over:
		return

	time_rem -= delta
	if time_rem <= 0.0:
		time_rem = 0.0
		timer_active   = false
		time_lab.text = "0.0s"
		time_lab.add_theme_color_override("font_color", C_RED)
		_update_timer_bar(0.0)
		_on_wrong("⏱  Too slow!  Ans: %d" % current_answer)
		return

	var max_time : float
	match operator:
		"×": max_time = TIME_MULTIPLY
		_:   max_time = TIME_ADDITION

	time_lab.text = "%.1fs" % time_rem
	var fraction : float = time_rem / max_time
	# Colour the label too
	if fraction > 0.5:
		time_lab.add_theme_color_override("font_color", C_CYAN)
	elif fraction > 0.25:
		time_lab.add_theme_color_override("font_color", C_AMBER)
	else:
		time_lab.add_theme_color_override("font_color", C_RED)
	_update_timer_bar(fraction)