extends MiniGamesTemplate
class_name TimingGame

const TARGET_MIN   := 18.0   
const TARGET_MAX   := 20.0
const SHOW_SECONDS := 3.0  

enum Phase { IDLE, COUNTING, HIDDEN, RESULT }

var phase   : Phase = Phase.IDLE
var popup   : GamePopup
var elapsed : float = 0.0

func on_game_started() -> void:
	add_child(TCBackground.new())
	_build_popup()

func _build_popup() -> void:
	var config               := PopupConfig.new()
	config.title             = "AGREE b/w 18–20s"
	config.panel_color       = "blue"
	config.show_close_button = false
	config.content_rows      = [
		{
			type  = "text",
			value = "The timer will show for 3 seconds then disappear.\nPress AGREE when you think it hits 18–20 seconds.",
		},
		{type = "timer_display", initial_text = "0.00", font_size = 80},
	]
	config.popup_height = 500
	config.buttons = [
		{id = "action", label = "START", shouldClose= false, color = "green"},
	]

	popup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)
	popup.button_pressed.connect(_on_action_pressed)

func _on_action_pressed(_id: String) -> void:
	match phase:
		Phase.IDLE:   _start_counting()
		Phase.HIDDEN: _player_guessed()

func _start_counting() -> void:
	phase   = Phase.COUNTING
	elapsed = 0.0
	play_game_music()

	popup.set_timer_visible(true)
	popup.set_timer_color(Color(0.15, 0.15, 0.15))
	popup.set_timer_text("0.00")
	popup.title_label.text = "Watch the timer..."
	popup.set_bottom_button_disabled(0, true)
	popup.set_bottom_button_label(0, "...")

	await get_tree().create_timer(SHOW_SECONDS).timeout
	if is_game_over: return

	# Timer disappears — player must now guess
	phase = Phase.HIDDEN
	popup.set_timer_visible(false)
	popup.title_label.text = "Now!!"
	popup.set_bottom_button_label(0, "AGREE")
	popup.set_bottom_button_color(0, "green")
	popup.set_bottom_button_disabled(0, false)

# ── PHASE: PLAYER GUESSES ─────────────────────────────────────────────────────
func _player_guessed() -> void:
	if phase != Phase.HIDDEN or is_game_over:
		return
	AudioManager.stop_music()
	phase = Phase.RESULT
	popup.set_bottom_button_disabled(0, true)

	# Reveal the actual time
	popup.set_timer_visible(true)
	popup.set_timer_text("%.2f" % elapsed)

	if elapsed >= TARGET_MIN and elapsed <= TARGET_MAX:
		popup.set_timer_color(Color(0.1, 0.65, 0.2))
		popup.title_label.text = "%.2fs — Perfect!" % elapsed
		AudioManager.play_sfx(AudioManager.SFX.CORRECT)
		await get_tree().create_timer(1.2).timeout
		win_game()
	else:
		popup.set_timer_color(Color(0.75, 0.1, 0.1))
		var hint := "Too early!" if elapsed < TARGET_MIN else "Too late!"
		popup.title_label.text = "%s — %.2fs" % [hint, elapsed]
		AudioManager.play_sfx(AudioManager.SFX.WRONG)
		await get_tree().create_timer(1.2).timeout
		fail_game("You pressed at %.2fs.\nTarget window: 18–20s." % elapsed)

func _process(delta: float) -> void:
	if phase == Phase.IDLE or phase == Phase.RESULT or is_game_over:
		return

	elapsed += delta

	if phase == Phase.COUNTING:
		popup.set_timer_text("%.2f" % elapsed)

	if phase == Phase.HIDDEN and elapsed > TARGET_MAX + 3.0:
		phase = Phase.RESULT
		popup.set_timer_visible(true)
		popup.set_timer_color(Color(0.75, 0.1, 0.1))
		popup.set_timer_text("%.2f" % elapsed)
		popup.title_label.text = "Too slow! — %.2fs" % elapsed
		popup.set_bottom_button_disabled(0, true)
		fail_game("You waited too long!\nTarget window: 18–20s.")
