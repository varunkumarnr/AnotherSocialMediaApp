extends Node
class_name MiniGamesTemplate


@onready var article_label      = $GameUI/TopBar/TopMargin/TopVBox/ArticleLabel
@onready var timer_label        = $GameUI/BottomBar/BottomMargin/BottomHBox/TimerPanel/TimerMargin/TimerVBox/TimerLabel
@onready var score_label        = $GameUI/BottomBar/BottomMargin/BottomHBox/ScorePanel/ScoreMargin/ScoreVBox/ScoreLabel
@onready var instructions_label = $GameUI/InstructionsBar/InstructionsMargin/InstructionsLabel
@onready var gameTimer          = $Timer
@onready var vignette_rect      = $GameUI/VignetteRect
@onready var timer_panel        = $GameUI/BottomBar/BottomMargin/BottomHBox/TimerPanel
@onready var timer_caption      = $GameUI/BottomBar/BottomMargin/BottomHBox/TimerPanel/TimerMargin/TimerVBox/TimerCaption
@onready var score_panel        = $GameUI/BottomBar/BottomMargin/BottomHBox/ScorePanel
@onready var module_caption     = $GameUI/TopBar/TopMargin/TopVBox/ModuleCaption

const POPUP_SCENE = preload("res://scenes/core/gamePopup.tscn")
const RESULT_SCREEN = preload("res://scenes/core/result_screen.tscn")

const FONT_PATH := "res://assets/fonts/JetBrainsMono-Regular.ttf"

var game_config : GameData.MiniGameConfig = null 

var current_score : float = 0.0
var time_remaining: float = 0.0
var is_game_active: bool = false
var is_game_over: bool = false
var failed_once: bool = false


func _ready() -> void:
	game_config = GameManager.get_current_game_config()

	if not game_config: 
		print("No game config found for the current mini_game.") 
		return
	
	setup_from_config()
	setup_ui()
	setup_timer()
	# REMOVED: connect_signals() — popup handles its own buttons

	GameManager.start_current_game()
	await get_tree().create_timer(0.5).timeout
	start_game()

	
func setup_from_config():
	time_remaining = game_config.time_limit
	print("Loaded config: ", game_config.display_name)

func play_game_music():
	if game_config.music_track >= 0:
		AudioManager.play_music(game_config.music_track, 1.5, true)

func setup_ui():
	var mono_font: FontFile = null
	if ResourceLoader.exists("res://assets/fonts/JetBrainsMono-Regular.ttf"):
		mono_font = load("res://assets/fonts/JetBrainsMono-Regular.ttf")

	var article_num := GameManager.current_article_index + 1
	module_caption.text = "SUBROUTINE DEPLOYMENT  //  MODULE %02d" % article_num
	article_label.text  = "MODULE %02d — %s" % [article_num, game_config.display_name.to_upper()]
	instructions_label.text = get_instructions()

	if mono_font:
		for node in [article_label, timer_label, score_label,
					 instructions_label, module_caption, timer_caption]:
			if node:
				node.add_theme_font_override("font", mono_font)
		var score_caption = score_panel.get_node_or_null(
			"ScoreMargin/ScoreVBox/ScoreCaption")
		if score_caption:
			score_caption.add_theme_font_override("font", mono_font)

	var needs_score := game_config.win_factor in [GameData.WINFACTOR.POINTS_IN_TIME]
	score_panel.visible = needs_score
	score_label.visible = needs_score
	if needs_score:
		update_score_display()

	timer_panel.visible = game_config.is_timed
	timer_label.visible = game_config.is_timed

func _find_node_by_name(root: Node, target: String) -> Node:
	if root.name == target:
		return root
	for child in root.get_children():
		var result = _find_node_by_name(child, target)
		if result != null:
			return result
	return null


func get_instructions() -> String: 
	match game_config.win_factor:
		GameData.WINFACTOR.POINTS_IN_TIME: 
			return 'Earn %d points within %d seconds!' % [game_config.success_condition, game_config.time_limit]
		GameData.WINFACTOR.NO_FAIL: 
			return 'Complete the game without failing!'
		GameData.WINFACTOR.TIME_LIMIT:
			return 'Complete the game within %d seconds!' % game_config.time_limit
		GameData.WINFACTOR.NO_FAIL_TIME_TIMIT: 
			return 'Complete the game within %d seconds without failing!' % game_config.time_limit
		GameData.WINFACTOR.COMPLETE: 
			return 'Complete this game to proceed!'
		_: 
			return 'FUCK!'

func setup_timer(): 
	if game_config.is_timed: 
		gameTimer.wait_time = 0.1
		gameTimer.timeout.connect(_on_timer_tick) 
		update_timer_display()

func start_game(): 
	is_game_active = true
	if game_config.is_timed:
		gameTimer.start()
	on_game_started()
	print("game started")

func _on_timer_tick():
	if not is_game_active or is_game_over:
		return
	
	time_remaining -= 0.1
	update_timer_display()
	
	if time_remaining <= 0:
		time_remaining = 0
		update_timer_display()
		gameTimer.stop()
		match game_config.win_factor: 
			GameData.WINFACTOR.NO_FAIL_TIME_TIMIT, GameData.WINFACTOR.TIME_LIMIT: 
				fail_game("Times up!")

