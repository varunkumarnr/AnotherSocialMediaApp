extends Node
class_name MiniGamesTemplate


@onready var article_label = $GameUI/MarginContainer/VBoxContainer/TopBar/ArticleLabel
@onready var timer_label = $GameUI/MarginContainer/VBoxContainer/TopBar/TimerLabel
@onready var score_label = $GameUI/MarginContainer/VBoxContainer/TopBar/ScoreLabel
@onready var instructions_label = $GameUI/MarginContainer/VBoxContainer/InstructionsLabel 
@onready var gameTimer = $Timer 
@onready var failScreen = $FailScreen
@onready var successScreen = $VictoryScreen
@onready var restartButton = $FailScreen/CenterContainer/VBoxContainer/RestartButton 
@onready var nextButton = $VictoryScreen/CenterContainer/VBoxContainer/NextButton
@onready var fail_reason_label = $FailScreen/CenterContainer/VBoxContainer/FailureReasonLabel

var game_config :  GameData.MiniGameConfig = null 

var current_score : float = 0.0
var time_remaining: float = 0.0
var is_game_active: bool = false
var is_game_over: bool = false
var failed_once: bool = false



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_config = GameManager.get_current_game_config()

	if not game_config: 
		print("No game config found for the current mini_game.") 
		return
	
	setup_from_config()
	setup_ui()
	setup_timer()
	connect_signals()


	GameManager.start_current_game()
	await get_tree().create_timer(0.5).timeout
	start_game()

	
func setup_from_config():
	"""Load settings from game config"""
	time_remaining = game_config.time_limit
	
	print("Loaded config: ", game_config.display_name)

func play_game_music():
	"""Play music for this mini-game"""
	if game_config.music_track >= 0:
		AudioManager.play_music(game_config.music_track, 1.5, true)

func setup_ui():
	"""Setup UI elements"""
	# Set article info
	var article_num = GameManager.current_article_index + 1
	article_label.text = "Article %d: %s" % [article_num, game_config.display_name]
	
	# Set instructions
	instructions_label.text = get_instructions()
	
	# Show/hide score based on win factor
	var needs_score = game_config.win_factor in [
		GameData.WINFACTOR.POINTS_IN_TIME
	]
	score_label.visible = needs_score
	
	if needs_score:
		update_score_display()
	
	# Show/hide timer
	timer_label.visible = game_config.is_timed
	
	# Hide screens
	failScreen.visible = false
	successScreen.visible = false

func get_instructions() -> String: 
	match game_config.win_factor:
		GameData.WINFACTOR.POINTS_IN_TIME: 
			return 'Earn %d points within %d seconds!' % [game_config.success_condition, game_config.time_limit]
		GameData.WINFACTOR.NO_FAIL: 
			return 'Complete the game without failing!'
		GameData.WINFACTOR.TIME_LIMIT:
			return 'Complete the game within %d seconds!' % game_config.time_limit
		GameData.WINFACTOR.NO_FAIL_TIME_TIMIT: 
			return 'Complete the game wiithin %d seconds without failing!' % game_config.time_limit
		GameData.WINFACTOR.COMPLETE: 
			return 'Complete this game to proceed!'
		_: 
			return 'FUCK!'



func setup_timer(): 
	if game_config.is_timed: 
		gameTimer.wait_time = 0.1
		gameTimer.timeout.connect(_on_timer_tick) 
		update_timer_display()

func connect_signals(): 
	restartButton.pressed.connect(_on_restart_button_pressed)
	nextButton.pressed.connect(on_next_button_pressed)

func start_game(): 
	is_game_active = true

	if game_config.is_timed:
		gameTimer.start()
	
	on_game_started() 

	print("game started")

func _on_timer_tick():
	"""Called every 0.1 seconds to update timer"""
	if not is_game_active or is_game_over:
		return
	
	time_remaining -= 0.1
	update_timer_display()
	
	# Check if time ran out
	if time_remaining <= 0:
		time_remaining = 0
		update_timer_display()
		gameTimer.stop()
		match game_config.win_factor: 
			GameData.WINFACTOR.NO_FAIL_TIME_TIMIT , GameData.WINFACTOR.TIME_LIMIT: 
				fail_game("Times up!")

func update_timer_display():
	"""Update timer label with color changes"""
	var seconds = int(time_remaining)
	var deciseconds = int((time_remaining - seconds) * 10)
	timer_label.text = "⏱️ %d.%d" % [seconds, deciseconds]
	
	# Color changes based on time remaining
	if time_remaining <= 5.0:
		timer_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red
		# Pulse effect
		if int(time_remaining * 2) % 2 == 0:
			timer_label.scale = Vector2(1.15, 1.15)
		else:
			timer_label.scale = Vector2(1.0, 1.0)
	elif time_remaining <= 10.0:
		timer_label.add_theme_color_override("font_color", Color(1, 0.6, 0))  # Orange
		timer_label.scale = Vector2(1.0, 1.0)
	else:
		timer_label.add_theme_color_override("font_color", Color(1, 1, 1))  # White
		timer_label.scale = Vector2(1.0, 1.0)


func add_score(points: float = 1.0):
	"""Add to score and check win condition"""
	current_score += points
	update_score_display()
	
	# Check success condition based on win factor
	# match game_config.win_factor:
	# 	GameData.WINFACTOR.POINTS_IN_TIME:
	# 		if current_score >= game_config.success_condition:
	# 			win_game()
	
func update_score_display():
	"""Update score label"""
	score_label.text = str(current_score)

func register_failure():
	"""Called when player makes a mistake (for NO_FAIL modes)"""
	match game_config.win_factor:
		GameData.WINFACTOR.NO_FAIL, GameData.WINFACTOR.NO_FAIL_TIME_TIMIT:
			if not failed_once:
				failed_once = true
				fail_game("You Failed!")
	
	# if the run is active even if the time is over it should only fail after the run completes. Like rocket league.
	match game_config.win_factor:
		GameData.WINFACTOR.POINTS_IN_TIME: 
			if current_score < game_config.success_condition && time_remaining <= 0:
				fail_game("You Failed!")

func win_game(): 
	if is_game_over: 
		return 

	is_game_over = true
	is_game_active = false 
	gameTimer.stop()

	on_game_ended()

	successScreen.visible = true

	await get_tree().create_timer(2).timeout

func on_next_button_pressed(): 
	GameManager.complete_current_level(current_score)

func fail_game(reason: String = "Failed"):
	if is_game_over:
		return 
	
	is_game_over = true
	is_game_active = false
	gameTimer.stop()

	on_game_ended()

	print("Game failed! Reason: ", reason) 

	fail_reason_label.text = reason
	failScreen.visible = true

func restart_level(): 
	get_tree().reload_current_scene()


func _on_restart_button_pressed():
	GameManager.reset_game()

func get_time_remaining() -> float:
	return time_remaining

func on_game_started(): 
	"""child classes overload this to implement game logic when the game starts"""
	pass

func on_game_ended(): 
	"""child classes overlaod this to implement game logic when the game ends (win or lose)"""
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
