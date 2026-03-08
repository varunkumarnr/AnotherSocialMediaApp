extends "res://scripts/core/miniGamesTemplate.gd"
class_name SequenceGame

const MAX_ROUNDS    := 5   # sequence grows from 1 to this
const SHOW_SPEED    := 1 # seconds per item when showing
const SHOW_GAP      := 0.1 # gap between items
const INPUT_TIMEOUT := 4.0  # seconds player has per item to input (resets each press)

var popup           : GamePopup
var sequence        : Array  = []   # full sequence built up over rounds
var input_pos       : int    = 0    # how far through the sequence the player is
var accepting_input : bool   = false
var round_num       : int    = 0

signal input_received(id: String)

var rng := RandomNumberGenerator.new()

# ── ENTRY ─────────────────────────────────────────────────────────────────────
func on_game_started() -> void:
	rng.randomize()
	play_game_music()
	add_child(TCBackground.new())
	await _build_popup()
	_run_game()

# ── BUILD POPUP ───────────────────────────────────────────────────────────────
func _build_popup() -> void:
	var vp     : Vector2 = get_viewport().get_visible_rect().size
	# Popup fills almost the full content area
	var pw : float = vp.x - 60.0
	var ph : float = vp.y - 160.0   # leave room for top bar

	var config               := PopupConfig.new()
	config.title             = "Round 1 — Watch!"
	config.panel_color       = "blue"
	config.show_close_button = false
	config.popup_width       = 700
	config.popup_height      = 1200
	config.content_rows      = [
		# Big single-color display screen
		{type = "big_display",   height = get_display_height()},
		{type = "separator"},
		# 3x3 grid of square buttons
		{
			type     = "input_grid",
			items    = get_items(),
			columns  = get_columns(),
			btn_size = get_button_size(),
		},
	]
	config.buttons = []

	popup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)
	popup.set_all_input_cells_disabled(true)
	popup.grid_button_pressed.connect(_on_input)

	await get_tree().process_frame
	await get_tree().process_frame

# ── GAME LOOP ─────────────────────────────────────────────────────────────────
func _run_game() -> void:
	await get_tree().create_timer(0.8).timeout

	while not is_game_over:
		round_num += 1

		# Build a completely fresh random sequence of length round_num
		var items := get_items()
		sequence.clear()
		for _i in range(round_num):
			sequence.append(items[rng.randi() % items.size()]["id"])

		popup.title_label.text = "Round %d of %d — Watch!" % [round_num, MAX_ROUNDS]
		popup.set_all_input_cells_disabled(true)
		popup.set_big_display(Color(0.08, 0.08, 0.08), "...", 0, sequence.size())

		# Show the sequence — flash each color on the big display
		for i in range(sequence.size()):
			var sid   : String = sequence[i]
			var col   : Color  = get_item_color(sid)
			var lbl   : String = get_item_label(sid)
			# Flash big display
			popup.set_big_display(col, lbl, i + 1, sequence.size())
			# Also flash the corresponding input button
			popup.flash_input_cell(sid, col.lightened(0.3), SHOW_SPEED * 0.8)
			await get_tree().create_timer(SHOW_SPEED).timeout
			if is_game_over: return
			# Brief dark gap between items
			popup.set_big_display(Color(0.08, 0.08, 0.08), "", i + 1, sequence.size())
			await get_tree().create_timer(SHOW_GAP).timeout
			if is_game_over: return

		await on_sequence_shown()

		# Open input
		popup.title_label.text = "Your turn! %d steps" % sequence.size()
		popup.set_big_display(Color(0.08, 0.08, 0.08), "?", 0, sequence.size())
		popup.set_all_input_cells_disabled(false)
		accepting_input = true
		input_pos       = 0

		# Wait for player to complete or fail — driven by _on_input via signal
		var result : String = await _wait_for_round_complete()
		accepting_input = false
		popup.set_all_input_cells_disabled(true)

		if result == "fail":
			return

		# Round complete
		if round_num >= MAX_ROUNDS:
			popup.title_label.text = "Perfect! You completed all %d rounds!" % MAX_ROUNDS
			await get_tree().create_timer(0.8).timeout
			win_game()
			return

		popup.title_label.text = "✓ Correct! Get ready for round %d…" % (round_num + 1)
		await get_tree().create_timer(1.0).timeout

# ── WAIT FOR ROUND ────────────────────────────────────────────────────────────
signal _round_done(result: String)

func _wait_for_round_complete() -> String:
	return await _round_done

# ── INPUT HANDLER ─────────────────────────────────────────────────────────────
func _on_input(bid: String) -> void:
	if not accepting_input or is_game_over:
		return

	var expected : String = sequence[input_pos]
	var col      : Color  = get_item_color(bid)

	if bid == expected:
		# Correct
		popup.flash_input_cell(bid, col.lightened(0.4), 0.15)
		popup.set_big_display(col, get_item_label(bid), input_pos + 1, sequence.size())
		AudioManager.play_sfx(AudioManager.SFX.CLICK)
		input_pos += 1

		if input_pos >= sequence.size():
			accepting_input = false
			popup.set_big_display(Color(0.15, 0.65, 0.35), "Next", sequence.size(), sequence.size())
			await get_tree().create_timer(0.4).timeout
			_round_done.emit("ok")
	else:
		# Wrong
		accepting_input = false
		popup.flash_input_cell(bid, Color(1, 0.1, 0.1), 0.4)
		popup.set_big_display(Color(0.85, 0.15, 0.15), "END", input_pos + 1, sequence.size())
		AudioManager.play_sfx(AudioManager.SFX.WRONG)
		popup.title_label.text = "✗ Wrong! Expected %s" % expected.to_upper()
		await get_tree().create_timer(0.8).timeout
		fail_game("Wrong sequence at step %d!" % (input_pos + 1))
		_round_done.emit("fail")

# ── OVERRIDABLE INTERFACE ─────────────────────────────────────────────────────
# Subclasses MUST override get_items() and get_item_color()
# Everything else is optional.

func get_display_height() -> int:
	return 160

func get_items() -> Array:
	# Return array of {id, label, color (Color)} dicts
	return []

func get_columns() -> int:
	return 3

func get_button_size() -> int:
	return 110

func get_item_color(_id: String) -> Color:
	return Color(0.5, 0.5, 0.5)

func get_item_label(_id: String) -> String:
	return ""

func on_sequence_shown() -> void:
	pass   # subclass can await audio here