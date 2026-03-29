extends MiniGamesTemplate
class_name BasketballGame

const BACKBOARD_TEX := "res://assets/minigames/sprites/basketball/backboard.png"
const BALL_TEX      := "res://assets/minigames/sprites/basketball/ball.png"
const RIM_TEX       := "res://assets/minigames/sprites/basketball/rim.png"

const BASKETS_TO_WIN   := 10
const MISSES_TO_FAIL   := 1000
const BALL_SPRITE_SIZE := 240.0
const BALL_RADIUS      := 120.0
const MAX_PULL_DIST    := 200.0
const GRAVITY          := 900.0    
const MIN_LAUNCH_SPD   := 600.0
const MAX_LAUNCH_SPD   := 1400.0
const ARC_POINTS       := 36
const ARC_STEP_T       := 0.055   
const BALL_Y_FRAC      := 0.78
const SPAWN_X_RANGE    := 400.0

const BASKET_Y_FRAC    := 0.34    

const BOARD_W := 500.0
const BOARD_H := 400.0

const RIM_WORLD_W      := 200.0
const RIM_WORLD_H      := 18.0
const RIM_OPENING_W    := 140.0    

# ── MOVEMENT CONSTANTS (added) ────────────────────────────────────────────────
const MOVE_STARTS_AT     := 9    # basket count that triggers movement
const BASKET_MOVE_SPD    := 60.0   # px/s
const BASKET_MOVE_MARGIN := 60.0    # px from screen edge before turning

var game_layer    : CanvasLayer
var ui_layer      : CanvasLayer

var backboard_node : CanvasItem   
var rim_node       : CanvasItem
var ball_sprite    : Sprite2D
var arc_draw       : Control

var score_lab    : Label
var miss_label     : Label
var feedback_label : Label

enum BallState { IDLE, PULLING, FLYING, SCORING, RESETTING }

var ball_state    : BallState = BallState.IDLE
var ball_origin   : Vector2   = Vector2.ZERO
var ball_pos      : Vector2   = Vector2.ZERO
var ball_pos_prev : Vector2   = Vector2.ZERO
var ball_vel      : Vector2   = Vector2.ZERO

var pull_start   : Vector2 = Vector2.ZERO
var pull_current : Vector2 = Vector2.ZERO
var touch_idx    : int     = -1

var baskets    : int = 0
var misses     : int = 0
var shot_count : int = 0

var basket_centre : Vector2 = Vector2.ZERO
var rim_y         : float   = 0.0
var rim_open_l    : float   = 0.0
var rim_open_r    : float   = 0.0

var backboard_world_y : float = 0.0
var bounce_count  = 0
const MAX_BOUNCES = 5

# ── MOVEMENT STATE (added) ────────────────────────────────────────────────────
var basket_moving   : bool  = false
var basket_dir      : float = 1.0    # +1 right, -1 left
var vp_width        : float = 0.0

var rng := RandomNumberGenerator.new()

func on_game_started() -> void:
	rng.randomize()
	play_game_music()
	await get_tree().process_frame

	game_layer       = CanvasLayer.new()
	game_layer.layer = 1
	add_child(game_layer)

	add_child(TCBackground.new())

	ui_layer       = CanvasLayer.new()
	ui_layer.layer = 2
	add_child(ui_layer)

	_build_scene()
	_build_hud()

