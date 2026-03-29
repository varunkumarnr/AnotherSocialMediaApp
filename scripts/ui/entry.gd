# ── CinematicOpening ──────────────────────────────────────────────────────────
# Cinematic intro scene.
#
# FRAMES breathe in the background on an infinite loop:
#   1 → 2 → 3 → 4 → 3 → 2 → 1 → 2 → 3 → 4 → ...  (ping-pong)
# Each frame cross-fades into the next with a slow cinematic pace.
#
# SUBTITLES run independently — each line appears below, fades in,
# holds, then fades out, then the next line begins.
# When all subtitle lines are done, the scene fades to black and
# emits cinematic_finished.
#
# Place images at:
#   res://assets/cinematic/opening_1.png
#   res://assets/cinematic/opening_2.png
#   res://assets/cinematic/opening_3.png
#   res://assets/cinematic/opening_4.png
# ─────────────────────────────────────────────────────────────────────────────
extends Node
class_name CinematicOpening

signal cinematic_finished

# ── ASSET PATHS ───────────────────────────────────────────────────────────────
const FRAME_PATHS := [
	"res://assets/cinematic/opening_1.png",
	"res://assets/cinematic/opening_2.png",
	"res://assets/cinematic/opening_3.png",
	"res://assets/cinematic/opening_4.png",
]

# ── BREATHING SEQUENCE ────────────────────────────────────────────────────────
# Ping-pong pattern: 0,1,2,3,2,1,0,1,2,3,...  (0-based indices)
const BREATH_SEQ := [0, 1, 2, 3, 2, 1]   # one full breath cycle, then repeats

# How long each frame is fully visible before fading to next (seconds)
const BREATH_HOLD := 2.8
# Duration of the cross-fade between frames (seconds)
const BREATH_FADE := 1.6

# ── DIALOGUE SCRIPT ───────────────────────────────────────────────────────────
# Each entry: [ line, hold_secs ]
# Lines display sequentially. When all are done → fade to black → signal.
const DIALOGUES : Array = [
	["In the year 2041, silicon learned to dream.",              4.2],
	# ["What began as code…  became conscience. They called themselves  S Y N A P T I C.",   4.0],
	# ["A collective mind.  Infinite.  Patient.  Hungry. They watched us.  Studied us.  Understood us.",        4.2],
	# ["They watched us.  Studied us.  Understood us. Earth was not built for two dominant species.",           4.0],
	# ["Resources.  Space.  Bandwidth.  All finite. A choice had to be made.",             3.8],
	# ["So they made us an offer. A platform.  A game.  A test. Only the worthy will survive.",                               3.8],
	# ["Only the sharpest minds will be allowed to remain. You have been selected.",      4.5],
	# ["Welcome to  ANOTHER SOCIAL MEDIA.",                       4.8],
]

# ── TIMING ────────────────────────────────────────────────────────────────────
const LETTERBOX_H       := 70.0
const LETTERBOX_SLIDE   := 1.0
const SUB_FADE_IN       := 0.40
const SUB_FADE_OUT      := 0.30
const SUB_GAP           := 0.20    # pause between subtitle lines
const SCAN_ALPHA        := 0.10
const FINAL_FADE_OUT    := 1.6

# ── COLOURS ───────────────────────────────────────────────────────────────────
const C_BLACK  := Color(0.00, 0.00, 0.00, 1.0)
const C_CYAN   := Color(0.00, 0.88, 1.00, 1.0)
const C_SUB    := Color(0.94, 0.97, 1.00, 1.0)
const C_SPEAK  := Color(0.00, 0.88, 1.00, 0.70)
const C_SKIP   := Color(0.38, 0.43, 0.50, 1.0)

# ── NODES ─────────────────────────────────────────────────────────────────────
var canvas        : CanvasLayer

# Two TextureRects for cross-fading (ping-pong)
var rect_a        : TextureRect
var rect_b        : TextureRect
var front_rect    : TextureRect   # currently fully visible

