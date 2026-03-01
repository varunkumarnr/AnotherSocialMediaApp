extends "res://scripts/core/miniGamesTemplate.gd"
class_name ReactionGame

const TARGET_MS := 225.0
const WAIT_MIN  := 2.0
const WAIT_MAX  := 5.0

enum Phase { WAITING, READY, RESULT }

var phase      : Phase = Phase.WAITING
var elapsed_ms : float = 0.0
var measuring  : bool  = false
var locked     : bool  = false   # ← single gate, set FIRST before any await
var rng        := RandomNumberGenerator.new()

var bg         : ColorRect
var top_label  : Label
var time_label : Label

func on_game_started() -> void:
	rng.randomize()
	play_game_music()
	await _build_ui()
	_start_wait()

func _build_ui() -> void:
	await get_tree().process_frame

	var top_bar   := get_node_or_null("GameUI/MarginContainer/VBoxContainer/TopBar")
	var content_y : float = 120.0
	if top_bar:
		content_y = top_bar.global_position.y + top_bar.size.y

	var vp           : Vector2 = get_viewport().get_visible_rect().size
	var game_content            = get_node("GameContent")

	bg             = ColorRect.new()
	bg.position    = Vector2(0, content_y)
	bg.size        = Vector2(vp.x, vp.y - content_y)
	bg.color       = Color(0.78, 0.12, 0.12)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_content.add_child(bg)

	top_label                        = Label.new()
	top_label.position               = Vector2(0, content_y)
	top_label.size                   = Vector2(vp.x, vp.y - content_y)
	top_label.horizontal_alignment   = HORIZONTAL_ALIGNMENT_CENTER
	top_label.vertical_alignment     = VERTICAL_ALIGNMENT_CENTER
	top_label.mouse_filter           = Control.MOUSE_FILTER_IGNORE
	top_label.add_theme_font_size_override("font_size", 52)
	top_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	top_label.text = "Wait for green\nthen click!"
	game_content.add_child(top_label)

	time_label                       = Label.new()
	time_label.position              = Vector2(0, vp.y - 180.0)
	time_label.size                  = Vector2(vp.x, 120.0)
	time_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	time_label.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	time_label.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	time_label.add_theme_font_size_override("font_size", 80)
	time_label.add_theme_color_override("font_color", Color(1, 1, 1))
	time_label.text = ""
	game_content.add_child(time_label)

func _start_wait() -> void:
	# Unlock only when we're fully ready for new input
	phase      = Phase.WAITING
	measuring  = false
	elapsed_ms = 0.0
	locked     = false   # ← re-open input here, not before

	bg.color        = Color(0.78, 0.12, 0.12)
	top_label.text  = "Wait for green\nthen click!"
	time_label.text = ""

	var wait := rng.randf_range(WAIT_MIN, WAIT_MAX)
	await get_tree().create_timer(wait).timeout
	if is_game_over: return

	phase     = Phase.READY
	measuring = true
	bg.color       = Color(0.10, 0.72, 0.24)
	top_label.text = "CLICK!"

func _process(delta: float) -> void:
	if measuring:
		elapsed_ms += delta * 1000.0

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton: return
	if not (event as InputEventMouseButton).pressed: return
	if (event as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT: return
	if is_game_over: return
	if locked: return   # ← hard gate — if locked, do NOTHING

	match phase:
		Phase.WAITING:
			locked = true   # ← lock FIRST, before any await
			# AudioManager.play_sfx(AudioManager.SFX.WRONG)
			bg.color       = Color(0.45, 0.05, 0.05)
			top_label.text = "Too early!\nWait for green..."
			await get_tree().create_timer(1.5).timeout
			if not is_game_over:
				_start_wait()   

		Phase.READY:
			locked    = true   
			measuring = false
			phase     = Phase.RESULT
			var ms    := elapsed_ms  - 25
			time_label.text = "%.0f ms" % ms

			if ms <= TARGET_MS:
				bg.color       = Color(0.05, 0.45, 0.12)
				top_label.text = "%.0f ms\nExcellent! ✓" % ms
				AudioManager.play_sfx(AudioManager.SFX.CORRECT)
				await get_tree().create_timer(1.8).timeout
				win_game()
			else:
				bg.color       = Color(0.55, 0.08, 0.08)
				top_label.text = "%.0f ms\nToo slow — need < 225ms" % ms
				# AudioManager.play_sfx(AudioManager.SFX.WRONG)
				await get_tree().create_timer(1.8).timeout
				_start_wait()