func _build_scene() -> void:
	var vp : Vector2 = get_viewport().get_visible_rect().size
	vp_width = vp.x  # (added) store for movement bounds
	basket_centre     = Vector2(vp.x * 0.5, vp.y * BASKET_Y_FRAC)
	backboard_world_y = basket_centre.y + (BOARD_H * 0.16)

	if ResourceLoader.exists(BACKBOARD_TEX):
		var sp        := Sprite2D.new()
		sp.texture     = load(BACKBOARD_TEX)
		var tsize      : Vector2 = sp.texture.get_size()
		var sc         : float   = BOARD_W / max(tsize.x, 1.0)
		sp.scale       = Vector2(sc, sc)
		sp.position    = Vector2(basket_centre.x,
								 backboard_world_y - (tsize.y * sc) * 0.5)
		sp.z_index     = 1
		backboard_node = sp
		game_layer.add_child(sp)
	else:
		var c := _make_draw_node(vp)
		c.draw.connect(func():
			var bx : float = basket_centre.x - BOARD_W * 0.5
			var by : float = backboard_world_y - BOARD_H
			c.draw_rect(Rect2(bx, by, BOARD_W, BOARD_H),
						Color(0.72, 0.72, 0.72))
			c.draw_rect(Rect2(bx, by, BOARD_W, BOARD_H),
						Color(0.1, 0.1, 0.1), false, 4.0)
			var iw : float = BOARD_W * 0.42
			var ih : float = BOARD_H * 0.38
			var ix : float = basket_centre.x - iw * 0.5
			var iy : float = by + BOARD_H * 0.35
			c.draw_rect(Rect2(ix, iy, iw, ih), Color(1, 1, 1, 0.0))
			c.draw_rect(Rect2(ix, iy, iw, ih), Color(1, 1, 1), false, 3.0)
		)
		backboard_node = c
		game_layer.add_child(c)

	if ResourceLoader.exists(RIM_TEX):
		var rsp       := Sprite2D.new()
		rsp.texture    = load(RIM_TEX)
		var rtsize     : Vector2 = rsp.texture.get_size()
		rsp.scale      = Vector2(RIM_WORLD_W / max(rtsize.x, 1.0),
								 RIM_WORLD_H / max(rtsize.y, 1.0))
		rsp.position   = basket_centre
		rsp.z_index    = 3
		rim_node       = rsp
		game_layer.add_child(rsp)
	else:
		var c := _make_draw_node(vp)
		c.draw.connect(func():
			var rx : float = basket_centre.x - RIM_WORLD_W * 0.5
			var ry : float = basket_centre.y - RIM_WORLD_H * 0.5
			c.draw_rect(Rect2(rx, ry, RIM_WORLD_W, RIM_WORLD_H),
						Color(0.95, 0.25, 0.1))
			c.draw_rect(Rect2(rx, ry, RIM_WORLD_W, RIM_WORLD_H),
						Color(0.7, 0.1, 0.0), false, 3.0)
		)
		rim_node = c
		game_layer.add_child(c)

	# Cache rim physics geometry
	rim_y      = basket_centre.y
	rim_open_l = basket_centre.x - RIM_OPENING_W * 0.5
	rim_open_r = basket_centre.x + RIM_OPENING_W * 0.5

	ball_sprite = Sprite2D.new()
	if ResourceLoader.exists(BALL_TEX):
		ball_sprite.texture = load(BALL_TEX)
		var btsize  : Vector2 = ball_sprite.texture.get_size()
		ball_sprite.scale = Vector2.ONE * (BALL_SPRITE_SIZE / max(btsize.x, 1.0))
	else:
		pass   

	ball_origin          = Vector2(vp.x * 0.5, vp.y * BALL_Y_FRAC)
	ball_pos             = ball_origin
	ball_pos_prev        = ball_origin
	ball_sprite.position = ball_origin
	ball_sprite.z_index  = 2
	game_layer.add_child(ball_sprite)

	arc_draw              = Control.new()
	arc_draw.size         = vp
	arc_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arc_draw.z_index      = 10
	arc_draw.draw.connect(_draw_arc_overlay)
	ui_layer.add_child(arc_draw)

func _make_draw_node(vp: Vector2) -> Control:
	var c             := Control.new()
	c.size             = vp
	c.mouse_filter     = Control.MOUSE_FILTER_IGNORE
	return c

