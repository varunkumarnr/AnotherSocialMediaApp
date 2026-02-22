extends Node2D

const PIPE_SPEED: float = 200.0
var GAP_SIZE: float = 400.0
const SPAWN_INTERVAL: float = 3.0
const FIRST_PIPE_DELAY: float = 0
const MIN_GAP_Y: float = 400.0
const MAX_GAP_Y: float = 1400.0

var pipe_scene = preload("res://scenes/games/flappyGuy/pipe.tscn")

@onready var spawn_timer = $SpawnTimer

var first_pipe_spawned: bool = false
var is_spawning: bool = false
var pipes_spawned: int = 0
var current_difficulty: int

signal pipe_passed

func _ready():
	var config = GameManager.get_current_game_config()
	current_difficulty = config.difficulty
	
	if current_difficulty == GameData.DIFFICULTY.HARD:
		GAP_SIZE = 550.0
	elif current_difficulty == GameData.DIFFICULTY.EXTREMLY_HARD:
		GAP_SIZE = 600.0
	elif current_difficulty == GameData.DIFFICULTY.VERY_HARD:
		GAP_SIZE = 400.0  
	
	spawn_timer.one_shot = false
	spawn_timer.wait_time = SPAWN_INTERVAL
	spawn_timer.timeout.connect(_spawn_pipe)
	
	print("Pipe spawner ready")

func stop_spawning():
	is_spawning = false
	spawn_timer.stop()

func _spawn_pipe():
	if not is_spawning:
		return
	
	var pipes_container = get_parent().get_node_or_null("Pipes")
	
	if pipes_container == null:
		push_error("Pipes container not found!")
		return
	
	var pipe = pipe_scene.instantiate()
	pipes_container.add_child(pipe)
	pipes_spawned += 1
	
	var random_gap_y = randf_range(MIN_GAP_Y, MAX_GAP_Y)
	
	var spawn_x = 1200
	pipe.position = Vector2(spawn_x, random_gap_y)
	pipe.speed = PIPE_SPEED
	pipe.gap_size = GAP_SIZE
	pipe.is_moving_vertical = current_difficulty == GameData.DIFFICULTY.VERY_HARD || current_difficulty == GameData.DIFFICULTY.EXTREMLY_HARD
	
	if pipe.has_signal("player_passed"):
		pipe.player_passed.connect(_on_pipe_passed)
	
	print("Pipe #", pipes_spawned, " spawned at ", pipe.position)

func _on_pipe_passed():
	print("player passed")
	emit_signal("pipe_passed")

func start_spawning():
	is_spawning = true
	pipes_spawned = 0
	first_pipe_spawned = false  
	
	print("Waiting ", FIRST_PIPE_DELAY, "s before first pipe")
	
	await get_tree().create_timer(FIRST_PIPE_DELAY).timeout
	
	if not is_spawning:
		return
	
	_spawn_pipe()
	spawn_timer.start()
	print("Spawner active")
