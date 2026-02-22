extends Node

# Game state
var total_articles: int = 15
var articles_completed: int = 0
var current_article_index: int = 0

# Available mini-games (all point to test game for now)
var available_games: Array[String] = []

# Sequence of games for this playthrough
var game_sequence: Array[String] = []

# Signals
signal article_completed
signal game_won
signal game_lost
signal all_articles_completed

func _ready():
	print("🎮 GameManager initialized")
	load_available_games()

func load_available_games():
	# For testing: all 15 levels use the same test game
	var test_game_path = "res://scenes/games/testLevel.tscn"
	
	for i in range(15):
		available_games.append(test_game_path)
	
	print("📦 Loaded ", available_games.size(), " games")

func start_new_game():
	"""Called when user first logs in"""
	articles_completed = 0
	current_article_index = 0
	
	# For now, all games are the same test level
	game_sequence = available_games.duplicate()
	
	print("🎬 New game started!")
	print("📊 Sequence: ", game_sequence.size(), " games")

func get_current_game_path() -> String:
	"""Get the mini-game for current article"""
	if current_article_index < game_sequence.size():
		return game_sequence[current_article_index]
	return ""

func complete_current_article():
	articles_completed += 1
	current_article_index += 1
	
	print("✅ Article completed! Total: ", articles_completed, "/", total_articles)
	
	emit_signal("article_completed")
	
	if articles_completed >= total_articles:
		print("🎉 All articles completed!")
		emit_signal("all_articles_completed")
		get_tree().change_scene_to_file("res://scenes/ui/VictoryScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/core/ArticleProgress.tscn")

func fail_current_article():
	"""Called when user fails a mini-game"""
	print("❌ Article failed! Restarting game...")
	emit_signal("game_lost")
	
	# In a rage game, failing means starting over
	reset_game()

func reset_game():
	"""Reset all progress and go back to beginning"""
	articles_completed = 0
	current_article_index = 0
	
	# Go back to login/social feed
	get_tree().change_scene_to_file("res://scenes/core/FakeSocialFeed.tscn")

func get_progress_text() -> String:
	"""Get human-readable progress"""
	return str(current_article_index + 1) + "/15"

func get_current_article_data() -> Dictionary:
	"""Get data for current article"""
	return {
		"index": current_article_index,
		"number": current_article_index + 1,
		"total": total_articles,
		"completed": articles_completed
	}
