extends MiniGamesTemplate
class_name WordleGame

const WORDS : Array = [
	"AGREE", "TERMS", "LEGAL", "CLAIM", "LIMIT",
	"GRANT", "WAIVE", "COURT", "PARTY", "BOUND",
	"FORCE", "MAJOR", "SCOPE", "VALID", "PRIOR",
	"RIGHT", "SHARE", "CLASS", "FIRST", "FINAL",
	"TRIAL", "JUDGE", "PROOF", "CLAIM", "RULES",
	"WRITE", "FLOOR", "PLANE", "SHOUT", "BLINK",
	"CRANE", "GLARE", "FLUTE", "BRAVE", "CHESS",
	"DELTA", "EMBER", "FROWN", "GHOST", "HONEY",
]

const MAX_GUESSES  := 6
const WORD_LENGTH  := 5

const C_BG       := Color(0.039, 0.047, 0.063, 1)
const C_BG2      := Color(0.059, 0.071, 0.094, 1)
const C_BG3      := Color(0.082, 0.102, 0.133, 1)
const C_BORDER   := Color(0.118, 0.137, 0.176, 1)
const C_TEXT     := Color(0.784, 0.831, 0.910, 1)
const C_CORRECT  := Color(0.0,   0.6,   0.25,  1)  
const C_PRESENT  := Color(0.6,   0.5,   0.0,   1)  
const C_ABSENT   := Color(0.15,  0.18,  0.22,  1)  
const C_EMPTY    := Color(0.059, 0.071, 0.094, 1)  
const C_ACTIVE   := Color(0.118, 0.137, 0.176, 1)   

var target_word   : String = ""
var current_row   : int    = 0
var current_col   : int    = 0
var current_guess : String = ""
var game_over_flag: bool   = false

var key_states    : Dictionary = {}

var popup         : GamePopup
var tile_labels   : Array = []   # tile_labels[row][col] = Label
var tile_bgs      : Array = []   # tile_bgs[row][col]    = ColorRect
var key_buttons   : Dictionary = {}   

var rng := RandomNumberGenerator.new()

func on_game_started() -> void:
	rng.randomize()
	target_word = WORDS[rng.randi() % WORDS.size()].to_upper()
	play_game_music()
	await _build_ui()

func _build_ui() -> void:
	var config               := PopupConfig.new()
	config.title             = "Agree to the Terms — Guess the Word"
	config.panel_color       = "blue"
	config.show_close_button = false
	config.popup_width       = 420
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

	_build_grid(cc)
	_build_keyboard(cc)

	# Spacer at bottom
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	cc.add_child(sp)

# ── TILE GRID ─────────────────────────────────────────────────────────────────
func _build_grid(cc: VBoxContainer) -> void:
	var TILE   : float = 92.0
	var GAP    : float = 6.0

	var grid_w : float = WORD_LENGTH * TILE + (WORD_LENGTH - 1) * GAP

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(GAP))
	center.add_child(vbox)

	for row in range(MAX_GUESSES):
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", int(GAP))
		vbox.add_child(hbox)

		var row_bgs   : Array = []
		var row_lbls  : Array = []

		for col in range(WORD_LENGTH):
			var cell := Control.new()
			cell.custom_minimum_size = Vector2(TILE, TILE)

			var bg := ColorRect.new()
			bg.color    = C_EMPTY
			bg.size     = Vector2(TILE, TILE)
			cell.add_child(bg)

			# Border overlay
			var border := Control.new()
			border.size = Vector2(TILE, TILE)
			border.draw.connect(func():
				var bc : Color = C_ACTIVE if row == current_row and not game_over_flag \
								 else C_BORDER
				border.draw_rect(Rect2(0, 0, TILE, TILE), bc, false, 1.5)
			)
			cell.add_child(border)

			var lbl := Label.new()
			lbl.size                 = Vector2(TILE, TILE)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 40)
			lbl.add_theme_color_override("font_color", C_TEXT)
			lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
			lbl.text = ""
			cell.add_child(lbl)

			hbox.add_child(cell)
			row_bgs.append(bg)
			row_lbls.append(lbl)

		tile_bgs.append(row_bgs)
		tile_labels.append(row_lbls)

# ── KEYBOARD ──────────────────────────────────────────────────────────────────
const KB_ROWS := [
	["Q","W","E","R","T","Y","U","I","O","P"],
	["A","S","D","F","G","H","J","K","L"],
	["⌫", "Z","X","C","V","B","N","M", "↵"],
]

func _build_keyboard(cc: VBoxContainer) -> void:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 10)
	cc.add_child(sp)

	for kb_row in KB_ROWS:
		var hbox := HBoxContainer.new()
		hbox.alignment             = BoxContainer.ALIGNMENT_CENTER
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_theme_constant_override("separation", 5)
		cc.add_child(hbox)

		for key in kb_row:
			var btn := Button.new()
			var is_wide : bool = (key == "⌫" or key == "↵")
			btn.custom_minimum_size = Vector2(72 if is_wide else 72, 72)
			btn.text                = key
			btn.add_theme_font_size_override("font_size", 32)
			_style_key(btn, "")
			btn.pressed.connect(_on_key.bind(key))
			hbox.add_child(btn)
			if key != "⌫" and key != "↵":
				key_buttons[key] = btn

		var row_sp := Control.new()
		row_sp.custom_minimum_size = Vector2(0, 4)
		cc.add_child(row_sp)

