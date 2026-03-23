extends MiniGamesTemplate
class_name SequenceGame

var MAX_ROUNDS    := 5 
const SHOW_SPEED    := 0.6 
const SHOW_GAP      := 0 
const INPUT_TIMEOUT := 4.0  

var popup           : GamePopup
var sequence        : Array  = []   
var input_pos       : int    = 0    
var accepting_input : bool   = false
var round_num       : int    = 0

signal input_received(id: String)

var rng := RandomNumberGenerator.new()

func on_game_started() -> void:
	rng.randomize()
	play_game_music()
	await _build_popup()
	add_child(TCBackground.new())
	_run_game()
	MAX_ROUNDS = get_max_rounds()

func _build_popup() -> void:
	var vp     : Vector2 = get_viewport().get_visible_rect().size
	var pw : float = vp.x - 60.0
	var ph : float = vp.y - 160.0  

	var config               := PopupConfig.new()
	config.title             = "Round 1 — Watch!"
	config.panel_color       = "blue"
	config.show_close_button = false
	config.popup_width       = 700
	config.popup_height      = 1200
	config.content_rows      = [
		{type = "big_display",   height = get_display_height()},
		{type = "separator"},
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

func _run_game() -> void:
	await get_tree().create_timer(0.8).timeout

	while not is_game_over:
		round_num += 1

		var items := get_items()
		sequence.clear()
		for _i in range(round_num):
			sequence.append(items[rng.randi() % items.size()]["id"])

		popup.title_label.text = "Round %d of %d — Watch!" % [round_num, MAX_ROUNDS]
		popup.set_all_input_cells_disabled(true)
		popup.set_big_display(Color(0.08, 0.08, 0.08), "...", 0, sequence.size())

		for i in range(sequence.size()):
			var sid   : String = sequence[i]
			var col   : Color  = get_item_color(sid)
			var lbl   : String = get_item_label(sid)
			popup.set_big_display(col, lbl, i + 1, sequence.size())
			popup.flash_input_cell(sid, col.lightened(0.3), SHOW_SPEED * 0.8)
			await get_tree().create_timer(SHOW_SPEED).timeout
			if is_game_over: return
			popup.set_big_display(Color(0.08, 0.08, 0.08), "", i + 1, sequence.size())
			await get_tree().create_timer(SHOW_GAP).timeout
			if is_game_over: return

		await on_sequence_shown()

		popup.title_label.text = "Your turn! %d steps" % sequence.size()
		popup.set_big_display(Color(0.08, 0.08, 0.08), "?", 0, sequence.size())
		popup.set_all_input_cells_disabled(false)
		accepting_input = true
		input_pos       = 0

		var result : String = await _wait_for_round_complete()
		accepting_input = false
		popup.set_all_input_cells_disabled(true)

		if result == "fail":
			return

		if round_num >= MAX_ROUNDS:
			popup.title_label.text = "Perfect! You completed all %d rounds!" % MAX_ROUNDS
			await get_tree().create_timer(0.8).timeout
			win_game()
			return

		popup.title_label.text = "✓ Correct! Get ready for round %d…" % (round_num + 1)
		await get_tree().create_timer(1.0).timeout

signal _round_done(result: String)

func _wait_for_round_complete() -> String:
	return await _round_done

func _on_input(bid: String) -> void:
	if not accepting_input or is_game_over:
		return

	var expected : String = sequence[input_pos]
	var col      : Color  = get_item_color(bid)

	if bid == expected:
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
		accepting_input = false
		popup.flash_input_cell(bid, Color(1, 0.1, 0.1), 0.4)
		popup.set_big_display(Color(0.85, 0.15, 0.15), "END", input_pos + 1, sequence.size())
		AudioManager.play_sfx(AudioManager.SFX.WRONG)
		popup.title_label.text = "✗ Wrong! Expected %s" % expected.to_upper()
		await get_tree().create_timer(0.8).timeout
		fail_game("Wrong sequence at step %d!" % (input_pos + 1))
		_round_done.emit("fail")

func get_display_height() -> int:
	return 160

func get_items() -> Array:
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
	pass   

func get_max_rounds() -> int:
	return 5