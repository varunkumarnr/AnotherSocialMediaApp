extends SequenceGame
class_name MusicSequenceGame

const NOTE_SFX := {
	"sa"  : AudioManager.SFX.note_sa,
	"re"  : AudioManager.SFX.note_re,
	"ga"  : AudioManager.SFX.note_ga,
	"ma"  : AudioManager.SFX.note_ma,
	"pa"  : AudioManager.SFX.note_pa,
	"dha" : AudioManager.SFX.note_dha,
	"ni"  : AudioManager.SFX.note_ni,
	"sa2" : AudioManager.SFX.note_sa2, 
}

# ── ITEMS — 8 notes with distinct colours ────────────────────────────────────
const NOTE_ITEMS := [
	{id = "sa",  label = "Sa",  color = Color(0.90, 0.20, 0.20)},   # red
	{id = "re",  label = "Re",  color = Color(0.95, 0.55, 0.10)},   # orange
	{id = "ga",  label = "Ga",  color = Color(0.95, 0.88, 0.10)},   # yellow
	{id = "ma",  label = "Ma",  color = Color(0.15, 0.75, 0.30)},   # green
	{id = "pa",  label = "Pa",  color = Color(0.10, 0.72, 0.65)},   # teal
	{id = "dha", label = "Dha", color = Color(0.18, 0.45, 0.90)},   # blue
	{id = "ni",  label = "Ni",  color = Color(0.58, 0.20, 0.85)},   # purple
	{id = "sa2", label = "Sa2", color = Color(0.92, 0.30, 0.65)},   # pink  (upper Sa)
]

func get_items() -> Array:
	return NOTE_ITEMS

func get_columns() -> int:
	return 4   

func get_button_size() -> int:
	var vp_w : float = get_viewport().get_visible_rect().size.x
	var avail : float = min(vp_w, 700.0) - 80.0 - 30.0
	return int(avail / 4.0)

func get_display_height() -> int:
	return 140

func get_item_color(id: String) -> Color:
	for item in NOTE_ITEMS:
		if item["id"] == id:
			return item["color"]
	return Color(0.5, 0.5, 0.5)

func get_item_label(id: String) -> String:
	for item in NOTE_ITEMS:
		if item["id"] == id:
			return item["label"]
	return id

# ── PLAY NOTE ─────────────────────────────────────────────────────────────────
func _play_note(id: String) -> void:
	if NOTE_SFX.has(id):
		AudioManager.play_sfx(NOTE_SFX[id])

# ── on_sequence_shown: nothing extra needed — notes play during flash ─────────
func on_sequence_shown() -> void:
	pass

func _on_input(bid: String) -> void:
	_play_note(bid)
	super._on_input(bid)

func _run_game() -> void:
	await get_tree().create_timer(0.8).timeout

	while not is_game_over:
		round_num += 1

		var items := get_items()
		sequence.clear()
		for _i in range(round_num):
			sequence.append(items[rng.randi() % items.size()]["id"])

		popup.title_label.text = "Round %d of %d — Listen!" % [round_num, MAX_ROUNDS]
		popup.set_all_input_cells_disabled(true)
		popup.set_big_display(Color(0.08, 0.08, 0.08), "♪", 0, sequence.size())

		await get_tree().create_timer(0.4).timeout

		# Show + play each note
		for i in range(sequence.size()):
			var sid : String = sequence[i]
			var col : Color  = get_item_color(sid)
			var lbl : String = get_item_label(sid)

			_play_note(sid)
			popup.set_big_display(col, lbl, i + 1, sequence.size())
			popup.flash_input_cell(sid, col.lightened(0.3), SHOW_SPEED * 0.85)
			await get_tree().create_timer(SHOW_SPEED).timeout
			if is_game_over: return

			popup.set_big_display(Color(0.08, 0.08, 0.08), "", i + 1, sequence.size())
			await get_tree().create_timer(SHOW_GAP + 0.08).timeout
			if is_game_over: return

		# Player's turn
		popup.title_label.text = "Your turn! Play %d notes" % sequence.size()
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
			popup.title_label.text = "Perfect melody! All %d rounds done!" % MAX_ROUNDS
			await get_tree().create_timer(0.8).timeout
			win_game()
			return

		popup.title_label.text = "✓ Correct! Get ready for round %d…" % (round_num + 1)
		await get_tree().create_timer(1.0).timeout