func _build_hud() -> void:
	var vp : Vector2 = get_viewport().get_visible_rect().size

	# score_lab          = Label.new()
	# score_lab.text     = "0 / %d" % BASKETS_TO_WIN
	# score_lab.position = Vector2(20.0, 90.0)
	# score_lab.add_theme_font_size_override("font_size", 34)
	# score_lab.modulate = Color(1.0, 0.85, 0.2)
	# ui_layer.add_child(score_lab)

	# miss_label          = Label.new()
	# miss_label.text     = "0 / %d" % MISSES_TO_FAIL
	# miss_label.position = Vector2(vp.x - 200.0, 90.0)
	# miss_label.add_theme_font_size_override("font_size", 34)
	# miss_label.modulate = Color(1.0, 0.35, 0.35)
	# ui_layer.add_child(miss_label)

	feedback_label          = Label.new()
	feedback_label.text     = ""
	feedback_label.position = Vector2(vp.x * 0.5 - 120.0, vp.y * 0.50)
	feedback_label.add_theme_font_size_override("font_size", 52)
	feedback_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	ui_layer.add_child(feedback_label)

func _input(event: InputEvent) -> void:
	if is_game_over \
			or ball_state == BallState.FLYING \
			or ball_state == BallState.SCORING \
			or ball_state == BallState.RESETTING:
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed: _on_press(st.index, st.position)
		else:          _on_release(st.index)
		return
	if event is InputEventScreenDrag:
		_on_drag((event as InputEventScreenDrag).index,
				 (event as InputEventScreenDrag).position)
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed: _on_press(0, mb.global_position)
			else:          _on_release(0)
		return
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_on_drag(0, (event as InputEventMouseMotion).global_position)

func _on_press(idx: int, pos: Vector2) -> void:
	if touch_idx != -1: return
	if pos.distance_to(ball_pos) > BALL_RADIUS * 2.8: return
	touch_idx    = idx
	pull_start   = pos
	pull_current = pos
	ball_state   = BallState.PULLING

func _on_drag(idx: int, pos: Vector2) -> void:
	if idx != touch_idx or ball_state != BallState.PULLING: return
	pull_current = pos
	arc_draw.queue_redraw()

func _on_release(idx: int) -> void:
	if idx != touch_idx or ball_state != BallState.PULLING: return
	touch_idx = -1

	var pull_vec : Vector2 = pull_start - pull_current
	if pull_vec.length() < 12.0:
		ball_state = BallState.IDLE
		arc_draw.queue_redraw()
		return

	pull_vec    = pull_vec.normalized() * min(pull_vec.length(), MAX_PULL_DIST)
	var power   : float = pull_vec.length() / MAX_PULL_DIST
	ball_vel    = pull_vec.normalized() * lerp(MIN_LAUNCH_SPD, MAX_LAUNCH_SPD, power)

	ball_pos      = ball_origin
	ball_pos_prev = ball_origin
	ball_state    = BallState.FLYING
	shot_count   += 1
	bounce_count  = 0
	arc_draw.queue_redraw()

func _draw_arc_overlay() -> void:
	if ball_state != BallState.PULLING: return

	var pull_vec : Vector2 = pull_start - pull_current
	pull_vec = pull_vec.normalized() * min(pull_vec.length(), MAX_PULL_DIST)
	if pull_vec.length() < 12.0: return

	var power : float   = pull_vec.length() / MAX_PULL_DIST
	var vel   : Vector2 = pull_vec.normalized() * lerp(MIN_LAUNCH_SPD, MAX_LAUNCH_SPD, power)

	var prev_pt : Vector2 = ball_origin
	for i in range(1, ARC_POINTS + 1):
		var t  : float   = i * ARC_STEP_T
		var pt : Vector2 = Vector2(
			ball_origin.x + vel.x * t,
			ball_origin.y + vel.y * t + 0.5 * GRAVITY * t * t)

		if pt.y > get_viewport().get_visible_rect().size.y: break

		if i % 2 == 0:
			var alpha : float = lerp(0.9, 0.1, float(i) / float(ARC_POINTS))
			arc_draw.draw_circle(pt, 5.5, Color(1.0, 0.85, 0.2, alpha))
		prev_pt = pt

	arc_draw.draw_line(ball_origin,
					   ball_origin + pull_vec * 0.5,
					   Color(1.0, 1.0, 1.0, 0.8), 3.5)

