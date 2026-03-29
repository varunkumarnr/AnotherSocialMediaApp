extends Node
class_name MainMenu

signal on_start
signal on_practice
signal on_settings
signal on_quit

const STAT_TRIED    := 50000
const STAT_DISTINCT := 10000
const STAT_SUCCESS  := 0
const COUNT_DURATION := 2.2
const C_BG       := Color(0.03, 0.035, 0.045)
const C_BG2      := Color(0.063, 0.067, 0.082)
const C_CARD     := Color(0.071, 0.078, 0.098)
const C_BORDER   := Color(0.110, 0.122, 0.153)
const C_WHITE    := Color(0.97, 0.98, 1.0)
const C_CYAN     := Color(0.427, 0.612, 0.976)
const C_CYAN_BTN := Color(0.275, 0.420, 0.859)
const C_DIM      := Color(0.55,  0.61,  0.73)
const C_DIMMER   := Color(0.200, 0.224, 0.282)
const C_RED      := Color(0.859, 0.376, 0.290)

const FONT_TITLE  := "res://font/Inter_18pt-Black.ttf"
const FONT_BOLD   := "res://font/Inter_18pt-Bold.ttf"
const FONT_MEDIUM := "res://font/Inter_18pt-Medium.ttf"
const FONT_REG    := "res://font/Inter_18pt-Regular.ttf"

const ICON_PLAY     := "res://assets/icons/play.png"
const ICON_TERMINAL := "res://assets/icons/terminals.png"
const ICON_GEAR     := "res://assets/icons/settings.png"
const ICON_POWER    := "res://assets/icons/power.png"

var _ft : FontFile = null
var _fb : FontFile = null
var _fm : FontFile = null
var _fr : FontFile = null
var _icon_tex : Dictionary = {}

var canvas      : CanvasLayer
var ui_root     : Control
var lbl_tried    : Label
var lbl_distinct : Label
var lbl_success  : Label
var _count_elapsed : float = 0.0
var _counting      : bool  = false
var title     : Label
var start_btn : Button

var W : float
var H : float
var U : float

# ── clamp font so it stays readable on every screen ───────────────────────────
func _f(u_mult: float) -> int:
	return int(clamp(U * u_mult, 8.0, 120.0))

func _ready() -> void:
	_ft = _load_font(FONT_TITLE)
	_fb = _load_font(FONT_BOLD)
	_fm = _load_font(FONT_MEDIUM)
	_fr = _load_font(FONT_REG)
	_icon_tex["play"]     = _load_tex(ICON_PLAY)
	_icon_tex["terminal"] = _load_tex(ICON_TERMINAL)
	_icon_tex["gear"]     = _load_tex(ICON_GEAR)
	_icon_tex["power"]    = _load_tex(ICON_POWER)

	canvas       = CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)

	_build_ui()
	get_tree().get_root().size_changed.connect(_on_resize)

func _on_resize() -> void:
	_build_ui()

func _build_ui() -> void:
	# ── Teardown previous build ───────────────────────────────────────────────
	for c in canvas.get_children():
		c.queue_free()
	lbl_tried = null; lbl_distinct = null; lbl_success = null
	title = null; start_btn = null; _counting = false

	var vp := get_viewport().get_visible_rect().size
	W = vp.x; H = vp.y
	# U scales with width but is clamped so it never blows up on tablets/4K
	U = clamp(W / 24.0, 14.0, 72.0)

	# ── Background ────────────────────────────────────────────────────────────
	var base := ColorRect.new()
	base.color = C_BG; base.size = vp
	canvas.add_child(base)

	# ── Dot grid ──────────────────────────────────────────────────────────────
	var dots := Control.new()
	dots.size = vp; dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dots.draw.connect(func():
		var sp := U * 1.3
		var x := 0.0
		while x < W:
			var y := 0.0
			while y < H:
				dots.draw_rect(Rect2(x, y, U*0.055, U*0.055), Color(0.4,0.5,0.75,0.09))
				y += sp
			x += sp)
	canvas.add_child(dots)

	ui_root = Control.new()
	ui_root.size = vp; ui_root.modulate.a = 0.0
	canvas.add_child(ui_root)

	_add_topbar()
	_add_content()
	_add_footer()
	_animate_entrance()

