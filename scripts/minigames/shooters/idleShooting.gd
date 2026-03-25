extends ShootingTemplate
class_name ShootingGalleryGame

const DUCK_TEX_WHITE  := "res://assets/minigames/sprites/shooters/duck_outline_target_white.png"
const DUCK_TEX_YELLOW := "res://assets/minigames/sprites/shooters/duck_outline_target_yellow.png"
const TARGET_TEX      := "res://assets/minigames/sprites/shooters/target_colored.png"
const GUN_TEX         := "res://assets/minigames/sprites/shooters/rifle.png"
const SHOOT_BUTTON    := "res://assets/minigames/sprites/shooters/button_hexagon.png"

const POINTS_TO_WIN        := 10
const MAX_MISSES           := 3
const DUCK_SIZE            := 160.0
const TARGET_SIZE          := 150.0
const DUCK_SPEED_MIN       := 70.0
const DUCK_SPEED_MAX       := 100.0
const TARGET_LIFETIME      := 5.0
const SPAWN_INTERVAL_START := 1.6
const SPAWN_INTERVAL_MIN   := 0.7

var LANES : Array = []

var score          : int   = 0
var misses         : int   = 0
var targets        : Array = []
var spawn_timer    : float = 0.0
var spawn_interval : float = SPAWN_INTERVAL_START
var game_active    : bool  = false

var score_lbl  : Label
var miss_lbl   : Label
var gun_base   : Control
var gun_barrel : Control

var _gun_pivot : Vector2 = Vector2.ZERO

# Pre-loaded textures
var _duck_white_tex  : Texture2D = null
var _duck_yellow_tex : Texture2D = null
var _target_tex      : Texture2D = null
var _gun_tex         : Texture2D = null

var rng := RandomNumberGenerator.new()

# ── ENTRY ─────────────────────────────────────────────────────────────────────
func on_game_started() -> void:
	rng.randomize()
	play_game_music()
	_load_textures()
	await super.on_game_started()
	_setup_lanes()
	_build_hud()
	_build_gun()
	game_active = true

func _load_textures() -> void:
	if ResourceLoader.exists(DUCK_TEX_WHITE):  _duck_white_tex  = load(DUCK_TEX_WHITE)
	if ResourceLoader.exists(DUCK_TEX_YELLOW): _duck_yellow_tex = load(DUCK_TEX_YELLOW)
	if ResourceLoader.exists(TARGET_TEX):      _target_tex      = load(TARGET_TEX)
	if ResourceLoader.exists(GUN_TEX):         _gun_tex         = load(GUN_TEX)

func _setup_lanes() -> void:
	var top  : float = _content_rect.position.y + 40.0
	var span : float = _content_rect.size.y * 0.55
	var step : float = span / 3.0
	LANES = [
		top + step * 0.5,
		top + step * 1.5,
		top + step * 2.5,
	]

# ── OVERRIDES ─────────────────────────────────────────────────────────────────
func get_background_color() -> Color:
	return Color(0.38, 0.72, 0.95)

func get_crosshair_texture() -> String:
	return ""

func get_action_button_texture() -> String:
	return SHOOT_BUTTON

func get_action_button_label() -> String:
	return "SHOOT"

func get_action_button_color() -> Color:
	return Color(0.88, 0.18, 0.18)

# ── HUD ───────────────────────────────────────────────────────────────────────
func _build_hud() -> void:
	score_lbl = Label.new()
	score_lbl.position = Vector2(_content_rect.position.x + 14, _content_rect.position.y + 10)
	score_lbl.add_theme_font_size_override("font_size", 32)
	score_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	_add_label_shadow(score_lbl)
	score_lbl.text = "0 / %d" % POINTS_TO_WIN
	control_layer.add_child(score_lbl)

	miss_lbl = Label.new()
	miss_lbl.position = Vector2(_content_rect.position.x + 14, _content_rect.position.y + 50)
	miss_lbl.add_theme_font_size_override("font_size", 32)
	miss_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	_add_label_shadow(miss_lbl)
	miss_lbl.text = "0 / %d" % MAX_MISSES
	control_layer.add_child(miss_lbl)

func _add_label_shadow(lbl: Label) -> void:
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))

