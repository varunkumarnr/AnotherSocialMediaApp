extends CanvasLayer

signal button_pressed(button_id: String)

const FONT_PATH := "res://assets/fonts/JetBrainsMono-Regular.ttf"
var mono_font: FontFile = null

# Colors
const C_BG_FAIL    := Color(0.08,  0.01,  0.01,  1)
const C_BG_WIN     := Color(0.027, 0.04,  0.06,  1)
const C_BG2_FAIL   := Color(0.12,  0.03,  0.03,  1)
const C_BG2_WIN    := Color(0.059, 0.071, 0.094, 1)
const C_BORDER_FAIL:= Color(0.6,   0.1,   0.1,   1)
const C_BORDER_WIN := Color(0.0,   0.831, 1.0,   1)
const C_RED        := Color(0.9,   0.2,   0.1,   1)
const C_CYAN       := Color(0.0,   0.831, 1.0,   1)
const C_GREEN      := Color(0.0,   1.0,   0.533, 1)
const C_MUTED      := Color(0.29,  0.353, 0.439, 1)
const C_TEXT       := Color(0.784, 0.831, 0.910, 1)
const C_GHOST      := Color(0.2,   0.25,  0.32,  1)

var _is_win := false

func _ready() -> void:
	if ResourceLoader.exists(FONT_PATH):
		mono_font = load(FONT_PATH)

func setup_fail(reason: String, article_num: int, game_name: String) -> void:
	_is_win = false
	_apply_fail_theme()
	_set_header_fail()
	_set_headline("BREACH\nDETECTED", "CONTRACT NULLIFIED. IDENTITY PURGED.")
	_set_icon("⚠", C_RED)
	_set_data_rows(article_num, game_name, reason, false)
	_set_buttons_fail()
	_af(get_child(0))

func setup_win(article_num: int, game_name: String, score: float = -1.0) -> void:
	_is_win = true
	_apply_win_theme()
	_set_header_win()
	_set_headline("COMPLIANCE\nACCEPTED", "MODULE %02d COMPLETE. DATA UPLINK STABLE." % article_num)
	_set_icon("✓", C_GREEN)
	_set_data_rows(article_num, game_name, "", true, score)
	_set_buttons_win(article_num)
	_af(get_child(0))

# ── Theming ───────────────────────────────────────────────────────────────────

func _apply_fail_theme() -> void:
	var bg = _find("BgRect")
	if bg: bg.color = C_BG_FAIL

	var header = _find("HeaderPanel")
	if header:
		var sb := StyleBoxFlat.new()
		sb.bg_color         = C_BG2_FAIL
		sb.border_color     = C_RED
		sb.border_width_bottom = 2
		header.add_theme_stylebox_override("panel", sb)

	var divider = _find("Divider1")
	if divider: divider.color = C_BORDER_FAIL

	var data_sep = _find("DataSeparator")
	if data_sep: data_sep.color = C_BORDER_FAIL

	_style_data_panel(C_BG2_FAIL, C_BORDER_FAIL)

	var action = _find("ActionSection")
	if action:
		var sb := StyleBoxFlat.new()
		sb.bg_color         = C_BG2_FAIL
		sb.border_color     = C_BORDER_FAIL
		sb.border_width_top = 2
		action.add_theme_stylebox_override("panel", sb)

func _apply_win_theme() -> void:
	var bg = _find("BgRect")
	if bg: bg.color = C_BG_WIN

	var header = _find("HeaderPanel")
	if header:
		var sb := StyleBoxFlat.new()
		sb.bg_color         = C_BG2_WIN
		sb.border_color     = C_CYAN
		sb.border_width_bottom = 2
		header.add_theme_stylebox_override("panel", sb)

	var divider = _find("Divider1")
	if divider: divider.color = C_BORDER_WIN

	var data_sep = _find("DataSeparator")
	if data_sep: data_sep.color = C_BORDER_WIN

	_style_data_panel(C_BG2_WIN, C_BORDER_WIN)

	var action = _find("ActionSection")
	if action:
		var sb := StyleBoxFlat.new()
		sb.bg_color         = C_BG2_WIN
		sb.border_color     = C_BORDER_WIN
		sb.border_width_top = 2
		action.add_theme_stylebox_override("panel", sb)

func _style_data_panel(bg: Color, border: Color) -> void:
	var inner = _find("DataInnerPanel")
	if not inner: return
	var sb := StyleBoxFlat.new()
	sb.bg_color           = bg.darkened(0.2)
	sb.border_color       = border
	sb.border_width_left  = 1
	sb.border_width_right = 1
	sb.border_width_top   = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left     = 4
	sb.corner_radius_top_right    = 4
	sb.corner_radius_bottom_left  = 4
	sb.corner_radius_bottom_right = 4
	inner.add_theme_stylebox_override("panel", sb)

# ── Content setters ───────────────────────────────────────────────────────────

func _set_header_fail() -> void:
	var status = _find("StatusLabel")
	if status:
		status.text = "[SYSTEM_STATUS: BREACHED]"
		status.add_theme_color_override("font_color", C_RED)
	var signal_lbl = _find("SignalLabel")
	if signal_lbl:
		signal_lbl.text = "SIGNAL\nLOST"
		signal_lbl.add_theme_color_override("font_color", C_MUTED)
	var wifi = _find("WifiLabel")
	if wifi: wifi.add_theme_color_override("font_color", C_RED)
	var shield = _find("ShieldLabel")
	if shield: shield.add_theme_color_override("font_color", C_RED)