# ── TOP BAR ───────────────────────────────────────────────────────────────────
func _add_topbar() -> void:
	var bh := U * 1.9
	var bar := ColorRect.new()
	bar.color = C_BG2; bar.size = Vector2(W, bh)
	ui_root.add_child(bar)

	var line := ColorRect.new()
	line.color = C_BORDER; line.size = Vector2(W, 1); line.position = Vector2(0, bh - 1)
	ui_root.add_child(line)

	_lbl(">_",    Vector2(U*0.8,  U*0.48), _f(0.80), C_CYAN,  _fb)
	_lbl("2036",  Vector2(U*1.85, U*0.52), _f(0.68), C_WHITE, _fb)

	var vsep := ColorRect.new()
	vsep.color = C_BORDER; vsep.size = Vector2(1, U*1.0); vsep.position = Vector2(W - U*8.2, U*0.45)
	ui_root.add_child(vsep)

	var dot := _lbl("●", Vector2(W-U*7.7, U*0.58), _f(0.38), Color(0.3,0.9,0.45), null)
	var tw := create_tween(); tw.set_loops()
	tw.tween_property(dot, "modulate:a", 0.15, 0.75)
	tw.tween_property(dot, "modulate:a", 1.0,  0.75)

	_lbl("STATUS: NOMINAL", Vector2(W-U*7.1, U*0.58), _f(0.46), C_DIM, _fr)