func _style_key(btn: Button, state: String) -> void:
	var c : Color
	match state:
		"correct": c = C_CORRECT
		"present": c = C_PRESENT
		"absent":  c = C_ABSENT
		_:         c = C_BG3

	for s in ["normal","hover","pressed","disabled"]:
		var sb := StyleBoxFlat.new()
		match s:
			"normal":  sb.bg_color = c
			"hover":   sb.bg_color = c.lightened(0.15)
			"pressed": sb.bg_color = c.darkened(0.2)
			_:         sb.bg_color = c
		sb.set_corner_radius_all(4)
		sb.set_border_width_all(1)
		sb.border_color = c.lightened(0.2) if state != "" else C_BORDER
		btn.add_theme_stylebox_override(s, sb)
	btn.add_theme_color_override("font_color", C_TEXT)

# ── INPUT ─────────────────────────────────────────────────────────────────────
func _on_key(key: String) -> void:
	if game_over_flag or is_game_over: return

	if key == "⌫":
		if current_guess.length() > 0:
			current_guess = current_guess.left(current_guess.length() - 1)
			current_col = current_guess.length()
			tile_labels[current_row][current_col].text = ""
			tile_bgs[current_row][current_col].color   = C_EMPTY
	elif key == "↵":
		_submit_guess()
	else:
		if current_guess.length() < WORD_LENGTH:
			tile_labels[current_row][current_col].text = key
			tile_bgs[current_row][current_col].color   = C_ACTIVE
			current_guess += key
			current_col    = current_guess.length()
			# Redraw borders
			_redraw_borders()

func _redraw_borders() -> void:
	for row in range(MAX_GUESSES):
		for col in range(WORD_LENGTH):
			# border is child index 1 of each cell
			var cell = tile_bgs[row][col].get_parent()
			if cell.get_child_count() > 1:
				cell.get_child(1).queue_redraw()

# ── SUBMIT GUESS ──────────────────────────────────────────────────────────────
func _submit_guess() -> void:
	if current_guess.length() < WORD_LENGTH:
		_shake_row(current_row)
		return

	var guess  : String = current_guess
	var result : Array  = _evaluate(guess)

	# Colour tiles
	for col in range(WORD_LENGTH):
		var state : String = result[col]
		var c     : Color
		match state:
			"correct": c = C_CORRECT
			"present": c = C_PRESENT
			_:         c = C_ABSENT
		tile_bgs[current_row][col].color = c

		# Update key colour — only upgrade (absent → present → correct)
		var letter : String = guess[col]
		var old    : String = key_states.get(letter, "")
		if old != "correct":
			if state == "correct" or old == "":
				key_states[letter] = state
			elif state == "present" and old != "correct":
				key_states[letter] = state
		if key_buttons.has(letter):
			_style_key(key_buttons[letter], key_states[letter])

	_redraw_borders()

	if guess == target_word:
		game_over_flag = true
		popup.title_label.text = "✓ Correct! — %s" % target_word
		await get_tree().create_timer(1.0).timeout
		win_game()
		return

	current_row   += 1
	current_col    = 0
	current_guess  = ""

	if current_row >= MAX_GUESSES:
		game_over_flag = true
		popup.title_label.text = "The word was: %s" % target_word
		await get_tree().create_timer(1.2).timeout
		fail_game("The word was: %s" % target_word)

# ── EVALUATE GUESS ────────────────────────────────────────────────────────────
func _evaluate(guess: String) -> Array:
	var result   : Array  = ["absent", "absent", "absent", "absent", "absent"]
	var remaining: Array  = []

	# First pass — correct positions
	for i in range(WORD_LENGTH):
		if guess[i] == target_word[i]:
			result[i] = "correct"
		else:
			remaining.append(target_word[i])

	# Second pass — present (wrong position)
	for i in range(WORD_LENGTH):
		if result[i] == "correct": continue
		var idx : int = remaining.find(guess[i])
		if idx != -1:
			result[i] = "present"
			remaining.remove_at(idx)

	return result

func _shake_row(row: int) -> void:
	for col in range(WORD_LENGTH):
		var cell = tile_bgs[row][col].get_parent()
		var orig = cell.position
		var tw   = create_tween()
		tw.tween_property(cell, "position:x", orig.x + 6, 0.05)
		tw.tween_property(cell, "position:x", orig.x - 6, 0.05)
		tw.tween_property(cell, "position:x", orig.x + 4, 0.04)
		tw.tween_property(cell, "position:x", orig.x,     0.04)