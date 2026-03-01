extends MiniGamesTemplate
class_name VirusGame

# ── CONFIG ────────────────────────────────────────────────────────────────────
var BOX_COUNT := 20
var rng = RandomNumberGenerator.new()

# ── STATE ─────────────────────────────────────────────────────────────────────
var current_box_index   : int  = 0
var game_already_failed : bool = false

var prompts := [
	"I consent to data collection.",
	"Allow access to contacts.",
	"Enable background tracking.",
	"Share location at all times.",
	"Accept cookies & analytics.",
	"Opt in to email marketing.",
	"Allow microphone access.",
	"Enable push notifications.",
	"Store payment details.",
	"Allow camera access.",
	"Share usage statistics.",
	"Accept third-party ads.",
	"Allow file system access.",
	"Enable cloud sync.",
	"Accept auto-renewal terms.",
	"Share device identifiers.",
	"Allow in-app purchases.",
	"Enable biometric auth.",
	"Accept terms of service.",
	"Opt in to beta features.",
]

var variants : Array[int] = []


func on_game_started() -> void:
	random_box_count()
	play_game_music()
	add_child(TCBackground.new()) 
	prompts.shuffle()
	for i in range(BOX_COUNT):
		variants.append(randi() % 4)
	_show_next_box()

func random_box_count() -> void:
	rng.randomize()
	BOX_COUNT = rng.randi_range(5, 20)

func _show_next_box() -> void:
	if current_box_index >= BOX_COUNT:
		win_game()
		return

	var variant : int = variants[current_box_index]
	AudioManager.play_sfx(AudioManager.SFX.ERORR)

	var config               := PopupConfig.new()
	config.title             = "Clause %d / %s" % [current_box_index + 1, "?"]
	config.panel_color       = "blue" if variant < 2 else "yellow"
	config.show_close_button = false
	config.content_rows      = [
		{type = "text", value = prompts[current_box_index]},
	]

	match variant:
		0: config.buttons = [{id="agree",label="Agree",color="green"},{id="disagree",label="Disagree",color="red"}]
		1: config.buttons = [{id="disagree",label="Disagree",color="red"},{id="agree",label="Agree",color="green"}]
		2: config.buttons = [{id="agree",label="Agree",color="red"},{id="disagree",label="Disagree",color="green"}]
		3: config.buttons = [{id="disagree",label="Disagree",color="green"},{id="agree",label="Agree",color="red"}]

	var popup : GamePopup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)
	popup.button_pressed.connect(_on_clause_button)

	await get_tree().process_frame
	await get_tree().process_frame

	var center : CenterContainer = popup.get_node("Control/CenterContainer")
	var panel  : Panel           = center.get_node("Panel")

	center.set_anchors_preset(Control.PRESET_TOP_LEFT)
	center.size_flags_horizontal = 0
	center.size_flags_vertical   = 0

	center.reset_size()
	panel.reset_size()

	var vp : Vector2 = get_viewport().get_visible_rect().size
	var pw : float   = panel.size.x if panel.size.x > 1 else panel.custom_minimum_size.x
	var ph : float   = panel.size.y if panel.size.y > 1 else panel.custom_minimum_size.y
	if pw < 1: pw = 800.0
	if ph < 1: ph = 480.0

	const PAD := 24.0
	var max_x := vp.x - pw - PAD
	var max_y := vp.y - ph - PAD

	center.position = Vector2(
		randf_range(PAD, maxf(PAD, max_x)),
		randf_range(PAD, maxf(PAD, max_y))
	)

func _on_clause_button(button_id: String) -> void:
	if not is_game_active or is_game_over:
		return

	match button_id:
		"agree":
			current_box_index += 1
			_show_next_box()
			AudioManager.play_sfx(AudioManager.SFX.CORRECT)
		"disagree":
			if game_already_failed:
				return
			game_already_failed = true
			fail_game("You clicked Disagree!\nOne rejected clause voids the entire contract.")
			AudioManager.play_sfx(AudioManager.SFX.WRONG)
