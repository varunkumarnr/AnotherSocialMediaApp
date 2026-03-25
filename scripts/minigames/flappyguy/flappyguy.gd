extends MiniGamesTemplate

@onready var player = $GameContent/flappyGuy 
@onready var pipe_spawner = $GameContent/PipeSpawner
@onready var pipes = $GameContent/Pipes

func _ready():
	super._ready()
	
	var cam = Camera2D.new()
	cam.position = Vector2(540, 960)  
	cam.limit_left = 0
	cam.limit_right = 1080
	cam.limit_top = 0
	cam.limit_bottom = 1920
	add_child(cam)
	cam.make_current()
	add_child(TCBackground.new())
	await get_tree().create_timer(0.1).timeout
	setup_flappy_game()

func setup_flappy_game():
	player.position = Vector2(300, 960)
	player.player_died.connect(_on_player_died)
	pipe_spawner.pipe_passed.connect(_on_pipe_passed)

func on_game_started():
	print("Flappy Bird started!")
	pipe_spawner.start_spawning()

func on_game_ended():
	pipe_spawner.stop_spawning()

func _on_player_died():
	print("💀 Player died!")
	AudioManager.play_sfx(AudioManager.SFX.FLAPPY_GUY_HIT)
	
	player.modulate = Color(1, 0, 0, 1)
	Engine.time_scale = 0.3
	
	await get_tree().create_timer(1.0, true, false, true).timeout
	
	Engine.time_scale = 1.0
	player.modulate = Color(1, 1, 1, 1)
	
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
	AudioManager.play_sfx(AudioManager.SFX.FLAPPY_GUY_POINT)
	add_score(1.0)