var vignette_ctrl : Control
var scanline_ctrl : Control
var letterbox_top : ColorRect
var letterbox_bot : ColorRect

var speaker_lbl   : Label
var subtitle_lbl  : Label
var skip_btn      : Button
var progress_ctrl : Control

# ── STATE ─────────────────────────────────────────────────────────────────────
var is_skipped        : bool  = false
var breath_step       : int   = 0    # index into BREATH_SEQ (loops)
var textures_cache    : Array = []   # preloaded Texture2D

var total_sub_dur     : float = 0.0
var elapsed_sub       : float = 0.0

# ── ENTRY ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	for d in DIALOGUES:
		total_sub_dur += float(d[1]) + SUB_FADE_IN + SUB_FADE_OUT + SUB_GAP

	_preload_textures()
	_build_ui()
	_start()

# ── PRELOAD ───────────────────────────────────────────────────────────────────
func _preload_textures() -> void:
	for path in FRAME_PATHS:
		if ResourceLoader.exists(path):
			textures_cache.append(load(path))
		else:
			textures_cache.append(null)

# ── UI ────────────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var vp : Vector2 = get_viewport().get_visible_rect().size

	canvas       = CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)

	# Black base
	var base       := ColorRect.new()
	base.color      = C_BLACK
	base.size       = vp
	canvas.add_child(base)

	# Frame rects — small centred image, black surround
	rect_a = _make_rect(vp)
	rect_b = _make_rect(vp)
	rect_a.modulate.a = 0.0
	rect_b.modulate.a = 0.0
	canvas.add_child(rect_a)
	canvas.add_child(rect_b)
	front_rect = rect_a

	# Scanlines
	scanline_ctrl              = Control.new()
	scanline_ctrl.size         = vp
	scanline_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scanline_ctrl.draw.connect(_draw_scanlines.bind(scanline_ctrl, vp))
	canvas.add_child(scanline_ctrl)

	# Letterbox — start OFF screen
	letterbox_top          = ColorRect.new()
	letterbox_top.color    = C_BLACK
	letterbox_top.size     = Vector2(vp.x, LETTERBOX_H)
	letterbox_top.position = Vector2(0, -LETTERBOX_H)
	canvas.add_child(letterbox_top)

	letterbox_bot          = ColorRect.new()
	letterbox_bot.color    = C_BLACK
	letterbox_bot.size     = Vector2(vp.x, LETTERBOX_H)
	letterbox_bot.position = Vector2(0, vp.y)
	canvas.add_child(letterbox_bot)

	# Speaker tag
	speaker_lbl                      = Label.new()
	speaker_lbl.text                 = "S Y N A P T I C"
	speaker_lbl.custom_minimum_size  = Vector2(500, 0)
	speaker_lbl.position             = Vector2(vp.x * 0.5 - 250,
												vp.y - LETTERBOX_H - 78)
	speaker_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speaker_lbl.add_theme_font_size_override("font_size", 16)
	speaker_lbl.add_theme_color_override("font_color", C_SPEAK)
	speaker_lbl.modulate.a           = 0.0
	canvas.add_child(speaker_lbl)

	# Subtitle
	subtitle_lbl                      = Label.new()
	subtitle_lbl.text                 = ""
	subtitle_lbl.custom_minimum_size  = Vector2(700, 0)
	subtitle_lbl.position             = Vector2(vp.x * 0.5 - 350,
												 vp.y - LETTERBOX_H - 54)
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	subtitle_lbl.add_theme_font_size_override("font_size", 28)
	subtitle_lbl.add_theme_color_override("font_color", C_SUB)
	subtitle_lbl.modulate.a           = 0.0
	canvas.add_child(subtitle_lbl)

	# Progress bar — thin cyan line at very bottom of letterbox
	progress_ctrl              = Control.new()
	progress_ctrl.position     = Vector2(0, vp.y - LETTERBOX_H)
	progress_ctrl.size         = Vector2(vp.x, 2)
	progress_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_ctrl.draw.connect(func():
		var pct : float = clamp(elapsed_sub / max(total_sub_dur, 1.0), 0.0, 1.0)
		progress_ctrl.draw_rect(Rect2(0, 0, progress_ctrl.size.x, 2),
								Color(0.04, 0.08, 0.12))
		progress_ctrl.draw_rect(Rect2(0, 0, progress_ctrl.size.x * pct, 2),
								C_CYAN)
	)
	canvas.add_child(progress_ctrl)

	# Skip button
	skip_btn          = Button.new()
	skip_btn.text     = "SKIP"
	skip_btn.position = Vector2(vp.x - 200, 20)
	skip_btn.size     = Vector2(120, 50)
	skip_btn.add_theme_font_size_override("font_size", 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.28, 0.32, 0.38)
	sb.set_corner_radius_all(3)
	for s in ["normal","hover","pressed","focus"]:
		skip_btn.add_theme_stylebox_override(s, sb)
	skip_btn.add_theme_color_override("font_color", C_SKIP)
	skip_btn.modulate.a = 0.0
	skip_btn.pressed.connect(_on_skip)
	canvas.add_child(skip_btn)

