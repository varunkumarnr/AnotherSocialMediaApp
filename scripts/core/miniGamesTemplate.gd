extends Node
class_name MiniGamesTemplate


@onready var article_label = $GameUI/MarginContainer/VBoxContainer/TopBar/ArticleLabel
@onready var timer_label = $GameUI/MarginContainer/VBoxContainer/TopBar/TimerLabel
@onready var score_label = $GameUI/MarginContainer/VBoxContainer/TopBar/ScoreLabel
@onready var instructions_label = $GameUI/MarginContainer/VBoxContainer/InstructionsLabel 
@onready var gameTimer = $Timer 

const POPUP_SCENE = preload("res://scenes/core/gamePopup.tscn")

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
	var article_num = GameManager.current_article_index + 1
	article_label.text = "Article %d: %s" % [article_num, game_config.display_name]
	instructions_label.text = get_instructions()
	
	var needs_score = game_config.win_factor in [GameData.WINFACTOR.POINTS_IN_TIME]
	score_label.visible = needs_score
	if needs_score:
		update_score_display()
	
	timer_label.visible = game_config.is_timed

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
	var seconds = int(time_remaining)
	var deciseconds = int((time_remaining - seconds) * 10)
	timer_label.text = "⏱️ %d.%d" % [seconds, deciseconds]
	
	if time_remaining <= 5.0:
		timer_label.add_theme_color_override("font_color", Color(1, 0, 0))
		if int(time_remaining * 2) % 2 == 0:
			timer_label.scale = Vector2(1.15, 1.15)
		else:
			timer_label.scale = Vector2(1.0, 1.0)
	elif time_remaining <= 10.0:
		timer_label.add_theme_color_override("font_color", Color(1, 0.6, 0))
		timer_label.scale = Vector2(1.0, 1.0)
	else:
		timer_label.add_theme_color_override("font_color", Color(1, 1, 1))
		timer_label.scale = Vector2(1.0, 1.0)

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

func _show_popup(config: PopupConfig) -> void:
	var popup: GamePopup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)
	popup.button_pressed.connect(_on_popup_button)

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
	_show_popup(_build_win_config())

func fail_game(reason: String = "Failed"):
	if is_game_over:
		return 
	
	is_game_over = true
	is_game_active = false
	gameTimer.stop()
	on_game_ended()

	print("Game failed! Reason: ", reason)

	await get_tree().create_timer(0.5).timeout
	_show_popup(_build_fail_config(reason))

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