func _process(delta: float) -> void:
	if is_game_over or not is_game_active: return
	if baskets < MOVE_STARTS_AT: 
		basket_moving = false
		# return

	# ── MOVEMENT (added) ──────────────────────────────────────────────────────
	if basket_moving:
		basket_centre.x += basket_dir * BASKET_MOVE_SPD * delta

		var left_limit  : float = BASKET_MOVE_MARGIN + BOARD_W * 0.5
		var right_limit : float = vp_width - BASKET_MOVE_MARGIN - BOARD_W * 0.5

		if basket_centre.x >= right_limit:
			basket_centre.x = right_limit
			basket_dir = -1.0
		elif basket_centre.x <= left_limit:
			basket_centre.x = left_limit
			basket_dir = 1.0

		# Move the actual sprite nodes
		backboard_world_y = basket_centre.y + (BOARD_H * 0.16)
		if backboard_node is Sprite2D:
			var tsize : Vector2 = (backboard_node as Sprite2D).texture.get_size()
			var sc    : float   = (backboard_node as Sprite2D).scale.x
			(backboard_node as Sprite2D).position = Vector2(
				basket_centre.x,
				backboard_world_y - (tsize.y * sc) * 0.5)
		else:
			(backboard_node as Control).queue_redraw()

		if rim_node is Sprite2D:
			(rim_node as Sprite2D).position = basket_centre
		else:
			(rim_node as Control).queue_redraw()

		# Keep collision geometry in sync
		rim_y      = basket_centre.y
		rim_open_l = basket_centre.x - RIM_OPENING_W * 0.5
		rim_open_r = basket_centre.x + RIM_OPENING_W * 0.5
	# ── END MOVEMENT ──────────────────────────────────────────────────────────

	if ball_state == BallState.FLYING:
		_tick_flight(delta)

func _tick_flight(delta: float) -> void:
	ball_pos_prev  = ball_pos
	ball_vel.y    += GRAVITY * delta
	ball_pos      += ball_vel * delta

	var full_dist  : float = ball_origin.y - basket_centre.y
	var current_up : float = ball_origin.y - ball_pos.y
	var depth_t    : float = clamp(current_up / max(full_dist, 1.0), 0.0, 1.0)

	if ball_sprite.texture:
		var base_sc : float = BALL_SPRITE_SIZE / max(ball_sprite.texture.get_size().x, 1.0)
		ball_sprite.scale   = Vector2.ONE * base_sc * lerp(1.0, 0.38, depth_t)

	ball_sprite.z_index  = 4 if ball_pos.y > rim_y else 2
	ball_sprite.position = ball_pos
	ball_sprite.rotation += delta * 8.0

	_check_rim_crossing()

	var vp : Vector2 = get_viewport().get_visible_rect().size
	if ball_pos.y > vp.y + 120.0 or ball_pos.x < -140.0 or ball_pos.x > vp.x + 140.0:
		_register_miss()

func _check_rim_crossing() -> void:
	if ball_vel.y <= 0.0: return
	if not (ball_pos_prev.y < rim_y and ball_pos.y >= rim_y): return

	var t_c     : float = (rim_y - ball_pos_prev.y) / (ball_pos.y - ball_pos_prev.y)
	var cross_x : float = ball_pos_prev.x + t_c * (ball_pos.x - ball_pos_prev.x)

	var open_l : float = rim_open_l + BALL_RADIUS * 0.3
	var open_r : float = rim_open_r - BALL_RADIUS * 0.3

	if cross_x >= open_l and cross_x <= open_r:
		var cx     : float = (open_l + open_r) * 0.5
		var half_w : float = (open_r - open_l) * 0.5
		var off    : float = abs(cross_x - cx) / max(half_w, 1.0)
		if off < 0.22:
			_register_basket(true)
		elif off < 0.78:
			_register_basket(false)
		else:
			_bounce_off_rim(cross_x < cx)
	else:
		var near_l : bool = cross_x >= rim_open_l - 8.0 and cross_x < open_l
		var near_r : bool = cross_x <= rim_open_r + 8.0 and cross_x > open_r
		if near_l or near_r:
			_bounce_off_rim(near_l)