func _update_hud() -> void:
	if score_lbl: score_lbl.text = "%d / %d" % [score, POINTS_TO_WIN]
	if miss_lbl:  miss_lbl.text  = "%d / %d"  % [misses, MAX_MISSES]

# ── GUN — static base + rotating barrel ──────────────────────────────────────
func _build_gun() -> void:
	const BW  : float = 80.0    # base width
	const BH  : float = 50.0    # base height
	const RW  : float = 28.0    # barrel width
	const RH  : float = 110.0   # barrel height

	var cx : float = _content_rect.get_center().x
	var gy : float = _content_rect.position.y + _content_rect.size.y - BH - 160.0

	# Store pivot in world space so _process can compute angle correctly
	_gun_pivot = Vector2(cx, gy)

	# ── Static base ───────────────────────────────────────────────────────────
	gun_base = Control.new()
	gun_base.size         = Vector2(BW, BH)
	gun_base.position     = Vector2(cx - BW / 2.0, gy)
	gun_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gun_base.z_index      = 5

	gun_base.draw.connect(func():
		if _gun_tex:
			gun_base.draw_texture_rect_region(_gun_tex,
				Rect2(0, 0, BW, BH),
				Rect2(0, _gun_tex.get_height() * 0.55,
					_gun_tex.get_width(), _gun_tex.get_height() * 0.45))
		else:
			# Placeholder: wide trapezoid base
			var pts := PackedVector2Array([
				Vector2(0,      BH),
				Vector2(BW,     BH),
				Vector2(BW*0.8, 0),
				Vector2(BW*0.2, 0),
			])
			gun_base.draw_colored_polygon(pts, Color(0.30, 0.27, 0.22))
			# Grip
			gun_base.draw_rect(Rect2(BW*0.15, BH*0.4, BW*0.22, BH*0.6),
				Color(0.22, 0.18, 0.14))
	)
	control_layer.add_child(gun_base)

	gun_barrel = Control.new()
	gun_barrel.size         = Vector2(RW, RH)
	gun_barrel.position     = Vector2(_gun_pivot.x - RW / 2.0, _gun_pivot.y - RH)
	gun_barrel.pivot_offset = Vector2(RW / 2.0, RH)   # rotate from bottom-centre
	gun_barrel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gun_barrel.z_index      = 6

	gun_barrel.draw.connect(func():
		if _gun_tex:
			gun_barrel.draw_texture_rect_region(_gun_tex,
				Rect2(0, 0, RW, RH),
				Rect2(0, 0, _gun_tex.get_width(), _gun_tex.get_height() * 0.55))
		else:
			# Placeholder barrel
			gun_barrel.draw_rect(Rect2(RW/2 - 7, 0,          14, RH * 0.75),
				Color(0.38, 0.34, 0.28))
			gun_barrel.draw_rect(Rect2(RW/2 - 10, RH * 0.68, 20, RH * 0.32),
				Color(0.28, 0.25, 0.20))
			gun_barrel.draw_arc(Vector2(RW/2, 6), 8, 0, TAU, 16,
				Color(0.5, 0.45, 0.38), 3.0)
	)
	control_layer.add_child(gun_barrel)

func _spawn_target() -> void:
	var is_duck    : bool  = rng.randf() > 0.35
	var sz         : float = DUCK_SIZE if is_duck else TARGET_SIZE
	var lane_y     : float = LANES[rng.randi() % LANES.size()]
	var goes_right : bool  = rng.randf() > 0.5

	var start_x : float
	var vel_x   : float
	if is_duck:
		var spd : float = rng.randf_range(DUCK_SPEED_MIN, DUCK_SPEED_MAX)
		if goes_right:
			start_x = _content_rect.position.x - sz
			vel_x   = spd
		else:
			start_x = _content_rect.position.x + _content_rect.size.x
			vel_x   = -spd
	else:
		start_x = rng.randf_range(
			_content_rect.position.x + sz,
			_content_rect.position.x + _content_rect.size.x - sz)
		vel_x = 0.0

	var lifetime : float = max(TARGET_LIFETIME - score * 0.06, 1.5)

	var td := {
		"is_duck"   : is_duck,
		"pos"       : Vector2(start_x, lane_y),
		"vel_x"     : vel_x,
		"size"      : sz,
		"node"      : null,
		"timer"     : lifetime,
		"max_timer" : lifetime,
		"alive"     : true,
		"hit"       : false,
		"hit_timer" : 0.0,
	}

	var node := _build_target_node(td)
	td["node"] = node
	game_layer.add_child(node)
	targets.append(td)

