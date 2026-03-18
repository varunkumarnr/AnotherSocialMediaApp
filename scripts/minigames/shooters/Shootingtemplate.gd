# ── ShootingTemplate ──────────────────────────────────────────────────────────
# Base class for any "aim and fire" game.
# Crosshair + action button live in the GAME layer — not UI.
# Subclass and override:
#   get_background_color()        → Color
#   get_crosshair_texture()       → String path (or "" for default drawn crosshair)
#   get_action_button_texture()   → String path (or "" for default red circle)
#   get_action_button_label()     → String shown on button when no texture
#   build_game_content()          → called after base nodes are ready, add your content here
#   on_action(pos: Vector2)       → called when action button pressed (shoot/throw/etc)
# ─────────────────────────────────────────────────────────────────────────────
extends MiniGamesTemplate
class_name ShootingTemplate

signal action_fired(position: Vector2)
signal joystick_moved(direction: Vector2)

# ── CONFIG — override in subclass if needed ───────────────────────────────────
const CROSSHAIR_SPEED  := 500.0
const CROSSHAIR_SIZE   := 90.0
const JOYSTICK_RADIUS  := 140.0
const JOYSTICK_KNOB_R  := 50.0
const ACTION_BTN_SIZE  := 180.0

var game_layer    : CanvasLayer   # subclass adds content here
var control_layer : CanvasLayer   # crosshair + joystick + action btn

# ── NODES ─────────────────────────────────────────────────────────────────────
var crosshair_node  : Control
var joystick_base   : Control
var joystick_knob   : Control
var action_btn_node : Control

# ── STATE ─────────────────────────────────────────────────────────────────────
var crosshair_pos   : Vector2 = Vector2.ZERO
var joy_dir         : Vector2 = Vector2.ZERO
var joy_touch_idx   : int     = -1
var act_touch_idx   : int     = -1
var _content_rect   : Rect2   = Rect2()

# ── ENTRY ─────────────────────────────────────────────────────────────────────
func on_game_started() -> void:
	await get_tree().process_frame
	_measure_content()

	# Game content layer
	game_layer       = CanvasLayer.new()
	game_layer.layer = 1
	add_child(game_layer)

	add_child(TCBackground.new()) 

	# Background
	# var bg := ColorRect.new()
	# bg.color    = get_background_color()
	# bg.position = _content_rect.position
	# bg.size     = _content_rect.size
	# game_layer.add_child(bg)

	# Controls layer — same space as game, drawn on top
	control_layer       = CanvasLayer.new()
	control_layer.layer = 2
	add_child(control_layer)

	# Let subclass add its content first
	await build_game_content()

	# Then place controls on top
	_build_joystick()
	_build_action_button()
	_build_crosshair()

	crosshair_pos = _content_rect.get_center()   # stored as centre point

func _measure_content() -> void:
	var vp      : Vector2 = get_viewport().get_visible_rect().size
	var top_bar           = get_node_or_null("GameUI/MarginContainer/VBoxContainer/TopBar")
	var top_y   : float   = 100.0
	if top_bar:
		top_y = top_bar.global_position.y + top_bar.size.y
	_content_rect = Rect2(0, top_y, vp.x, vp.y - top_y)

# ── CROSSHAIR ─────────────────────────────────────────────────────────────────
func _build_crosshair() -> void:
	crosshair_node = Control.new()
	crosshair_node.size         = Vector2(CROSSHAIR_SIZE, CROSSHAIR_SIZE)
	crosshair_node.pivot_offset = Vector2(CROSSHAIR_SIZE / 2, CROSSHAIR_SIZE / 2)
	crosshair_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair_node.z_index      = 20

	var tex_path : String = get_crosshair_texture()
	crosshair_node.draw.connect(func():
		if tex_path != "" and ResourceLoader.exists(tex_path):
			var tex : Texture2D = load(tex_path)
			crosshair_node.draw_texture_rect(tex,
				Rect2(0, 0, CROSSHAIR_SIZE, CROSSHAIR_SIZE), false)
		else:
			_draw_default_crosshair()
	)
	control_layer.add_child(crosshair_node)