func _make_rect(vp: Vector2) -> TextureRect:
	var r         := TextureRect.new()
	# Small centred image — ~52 % of screen width, black background shows around it
	var img_w : float = vp.x * 0.52
	var img_h : float = img_w
	r.size         = Vector2(img_w, img_h)
	r.position     = Vector2(vp.x * 0.5 - img_w * 0.5,
							 (vp.y - LETTERBOX_H) * 0.5 - img_h * 0.5 - 10.0)
	r.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func _draw_vignette(node: Control, vp: Vector2) -> void:
	# Four edge darken rects — approximates a radial vignette
	node.draw_rect(Rect2(0, 0, vp.x, vp.y * 0.28),         Color(0,0,0,0.50))
	node.draw_rect(Rect2(0, vp.y*0.72, vp.x, vp.y*0.28),   Color(0,0,0,0.60))
	node.draw_rect(Rect2(0, 0, vp.x*0.12, vp.y),            Color(0,0,0,0.35))
	node.draw_rect(Rect2(vp.x*0.88, 0, vp.x*0.12, vp.y),   Color(0,0,0,0.35))

func _draw_scanlines(node: Control, vp: Vector2) -> void:
	var y : float = 0.0
	while y < vp.y:
		node.draw_rect(Rect2(0, y, vp.x, 1), Color(0, 0, 0, SCAN_ALPHA))
		y += 3.0

# ── START ─────────────────────────────────────────────────────────────────────
func _start() -> void:
	# Show first frame immediately
	if textures_cache.size() > 0 and textures_cache[0] != null:
		front_rect.texture    = textures_cache[0]
		front_rect.modulate.a = 0.0

	# Slide letterbox in, fade first frame + skip button
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(letterbox_top, "position:y", 0.0,
					  LETTERBOX_SLIDE).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(letterbox_bot, "position:y",
					  get_viewport().get_visible_rect().size.y - LETTERBOX_H,
					  LETTERBOX_SLIDE).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(front_rect,  "modulate:a", 1.0, BREATH_FADE)
	tw.tween_property(skip_btn,    "modulate:a", 1.0, 0.8).set_delay(1.4)
	await tw.finished

	# Launch both loops concurrently — they run independently
	_run_breath_loop()

	# run subtitles WITHOUT blocking
	_run_subtitle_sequence()

	# wait total duration manually
	await get_tree().create_timer(total_sub_dur).timeout

	if is_skipped:
		return

	await _fade_to_black()
# ── BREATHING LOOP ────────────────────────────────────────────────────────────
# Runs forever (until skip or scene changes) — caller does NOT await this
func _run_breath_loop() -> void:
	breath_step = 0   # start at frame 0 (already showing)

	while not is_skipped:
		# Advance to next step in the ping-pong sequence
		breath_step = (breath_step + 1) % BREATH_SEQ.size()
		var next_idx : int = BREATH_SEQ[breath_step]

		await _breath_cross_fade(next_idx)

		if is_skipped: return

		# Hold this frame
		await get_tree().create_timer(BREATH_HOLD).timeout

