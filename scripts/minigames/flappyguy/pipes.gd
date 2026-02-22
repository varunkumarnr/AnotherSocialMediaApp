extends Node2D

# Configuration
var speed: float = 200.0
var gap_size: float = 400.0

# Vertical movement (VERY_HARD)
var is_moving_vertical: bool = false
var move_direction: float = 1.0
var start_y: float = 0.0
const VERTICAL_SPEED: float = 150.0
const VERTICAL_LIMIT: float = 300.0 

@onready var pipe_layer = $PipeLayer

var has_scored: bool = false
var is_built: bool = false
var vertical_initialized: bool = false 

const TILE_SIZE = 64
const PIPE_WIDTH = 3
const SOURCE_ID = 0

signal player_passed
var player: Node2D

func _ready():
	var config = GameManager.get_current_game_config()
	if config.difficulty == GameData.DIFFICULTY.HARD or config.difficulty == GameData.DIFFICULTY.EXTREMLY_HARD:
		gap_size = 500.0
	
	if is_moving_vertical:
		# Randomly pick up or down, 50/50
		move_direction = 1.0 if randf() > 0.5 else -1.0
	
	if is_inside_tree() and get_parent() != null:
		if get_parent().name == "Pipes":
			build_pipes_when_ready()
		else:
			print("Pipe exists but not in Pipes container - skipping build")

func build_pipes_when_ready():
	await get_tree().process_frame
	build_pipe_columns()
	is_built = true

func build_pipe_columns():
	var half_gap_tiles = int(gap_size / (TILE_SIZE * 2))
	
	print("🏗️  Building pipe - Gap: ", gap_size, " at position: ", position)
	
	for y in range(-30, -half_gap_tiles):
		for x in range(PIPE_WIDTH):
			pipe_layer.set_cell(Vector2i(x, y), SOURCE_ID, Vector2i(0, 0))
	
	for y in range(half_gap_tiles, 30):
		for x in range(PIPE_WIDTH):
			pipe_layer.set_cell(Vector2i(x, y), SOURCE_ID, Vector2i(0, 0))
	
	print("Pipe built")

func _process(delta):
	if not is_built:
		return

	# Capture start_y on the first frame after everything is positioned
	if is_moving_vertical and not vertical_initialized:
		start_y = position.y
		vertical_initialized = true

	if is_moving_vertical and vertical_initialized:
		position.y += VERTICAL_SPEED * move_direction * delta
		
		# Hit the bottom limit, force back up
		if position.y >= start_y + VERTICAL_LIMIT:
			position.y = start_y + VERTICAL_LIMIT
			move_direction = -1.0
		# Hit the top limit, force back down
		elif position.y <= start_y - VERTICAL_LIMIT:
			position.y = start_y - VERTICAL_LIMIT
			move_direction = 1.0

	player = get_tree().get_first_node_in_group("player")

	if not has_scored and player:
		var pipe_center_x = position.x + (PIPE_WIDTH * TILE_SIZE) / 2
		if player.global_position.x > pipe_center_x:
			has_scored = true
			emit_signal("player_passed")
			print("Pipe passed!")
	
	position.x -= speed * delta
	
	if position.x < -300:
		print("🗑️  Pipe deleted at x:", position.x)
		queue_free()
