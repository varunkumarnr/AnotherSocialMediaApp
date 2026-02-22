extends Node


# Stores the current game session overall detailes
class CurrentSession:
	var session_id: String
	var start_time: float
	var end_time: float
	var articles_completed: int
	var games: Array 
	var progress_time: float
	var level_history: Dictionary  

	func _init(_games: Array):
		session_id = str(Time.get_unix_time_from_system())
		start_time = Time.get_unix_time_from_system()
		end_time = 0.0
		articles_completed = 0
		games = _games
		progress_time = 0.0
		level_history = {}

# stores cumulative stats across all sessions for a user
class TotalPlaySession: 
	var user_id: int
	var start_time: float
	var total_time: float 
	var articles_completed: int
	var articles_failed: int 
	var total_failed_sessions: int 
	var total_success_sessions: int
	var attempts_per_article: Array
	var best_time: float
	var attempt_history: Dictionary  

	func _init(): 
		user_id = ResourceUID.create_id()
		start_time = Time.get_unix_time_from_system()
		total_time = 0.0
		articles_completed = 0
		articles_failed = 0
		total_failed_sessions = 0
		total_success_sessions = 0
		attempts_per_article = []
		best_time = 999999.0
		attempt_history = {}

# Tracks the state of an individual level attempt
class LevelState: 
	var game_id: String 
	var article_index: int
	var start_time: float
	var end_time: float
	var time_taken: float
	var is_completed: bool
	var is_failed: bool 
	var failure_reason: String
	var score_achieved: float
	var attempts: int

	func _init(_game_id: String, _article_index: int):
		game_id = _game_id
		article_index = _article_index
		start_time = Time.get_unix_time_from_system()
		end_time = 0.0
		time_taken = 0.0
		is_completed = false
		is_failed = false
		failure_reason = ""
		score_achieved = 0.0
		attempts = 1


var current_session: CurrentSession = null
var total_play_session: TotalPlaySession = null
var current_level: LevelState = null

var total_games_played: int = 0
var total_wins: int = 0
var total_losses: int = 0

const SAVE_PATH = "user://game_state.save"

func _ready() -> void:
	load_total_session()
	print("💾 GameState initialized")


func start_new_session(games: Array):
	"""Start a new play session"""
	current_session = CurrentSession.new(games)
	
	if not total_play_session:
		total_play_session = TotalPlaySession.new()
	
	print("New session started: ", current_session.session_id)
	print("Games in sequence: ", games.size())

func end_session(completed_all: bool):
	"""End current session"""
	if not current_session:
		return
	
	current_session.end_time = Time.get_unix_time_from_system()
	current_session.progress_time = current_session.end_time - current_session.start_time
	
	if total_play_session:
		total_play_session.total_time += current_session.progress_time
		
		if completed_all:
			total_play_session.total_success_sessions += 1
			
			if current_session.progress_time < total_play_session.best_time:
				total_play_session.best_time = current_session.progress_time
		else:
			total_play_session.total_failed_sessions += 1
	
	save_total_session()
	
	print("Session ended - Completed: ", current_session.articles_completed, "/15")
	print("⏱Time: %.2f seconds" % current_session.progress_time)


func start_level(game_id: String, article_index: int):
	"""Start tracking a level attempt"""
	current_level = LevelState.new(game_id, article_index)
	
	if current_session:
		current_session.level_history[game_id] = current_level
	
	if total_play_session:
		if not total_play_session.attempt_history.has(article_index):
			total_play_session.attempt_history[article_index] = []
		total_play_session.attempt_history[article_index].append(current_level)
	
	print("Level started: ", game_id, " (Article ", article_index + 1, ")")

func end_level(success: bool, score: float = 0.0, failure_reason: String = ""):
	"""End current level"""
	if not current_level:
		return
	
	current_level.end_time = Time.get_unix_time_from_system()
	current_level.time_taken = current_level.end_time - current_level.start_time
	current_level.is_completed = success
	current_level.is_failed = not success
	current_level.failure_reason = failure_reason
	current_level.score_achieved = score
	
	# Update stats
	total_games_played += 1
	
	if success:
		total_wins += 1
		if current_session:
			current_session.articles_completed += 1
		if total_play_session:
			total_play_session.articles_completed += 1
	else:
		total_losses += 1
		if total_play_session:
			total_play_session.articles_failed += 1
	
	print("Level ended - Success: ", success, " Time: %.2f" % current_level.time_taken)
	
	save_total_session()
	current_level = null

