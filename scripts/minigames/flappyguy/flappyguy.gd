extends MiniGamesTemplate

@onready var player = $GameContent/flappyGuy 
@onready var pipe_spawner = $GameContent/PipeSpawner
@onready var pipes = $GameContent/Pipes

func _ready():
	# Call parent ready (loads config, sets up UI, etc.)
	super._ready()
	
	# Setup game-specific stuff after brief delay
	await get_tree().create_timer(0.1).timeout
	setup_flappy_game()

func setup_flappy_game():
	"""Setup Flappy Bird specific elements"""
	# Position player
	player.position = Vector2(300, 960)
	
	# Connect player signals
	player.player_died.connect(_on_player_died)
	pipe_spawner.pipe_passed.connect(_on_pipe_passed)

func on_game_started():
	"""Called by parent when game starts"""
	print("Flappy Bird started!")
	
	pipe_spawner.start_spawning()

func on_game_ended():
	"""Called by parent when game ends (win or lose)"""
	pipe_spawner.stop_spawning()

func _on_player_died():
	print("💀 Player died!")
	AudioManager.play_sfx(AudioManager.SFX.FLAPPY_GUY_HIT)
	
	# Make player red
	player.modulate = Color(1, 0, 0, 1)
	
	# Slow down time
	Engine.time_scale = 0.3
	
	# Wait 1 second in REAL time
	await get_tree().create_timer(1.0, true, false, true).timeout
	
	# Restore normal time and color
	Engine.time_scale = 1.0
	player.modulate = Color(1, 1, 1, 1)
	
	# Check game state
	if time_remaining > 0 and current_score < game_config.success_condition:
		start_new_run()
		return
	
	if current_score >= game_config.success_condition:
		win_game()
	else:
		fail_game("You Crashed!")


func start_new_run():
	print("New run")

	for pipe in pipes.get_children():
		pipe.queue_free()

	player.position = Vector2(300, 960)
	current_score = 0
	update_score_display()
	player.reset_game() 
	

func _on_pipe_passed():
	"""Player successfully passed through a pipe"""
	AudioManager.play_sfx(AudioManager.SFX.FLAPPY_GUY_POINT)
	add_score(1.0)
	
