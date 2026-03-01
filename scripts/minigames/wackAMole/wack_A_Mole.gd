extends MiniGamesTemplate
class_name WhackGame

# ── CONFIG ────────────────────────────────────────────────────────────────────
const GRID_COLS     := 3
const GRID_ROWS     := 4
const BUTTON_COUNT  := GRID_COLS * GRID_ROWS  # 12

const SHOW_DURATION := 0.8  # how long agree/disagree buttons stay lit
const HIDE_DURATION := 0.1   # grey pause between rounds
const ROUNDS_TO_WIN := 8     

var rng := RandomNumberGenerator.new()

# ── STATE ─────────────────────────────────────────────────────────────────────
var popup          : GamePopup
var btn_nodes      : Array = []
var agrees_clicked : int   = 0
var round_active   : bool  = false
var game_running   : bool  = false

# ── ENTRY POINT ───────────────────────────────────────────────────────────────
func on_game_started() -> void:
	rng.randomize()
	play_game_music()
	add_child(TCBackground.new())
	await _build_popup()
	game_running = true
	_run_loop()

# ── BUILD POPUP ───────────────────────────────────────────────────────────────
func _build_popup() -> void:
	var btn_list : Array = []
	for i in range(BUTTON_COUNT):
		btn_list.append({id = "slot_%d" % i, label = "", color = "grey"})

	var config               := PopupConfig.new()
	config.title             = "Click AGREE — %d to go!" % ROUNDS_TO_WIN
	config.panel_color       = "blue"
	config.show_close_button = false
	config.content_rows      = [
		{type = "separator"},
		{
			type      = "button_list",
			buttons   = btn_list,
			columns   = GRID_COLS,
			btn_w     = 180,
			btn_h     = 80,
			font_size = 22,
			disabled  = true,
		},
		{type = "separator"},
	]
	config.buttons = []

	popup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)
	popup.grid_button_pressed.connect(_on_button_pressed)

	await get_tree().process_frame
	await get_tree().process_frame

	for i in range(BUTTON_COUNT):
		btn_nodes.append(popup.get_grid_button("slot_%d" % i))

# ── MAIN LOOP ─────────────────────────────────────────────────────────────────
func _run_loop() -> void:
	while game_running and not is_game_over:
		# Pick 3 unique slots: 1 agree + 2 disagree
		var slots : Array = _pick_unique(3)

		_set_slot(slots[0], "AGREE",    "green")
		_set_slot(slots[1], "DISAGREE", "red")
		_set_slot(slots[2], "DISAGREE", "red")
		AudioManager.play_sfx(AudioManager.SFX.FLAPPY_GUY_FLAP)
		round_active = true
		await get_tree().create_timer(SHOW_DURATION).timeout

		if not game_running or is_game_over:
			return

		# Player didn't click — hide and go again
		round_active = false
		_reset_all()
		await get_tree().create_timer(HIDE_DURATION).timeout

# ── BUTTON PRESS ──────────────────────────────────────────────────────────────
func _on_button_pressed(bid: String) -> void:
	if not round_active or is_game_over:
		return

	var slot : int   = int(bid.replace("slot_", ""))
	var btn  : Button = btn_nodes[slot]

	match btn.text:
		"AGREE":
			agrees_clicked += 1
			AudioManager.play_sfx(AudioManager.SFX.CORRECT)
			round_active = false
			_reset_all()
			var left : int = ROUNDS_TO_WIN - agrees_clicked
			popup.title_label.text = "Click AGREE — %d to go!" % left
			if agrees_clicked >= ROUNDS_TO_WIN:
				game_running = false
				await get_tree().create_timer(0.3).timeout
				win_game()

		"DISAGREE":
			AudioManager.play_sfx(AudioManager.SFX.WRONG)
			game_running = false
			round_active = false
			_reset_all()
			await get_tree().create_timer(0.3).timeout
			fail_game("You clicked DISAGREE!")

# ── HELPERS ───────────────────────────────────────────────────────────────────
func _set_slot(slot: int, label: String, color: String) -> void:
	var btn : Button = btn_nodes[slot]
	btn.text     = label
	btn.disabled = false
	popup.set_grid_button_color("slot_%d" % slot, color)

func _reset_all() -> void:
	for i in range(BUTTON_COUNT):
		btn_nodes[i].text     = ""
		btn_nodes[i].disabled = true
		popup.set_grid_button_color("slot_%d" % i, "grey")

func _pick_unique(count: int) -> Array:
	var pool : Array = range(BUTTON_COUNT)
	pool.shuffle()
	return pool.slice(0, count)