func _draw_default_crosshair() -> void:
	var c   := Vector2(CROSSHAIR_SIZE / 2, CROSSHAIR_SIZE / 2)
	var r   : float = CROSSHAIR_SIZE / 2 - 4
	var col : Color = Color(1, 0.08, 0.08, 0.92)
	var w   : float = 2.5
	var gap : float = 9.0
	crosshair_node.draw_arc(c, r, 0, TAU, 48, col, w)
	crosshair_node.draw_line(Vector2(c.x - r, c.y),   Vector2(c.x - gap, c.y), col, w)
	crosshair_node.draw_line(Vector2(c.x + gap, c.y), Vector2(c.x + r, c.y),   col, w)
	crosshair_node.draw_line(Vector2(c.x, c.y - r),   Vector2(c.x, c.y - gap), col, w)
	crosshair_node.draw_line(Vector2(c.x, c.y + gap), Vector2(c.x, c.y + r),   col, w)
	crosshair_node.draw_circle(c, 3.0, col)

# ── JOYSTICK ──────────────────────────────────────────────────────────────────
func _build_joystick() -> void:
	var cx : float = _content_rect.position.x + 200.0
	var cy : float = _content_rect.position.y + _content_rect.size.y - 200.0

	joystick_base = Control.new()
	joystick_base.size         = Vector2(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2)
	joystick_base.position     = Vector2(cx - JOYSTICK_RADIUS, cy - JOYSTICK_RADIUS)
	joystick_base.pivot_offset = Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)
	joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.draw.connect(func():
		var c := Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)
		joystick_base.draw_circle(c, JOYSTICK_RADIUS - 2, Color(0, 0, 0, 0.22))
		joystick_base.draw_arc(c, JOYSTICK_RADIUS - 2, 0, TAU, 48, Color(1,1,1,0.3), 3.0)
	)
	control_layer.add_child(joystick_base)

	joystick_knob = Control.new()
	joystick_knob.size         = Vector2(JOYSTICK_KNOB_R * 2, JOYSTICK_KNOB_R * 2)
	joystick_knob.position     = joystick_base.position + \
		Vector2(JOYSTICK_RADIUS - JOYSTICK_KNOB_R, JOYSTICK_RADIUS - JOYSTICK_KNOB_R)
	joystick_knob.pivot_offset = Vector2(JOYSTICK_KNOB_R, JOYSTICK_KNOB_R)
	joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_knob.draw.connect(func():
		var c := Vector2(JOYSTICK_KNOB_R, JOYSTICK_KNOB_R)
		joystick_knob.draw_circle(c, JOYSTICK_KNOB_R, Color(1, 1, 1, 0.6))
		joystick_knob.draw_arc(c, JOYSTICK_KNOB_R - 1, 0, TAU, 32, Color(1,1,1,0.9), 2.5)
	)
	control_layer.add_child(joystick_knob)

func _build_action_button() -> void:
	var vp    : Vector2 = get_viewport().get_visible_rect().size
	var bx    : float   = vp.x - ACTION_BTN_SIZE - 28.0
	var by    : float   = _content_rect.position.y + _content_rect.size.y - ACTION_BTN_SIZE - 100.0

	action_btn_node = Control.new()
	action_btn_node.size         = Vector2(ACTION_BTN_SIZE, ACTION_BTN_SIZE)
	action_btn_node.position     = Vector2(bx, by)
	action_btn_node.pivot_offset = Vector2(ACTION_BTN_SIZE / 2, ACTION_BTN_SIZE / 2)
	action_btn_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_btn_node.z_index      = 20

	var tex_path  : String   = get_action_button_texture()
	var _btn_tex  : Texture2D = null
	if tex_path != "" and ResourceLoader.exists(tex_path):
		_btn_tex = load(tex_path)

	action_btn_node.draw.connect(func():
		var c := Vector2(ACTION_BTN_SIZE / 2, ACTION_BTN_SIZE / 2)
		var r : float = ACTION_BTN_SIZE / 2 - 4
		if _btn_tex:
			action_btn_node.draw_texture_rect(_btn_tex,
				Rect2(0, 0, ACTION_BTN_SIZE, ACTION_BTN_SIZE), false)
		else:
			action_btn_node.draw_circle(c, r, get_action_button_color())
			action_btn_node.draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.5), 3.5)
	)
	control_layer.add_child(action_btn_node)

