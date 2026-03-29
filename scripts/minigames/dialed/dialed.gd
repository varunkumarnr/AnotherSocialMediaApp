extends "res://scripts/core/miniGamesTemplate.gd"
class_name ColorGame

const TOTAL_ROUNDS  := 5
const PASS_AVG      := 8.0
const MEMORIZE_SECS := 4.0

var popup         : GamePopup
var round_num     : int   = 0
var scores        : Array = []
var target_color  : Color = Color.WHITE
var memorize_t    : float = 0.0
var game_active   : bool  = false

var _hsv     : Array = [0.55, 0.60, 0.65]
var _drag_idx: int   = -1

enum Phase { MEMORIZE, PICK, RESULT }
var phase : Phase = Phase.MEMORIZE

# Node refs
var _content_root : Control = null   # parent for phase content
var _preview_node : Control = null   # redrawn every slider move
var _sliders      : Array   = []     # 3 Control nodes
var _timer_big    : Label   = null
var _timer_small  : Label   = null

var rng := RandomNumberGenerator.new()

# ── ENTRY ─────────────────────────────────────────────────────────────────────
func on_game_started() -> void:
	rng.randomize()
	await get_tree().process_frame
	await _build_popup()
	game_active = true
	await _start_round()

func _build_popup() -> void:
	var vp   := get_viewport().get_visible_rect().size
	var pw   : int = int(vp.x * 0.66)
	var ph   : int = int(vp.y * 0.50)

	var config               := PopupConfig.new()
	config.title             = "COLOR MEMORY"
	config.panel_color       = "grey"
	config.show_close_button = false
	config.popup_width       = pw
	config.popup_height      = ph
	config.content_rows      = []
	config.buttons           = []

	popup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)
	add_child(TCBackground.new())

	await get_tree().process_frame
	await get_tree().process_frame

	# Hide the empty button bar — it renders as a white strip at the bottom
	var btn_margin = popup.get_node_or_null("Control/CenterContainer/Panel/VBoxContainer/ButtonMargin")
	if btn_margin: btn_margin.visible = false

	# Style the panel to match game aesthetic
	var main_panel : Panel = popup.get_node("Control/CenterContainer/Panel")
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.97, 0.97, 0.97)
	sb.set_corner_radius_all(20)
	sb.set_border_width_all(0)
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size  = 16
	main_panel.add_theme_stylebox_override("panel", sb)
	main_panel.add_theme_stylebox_override("focus", sb)

	# Hide title bar — we draw our own UI inside
	var title_bar = popup.get_node_or_null("Control/CenterContainer/Panel/VBoxContainer/TitleBar")
	if title_bar: title_bar.visible = false

	# Get content container and make it fill
	var cc : VBoxContainer = popup.get_node(
		"Control/CenterContainer/Panel/VBoxContainer/ContentMargin/ContentContainer"
	)
	# Remove content margin padding so we control all layout
	var cm = popup.get_node("Control/CenterContainer/Panel/VBoxContainer/ContentMargin")
	if cm:
		cm.add_theme_constant_override("margin_left",   0)
		cm.add_theme_constant_override("margin_right",  0)
		cm.add_theme_constant_override("margin_top",    0)
		cm.add_theme_constant_override("margin_bottom", 0)

	# Single content area — we manage all phase UI ourselves
	_content_root = Control.new()
	_content_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_root.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_content_root.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	cc.add_child(_content_root)

	await get_tree().process_frame

func _start_round() -> void:
	round_num += 1
	target_color = Color.from_hsv(
		rng.randf(),
		rng.randf_range(0.60, 1.00),
		rng.randf_range(0.60, 1.00)
	)
	memorize_t = MEMORIZE_SECS
	phase      = Phase.MEMORIZE
	await _build_memorize()