func _set_header_win() -> void:
	var status = _find("StatusLabel")
	if status:
		status.text = "[SYSTEM_STATUS: NOMINAL]"
		status.add_theme_color_override("font_color", C_CYAN)
	var signal_lbl = _find("SignalLabel")
	if signal_lbl:
		signal_lbl.text = "ENCRYPTION:\nACTIVE"
		signal_lbl.add_theme_color_override("font_color", C_MUTED)
	var wifi = _find("WifiLabel")
	if wifi: wifi.add_theme_color_override("font_color", C_CYAN)
	var shield = _find("ShieldLabel")
	if shield: shield.add_theme_color_override("font_color", C_CYAN)

func _set_headline(headline: String, subtitle: String) -> void:
	var h = _find("HeadlineLabel")
	if h:
		h.text = headline
		h.add_theme_color_override("font_color", C_TEXT)
	var s = _find("SubtitleLabel")
	if s:
		s.text = subtitle
		s.add_theme_color_override("font_color", C_MUTED)

func _set_icon(icon: String, color: Color) -> void:
	var lbl = _find("IconLabel")
	if lbl:
		lbl.text = icon
		lbl.add_theme_color_override("font_color", color)

func _set_data_rows(article_num: int, game_name: String,
					reason: String, is_win: bool, score: float = -1.0) -> void:
	var ts = _find("TimestampVal")
	if ts:
		var t := Time.get_time_dict_from_system()
		ts.text = "%02d:%02d:%02d_UTC" % [t.hour, t.minute, t.second]
		ts.add_theme_color_override("font_color", C_TEXT)

	var ts_key = _find("TimestampKey")
	if ts_key: ts_key.add_theme_color_override("font_color", C_GHOST)

	var viol_row = _find("ViolationRow")
	var cont_row = _find("ContainmentRow")
	var reason_lbl = _find("ReasonLabel")

	if is_win:
		# Win: show module + verification sequence
		var viol_key = _find("ViolationKey")
		var viol_val = _find("ViolationVal")
		if viol_key: viol_key.text = "MODULE"
		if viol_val:
			viol_val.text = "MODULE %02d — %s" % [article_num, game_name]
			viol_val.add_theme_color_override("font_color", C_CYAN)

		var cont_key = _find("ContainmentKey")
		var cont_val = _find("ContainmentVal")
		if cont_key: cont_key.text = "VERIFICATION SEQUENCE"
		if cont_val:
			cont_val.text = "%d/15 VERIFIED" % article_num
			cont_val.add_theme_color_override("font_color", C_GREEN)

		if reason_lbl:
			if score >= 0:
				reason_lbl.text = "MODULE %02d COMPLETE.\nDATA UPLINK STABLE.\nSCORE: %s" % [article_num, str(score)]
			else:
				reason_lbl.text = "MODULE %02d COMPLETE.\nDATA UPLINK STABLE." % article_num
			reason_lbl.add_theme_color_override("font_color", C_TEXT)
	else:
		# Fail: show violation + containment
		var viol_key = _find("ViolationKey")
		var viol_val = _find("ViolationVal")
		if viol_key:
			viol_key.text = "VIOLATION CODE"
			viol_key.add_theme_color_override("font_color", C_GHOST)
		if viol_val:
			viol_val.text = "ERR_%s" % game_name.to_upper().replace(" ", "_")
			viol_val.add_theme_color_override("font_color", C_RED)

		var cont_key = _find("ContainmentKey")
		var cont_val = _find("ContainmentVal")
		if cont_key:
			cont_key.text = "CONTAINMENT"
			cont_key.add_theme_color_override("font_color", C_GHOST)
		if cont_val:
			cont_val.text = "ACTIVE"
			cont_val.add_theme_color_override("font_color", C_RED)

		if reason_lbl:
			reason_lbl.text = "User privileges have been permanently revoked.\n" + reason
			reason_lbl.add_theme_color_override("font_color", C_MUTED)

func _set_buttons_fail() -> void:
	var primary = _find("PrimaryButton")
	if primary:
		primary.text = "RETRY FROM MODULE %d" % (GameManager.current_article_index + 1)
		_style_btn(primary, C_RED)
		primary.pressed.connect(func():
			button_pressed.emit("restart")
			queue_free()
		)

	var secondary = _find("SecondaryButton")
	if secondary:
		secondary.visible = true
		secondary.text    = "GIVE UP"
		_style_btn(secondary, Color(0.12, 0.15, 0.20, 1))
		secondary.pressed.connect(func():
			button_pressed.emit("quit")
			queue_free()
		)

func _set_buttons_win(article_num: int) -> void:
	var primary = _find("PrimaryButton")
	if primary:
		primary.text = "CONTINUE TO NEXT\nMODULE"
		_style_btn(primary, C_CYAN)
		primary.add_theme_color_override("font_color", Color(0.039, 0.047, 0.063, 1))
		primary.pressed.connect(func():
			button_pressed.emit("next")
			queue_free()
		)

	var secondary = _find("SecondaryButton")
	if secondary:
		secondary.visible = false

func _style_btn(btn: Button, color: Color) -> void:
	if mono_font:
		btn.add_theme_font_override("font", mono_font)
	for state in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		match state:
			"normal":  sb.bg_color = color
			"hover":   sb.bg_color = color.lightened(0.15)
			"pressed": sb.bg_color = color.darkened(0.2)
		sb.set_corner_radius_all(4)
		sb.set_border_width_all(0)
		btn.add_theme_stylebox_override(state, sb)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _find(node_name: String) -> Node:
	return _search(get_child(0), node_name)

func _search(root: Node, target: String) -> Node:
	if root.name == target:
		return root
	for child in root.get_children():
		var r = _search(child, target)
		if r != null:
			return r
	return null

func _af(node: Node) -> void:
	if mono_font == null:
		return
	if node is Label or node is Button:
		node.add_theme_font_override("font", mono_font)
	for child in node.get_children():
		_af(child)