func _build_target_node(td: Dictionary) -> Control:
	var sz   : float = td["size"]
	var node := Control.new()
	node.size         = Vector2(sz, sz)
	node.position     = td["pos"] - Vector2(sz / 2, sz / 2)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.z_index      = 4

	node.set_meta("facing", 1)   # default facing right
	node.draw.connect(func():
		var alpha  : float = 1.0
		if td["hit"]:
			alpha = max(0.0, 1.0 - td["hit_timer"] * 3.0)

		if td["is_duck"]:
			var tex    : Texture2D = _duck_yellow_tex if _duck_yellow_tex else _duck_white_tex
			var facing : int       = node.get_meta("facing", 1)
			if tex:
				# if facing < 0:
				# 	# Flip horizontally by drawing right-to-left
				# 	node.draw_texture_rect(tex, Rect2(sz, 0, -sz, sz), false, Color(1, 1, 1, alpha))
				# else:
					node.draw_texture_rect(tex, Rect2(0, 0, sz, sz), false, Color(1, 1, 1, alpha))
			else:
				_draw_duck_placeholder(node, sz, alpha)
		else:
			if _target_tex:
				node.draw_texture_rect(_target_tex, Rect2(0, 0, sz, sz), false, Color(1, 1, 1, alpha))
			else:
				_draw_bullseye_placeholder(node, sz, alpha)

		# Countdown bar
		if not td["hit"] and td["timer"] > 0:
			var frac  : float = td["timer"] / td["max_timer"]
			var bar_c : Color = Color(0.15, 0.9, 0.15).lerp(Color(0.9, 0.1, 0.1), 1.0 - frac)
			node.draw_rect(Rect2(0, sz - 6, sz, 6), Color(0, 0, 0, 0.35))
			node.draw_rect(Rect2(0, sz - 6, sz * frac, 6), bar_c)
	)
	return node

func _draw_duck_placeholder(node: Control, sz: float, alpha: float) -> void:
	var col := Color(0.95, 0.82, 0.12, alpha)
	node.draw_circle(Vector2(sz*0.5, sz*0.45), sz*0.38, col)
	node.draw_circle(Vector2(sz*0.72, sz*0.28), sz*0.2, col)
	node.draw_rect(Rect2(sz*0.88, sz*0.24, sz*0.12, sz*0.09), Color(1.0, 0.55, 0.0, alpha))
	node.draw_circle(Vector2(sz*0.76, sz*0.24), sz*0.04, Color(0.1, 0.1, 0.1, alpha))
	node.draw_arc(Vector2(sz*0.5, sz*0.45), sz*0.38, 0, TAU, 32, Color(0.6, 0.4, 0, alpha), 2.0)

func _draw_bullseye_placeholder(node: Control, sz: float, alpha: float) -> void:
	var rings : Array = [
		Color(0.9, 0.1, 0.1, alpha),
		Color(1.0, 1.0, 1.0, alpha),
		Color(0.1, 0.1, 0.85, alpha),
		Color(0.9, 0.1, 0.1, alpha),
	]
	for i in range(rings.size()):
		var r : float = (sz / 2 - 3) * (1.0 - float(i) / rings.size())
		node.draw_circle(Vector2(sz/2, sz/2), r, rings[i])


func on_action(pos: Vector2) -> void:
	if not game_active or is_game_over: return

	var aim : Vector2 = pos

	AudioManager.play_sfx(AudioManager.SFX.GUN_SHOT)

	var hit_any : bool = false
	for td in targets:
		if not td["alive"] or td["hit"]: continue
		var half : float = td["size"] / 2.0
		var rect := Rect2(td["pos"] - Vector2(half, half), Vector2(td["size"], td["size"]))
		if rect.has_point(aim):
			_hit_target(td)
			hit_any = true
			break

	if not hit_any:
		_spawn_shot_fx(aim, false)

