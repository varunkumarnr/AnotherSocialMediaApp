extends MiniGamesTemplate
class_name ShuffleGame

# ── CONFIG ────────────────────────────────────────────────────────────────────
const GRID_COLS       := 3
const GRID_ROWS       := 4
const BUTTON_COUNT    := GRID_COLS * GRID_ROWS  
const REVEAL_DURATION := 2.0
const GREY_TRANSITION := 0.6   
var SHUFFLE_COUNT   := 5
const SWAP_DURATION   := 0.35
const SWAP_PAUSE      := 0.08

# ── STATE ─────────────────────────────────────────────────────────────────────
enum Phase { REVEAL, TRANSITION, SHUFFLE, GUESS, DONE }

var phase            : Phase  = Phase.REVEAL
var agree_index      : int    = 0
var slot_positions   : Array  = []
var btn_nodes        : Array  = []
var original_buttons : Array  = []
var popup            : GamePopup
var status_label     : Label

var rng = RandomNumberGenerator.new()

func random_box_count() -> void: 
	rng.randomize()
	SHUFFLE_COUNT = rng.randi_range(3,8) 

# ── ENTRY POINT ───────────────────────────────────────────────────────────────
func on_game_started() -> void:
	play_game_music()
	add_child(TCBackground.new())
	await _build_popup()
	_run_sequence()


# ── BUILD POPUP ───────────────────────────────────────────────────────────────
func _build_popup() -> void:
	agree_index = randi() % BUTTON_COUNT

	var btn_list : Array = []
	for i in range(BUTTON_COUNT):
		btn_list.append({id = "slot_%d" % i, label = "???", color = "grey"})

	var config               := PopupConfig.new()
	config.title             = "Find the AGREE button"
	config.panel_color       = "blue"
	config.show_close_button = false
	config.popup_height = 500
	config.content_rows      = [
		{
			type      = "button_list",
			buttons   = btn_list,
			columns   = GRID_COLS,
			btn_w     = 180,
			btn_h     = 80,
			font_size = 22,
			disabled  = true,
		},
	]
	config.buttons = []

	popup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)
	popup.grid_button_pressed.connect(_on_grid_button_pressed)

	await get_tree().process_frame
	await get_tree().process_frame

	for i in range(BUTTON_COUNT):
		var btn := popup.get_grid_button("slot_%d" % i)
		btn_nodes.append(btn)
		slot_positions.append(btn.global_position)

	original_buttons = btn_nodes.duplicate()

# ── SEQUENCE ──────────────────────────────────────────────────────────────────
func _run_sequence() -> void:
	# Step 1: Show green/red so player learns which is AGREE
	phase = Phase.REVEAL
	popup.title_label.text = "Remember which one is AGREE!"
	_set_colours(true)
	popup.set_all_grid_buttons_disabled(true)

	await get_tree().create_timer(REVEAL_DURATION).timeout

	# Step 2: Go grey — brief pause so player sees the transition
	phase = Phase.TRANSITION
	popup.title_label.text = "Watch carefully..."
	_set_colours(false)

	await get_tree().create_timer(GREY_TRANSITION).timeout

	# Step 3: Animate shuffles
	phase = Phase.SHUFFLE
	await _animate_shuffles()

	# Step 4: Let player guess
	phase = Phase.GUESS
	popup.title_label.text = "Which one is AGREE?"
	popup.set_all_grid_buttons_disabled(false)

# ── COLOUR HELPERS ────────────────────────────────────────────────────────────
func _set_colours(revealed: bool) -> void:
	for logical in range(BUTTON_COUNT):
		var is_agree : bool = (logical == agree_index)
		var orig_id  : String = "slot_%d" % _logical_to_original(logical)
		if revealed:
			btn_nodes[logical].text = "AGREE" if is_agree else "DISAGREE"
			popup.set_grid_button_color(orig_id, "green" if is_agree else "red")
		else:
			btn_nodes[logical].text = "???"
			popup.set_grid_button_color(orig_id, "grey")

# ── SHUFFLE ANIMATION ────────────────────────────────────────────────────────
const SIMULTANEOUS_SWAPS := 2   

func _animate_shuffles() -> void:
	for _round in range(SHUFFLE_COUNT):
		# Build a set of non-overlapping pairs so buttons don't fight each other
		var used    : Array = []
		var pairs   : Array = []

		for _attempt in range(SIMULTANEOUS_SWAPS):
			var a : int = randi() % BUTTON_COUNT
			var b : int = randi() % BUTTON_COUNT
			var tries := 0
			# Make sure neither slot is already in this round's swap
			while (a == b or a in used or b in used) and tries < 20:
				a = randi() % BUTTON_COUNT
				b = randi() % BUTTON_COUNT
				tries += 1
			if a != b and not (a in used) and not (b in used):
				pairs.append([a, b])
				used.append(a)
				used.append(b)

		# Fire all swaps simultaneously, await all tweens together
		var tweens : Array = []
		for pair in pairs:
			tweens.append(_start_swap_tween(pair[0], pair[1]))
		
		AudioManager.play_sfx(AudioManager.SFX.FLAPPY_GUY_FLAP)		

		# Wait for the longest tween (they're all same duration)
		if tweens.size() > 0:
			await tweens[0].finished

		# Commit logical order after all tweens done
		for pair in pairs:
			_commit_swap(pair[0], pair[1])

		await get_tree().create_timer(SWAP_PAUSE).timeout

func _start_swap_tween(slot_a: int, slot_b: int) -> Tween:
	var btn_a : Button  = btn_nodes[slot_a]
	var btn_b : Button  = btn_nodes[slot_b]
	var pos_a : Vector2 = btn_a.global_position
	var pos_b : Vector2 = btn_b.global_position

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(btn_a, "global_position", pos_b, SWAP_DURATION).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(btn_b, "global_position", pos_a, SWAP_DURATION).set_trans(Tween.TRANS_CUBIC)
	return tween

func _commit_swap(slot_a: int, slot_b: int) -> void:
	var tmp : Button = btn_nodes[slot_a]
	btn_nodes[slot_a] = btn_nodes[slot_b]
	btn_nodes[slot_b] = tmp

	if agree_index == slot_a:     agree_index = slot_b
	elif agree_index == slot_b:   agree_index = slot_a

# ── GUESS ─────────────────────────────────────────────────────────────────────
func _on_grid_button_pressed(bid: String) -> void:
	if phase != Phase.GUESS or is_game_over:
		return
	phase = Phase.DONE
	popup.set_all_grid_buttons_disabled(true)

	var original_idx : int = int(bid.replace("slot_", ""))
	var logical      : int = _original_to_logical(original_idx)

	_set_colours(true)
	await get_tree().create_timer(0.5).timeout

	if logical == agree_index:
		win_game()
		AudioManager.play_sfx(AudioManager.SFX.CORRECT)
	else:
		fail_game("You lost track of the Agree button!")
		AudioManager.play_sfx(AudioManager.SFX.WRONG)

# ── INDEX HELPERS ─────────────────────────────────────────────────────────────
func _original_to_logical(original_idx: int) -> int:
	var target : Button = original_buttons[original_idx]
	for i in range(btn_nodes.size()):
		if btn_nodes[i] == target:
			return i
	return original_idx

func _logical_to_original(logical: int) -> int:
	var target : Button = btn_nodes[logical]
	for i in range(original_buttons.size()):
		if original_buttons[i] == target:
			return i
	return logical