# ── PHASE 1: MEMORIZE ─────────────────────────────────────────────────────────
func _build_memorize() -> void:
	_clear_content()

	var sz := _content_root.size
	if sz.x < 10:
		await get_tree().process_frame
		sz = _content_root.size

	# Full color fill
	var fill := ColorRect.new()
	fill.color = target_color
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(fill)

	# Round counter top-left
	var rl := Label.new()
	rl.text     = "%d / %d" % [round_num, TOTAL_ROUNDS]
	rl.position = Vector2(20, 18)
	rl.add_theme_font_size_override("font_size", 20)
	rl.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	_content_root.add_child(rl)

	# Timer: big number top-right, smaller dimmer number just right of it
	var font_sz  : float = 96.0
	var small_sz : float = 80.0
	var top_pad  : float = 14.0

	var big := Label.new()
	big.name     = "BigTimer"
	big.position = Vector2(sz.x * 0.58, top_pad)
	big.size     = Vector2(sz.x * 0.22, font_sz + 10)
	big.add_theme_font_size_override("font_size", int(font_sz))
	big.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_content_root.add_child(big)
	_timer_big = big


	var sub := Label.new()
	sub.text     = "Seconds to remember"
	sub.position = Vector2(sz.x * 0.48, top_pad + font_sz + 6)
	sub.add_theme_font_size_override("font_size", 32)
	sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_content_root.add_child(sub)

	var sub_2 := Label.new()
	sub_2.text     = "You have to recreate it"
	sub_2.position = Vector2(sz.x * 0.48, top_pad + font_sz + 40)
	sub_2.add_theme_font_size_override("font_size", 32)
	sub_2.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_content_root.add_child(sub_2)

	_update_timer_labels()

# ── PHASE 2: PICK ─────────────────────────────────────────────────────────────
func _build_pick() -> void:
	_clear_content()

	# Start sliders at a clearly visible non-black position
	_hsv      = [rng.randf(), rng.randf_range(0.35, 0.75), rng.randf_range(0.45, 0.80)]
	_drag_idx = -1
	_sliders  = []

	var sz := _content_root.size
	if sz.x < 10:
		await get_tree().process_frame
		sz = _content_root.size

	# Layout: 3 sliders on left (each ~15% width), preview fills rest
	var pad   : float = 6.0
	var sw    : float = (sz.x * 0.42 - pad * 4) / 3.0   # each slider width
	var sh    : float = sz.y - pad * 2
	var prev_x: float = pad * 4 + sw * 3
	var prev_w: float = sz.x - prev_x - pad

	# Preview panel
	var prev := Control.new()
	prev.name         = "Preview"
	prev.position     = Vector2(prev_x, pad)
	prev.size         = Vector2(prev_w, sh)
	prev.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(prev)

	var prev_draw := Control.new()
	prev_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	prev_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prev.add_child(prev_draw)
	_preview_node = prev_draw
	prev_draw.draw.connect(func():
		var col := Color.from_hsv(_hsv[0], _hsv[1], _hsv[2])
		_draw_card(prev_draw, col, 14.0)
	)

	# Round label on preview
	var rl := Label.new()
	rl.text     = "%d / %d" % [round_num, TOTAL_ROUNDS]
	rl.position = Vector2(prev_x + 14, pad + 14)
	rl.add_theme_font_size_override("font_size", 18)
	rl.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	_content_root.add_child(rl)

	# Submit arrow button — bottom right of preview
	var btn_sz : float = 52.0
	var btn_pos := Vector2(prev_x + prev_w - btn_sz - 12, pad + sh - btn_sz - 12)
	var sbtn := Control.new()
	sbtn.position     = btn_pos
	sbtn.size         = Vector2(btn_sz, btn_sz)
	sbtn.mouse_filter = Control.MOUSE_FILTER_STOP
	_content_root.add_child(sbtn)
	sbtn.draw.connect(func():
		var r : float = btn_sz / 2.0
		sbtn.draw_circle(Vector2(r, r), r, Color.WHITE)
		sbtn.draw_circle(Vector2(r, r), r - 1.0, Color(1, 1, 1, 0.0))
		var c := Color(0.12, 0.12, 0.12)
		sbtn.draw_line(Vector2(r - 10, r), Vector2(r + 10, r), c, 2.5)
		sbtn.draw_line(Vector2(r + 1, r - 9), Vector2(r + 10, r), c, 2.5)
		sbtn.draw_line(Vector2(r + 1, r + 9), Vector2(r + 10, r), c, 2.5)
	)
	sbtn.gui_input.connect(func(ev):
		if _is_press(ev) and phase == Phase.PICK: _submit_guess()
	)

	# Build 3 sliders — input handled globally in _input()
	for i in range(3):
		var sx : float = pad + i * (sw + pad)
		var sc := Control.new()
		sc.name         = "Slider%d" % i
		sc.position     = Vector2(sx, pad)
		sc.size         = Vector2(sw, sh)
		sc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content_root.add_child(sc)
		_sliders.append(sc)

		var idx := i
		sc.draw.connect(func(): _draw_slider(sc, idx))

