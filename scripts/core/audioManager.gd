extends Node

var music_player_a: AudioStreamPlayer
var music_player_b: AudioStreamPlayer
var current_music_player: AudioStreamPlayer
var next_music_player: AudioStreamPlayer

var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 16

var ui_player: AudioStreamPlayer


var master_volume: float = 1.0
var sfx_volume: float = 1.0 
var music_volume: float = 1.0 
const SETTINGS_PATH = "user://audio_settings.save"


enum MUSICTRACK { 
	NONE, 
	TIME_TICKING
}

var music_library: Dictionary = { 
	# add all the songs here with their enum keys when I have them, TODO: please remeber
	MUSICTRACK.TIME_TICKING: "res://sounds/music/time_ticking.ogg" 
}

enum SFX { 
	FLAPPY_GUY_POINT,
	FLAPPY_GUY_HIT, 
	FLAPPY_GUY_FLAP,  
	ERORR, 
	CORRECT, 
	WRONG, 
	CLICK
}

var sfx_library: Dictionary = {
	# TODO: please god help me find goood sound effects..... :( 
	# is life depressing or is it just me... I am going schizo fuck. 
	SFX.FLAPPY_GUY_POINT: "res://sounds/sfx/point_sound.ogg", 
	SFX.FLAPPY_GUY_HIT: "res://sounds/sfx/died_flappy_guy.ogg", 
	SFX.FLAPPY_GUY_FLAP: "res://sounds/sfx/bubble.ogg",
	SFX.ERORR: "res://sounds/sfx/windows-error.ogg", 
	SFX.CORRECT: "res://sounds/sfx/correct.ogg",
	SFX.WRONG: "res://sounds/sfx/wrong.ogg", 
	SFX.CLICK: "res://sounds/sfx/click.ogg"
} 




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_player_a = AudioStreamPlayer.new() 
	music_player_a.name = "MusicPlayerA" 
	music_player_a.bus = "Music" 
	add_child(music_player_a)
	
	music_player_b = AudioStreamPlayer.new() 
	music_player_b.name = "MusicPlayerB" 
	music_player_b.bus = "Music" 
	add_child(music_player_b)

	current_music_player = music_player_a
	next_music_player = music_player_b
	
	for i in range(SFX_POOL_SIZE):
		var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer" + str(i)
		sfx_player.bus = "SFX"
		sfx_players.append(sfx_player)
		add_child(sfx_player)
		
	ui_player = AudioStreamPlayer.new()
	ui_player.name = "UIPlayer"
	ui_player.bus = "UI"
	add_child(ui_player)

	load_settings() 
	apply_volumes() 

	print("AudioManager initilized")

func play_music(track: MUSICTRACK, fade_duration: float =1.0 , loop: bool = true):
	if track == MUSICTRACK.NONE: 
		stop_music(fade_duration) 
		return 
	
	if not music_library.has(track): 
		push_error("Music track not found: " + str(track))
		return
	
	var path = music_library[track] 
	var music_stream = load(path)

	if not music_stream: 
		push_error("Failed to load music: " , path)
		return
	
	next_music_player.stream = music_stream 
	next_music_player.volume_db = linear_to_db(0.0) # start silent for fade in

	if music_stream is AudioStreamOggVorbis:
		music_stream.loop = loop
	elif music_stream is AudioStreamMP3:
		music_stream.loop = loop

	next_music_player.play() 

	if current_music_player.playing: 
		crossfade_music(fade_duration)
	else: 
		fade_in_music(next_music_player, fade_duration) 
	
	var temp = current_music_player 
	current_music_player = next_music_player
	next_music_player = temp 

	print("playing music:", track)


func crossfade_music(duration: float): 
	var tween  = create_tween()
	tween.set_parallel(true) 

	tween.tween_method(
		func(vol): current_music_player.volume_db = linear_to_db(vol * music_volume * master_volume),
		1.0, 0.0, duration
	)

	tween.tween_method(
		func(vol): next_music_player.volume_db = linear_to_db(vol * music_volume * master_volume),
		0.0, 1.0, duration
	)

	tween.finished.connect(func(): current_music_player.stop())

func fade_in_music(player: AudioStreamPlayer, duration: float): 
	var tween = create_tween()
	tween.tween_method(
		func(vol): player.volume_db = linear_to_db(vol * music_volume * master_volume),
		0.0, 1.0, duration
	)

func stop_music(fade_duration: float = 1.0): 
	if current_music_player.playing: 
		var tween = create_tween()
		tween.tween_method(
			func(vol): current_music_player.volume_db = linear_to_db(vol * music_volume * master_volume), 
			1.0, 0.0, fade_duration
		)
		tween.finished.connect(func(): current_music_player.stop())

func pause_music():
	if current_music_player.playing:
		current_music_player.stream_paused = true

func resume_music():
	if current_music_player.stream_paused:
		current_music_player.stream_paused = false

func play_sfx(sound: SFX, volume_multiplier: float = 1.0):
	"""Play sound effect"""
	
	if not sfx_library.has(sound):
		push_error("SFX not found: ", sound)
		return
	
	var path = sfx_library[sound]
	var stream = load(path)
	
	if not stream:
		push_error("Failed to load SFX: ", path)
		return
	
	# Find available player
	var player = get_available_sfx_player()
	
	if not player:
		print("⚠️  SFX pool exhausted!")
		return
	
	# Play sound
	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume * master_volume * volume_multiplier)
	player.play()

func play_ui_sound(sound: SFX):
	"""Play UI sound (uses dedicated player)"""
	
	if not sfx_library.has(sound):
		return
	
	var path = sfx_library[sound]
	var stream = load(path)
	
	if stream:
		ui_player.stream = stream
		ui_player.volume_db = linear_to_db(sfx_volume * master_volume)
		ui_player.play()

func get_available_sfx_player() -> AudioStreamPlayer:
	"""Get an available SFX player from pool"""
	for player in sfx_players:
		if not player.playing:
			return player
	return null

func set_master_volume(volume: float):
	"""Set master volume (0.0 to 1.0)"""
	master_volume = clamp(volume, 0.0, 1.0)
	apply_volumes()
	save_settings()

func set_music_volume(volume: float):
	"""Set music volume (0.0 to 1.0)"""
	music_volume = clamp(volume, 0.0, 1.0)
	apply_volumes()
	save_settings()

func set_sfx_volume(volume: float):
	"""Set SFX volume (0.0 to 1.0)"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	apply_volumes()
	save_settings()

func apply_volumes():
	"""Apply volume settings to audio buses"""
	# Master bus
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(master_volume) if master_volume > 0 else -80
	)
	
	# Music bus
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(music_volume) if music_volume > 0 else -80
	)
	
	# SFX bus
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(sfx_volume) if sfx_volume > 0 else -80
	)

func save_settings():
	"""Save audio settings"""
	var save_data = {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume
	}
	
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_settings():
	"""Load audio settings"""
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		
		master_volume = save_data.get("master_volume", 1.0)
		music_volume = save_data.get("music_volume", 0.8)
		sfx_volume = save_data.get("sfx_volume", 1.0)
		
		file.close()
		print("🔊 Audio settings loaded")



func linear_to_db(linear: float) -> float:
	"""Convert linear volume to decibels"""
	return 20.0 * log(linear) / log(10.0) if linear > 0 else -80.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