func get_win_rate() -> float:
	"""Get overall win rate"""
	if total_games_played == 0:
		return 0.0
	return (float(total_wins) / float(total_games_played)) * 100.0

func get_average_time_per_article() -> float:
	"""Get average time per completed article"""
	if not total_play_session or total_play_session.articles_completed == 0:
		return 0.0
	return total_play_session.total_time / float(total_play_session.articles_completed)

func get_current_session_time() -> float:
	"""Get current session elapsed time"""
	if not current_session:
		return 0.0
	return Time.get_unix_time_from_system() - current_session.start_time

func get_article_attempts(article_index: int) -> int:
	"""Get number of attempts for specific article"""
	if not total_play_session:
		return 0
	
	if total_play_session.attempt_history.has(article_index):
		return total_play_session.attempt_history[article_index].size()
	return 0

func get_fastest_article_time(article_index: int) -> float:
	"""Get fastest completion time for an article"""
	if not total_play_session or not total_play_session.attempt_history.has(article_index):
		return 0.0
	
	var fastest = 999999.0
	for attempt in total_play_session.attempt_history[article_index]:
		if attempt.is_completed and attempt.time_taken < fastest:
			fastest = attempt.time_taken
	
	return fastest if fastest < 999999.0 else 0.0

func get_stats_summary() -> Dictionary:
	"""Get comprehensive stats"""
	return {
		"total_games_played": total_games_played,
		"total_wins": total_wins,
		"total_losses": total_losses,
		"win_rate": get_win_rate(),
		"total_sessions": total_play_session.total_success_sessions + total_play_session.total_failed_sessions if total_play_session else 0,
		"successful_sessions": total_play_session.total_success_sessions if total_play_session else 0,
		"failed_sessions": total_play_session.total_failed_sessions if total_play_session else 0,
		"best_time": total_play_session.best_time if total_play_session else 0.0,
		"total_playtime": total_play_session.total_time if total_play_session else 0.0,
		"current_session_time": get_current_session_time()
	}

func save_total_session():
	"""Save total session to disk"""
	if not total_play_session:
		return
	
	var save_data = {
		"user_id": total_play_session.user_id,
		"start_time": total_play_session.start_time,
		"total_time": total_play_session.total_time,
		"articles_completed": total_play_session.articles_completed,
		"articles_failed": total_play_session.articles_failed,
		"total_failed_sessions": total_play_session.total_failed_sessions,
		"total_success_sessions": total_play_session.total_success_sessions,
		"best_time": total_play_session.best_time,
		"total_games_played": total_games_played,
		"total_wins": total_wins,
		"total_losses": total_losses
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("Progress saved")

func load_total_session():
	"""Load total session from disk"""
	if not FileAccess.file_exists(SAVE_PATH):
		total_play_session = TotalPlaySession.new()
		print("No save file - starting fresh")
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		
		total_play_session = TotalPlaySession.new()
		total_play_session.user_id = save_data.get("user_id", ResourceUID.create_id())
		total_play_session.start_time = save_data.get("start_time", Time.get_unix_time_from_system())
		total_play_session.total_time = save_data.get("total_time", 0.0)
		total_play_session.articles_completed = save_data.get("articles_completed", 0)
		total_play_session.articles_failed = save_data.get("articles_failed", 0)
		total_play_session.total_failed_sessions = save_data.get("total_failed_sessions", 0)
		total_play_session.total_success_sessions = save_data.get("total_success_sessions", 0)
		total_play_session.best_time = save_data.get("best_time", 999999.0)
		
		total_games_played = save_data.get("total_games_played", 0)
		total_wins = save_data.get("total_wins", 0)
		total_losses = save_data.get("total_losses", 0)
		
		file.close()
		print("Progress loaded - Sessions: ", total_play_session.total_success_sessions)