func _draw_slider(ctrl: Control, idx: int) -> void:
	var sz := ctrl.size
	if sz.x < 2 or sz.y < 2: return
	var w  : float = sz.x
	var h  : float = sz.y
	var cx : float = w / 2.0
	var r  : float = 10.0   # knob radius
	var bx : float = cx - w * 0.30   # bar left edge
	var bw : float = w * 0.60        # bar width

	# Rounded bar background (black, slight padding top/bottom for knob overhang)
	var bar_top    : float = r + 2
	var bar_bottom : float = h - r - 2
	var bar_h      : float = bar_bottom - bar_top

	# Draw gradient bar — pixel rows
	var steps : int = int(bar_h)
	for i in range(steps):
		var t   : float = float(i) / float(max(steps - 1, 1))
		var col : Color
		match idx:
			0: col = Color.from_hsv(t, 1.0, 1.0)
			1: col = Color.from_hsv(_hsv[0], t, max(_hsv[2], 0.15))
			2: col = Color.from_hsv(_hsv[0], max(_hsv[1], 0.15), t)
		ctrl.draw_rect(Rect2(bx, bar_top + float(i), bw, 1.5), col)

	# Bar outline
	ctrl.draw_rect(Rect2(bx - 1, bar_top - 1, bw + 2, bar_h + 2),
		Color(0, 0, 0, 0.10))

	# Knob — circle on the bar, positioned by _hsv value
	var ky : float = bar_top + _hsv[idx] * bar_h
	ky = clamp(ky, bar_top, bar_bottom)
	# Shadow
	ctrl.draw_circle(Vector2(cx, ky), r + 2.5, Color(0, 0, 0, 0.15))
	# White fill
	ctrl.draw_circle(Vector2(cx, ky), r, Color.WHITE)
	# Colored ring matching current value
	var ring_col : Color
	match idx:
		0: ring_col = Color.from_hsv(_hsv[0], 1.0, 1.0)
		_: ring_col = Color.from_hsv(_hsv[0], _hsv[1], _hsv[2])
	ctrl.draw_arc(Vector2(cx, ky), r - 2.5, 0, TAU, 32, ring_col, 2.5)