# ── INPUT ─────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if is_game_over: return

	var press_pos  : Vector2 = Vector2.ZERO
	var release_idx: int     = -1
	var drag_idx   : int     = -1
	var drag_pos   : Vector2 = Vector2.ZERO
	var is_press   : bool    = false

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			press_pos = st.position; is_press = true
			_handle_press(st.index, press_pos)
		else:
			_handle_release(st.index)
		return

	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		_handle_drag(sd.index, sd.position)
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_handle_press(0, mb.global_position)
			else:
				_handle_release(0)
		return

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_handle_drag(0, (event as InputEventMouseMotion).global_position)

func _handle_press(idx: int, pos: Vector2) -> void:
	var mid : float = get_viewport().get_visible_rect().size.x / 2.0

	if pos.x < mid:
		# Left half — joystick
		if joy_touch_idx == -1:
			joy_touch_idx = idx
			_update_joystick(pos)
	else:
		# Right half — action button
		if act_touch_idx == -1:
			act_touch_idx = idx
			_trigger_action()

func _handle_release(idx: int) -> void:
	if idx == joy_touch_idx:
		joy_touch_idx = -1
		joy_dir       = Vector2.ZERO
		_reset_joystick()
	if idx == act_touch_idx:
		act_touch_idx = -1

func _handle_drag(idx: int, pos: Vector2) -> void:
	if idx == joy_touch_idx:
		_update_joystick(pos)

func _update_joystick(touch_pos: Vector2) -> void:
	var base_c : Vector2 = joystick_base.position + Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)
	var delta  : Vector2 = touch_pos - base_c
	var max_r  : float   = JOYSTICK_RADIUS - JOYSTICK_KNOB_R
	var clamped: Vector2 = delta.normalized() * min(delta.length(), max_r)

	joystick_knob.position = base_c - Vector2(JOYSTICK_KNOB_R, JOYSTICK_KNOB_R) + clamped
	joystick_knob.queue_redraw()
	joy_dir = clamped / max_r
	joystick_moved.emit(joy_dir)

func _reset_joystick() -> void:
	var base_c : Vector2 = joystick_base.position + Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)
	joystick_knob.position = base_c - Vector2(JOYSTICK_KNOB_R, JOYSTICK_KNOB_R)
	joystick_knob.queue_redraw()
	joy_dir = Vector2.ZERO

func _trigger_action() -> void:
	# Brief scale-down feedback
	action_btn_node.scale = Vector2(0.87, 0.87)
	action_btn_node.queue_redraw()
	get_tree().create_timer(0.08).timeout.connect(func():
		if action_btn_node:
			action_btn_node.scale = Vector2(1.0, 1.0)
			action_btn_node.queue_redraw()
	)
	action_fired.emit(crosshair_pos)
	on_action(crosshair_pos)

# ── PROCESS ───────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if is_game_over or not is_game_active: return

	if joy_dir.length() > 0.04:
		crosshair_pos += joy_dir * CROSSHAIR_SPEED * delta
		# Clamp centre point so crosshair stays fully inside content area
		crosshair_pos.x = clamp(crosshair_pos.x,
			_content_rect.position.x + CROSSHAIR_SIZE / 2.0,
			_content_rect.position.x + _content_rect.size.x - CROSSHAIR_SIZE / 2.0)
		crosshair_pos.y = clamp(crosshair_pos.y,
			_content_rect.position.y + CROSSHAIR_SIZE / 2.0,
			_content_rect.position.y + _content_rect.size.y - CROSSHAIR_SIZE / 2.0)

	if crosshair_node:
		# crosshair_pos = centre of crosshair; node.position = top-left
		crosshair_node.position = crosshair_pos - Vector2(CROSSHAIR_SIZE / 2.0, CROSSHAIR_SIZE / 2.0)
		crosshair_node.queue_redraw()

# ── OVERRIDABLE ───────────────────────────────────────────────────────────────
func get_background_color() -> Color:
	return Color(0.15, 0.52, 0.22)

func get_crosshair_texture() -> String:
	return ""   # "" = draw default red crosshair

func get_action_button_texture() -> String:
	return ""   # "" = draw default coloured circle

func get_action_button_label() -> String:
	return "FIRE"   # shown as hint; override for "THROW", "SHOOT" etc

func get_action_button_color() -> Color:
	return Color(0.85, 0.15, 0.15)   # red for shooting; override for basketball etc

func build_game_content() -> void:
	pass   # subclass adds nodes to game_layer here

func on_action(_pos: Vector2) -> void:
	pass   # called every time the action button is pressed