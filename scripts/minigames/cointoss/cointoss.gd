extends "res://scripts/core/miniGamesTemplate.gd"
class_name CoinTossGame

const TOSSES_NEEDED := 5
var HEADS_TO_WIN  := 2
const SPIN_DURATION := 1.4
const SPIN_FREQ     := 3.5   

const CHECK_PATH := "res://assets/ui/Green/Double/star.png"
const CROSS_PATH := "res://assets/ui/Red/Double/star.png"

var popup       : GamePopup
var toss_count  : int   = 0
var heads_count : int   = 0
var tossing     : bool  = false
var spinning    : bool  = false
var spin_t      : float = 0.0

var rng := RandomNumberGenerator.new()

func on_game_started() -> void:
	rng.randomize()
	play_game_music()
	add_child(TCBackground.new())
	HEADS_TO_WIN = randi_range(1, TOSSES_NEEDED-1) 
	_build_popup()

func _build_popup() -> void:
	var config               := PopupConfig.new()
	config.title             = "Coin Toss — Get %d Heads out of 4!" % HEADS_TO_WIN
	config.panel_color       = "blue"
	config.show_close_button = false
	config.popup_height = 600 
	config.popup_width = 900
	config.content_rows      = [
		{type = "text",   value = "Press TOSS. Get at least %d HEADS out of 4 tosses to win." % HEADS_TO_WIN},
		{type = "coin_display",    size = 160},
		{
			type       = "progress_icons",
			count      = TOSSES_NEEDED,
			icon_size  = 108,
			check_path = CHECK_PATH,
			cross_path = CROSS_PATH,
		},
	]
	config.buttons = [
		{id = "toss", label = "TOSS", shouldClose = false , color = "blue"},
	]

	popup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)
	popup.button_pressed.connect(_on_toss_pressed)

func _on_toss_pressed(_id: String) -> void:
	if tossing or toss_count >= TOSSES_NEEDED or is_game_over:
		return

	tossing = true
	popup.set_bottom_button_disabled(0, true)

	spinning = true
	spin_t   = 0.0
	popup.set_coin_text("...")
	popup.title_label.text = "Tossing..."

	await get_tree().create_timer(SPIN_DURATION).timeout

	spinning = false
	var is_heads : bool = rng.randi() % 2 == 0

	popup.set_coin_scale(1.0)
	popup.set_coin_color(Color(0.94, 0.78, 0.22) if is_heads else Color(0.72, 0.72, 0.72))
	popup.set_coin_text("HEAD" if is_heads else "TAIL")
	popup.set_progress_icon(toss_count, "pass" if is_heads else "fail")

	if is_heads:
		heads_count += 1

	toss_count += 1
	tossing = false

	var remaining := TOSSES_NEEDED - toss_count
	if remaining > 0:
		popup.title_label.text = "%d toss%s left — %d head%s so far" % [
			remaining, "es" if remaining > 1 else "",
			heads_count, "s" if heads_count != 1 else ""
		]
		popup.set_bottom_button_disabled(0, false)
	else:
		popup.title_label.text = "Done! — %d head%s" % [heads_count, "s" if heads_count != 1 else ""]
		await get_tree().create_timer(0.8).timeout
		if heads_count >= HEADS_TO_WIN:
			win_game()
		else:
			fail_game("Only %d head%s — need at least %d!" % [
				heads_count,
				"s" if heads_count != 1 else "",
				HEADS_TO_WIN
			])

func _process(delta: float) -> void:
	if not spinning:
		return

	spin_t += delta
	var cycle : float = sin(spin_t * SPIN_FREQ * TAU)

	popup.set_coin_scale(abs(cycle))

	if cycle >= 0.0:
		popup.set_coin_color(Color(0.94, 0.78, 0.22))
		popup.set_coin_text("HEAD")
	else:
		popup.set_coin_color(Color(0.78, 0.78, 0.78))
		popup.set_coin_text("TAIL")