# ── GLOBAL INPUT — slider drag using screen-space hit testing ─────────────────
func _input(ev: InputEvent) -> void:
	if phase != Phase.PICK: return
	if _sliders.is_empty(): return

	var global_y : float = -1.0
	var global_x : float = -1.0
	var is_release := false

	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT: return
		if mb.pressed:
			global_x = mb.global_position.x
			global_y = mb.global_position.y
		else:
			is_release = true
	elif ev is InputEventMouseMotion:
		if _drag_idx >= 0:
			global_x = ev.global_position.x
			global_y = ev.global_position.y
	elif ev is InputEventScreenTouch:
		var st := ev as InputEventScreenTouch
		if st.pressed:
			global_x = st.position.x
			global_y = st.position.y
		else:
			is_release = true
	elif ev is InputEventScreenDrag:
		if _drag_idx >= 0:
			global_x = ev.position.x
			global_y = ev.position.y

	if is_release:
		_drag_idx = -1
		return

	if global_y < 0.0: return

	# On initial press, find which slider was hit
	if _drag_idx < 0:
		for i in range(_sliders.size()):
			var sc : Control = _sliders[i]
			if not sc or not is_instance_valid(sc): continue
			var gr : Rect2 = Rect2(sc.global_position, sc.size)
			if gr.has_point(Vector2(global_x, global_y)):
				_drag_idx = i
				break
		if _drag_idx < 0: return

	# Map global_y into the slider's local bar coordinates
	var sc : Control = _sliders[_drag_idx]
	if not sc or not is_instance_valid(sc): return
	var bar_top : float = 12.0
	var bar_h   : float = sc.size.y - bar_top * 2.0
	if bar_h <= 0: return
	var local_y : float = global_y - sc.global_position.y
	var t : float = clamp((local_y - bar_top) / bar_h, 0.0, 1.0)
	_hsv[_drag_idx] = t
	_redraw_all_sliders()
	if _preview_node and is_instance_valid(_preview_node):
		_preview_node.queue_redraw()
	get_viewport().set_input_as_handled()

func _redraw_all_sliders() -> void:
	for sc in _sliders:
		if sc and is_instance_valid(sc):
			sc.queue_redraw()

# ── PHASE 3: RESULT ───────────────────────────────────────────────────────────
func _show_result(score: float, guessed: Color) -> void:
	_clear_content()
	phase = Phase.RESULT

	var sz := _content_root.size
	if sz.x < 10:
		await get_tree().process_frame
		sz = _content_root.size

	var split : float = sz.y * 0.46
	var pad   : float = 4.0

	# Top half — guessed color
	var top := Control.new()
	top.position     = Vector2(pad, pad)
	top.size         = Vector2(sz.x - pad * 2, split)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(top)
	var top_draw := Control.new()
	top_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(top_draw)
	top_draw.draw.connect(func(): _draw_card_top(top_draw, guessed, 14.0))

	# Bottom half — target color
	var bot := Control.new()
	bot.position     = Vector2(pad, split + pad)
	bot.size         = Vector2(sz.x - pad * 2, sz.y - split - pad * 2)
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(bot)
	var bot_draw := Control.new()
	bot_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	bot_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bot.add_child(bot_draw)
	bot_draw.draw.connect(func(): _draw_card_bot(bot_draw, target_color, 14.0))

	# Score — large number top-right of guessed half (matches reference)
	var sc_lbl := Label.new()
	sc_lbl.text     = "%.2f" % score
	sc_lbl.position = Vector2(sz.x * 0.56, pad + 10)
	sc_lbl.size     = Vector2(sz.x * 0.58, split * 0.62)
	sc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sc_lbl.add_theme_font_size_override("font_size", 108)
	sc_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_content_root.add_child(sc_lbl)

	# Message — below score, right side
	var msg := Label.new()
	msg.text          = _score_message(score)
	msg.position      = Vector2(sz.x * 0.50, pad + split * 0.45)
	msg.size          = Vector2(sz.x * 0.58, split * 0.30)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_font_size_override("font_size", 24)
	msg.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_content_root.add_child(msg)

	# Your selection — top-left of guessed half
	var sel := Label.new()
	sel.text     = "Your selection\n" + _hsb_str(guessed)
	sel.position = Vector2(pad + 16, pad + 14)
	sel.add_theme_font_size_override("font_size", 24)
	sel.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_content_root.add_child(sel)

	# Original — top-left of target half
	var orig := Label.new()
	orig.text     = "Original\n" + _hsb_str(target_color)
	orig.position = Vector2(pad + 16, split + pad + 14)
	orig.add_theme_font_size_override("font_size", 24)
	orig.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_content_root.add_child(orig)

	# Next / done button
	var btn_sz  : float = 50.0
	var btn_pos := Vector2(sz.x - btn_sz - 20, sz.y - btn_sz - 18)
	var nb := Control.new()
	nb.position     = btn_pos
	nb.size         = Vector2(btn_sz, btn_sz)
	nb.mouse_filter = Control.MOUSE_FILTER_STOP
	_content_root.add_child(nb)
	nb.draw.connect(func():
		var r : float = btn_sz / 2.0
		nb.draw_circle(Vector2(r, r), r, Color.WHITE)
		var c := Color(0.10, 0.10, 0.10)
		nb.draw_line(Vector2(r - 10, r), Vector2(r + 10, r), c, 2.5)
		nb.draw_line(Vector2(r + 1, r - 9), Vector2(r + 10, r), c, 2.5)
		nb.draw_line(Vector2(r + 1, r + 9), Vector2(r + 10, r), c, 2.5)
	)
	nb.gui_input.connect(func(ev):
		if _is_press(ev): _next_round()
	)

