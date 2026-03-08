extends MiniGamesTemplate
class_name SimonSaysGame

const ACTIONS := ["up", "down", "jump", "sit"]

const IMG := {
	"up":   "res://assets/minigames/sprites/simonsays/player_up.png",
	"down": "res://assets/minigames/sprites/simonsays/player_down.png",
	"jump": "res://assets/minigames/sprites/simonsays/player_jump.png",
	"sit":  "res://assets/minigames/sprites/simonsays/player_sit.png",
}

const WINDOW_START  := 2.5
const WINDOW_END    := 1.8
const GAME_DURATION := 10.0

# Emitted by _process when window expires, or by _on_action_pressed immediately
signal round_done(outcome: String)  # "timeout" | "correct" | "wrong" | "fake_press"

var popup          : GamePopup
var game_running   : bool   = false
var waiting_input  : bool   = false
var is_simon       : bool   = false
var current_action : String = ""
var elapsed        : float  = 0.0
var window_elapsed : float  = 0.0
var window_limit   : float  = 0.0

var rng := RandomNumberGenerator.new()

# ── ENTRY ─────────────────────────────────────────────────────────────────────
func on_game_started() -> void:
	rng.randomize()
	play_game_music()
	add_child(TCBackground.new())
	await _build_popup()
	game_running = true
	_run_loop()

# ── POPUP ─────────────────────────────────────────────────────────────────────
func _build_popup() -> void:
	var cells : Array = []
	for action in ACTIONS:
		cells.append({id = action, label = action.to_upper(), image = IMG[action], color = "grey"})

	var config               := PopupConfig.new()
	config.title             = "Simon Says!"
	config.panel_color       = "blue"
	config.show_close_button = false
	config.content_rows      = [
		{type = "text", value = "Only press when SIMON SAYS so!"},
		{type = "image_grid", cells = cells, columns = 2, cell_size = 140},
	]
	config.buttons = []

	popup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)
	popup.grid_button_pressed.connect(_on_action_pressed)
	await get_tree().process_frame
	await get_tree().process_frame

# ── MAIN LOOP — never awaits a timer, only awaits round_done signal ───────────
func _run_loop() -> void:
	popup.title_label.text = "Get ready..."
	popup.set_all_image_cells_disabled(true)
	await get_tree().create_timer(2.0).timeout

	while game_running and not is_game_over:
		current_action = ACTIONS[rng.randi() % ACTIONS.size()]
		var simon_chance : float = lerp(0.80, 0.60, elapsed / GAME_DURATION)
		is_simon = rng.randf() < simon_chance


		_play_command(is_simon, current_action)
		popup.set_image_cell_color(current_action, "blue")

		var t : float = clamp(elapsed / GAME_DURATION, 0.0, 1.0)
		window_limit   = lerp(WINDOW_START, WINDOW_END, t)
		window_elapsed = 0.0

		popup.title_label.text = ("SIMON SAYS: %s!" if is_simon else "%s!") % current_action.to_upper()
		popup.set_all_image_cells_disabled(false)
		waiting_input = true

		# Block here — _process fires round_done on timeout, _on_action_pressed fires it on press
		var outcome : String = await round_done

		waiting_input = false
		popup.set_all_image_cells_disabled(true)
		popup.set_image_cell_color(current_action, "grey")

		if not game_running or is_game_over:
			return

		match outcome:
			"timeout":
				if is_simon:
					_fail("Too slow! Simon said %s!" % current_action.to_upper())
					return
				popup.title_label.text = "✓ Good — that wasn't Simon!"
				await get_tree().create_timer(0.4).timeout

			"correct":
				popup.title_label.text = "✓ Correct!"
				await get_tree().create_timer(0.3).timeout

			"wrong", "fake_press":
				return   # _fail already called in _on_action_pressed

		if elapsed >= GAME_DURATION:
			_win()
			return

# ── PROCESS — advances window timer, emits timeout ───────────────────────────
func _process(delta: float) -> void:
	if game_running and not is_game_over:
		elapsed += delta

	if waiting_input:
		window_elapsed += delta
		if window_elapsed >= window_limit:
			waiting_input = false
			round_done.emit("timeout")

func _on_action_pressed(bid: String) -> void:
	print(bid, " " , current_action) 
	if not waiting_input or is_game_over:
		return

	waiting_input = false 
	print(bid, " " , current_action) 
	if not is_simon:
		popup.set_image_cell_color(bid, "red")
		round_done.emit("fake_press")
		await get_tree().create_timer(0.5).timeout
		_fail("Simon didn't say %s!" % bid.to_upper())
		return

	if bid == current_action:
		popup.set_image_cell_color(bid, "green")
		round_done.emit("correct")   
		AudioManager.play_sfx(AudioManager.SFX.CORRECT)
	else:
		popup.set_image_cell_color(bid, "red")
		round_done.emit("wrong")
		await get_tree().create_timer(0.5).timeout
		_fail("Wrong button! Simon said %s!" % current_action.to_upper())

# ── AUDIO ─────────────────────────────────────────────────────────────────────
func _play_command(simon: bool, action: String) -> void:
	if simon:
		match action:
			"up":   AudioManager.play_sfx(AudioManager.SFX.simon_says_up)
			"down": AudioManager.play_sfx(AudioManager.SFX.simon_says_down)
			"jump": AudioManager.play_sfx(AudioManager.SFX.simon_says_jump)
			"sit":  AudioManager.play_sfx(AudioManager.SFX.simon_says_sit)
	else:
		match action:
			"up":   AudioManager.play_sfx(AudioManager.SFX.up)
			"down": AudioManager.play_sfx(AudioManager.SFX.down)
			"jump": AudioManager.play_sfx(AudioManager.SFX.jump)
			"sit":  AudioManager.play_sfx(AudioManager.SFX.sit)

func _win() -> void:
	if is_game_over: return
	game_running = false
	popup.title_label.text = "You survived 60 seconds!"
	await get_tree().create_timer(0.5).timeout
	win_game()

func _fail(reason: String) -> void:
	if is_game_over: return
	game_running = false
	waiting_input = false
	popup.title_label.text = reason
	await get_tree().create_timer(0.8).timeout
	fail_game(reason)
