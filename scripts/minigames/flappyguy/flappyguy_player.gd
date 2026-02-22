extends CharacterBody2D

const GRAVITY: float = 1200.0     
const FLAP_FORCE: float = -600.0    
const MAX_FALL_SPEED: float = 800.0 
const MAX_RISE_SPEED: float = -700.0

# References
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
# State
var is_dead: bool = false

# Signals
signal player_died

func _ready():
	if animated_sprite:
		animated_sprite.play("idle")

func _physics_process(delta):
	if is_dead:
		return
	
	# Apply gravity
	velocity.y += GRAVITY * delta
	
	# Clamp speeds
	velocity.y = clamp(velocity.y, MAX_RISE_SPEED, MAX_FALL_SPEED)
	
	move_and_slide()
	
	if get_slide_collision_count() > 0:
		die()
	
	update_animation()
	
	if animated_sprite:
		var target_rotation = clamp(velocity.y * 0.0006, -0.4, 0.4)
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
	"""Make the player jump"""
	velocity.y = FLAP_FORCE
	
	# Play jump animation
	if animated_sprite:
		animated_sprite.play("jump")

func update_animation():
	if not animated_sprite or is_dead:
		return
	
	if animated_sprite.animation == "jump":
		return
	
	# Use walk when falling
	if velocity.y > 200:
		animated_sprite.play("walk")
	elif velocity.y < 100:
		animated_sprite.play("idle")

func reset_game():
	is_dead = false
	velocity = Vector2.ZERO
	rotation = 0
	animated_sprite.modulate = Color(1, 1, 1)
	animated_sprite.play("idle")

	await get_tree().process_frame
	set_physics_process(true)

func die():
	if is_dead:
		return
	
	is_dead = true
	emit_signal("player_died")
	
	# Visual feedback
	if animated_sprite:
		animated_sprite.play("idle")
		# animated_sprite.modulate = Color(1, 0.3, 0.3)
	
	# Stop physics
	set_physics_process(false)
	
	print("💀 Player died")