# ── DRAW HELPERS ──────────────────────────────────────────────────────────────
func _draw_card(draw: Control, col: Color, r: float) -> void:
	var sz := draw.size
	if sz.x < 2: return
	var bg := Color(0.97, 0.97, 0.97)
	draw.draw_rect(Rect2(0, 0, sz.x, sz.y), col)
	# Knock corners
	for corner in [Vector2(0,0), Vector2(sz.x-r,0), Vector2(0,sz.y-r), Vector2(sz.x-r,sz.y-r)]:
		draw.draw_rect(Rect2(corner, Vector2(r,r)), bg)
	draw.draw_arc(Vector2(r,r),             r, deg_to_rad(180), deg_to_rad(270), 32, col, r+2, true)
	draw.draw_arc(Vector2(sz.x-r,r),        r, deg_to_rad(270), deg_to_rad(360), 32, col, r+2, true)
	draw.draw_arc(Vector2(r,sz.y-r),        r, deg_to_rad(90),  deg_to_rad(180), 32, col, r+2, true)
	draw.draw_arc(Vector2(sz.x-r,sz.y-r),   r, deg_to_rad(0),   deg_to_rad(90),  32, col, r+2, true)

func _draw_card_top(draw: Control, col: Color, r: float) -> void:
	var sz := draw.size
	var bg := Color(0.97, 0.97, 0.97)
	draw.draw_rect(Rect2(0, 0, sz.x, sz.y), col)
	draw.draw_rect(Rect2(0, 0, r, r), bg)
	draw.draw_rect(Rect2(sz.x-r, 0, r, r), bg)
	draw.draw_arc(Vector2(r,r),       r, deg_to_rad(180), deg_to_rad(270), 32, col, r+2, true)
	draw.draw_arc(Vector2(sz.x-r,r),  r, deg_to_rad(270), deg_to_rad(360), 32, col, r+2, true)

func _draw_card_bot(draw: Control, col: Color, r: float) -> void:
	var sz := draw.size
	var bg := Color(0.97, 0.97, 0.97)
	draw.draw_rect(Rect2(0, 0, sz.x, sz.y), col)
	draw.draw_rect(Rect2(0, sz.y-r, r, r), bg)
	draw.draw_rect(Rect2(sz.x-r, sz.y-r, r, r), bg)
	draw.draw_arc(Vector2(r,sz.y-r),      r, deg_to_rad(90),  deg_to_rad(180), 32, col, r+2, true)
	draw.draw_arc(Vector2(sz.x-r,sz.y-r), r, deg_to_rad(0),   deg_to_rad(90),  32, col, r+2, true)