func update_timer_display():
	var s  := int(time_remaining)
	var ds := int((time_remaining - s) * 10)
	# Format like mock: 00:44:02
	var minutes := s / 60
	var seconds := s % 60
	timer_label.text = "%02d:%02d:%d" % [minutes, seconds, ds]

	if time_remaining <= 5.0:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))
		timer_caption.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))
		if int(time_remaining * 2) % 2 == 0:
			timer_label.add_theme_font_size_override("font_size", 86)
		else:
			timer_label.add_theme_font_size_override("font_size", 72)
		var alpha := 0.2 + 0.15 * sin(Time.get_ticks_msec() * 0.006)
		vignette_rect.color = Color(0.7, 0.0, 0.0, alpha)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.22, 0.02, 0.02, 1)
		sb.border_color = Color(1, 0.1, 0.1, 1)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(8)
		timer_panel.add_theme_stylebox_override("panel", sb)

	elif time_remaining <= 10.0:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0))
		timer_caption.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0))
		timer_label.add_theme_font_size_override("font_size", 72)
		vignette_rect.color = Color(0.4, 0.2, 0.0, 0.1)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.12, 0.07, 0.0, 1)
		sb.border_color = Color(1, 0.6, 0, 1)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(8)
		timer_panel.add_theme_stylebox_override("panel", sb)

	else:
		timer_label.add_theme_color_override("font_color", Color(0.784, 0.831, 0.910, 1))
		timer_caption.add_theme_color_override("font_color", Color(0.29, 0.353, 0.439, 1))
		timer_label.add_theme_font_size_override("font_size", 72)
		vignette_rect.color = Color(0, 0, 0, 0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.039, 0.047, 0.063, 1)
		sb.border_color = Color(0.0, 0.831, 1.0, 1)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(8)
		timer_panel.add_theme_stylebox_override("panel", sb)
		
func add_score(points: float = 1.0):
	current_score += points
	update_score_display()
	
func update_score_display():
	score_label.text = str(current_score)

func register_failure():
	match game_config.win_factor:
		GameData.WINFACTOR.NO_FAIL, GameData.WINFACTOR.NO_FAIL_TIME_TIMIT:
			if not failed_once:
				failed_once = true
				fail_game("You Failed!")
	
	match game_config.win_factor:
		GameData.WINFACTOR.POINTS_IN_TIME: 
			if current_score < game_config.success_condition && time_remaining <= 0:
				fail_game("You Failed!")

# ── POPUP HELPERS ──────────────────────────────────────────────────────────────

func _show_result_screen(is_win: bool, reason: String = "") -> void:
	var screen = RESULT_SCREEN.instantiate()
	add_child(screen)
	var article_num := GameManager.current_article_index + 1
	var game_name   := game_config.display_name
	if is_win:
		screen.setup_win(article_num, game_name, current_score if game_config.win_factor == GameData.WINFACTOR.POINTS_IN_TIME else -1.0)
	else:
		screen.setup_fail(reason, article_num, game_name)
	screen.button_pressed.connect(_on_popup_button)

func _on_popup_button(button_id: String) -> void:
	match button_id:
		"restart":
			GameManager.reset_game()
		"next":
			GameManager.complete_current_level(current_score)
		"quit":
			GameManager.reset_game()

func _build_fail_config(reason: String) -> PopupConfig:
	var config := PopupConfig.new()
	config.title = "Terms Rejected "
	config.panel_color = "red"
	config.show_close_button = false
	config.content_rows = [
		{type = "label_value", label = "Article:", value = "Article %d" % (GameManager.current_article_index + 1)},
		{type = "label_value", label = "Game:", value = game_config.display_name},
		{type = "separator"},
		{type = "text", value = reason},
	]
	config.buttons = [
		{id = "restart", label = "Try Again", color = "red"},
		{id = "quit",    label = "Give Up",   color = "grey"},
	]
	return config

func _build_win_config() -> PopupConfig:
	var config := PopupConfig.new()
	config.title = "Terms Accepted"
	config.panel_color = "green"
	config.show_close_button = false
	config.content_rows = [
		{type = "label_value", label = "Article:", value = "Article %d" % (GameManager.current_article_index + 1)},
		{type = "label_value", label = "Game:", value = game_config.display_name},
	]
	# Add score row only if game uses scoring
	if game_config.win_factor == GameData.WINFACTOR.POINTS_IN_TIME:
		config.content_rows.append({type = "label_value", label = "Score:", value = str(current_score)})
	
	config.content_rows.append({type = "separator"})
	config.content_rows.append({type = "text", value = "You have successfully complied with all terms."})
	
	config.buttons = [
		{id = "next", label = "Continue", color = "green"},
	]
	return config

# ── WIN / FAIL ─────────────────────────────────────────────────────────────────

func win_game():
	if is_game_over:
		return
	is_game_over = true
	is_game_active = false
	gameTimer.stop()
	on_game_ended()
	await get_tree().create_timer(0.5).timeout
	_show_result_screen(true)

func fail_game(reason: String = "Failed"):
	if is_game_over:
		return
	is_game_over = true
	is_game_active = false
	gameTimer.stop()
	on_game_ended()
	print("Game failed! Reason: ", reason)
	await get_tree().create_timer(0.5).timeout
	_show_result_screen(false, reason)

func restart_level(): 
	get_tree().reload_current_scene()

func get_time_remaining() -> float:
	return time_remaining

func on_game_started(): 
	pass

func on_game_ended(): 
	pass

func _process(_delta: float) -> void:
	pass
