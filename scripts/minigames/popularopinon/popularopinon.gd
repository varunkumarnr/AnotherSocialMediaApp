extends MiniGamesTemplate
class_name PopularOpinionGame

# ── DATA ──────────────────────────────────────────────────────────────────────
const QUESTIONS_JSON := "res://assets/data/agree_with_internet.json"

var QUESTIONS : Array = []

func _load_questions() -> void:
	var file := FileAccess.open(QUESTIONS_JSON, FileAccess.READ)
	if file == null:
		push_error("PopularOpinionGame: could not open %s" % QUESTIONS_JSON)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Array:
		QUESTIONS = parsed
	else:
		push_error("PopularOpinionGame: JSON root must be an Array")

const QUESTIONS_PER_GAME := 5

# ── STATE ─────────────────────────────────────────────────────────────────────
var popup           : GamePopup
var question_queue  : Array  = []   # shuffled subset of 3
var current_q_idx   : int    = 0
var answered        : bool   = false
var rng             := RandomNumberGenerator.new()

# ── ENTRY ─────────────────────────────────────────────────────────────────────
func on_game_started() -> void:
	rng.randomize()
	play_game_music()
	add_child(TCBackground.new())
	_load_questions()
	_pick_questions()
	_build_popup()

# ── PICK 3 RANDOM QUESTIONS ───────────────────────────────────────────────────
func _pick_questions() -> void:
	var pool := QUESTIONS.duplicate()
	pool.shuffle()
	question_queue = pool.slice(0, QUESTIONS_PER_GAME)

# ── BUILD POPUP ───────────────────────────────────────────────────────────────
func _build_popup() -> void:
	var q    = question_queue[0]
	var config               := PopupConfig.new()
	config.title             = "Question 1"
	config.panel_color       = "blue"
	config.show_close_button = false

	config.content_rows      = [
		{type = "separator"},
		{type = "text", value = q["question"]},
		# {type = "text", value = "Think like the internet — pick the majority answer."},
	]
	config.buttons = [
		{id = "choice_0", label = q["choices"][0], shouldClose = false ,color = "blue"},
		{id = "choice_1", label = q["choices"][1], shouldClose = false , color = "blue"},
	]

	popup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)
	popup.button_pressed.connect(_on_choice)

# ── ANSWER HANDLER ────────────────────────────────────────────────────────────
func _on_choice(bid: String) -> void:
	if answered or is_game_over:
		return
	answered = true

	popup.set_bottom_button_disabled(0, true)
	popup.set_bottom_button_disabled(1, true)

	var q          = question_queue[current_q_idx]
	var choice_idx : int  = int(bid.replace("choice_", ""))
	var pct_chosen : int  = int(q["percentage"][choice_idx])
	var pct_other  : int  = int(q["percentage"][1 - choice_idx])
	var majority   : bool = pct_chosen >= pct_other
	

	# Show result colours on buttons
	popup.set_bottom_button_color(choice_idx,     "green" if majority else "red")
	popup.set_bottom_button_color(1 - choice_idx, "grey")
	popup.set_bottom_button_label(choice_idx, str(pct_chosen)+"%")
	popup.set_bottom_button_label_color(choice_idx, Color.BLACK)
	popup.set_bottom_button_label_font_size(choice_idx, 36)
	
	# Show result in popup
	var result_text : String
	if majority:
		result_text = "%d%% agree" % pct_chosen 
		AudioManager.play_sfx(AudioManager.SFX.CORRECT)
	else:
		result_text = "Only %d%% picked." % pct_chosen
		AudioManager.play_sfx(AudioManager.SFX.WRONG, 0.03)
		fail_game()

		# AudioManager.play_sfx(AudioManager.SFX.WRONG)

	await get_tree().create_timer(2.4).timeout

	# popup.title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	popup.title_label.add_theme_font_size_override("font_size", 32)
	popup.title_label.text = result_text

	
	if is_game_over:
		return

	current_q_idx += 1

	if current_q_idx >= QUESTIONS_PER_GAME:
		# All 3 answered — win regardless (it's opinion, not right/wrong)
		win_game()
		return

	_load_next_question()

func _load_next_question() -> void:
	answered = false
	var q = question_queue[current_q_idx]

	popup.title_label.add_theme_font_size_override("font_size", 36)
	popup.title_label.text = "Question"

	var cc : VBoxContainer = popup.get_node(
		"Control/CenterContainer/Panel/VBoxContainer/ContentMargin/ContentContainer"
	)
	var q_label : Label = cc.get_child(1) as Label
	if q_label:
		q_label.text = q["question"]

	popup.set_bottom_button_label(0, q["choices"][0])
	popup.set_bottom_button_label(1, q["choices"][1])
	popup.set_bottom_button_color(0, "blue")
	popup.set_bottom_button_color(1, "blue")
	popup.set_bottom_button_disabled(0, false)
	popup.set_bottom_button_disabled(1, false)
