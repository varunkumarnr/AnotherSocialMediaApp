extends Node


# Game state
var total_articles: int = 15
var current_article_index: int = 0

var game_sequence: Array[String] = []
var game_config: Array= []

signal article_completed(article_index)
signal game_won
signal game_lost(reason)
signal all_articles_completed

func _ready(): 
	print("Game manager Initialized") 


func start_new_game():
	current_article_index = 0
	generate_game_sequence()
	print("New game started! Pog!!! Sequence: ", game_sequence)
	
func get_current_article_index() -> int: 
	return current_article_index

# Generate mini sequence for the 15 levels in the session fuckin hell!!!! I tired help 
func generate_game_sequence(): 
	game_sequence.clear()
	game_config.clear()

	var random_ids = GameData.get_random_games()
	for id in random_ids: 
		game_sequence.append(id)
		game_config.append(GameData.get_game_config(id))

func get_current_game_config(): 
	if current_article_index < game_config.size(): 
		return game_config[current_article_index]
	return null

func get_current_game_scene():
	var config = get_current_game_config()
	if(config != null): 
		return config.scene_path 
	return ""

func start_current_game(): 
	var game_id = game_sequence[current_article_index]
	GameState.start_level(game_id, current_article_index) 
	print("BOOM !!! level started")

func complete_current_level(score: float = 0.0): 
	GameState.end_level(true, score)
	current_article_index += 1

	# I need to go back to article progress 

	emit_signal("article_completed", current_article_index -1)

	if(current_article_index >= total_articles):  
		complete_game() 
	else: 
		get_tree().change_scene_to_file("res://scenes/core/ArticleProgress.tscn")


func fail_current_level(reason: String = "Failed"):
	GameState.end_level(false,0.0, reason)
	emit_signal("game_lost", reason) 
	print("You lost bruh!!! get good")

	reset_game()
	

func complete_game():
	GameState.end_session(true)
	emit_signal("all_articles_completed")
	print("Game won! All levels completed!!!")
	get_tree().change_scene_to_file("res://scenes/core/GameWon.tscn")


func reset_game(): 
	current_article_index = 0
	game_sequence.clear()
	game_config.clear()
	print("Game reset. Done!!");
	get_tree().change_scene_to_file("res://scenes/core/main_menu.tscn")


func get_progress_text() -> String:
	return "%d/15" % (current_article_index + 1)

func get_time_limit() -> float:
	var config = get_current_game_config()
	return config.time_limit if config else 30.0

func get_win_factor() -> GameData.WINFACTOR:
	var config = get_current_game_config()
	return config.win_factor if config else GameData.WINFACTOR.COMPLETE

func get_success_condition() -> float:
	var config = get_current_game_config()
	return config.success_condition if config else 1.0