# ── HELPERS ───────────────────────────────────────────────────────────────────
func _clear_content() -> void:
	_timer_big    = null
	_timer_small  = null
	_preview_node = null
	_sliders      = []
	if _content_root and is_instance_valid(_content_root):
		for child in _content_root.get_children():
			child.queue_free()
	await get_tree().process_frame

func _is_press(ev: InputEvent) -> bool:
	if ev is InputEventMouseButton:
		return (ev as InputEventMouseButton).pressed and \
			   (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	if ev is InputEventScreenTouch:
		return (ev as InputEventScreenTouch).pressed
	return false

func _submit_guess() -> void:
	if phase != Phase.PICK: return
	phase = Phase.RESULT
	var guessed : Color = Color.from_hsv(_hsv[0], _hsv[1], _hsv[2])
	var score   : float = _color_score(target_color, guessed)
	scores.append(score)
	AudioManager.play_sfx(AudioManager.SFX.CORRECT if score >= 7.0 else AudioManager.SFX.WRONG)
	await _show_result(score, guessed)

func _next_round() -> void:
	if round_num >= TOTAL_ROUNDS:
		var total : float = 0.0
		for s in scores: total += s
		var avg : float = total / float(scores.size())
		if avg >= PASS_AVG: win_game()
		else: fail_game("Average: %.2f / 10  (need %.0f)" % [avg, PASS_AVG])
	else:
		await _start_round()

func _color_score(a: Color, b: Color) -> float:
	# Convert both to RGB and measure perceptual distance
	# Also measure HSV component distances with heavy hue weighting
	var dh : float = abs(a.h - b.h)
	if dh > 0.5: dh = 1.0 - dh   # wrap around hue circle
	var ds : float = abs(a.s - b.s)
	var dv : float = abs(a.v - b.v)

	# RGB euclidean distance (0..sqrt(3) max)
	var dr : float = a.r - b.r
	var dg : float = a.g - b.g
	var db : float = a.b - b.b
	var rgb_dist : float = sqrt(dr*dr + dg*dg + db*db) / sqrt(3.0)

	# HSV weighted distance — hue is most perceptually important
	# dh max=0.5, ds/dv max=1.0 — normalise all to 0..1
	var hsv_dist : float = sqrt(dh*dh*9.0 + ds*ds*2.0 + dv*dv*2.0) / sqrt(13.0)

	# Combined: 60% RGB, 40% HSV — then apply power curve to make it stricter
	var raw : float = rgb_dist * 0.6 + hsv_dist * 0.4

	# Power curve: score = (1 - raw)^1.8 mapped to 0..10
	# This makes small differences hurt more — 10% off = ~8.2, 20% off = ~6.5
	var score : float = pow(max(1.0 - raw * 1.6, 0.0), 1.8) * 10.0
	return snappedf(clamp(score, 0.0, 10.0), 0.01)

func _score_message(s: float) -> String:
	if s >= 9.5: return "Extraordinary. Are you even human?"
	if s >= 8.5: return "Almost perfect. Respect."
	if s >= 7.0: return "Really good eye."
	if s >= 5.5: return "Close, but not quite."
	if s >= 3.5: return "The gap between what you saw and what you picked is measurable in light-years."
	return "Did you even try?"

func _hsb_str(c: Color) -> String:
	return "H%d  S%d  B%d" % [int(c.h * 360), int(c.s * 100), int(c.v * 100)]

func _update_timer_labels() -> void:
	var t_ceil : int = int(ceil(max(memorize_t, 0.0)))
	var t_next : int = max(t_ceil - 1, 0)
	if _timer_big   and is_instance_valid(_timer_big):   _timer_big.text   = "%d" % t_ceil
	if _timer_small and is_instance_valid(_timer_small): _timer_small.text = "%d" % t_next if t_next > 0 else ""

# ── PROCESS ───────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not game_active or is_game_over: return
	if phase != Phase.MEMORIZE: return
	memorize_t -= delta
	_update_timer_labels()
	if memorize_t <= 0.0:
		phase = Phase.PICK
		await _build_pick()