# ── MAIN CONTENT ──────────────────────────────────────────────────────────────
func _add_content() -> void:
	var pad := U * 0.85
	var fw  := W - pad * 2.0
	var y   := U * 1.9

	y += U * 1.6
	var over := _lbl("AUTHORIZED PERSONNEL ONLY  //  SECTOR 7G",
		Vector2(0, y), _f(0.42), C_DIMMER, _fr)
	over.custom_minimum_size = Vector2(W, 0)
	over.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	y += U * 5.0
	title = _lbl("2036: LAST SOCIAL\nNETWORK",
		Vector2(0, y), _f(2.0), C_WHITE, _ft)
	title.custom_minimum_size  = Vector2(W, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	title.size                 = Vector2(W, U*5.8)

	y += U * 5.4
	var tag := _lbl("....", Vector2(0, y), _f(0.68), C_DIM, _fr)
	tag.custom_minimum_size  = Vector2(W, 0)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	y += U * 1.4
	var ch := U * 3.1
	_draw_card(Rect2(pad, y, fw, ch))

	var cw   := fw / 3.0
	var defs := [
		["TRIED",   STAT_TRIED,    C_WHITE],
		["HUMANS",  STAT_DISTINCT, C_CYAN],
		["SUCCESS", STAT_SUCCESS,  C_RED],
	]
	var stat_lbls : Array = []
	for i in range(3):
		var sx := pad + cw * i
		if i > 0:
			var dv := ColorRect.new()
			dv.color = C_BORDER; dv.size = Vector2(1, ch*0.70)
			dv.position = Vector2(sx, y + ch*0.15)
			ui_root.add_child(dv)
		var cat := _lbl(defs[i][0], Vector2(sx, y + U*0.38), _f(0.46), C_DIMMER, _fr)
		cat.custom_minimum_size = Vector2(cw, 0)
		cat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var val := _lbl("0", Vector2(sx, y + U*1.05), _f(1.55), defs[i][2], _fm)
		val.custom_minimum_size = Vector2(cw, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_lbls.append(val)

	lbl_tried = stat_lbls[0]; lbl_distinct = stat_lbls[1]; lbl_success = stat_lbls[2]

	y += ch + U * 1.1
	_add_divider(y)

	y += U * 0.7
	var bh  := U * 2.7
	var gap := U * 0.28

	var btn_defs := [
		["INITIATE LOGIN",    "CMD_START",   "play",     C_CYAN,  true,  "on_start"],
		["PRACTICE MODE",     "SANDBOX_ENV", "terminal", C_WHITE, false, "on_practice"],
		["SYSTEM SETTINGS",   "SYS_CONFIG",  "gear",     C_WHITE, false, "on_settings"],
		["TERMINATE SESSION", "EXIT_HALT",   "power",    C_RED,   false, "on_quit"],
	]

	for i in range(btn_defs.size()):
		var d       : Array = btn_defs[i]
		var primary : bool  = d[4]
		var by      : float = y + i * (bh + gap)
		var col     : Color = d[3]

		var btn := Button.new()
		if d[5] == "on_start": start_btn = btn
		btn.position   = Vector2(pad, by)
		btn.size       = Vector2(fw, bh)
		btn.focus_mode = Control.FOCUS_NONE
		btn.text       = ""
		var sb := StyleBoxFlat.new()
		sb.bg_color = C_CYAN_BTN if primary else C_CARD
		sb.set_border_width_all(1)
		sb.border_color = C_CYAN if primary else C_BORDER
		sb.set_corner_radius_all(3)
		btn.add_theme_stylebox_override("normal", sb)
		var sb_h := sb.duplicate() as StyleBoxFlat
		sb_h.bg_color = C_CYAN_BTN.lightened(0.12) if primary else C_BG2
		sb_h.border_color = C_CYAN
		for st in ["hover","focus","pressed"]:
			btn.add_theme_stylebox_override(st, sb_h)
		var action : String = d[5]
		btn.pressed.connect(func(): _handle_button(action))
		ui_root.add_child(btn)

		if primary:
			var acc := ColorRect.new()
			acc.color = C_CYAN; acc.size = Vector2(U*0.16, bh)
			acc.position = Vector2(pad, by)
			ui_root.add_child(acc)

		var icon_ctrl := Control.new()
		icon_ctrl.position     = Vector2(pad + U*0.65, by + bh*0.5 - U*0.55)
		icon_ctrl.size         = Vector2(U*1.1, U*1.1)
		icon_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic : String = d[2]
		var ic_col : Color = Color.WHITE if primary else col
		icon_ctrl.draw.connect(func(): _draw_icon(icon_ctrl, ic, ic_col))
		ui_root.add_child(icon_ctrl)

		var ml := _lbl(d[0], Vector2(pad + U*2.0, by + bh*0.30),
			_f(0.78), Color.WHITE if primary else col, _fb)
		ml.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var ct := _lbl(d[1], Vector2(pad + fw - U*5.2, by + bh*0.36),
			_f(0.46), Color(1,1,1,0.35) if primary else C_DIMMER, _fr)
		ct.mouse_filter = Control.MOUSE_FILTER_IGNORE

# ── ICON DRAWING ──────────────────────────────────────────────────────────────
func _draw_icon(ctrl: Control, icon: String, col: Color) -> void:
	var s  := ctrl.size
	var cx := s.x * 0.5; var cy := s.y * 0.5
	var r  : float = min(s.x, s.y) * 0.5
	var tex : Texture2D = _icon_tex.get(icon, null)
	if tex:
		var tsz  := Vector2(s.x * 0.82, s.y * 0.82)
		var tpos := Vector2((s.x - tsz.x) * 0.5, (s.y - tsz.y) * 0.5)
		ctrl.draw_texture_rect(tex, Rect2(tpos, tsz), false, col)
		return
	match icon:
		"play":
			ctrl.draw_colored_polygon(PackedVector2Array([
				Vector2(cx - r*0.35, cy - r*0.62),
				Vector2(cx + r*0.65, cy),
				Vector2(cx - r*0.35, cy + r*0.62),
			]), col)
		"terminal":
			ctrl.draw_line(Vector2(cx-r*0.55, cy-r*0.3), Vector2(cx+r*0.05, cy),       col, r*0.18)
			ctrl.draw_line(Vector2(cx+r*0.05, cy),       Vector2(cx-r*0.55, cy+r*0.3), col, r*0.18)
			ctrl.draw_line(Vector2(cx+r*0.05, cy+r*0.52),Vector2(cx+r*0.65, cy+r*0.52),col, r*0.18)
		"gear":
			ctrl.draw_arc(Vector2(cx,cy), r*0.42, 0, TAU, 32, col, r*0.22)
			for j in range(6):
				var a := j * TAU / 6.0
				ctrl.draw_line(
					Vector2(cx,cy) + Vector2(cos(a),sin(a)) * r*0.55,
					Vector2(cx,cy) + Vector2(cos(a),sin(a)) * r*0.92, col, r*0.22)
		"power":
			ctrl.draw_arc(Vector2(cx,cy), r*0.55, deg_to_rad(130), deg_to_rad(410), 24, col, r*0.20)
			ctrl.draw_line(Vector2(cx, cy-r*0.30), Vector2(cx, cy-r*0.90), col, r*0.22)

# ── FOOTER ────────────────────────────────────────────────────────────────────
func _add_footer() -> void:
	var line := ColorRect.new()
	line.color = C_BORDER; line.size = Vector2(W, 1); line.position = Vector2(0, H - U*2.0)
	ui_root.add_child(line)
	_lbl("MEM_USAGE: 4.2GB / 64GB",
		Vector2(U*0.85, H-U*1.55), _f(0.46), C_DIMMER, _fr).mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rt := _lbl("Zino Studios  //  ENCRYPT_AES_256\nLOC: [37.7749° N, 122.4194° W]",
		Vector2(W-U*11.5, H-U*1.65), _f(0.46), C_DIMMER, _fr)
	rt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rt.custom_minimum_size  = Vector2(U*10.6, 0)
	rt.mouse_filter         = Control.MOUSE_FILTER_IGNORE

# ── HELPERS ───────────────────────────────────────────────────────────────────
func _lbl(text: String, pos: Vector2, fsize: int, col: Color,
		font: FontFile = null) -> Label:
	var l := Label.new()
	l.text = text; l.position = pos
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	if font: l.add_theme_font_override("font", font)
	ui_root.add_child(l)
	return l

func _draw_card(rect: Rect2) -> void:
	var c := ColorRect.new()
	c.color = C_CARD; c.position = rect.position; c.size = rect.size
	ui_root.add_child(c)
	var b := Control.new()
	b.position = rect.position; b.size = rect.size
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bw := rect.size.x; var bh := rect.size.y
	b.draw.connect(func(): b.draw_rect(Rect2(0,0,bw,bh), C_BORDER, false, 1.0))
	ui_root.add_child(b)

func _add_divider(y: float) -> void:
	var cx  := W * 0.5
	var lw  := W * 0.26
	var pad := U * 0.85
	var ll := ColorRect.new()
	ll.color = C_BORDER; ll.size = Vector2(lw, 1); ll.position = Vector2(pad, y)
	ui_root.add_child(ll)
	var d := Control.new()
	d.position = Vector2(cx - U*0.36, y - U*0.36)
	d.size     = Vector2(U*0.72, U*0.72)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.draw.connect(func():
		var s := d.size; var mid := s / 2.0
		d.draw_colored_polygon(PackedVector2Array([
			Vector2(mid.x, 0), Vector2(s.x, mid.y),
			Vector2(mid.x, s.y), Vector2(0, mid.y)
		]), C_CYAN))
	ui_root.add_child(d)
	var rl := ColorRect.new()
	rl.color = C_BORDER; rl.size = Vector2(lw, 1); rl.position = Vector2(cx + U*0.72, y)
	ui_root.add_child(rl)

func _handle_button(action: String) -> void:
	match action:
		"on_start":    get_tree().change_scene_to_file("res://scenes/core/ArticleProgress.tscn")
		"on_practice": get_tree().change_scene_to_file("res://scenes/practice.tscn")
		"on_settings": get_tree().change_scene_to_file("res://scenes/settings.tscn")
		"on_quit":     get_tree().quit()

func _load_font(path: String) -> FontFile:
	if ResourceLoader.exists(path):
		var f = load(path); if f is FontFile: return f
	return null

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var t = load(path); if t is Texture2D: return t
	return null

# ── ENTRANCE + BREATHING ──────────────────────────────────────────────────────
func _animate_entrance() -> void:
	var tw := create_tween()
	tw.tween_property(ui_root, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_counting = true; _count_elapsed = 0.0
	_start_breathing()

func _start_breathing() -> void:
	if title and is_instance_valid(title):
		title.pivot_offset = title.size / 2
		_breathe(title, 1.025, 2.8)
	if start_btn and is_instance_valid(start_btn):
		start_btn.pivot_offset = start_btn.size / 2
		_breathe(start_btn, 1.035, 2.2)

func _breathe(node: Control, scale_max: float, duration: float) -> void:
	if not is_instance_valid(node): return
	var tw := create_tween(); tw.set_loops()
	tw.tween_property(node, "scale", Vector2(scale_max, scale_max), duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "scale", Vector2(1.0, 1.0), duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ── COUNT-UP ──────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not _counting: return
	_count_elapsed += delta
	var t :float = clamp(_count_elapsed / COUNT_DURATION, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - t, 3.0)
	if lbl_tried    and is_instance_valid(lbl_tried):    lbl_tried.text    = _fmt(int(STAT_TRIED    * e))
	if lbl_distinct and is_instance_valid(lbl_distinct): lbl_distinct.text = _fmt(int(STAT_DISTINCT * e))
	if lbl_success  and is_instance_valid(lbl_success):  lbl_success.text  = _fmt(int(STAT_SUCCESS  * e))
	if t >= 1.0:
		_counting = false
		if lbl_tried    and is_instance_valid(lbl_tried):    lbl_tried.text    = _fmt(STAT_TRIED)
		if lbl_distinct and is_instance_valid(lbl_distinct): lbl_distinct.text = _fmt(STAT_DISTINCT)
		if lbl_success  and is_instance_valid(lbl_success):  lbl_success.text  = _fmt(STAT_SUCCESS)

func _fmt(n: int) -> String:
	if n == 0: return "0"
	var s := str(n); var out := ""; var cnt := 0
	for i in range(s.length()-1, -1, -1):
		if cnt > 0 and cnt % 3 == 0: out = "," + out
		out = s[i] + out; cnt += 1
	return out