func _bounce_off_rim(hit_left: bool) -> void:
	bounce_count += 1
 
	if bounce_count >= MAX_BOUNCES:
		_register_miss()
		return

	ball_vel.x  = abs(ball_vel.x) * (1.0 if hit_left else 1.0) * 1
	ball_vel.y *= -1.0
	ball_vel.y  = min(ball_vel.y, -50.0)
	

func _register_basket(swish: bool) -> void:
	if ball_state != BallState.FLYING: return
	ball_state = BallState.SCORING
	baskets   += 1
	add_score()
	# _update_hud()
	AudioManager.play_sfx(AudioManager.SFX.CORRECT)
	_flash_feedback("🔥 KOBE!" if swish else "🏀 HIT!", Color(1.0, 0.85, 0.2))

	# ── START MOVING at threshold (added) ─────────────────────────────────────
	if baskets == MOVE_STARTS_AT and not basket_moving:
		basket_moving = true
		_flash_feedback("🏀 IT'S MOVING!", Color(1.0, 0.5, 0.1))

	var tw := create_tween()
	tw.tween_property(ball_sprite, "position:y", rim_y + 80.0, 0.22)
	tw.tween_property(ball_sprite, "modulate:a", 0.0, 0.18)
	await tw.finished

	if baskets >= BASKETS_TO_WIN:
		await get_tree().create_timer(0.3).timeout
		win_game()
		return
	_reset_ball()

func _register_miss() -> void:
	if ball_state != BallState.FLYING: return
	ball_state = BallState.RESETTING
	misses    += 1
	if(baskets > 0):
		baskets -=1
		add_score(-1)
	
	# _update_hud()
	AudioManager.play_sfx(AudioManager.SFX.WRONG)
	_flash_feedback("MISS!", Color(1.0, 0.3, 0.3))

	await get_tree().create_timer(0.55).timeout

	if misses >= MISSES_TO_FAIL:
		fail_game("Too many misses! Try again.")
		return
	_reset_ball()

func _reset_ball() -> void:
	var vp : Vector2 = get_viewport().get_visible_rect().size

	ball_origin.y = vp.y * BALL_Y_FRAC
	ball_origin.x = vp.x * 0.5 if shot_count <= 1 \
		else vp.x * 0.5 + rng.randf_range(-SPAWN_X_RANGE, SPAWN_X_RANGE)

	ball_pos             = ball_origin
	ball_pos_prev        = ball_origin
	ball_sprite.position = ball_origin
	ball_sprite.modulate = Color(1, 1, 1, 1)
	ball_sprite.rotation = 0.0
	ball_state           = BallState.IDLE

	if ball_sprite.texture:
		var base_sc : float = BALL_SPRITE_SIZE / max(ball_sprite.texture.get_size().x, 1.0)
		ball_sprite.scale   = Vector2.ONE * base_sc

	arc_draw.queue_redraw()

# func _update_hud() -> void:
# 	score_lab.text = "%d / %d" % [baskets, BASKETS_TO_WIN]
# 	miss_label.text  = "%d / %d" % [misses,  MISSES_TO_FAIL]

func _flash_feedback(msg: String, col: Color) -> void:
	feedback_label.text     = msg
	feedback_label.modulate = Color(col.r, col.g, col.b, 1.0)
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.tween_property(feedback_label, "modulate:a", 0.0, 0.4)
