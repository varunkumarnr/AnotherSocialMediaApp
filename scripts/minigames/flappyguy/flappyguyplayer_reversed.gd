extends CharacterBody2D

const GRAVITY: float = -1200.0     
const FLAP_FORCE: float = 650.0    
const MAX_FALL_SPEED: float = -500.0 
const MAX_RISE_SPEED: float = 650.0
const COYOTE_DURATION: float = 0.2

# References
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

# State
var is_dead: bool = false
var coyote_time: float = 0.0

# Constants

# Signals
signal player_died

func _ready():
	if animated_sprite:
		# animated_sprite.flip_v = true
		animated_sprite.play("idle")

func _physics_process(delta):
	if is_dead:
		return
	
	coyote_time -= delta
	
	# Apply gravity
	velocity.y += GRAVITY * delta
	
	# Clamp speeds
	velocity.y = clamp(velocity.y, MAX_FALL_SPEED, MAX_RISE_SPEED)
	
	move_and_slide()
	
	if get_slide_collision_count() > 0:
		die()
	
	update_animation()
	
	if animated_sprite:
		var target_rotation = clamp(velocity.y * -0.0006, -0.4, 0.4)
		animated_sprite.rotation = lerp(animated_sprite.rotation, target_rotation, 0.1)

func _input(event):
	if is_dead:
		return
	
	if event is InputEventScreenTouch and event.pressed:
		flap()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		flap()

func flap():
	AudioManager.play_sfx(AudioManager.SFX.FLAPPY_GUY_FLAP)
	velocity.y = FLAP_FORCE
	coyote_time = COYOTE_DURATION
	
	if animated_sprite:
		animated_sprite.play("jump")

func update_animation():
	if not animated_sprite or is_dead:
		return
	
	if animated_sprite.animation == "jump":
		return
	
	if velocity.y < -200:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")

func reset_game():
	is_dead = false
	velocity = Vector2.ZERO
	rotation = 0
	coyote_time = 0.0
	if animated_sprite:
		animated_sprite.modulate = Color(1, 1, 1)
		# animated_sprite.flip_v = true
		animated_sprite.play("idle")

	await get_tree().process_frame
	set_physics_process(true)

func die():
	if is_dead:
		return
	
	is_dead = true
	emit_signal("player_died")
	
	if animated_sprite:
		animated_sprite.play("idle")
	
	set_physics_process(false)
	
	print("💀 Player died")