func _hit_target(td: Dictionary) -> void:
	td["hit"]       = true
	td["hit_timer"] = 0.0
	score += 1
	_update_hud()
	# AudioManager.play_sfx(AudioManager.SFX.CORRECT)
	_spawn_shot_fx(td["pos"], true)
	if score >= POINTS_TO_WIN:
		game_active = false
		await get_tree().create_timer(0.6).timeout
		win_game()

func _spawn_shot_fx(pos: Vector2, hit: bool) -> void:
	var fx  := Control.new()
	var sz  : float = 60.0
	fx.position     = pos - Vector2(sz/2, sz/2)
	fx.size         = Vector2(sz, sz)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.z_index      = 15
	var t   : float = 0.0
	var col : Color = Color(0.2, 1.0, 0.2) if hit else Color(1.0, 0.2, 0.2)
	fx.draw.connect(func():
		var a : float = 1.0 - t
		if hit:
			fx.draw_circle(Vector2(sz/2, sz/2), sz/2 * t * 1.5,
				Color(col.r, col.g, col.b, a * 0.5))
			fx.draw_arc(Vector2(sz/2, sz/2), sz/2 * (0.3 + t),
				0, TAU, 24, Color(col.r, col.g, col.b, a), 3.0)
		else:
			fx.draw_line(Vector2(6, 6),       Vector2(sz-6, sz-6), Color(col.r, col.g, col.b, a), 4.0)
			fx.draw_line(Vector2(sz-6, 6),    Vector2(6, sz-6),    Color(col.r, col.g, col.b, a), 4.0)
	)
	game_layer.add_child(fx)
	var tw := create_tween()
	tw.tween_method(func(v: float): t = v; fx.queue_redraw(), 0.0, 1.0, 0.35)
	tw.tween_callback(fx.queue_free)

func _process(delta: float) -> void:
	super._process(delta)   
	if not game_active or is_game_over: return

	if gun_barrel:
		var to_crosshair : Vector2 = crosshair_pos - _gun_pivot
		
		var angle : float = atan2(to_crosshair.y, to_crosshair.x) + PI / 2.0
		angle = clamp(angle, -PI * 0.42, PI * 0.42)
		gun_barrel.rotation = angle
		gun_barrel.queue_redraw()

	spawn_timer    += delta
	spawn_interval  = lerp(SPAWN_INTERVAL_START, SPAWN_INTERVAL_MIN,
		float(score) / float(POINTS_TO_WIN))
	if spawn_timer >= spawn_interval and targets.size() < 5:
		spawn_timer = 0.0
		_spawn_target()

	var alive_list : Array = []
	for td in targets:
		if not td["alive"]: continue

		if td["hit"]:
			td["hit_timer"] += delta
			if td["hit_timer"] >= 0.35:
				td["node"].queue_free()
			else:
				td["node"].queue_redraw()
			if td["hit_timer"] < 0.35:
				alive_list.append(td)
			continue

		if td["is_duck"] and td["vel_x"] != 0.0:
			td["pos"].x += td["vel_x"] * delta
			var half : float = td["size"] / 2.0
			td["node"].scale        = Vector2(1, 1)
			td["node"].pivot_offset = Vector2.ZERO
			td["node"].position     = td["pos"] - Vector2(half, half)
			td["node"].set_meta("facing", -1 if td["vel_x"] < 0 else 1)
			td["node"].queue_redraw()

			# Off-screen = miss
			if td["pos"].x < _content_rect.position.x - td["size"] * 2 or \
			   td["pos"].x > _content_rect.position.x + _content_rect.size.x + td["size"] * 2:
				td["alive"] = false
				td["node"].queue_free()
				misses += 1
				_update_hud()
				if misses >= MAX_MISSES:
					game_active = false
					await get_tree().create_timer(0.5).timeout
					fail_game("Too many misses!")
					return
				continue

		# Static target countdown
		if td["vel_x"] == 0.0:
			td["timer"] -= delta
			td["node"].queue_redraw()
			if td["timer"] <= 0:
				td["alive"] = false
				td["node"].queue_free()
				misses += 1
				_update_hud()
				if misses >= MAX_MISSES:
					game_active = false
					await get_tree().create_timer(0.5).timeout
					fail_game("Too many misses!")
					return
				continue

		alive_list.append(td)

	targets = alive_list