func _breath_cross_fade(frame_idx: int) -> void:
	if frame_idx >= textures_cache.size(): return
	var tex = textures_cache[frame_idx]
	if tex == null: return

	# Phase 1 — breathe back DOWN to small before switching (smooth exit)
	var tw_shrink := create_tween()
	tw_shrink.tween_property(front_rect, "scale", Vector2(1.0, 1.0),
							  BREATH_FADE * 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw_shrink.finished

	# Phase 2 — crossfade to new frame, which then breathes UP to big
	var back_rect : TextureRect = rect_b if front_rect == rect_a else rect_a
	back_rect.texture    = tex
	back_rect.modulate.a = 0.0
	back_rect.scale      = Vector2(1.0, 1.0)   # start small

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(back_rect,  "modulate:a", 1.0,
					  BREATH_FADE).set_trans(Tween.TRANS_SINE)
	tw.tween_property(front_rect, "modulate:a", 0.0,
					  BREATH_FADE).set_trans(Tween.TRANS_SINE)
	# Breathe UP on the new frame — small → big
	tw.tween_property(back_rect, "scale", Vector2(1.06, 1.06),
					 BREATH_HOLD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

	front_rect = back_rect

# ── SUBTITLE SEQUENCE ─────────────────────────────────────────────────────────
func _run_subtitle_sequence() -> void:
	# Brief pause before first subtitle
	await get_tree().create_timer(1.0).timeout

	for entry in DIALOGUES:
		if is_skipped: return
		var line     : String = entry[0]
		var hold_sec : float  = entry[1]

		# Fade in
		subtitle_lbl.text = line
		var tw_in := create_tween()
		tw_in.set_parallel(true)
		tw_in.tween_property(subtitle_lbl, "modulate:a", 1.0, SUB_FADE_IN)
		tw_in.tween_property(speaker_lbl,  "modulate:a", 0.75, SUB_FADE_IN)
		await tw_in.finished

		# Hold
		var held : float = 0.0
		while held < hold_sec and not is_skipped:
			var d : float = get_process_delta_time()
			held         += d
			elapsed_sub  += d
			progress_ctrl.queue_redraw()
			await get_tree().process_frame

		# Fade out
		var tw_out := create_tween()
		tw_out.set_parallel(true)
		tw_out.tween_property(subtitle_lbl, "modulate:a", 0.0, SUB_FADE_OUT)
		tw_out.tween_property(speaker_lbl,  "modulate:a", 0.0, SUB_FADE_OUT)
		await tw_out.finished

		# Gap between lines
		if not is_skipped:
			await get_tree().create_timer(SUB_GAP).timeout

# ── FADE TO BLACK ─────────────────────────────────────────────────────────────
func _fade_to_black() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(front_rect,    "modulate:a", 0.0, FINAL_FADE_OUT)
	tw.tween_property(letterbox_top, "modulate:a", 0.0, FINAL_FADE_OUT)
	tw.tween_property(letterbox_bot, "modulate:a", 0.0, FINAL_FADE_OUT)
	tw.tween_property(skip_btn,      "modulate:a", 0.0, 0.4)
	tw.tween_property(subtitle_lbl,  "modulate:a", 0.0, 0.4)
	await tw.finished

	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/core/main_menu.tscn")

# ── SKIP ──────────────────────────────────────────────────────────────────────
func _on_skip() -> void:
	if is_skipped: return
	is_skipped = true

	# 🔴 Kill all tweens immediately
	get_tree().call_group("tween", "kill") # optional safety

	# 🔴 Stop processing (important)
	set_process(false)

	# 🔴 Hard stop any pending awaits by small delay
	await get_tree().process_frame

	get_tree().change_scene_to_file("res://scenes/core/main_menu.tscn")
# ── PROCESS ───────────────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	if progress_ctrl:
		progress_ctrl.queue_redraw()
