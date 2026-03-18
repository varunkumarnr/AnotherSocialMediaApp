extends ShootingGalleryGame
class_name PulsingGalleryGame

const PULSE_SPEED := 0.4
const PULSE_MIN   := 0.2
const PULSE_MAX   := 1.0

func _spawn_target() -> void:
	super._spawn_target()
	if targets.size() > 0:
		targets[-1]["pulse_t"]     = randf() * TAU
		targets[-1]["pulse_scale"] = 1.0 

func on_action(pos: Vector2) -> void:
	if not game_active or is_game_over: return

	var aim : Vector2 = pos
	var hit_any : bool = false

	for td in targets:
		if not td["alive"] or td["hit"]: continue

		# Use pulse_scale to shrink the hitbox — same as visual
		var s    : float = td.get("pulse_scale", 1.0)
		var half : float = (td["size"] * s) / 2.0
		var rect := Rect2(td["pos"] - Vector2(half, half), Vector2(td["size"] * s, td["size"] * s))
		if rect.has_point(aim):
			_hit_target(td)
			hit_any = true
			break

	if not hit_any:
		_spawn_shot_fx(aim, false)

func _process(delta: float) -> void:
	super._process(delta)

	for td in targets:
		if not td["alive"] or td["hit"]: continue
		if not td.has("pulse_t"): continue

		td["pulse_t"] += delta * PULSE_SPEED * TAU
		var s : float = lerp(PULSE_MIN, PULSE_MAX, (sin(td["pulse_t"]) + 1.0) / 2.0)

		td["pulse_scale"] = s

		var node : Control = td["node"]
		if node:
			node.scale        = Vector2(s, s)
			node.pivot_offset = Vector2(td["size"] / 2.0, td["size"] / 2.0)