extends Control

const COLOR_BG     := Color(0.039, 0.047, 0.063, 1)
const COLOR_BG2    := Color(0.059, 0.071, 0.094, 1)
const COLOR_BG3    := Color(0.082, 0.102, 0.133, 1)
const COLOR_BORDER := Color(0.118, 0.137, 0.176, 1)
const COLOR_CYAN   := Color(0.0,   0.831, 1.0,   1)
const COLOR_GREEN  := Color(0.0,   1.0,   0.533, 1)
const COLOR_RED    := Color(0.9,   0.2,   0.1,   1)
const COLOR_AMBER  := Color(1.0,   0.67,  0.0,   1)
const COLOR_MUTED  := Color(0.29,  0.353, 0.439, 1)
const COLOR_BLACK  := Color(0,  0, 0, 1)
const COLOR_LIGHT_BLACK := Color(0.18, 0.278, 0.337, 1.0)
const COLOR_TEXT   := Color(0.784, 0.831, 0.910, 1)
const COLOR_GHOST  := Color(0.2,   0.25,  0.32,  1)

const FONT_TITLE  := "res://font/Inter_18pt-Black.ttf"
const FONT_BOLD   := "res://font/Inter_18pt-Bold.ttf"
const FONT_MEDIUM := "res://font/Inter_18pt-Medium.ttf"
const FONT_REG    := "res://font/Inter_18pt-Regular.ttf"

var _ft : FontFile = null
var _fb : FontFile = null
var _fm : FontFile = null
var _fr : FontFile = null

# ── Node refs ─────────────────────────────────────────────────────────────────
var article_number_label : Label
var article_title_label  : Label
var description_label    : RichTextLabel
var minigame_title       : Label
var difficulty_value     : Label
var risk_value           : Label
var accept_button        : Button
var scroll_container     : ScrollContainer

var _scroll_reset_done := false

const MINIGAME_NAMES := {
	"coin_toss":          "COIN TOSS PROTOCOL",
	"flappy":             "EVASION SEQUENCE",
	"shellgame":          "SHELL GAME CIPHER",
	"react":              "REFLEX INTERCEPT",
	"virus_agree_popups": "VIRUS AGREE POPUPS",
	"default":            "UNKNOWN PROTOCOL",
}
const DIFFICULTY_NAMES := ["NOVICE", "OPERATIVE", "ADVANCED", "EXPERT", "CRITICAL"]
const RISK_LEVELS      := ["LOW", "MODERATE", "ELEVATED", "HIGH", "CRITICAL"]
const RISK_COLORS := [
	Color(0.0, 1.0, 0.533, 1),
	Color(1.0, 0.67, 0.0,  1),
	Color(1.0, 0.67, 0.0,  1),
	Color(0.9, 0.2,  0.1,  1),
	Color(0.9, 0.2,  0.1,  1),
]

var article_data := [
	{ "number": "01", "title": "SOVEREIGNTY WAIVER",        "ref": "SEC-992-B", "game": "virus_agree_popups", "difficulty": 0, "risk": 4 },
	{ "number": "02", "title": "BIOMETRIC EXTRACTION",      "ref": "SEC-114-A", "game": "coin_toss",          "difficulty": 1, "risk": 3 },
	{ "number": "03", "title": "NEURAL SYNCING",            "ref": "SEC-223-C", "game": "flappy",             "difficulty": 1, "risk": 3 },
	{ "number": "04", "title": "COGNITIVE MAPPING",         "ref": "SEC-331-D", "game": "shellgame",          "difficulty": 2, "risk": 3 },
	{ "number": "05", "title": "ASSET CATEGORIZATION",      "ref": "SEC-442-E", "game": "react",              "difficulty": 2, "risk": 2 },
	{ "number": "06", "title": "MEMORY SANITATION",         "ref": "SEC-551-F", "game": "coin_toss",          "difficulty": 2, "risk": 3 },
	{ "number": "07", "title": "BEHAVIORAL REFACTORING",    "ref": "SEC-663-G", "game": "flappy",             "difficulty": 3, "risk": 3 },
	{ "number": "08", "title": "LOYALTY IMPRINTING",        "ref": "SEC-774-H", "game": "react",              "difficulty": 3, "risk": 4 },
	{ "number": "09", "title": "VISUAL FEED OVERRIDE",      "ref": "SEC-882-I", "game": "shellgame",          "difficulty": 3, "risk": 4 },
	{ "number": "10", "title": "DIRECT COMMAND INJECT",     "ref": "SEC-991-J", "game": "virus_agree_popups", "difficulty": 3, "risk": 4 },
	{ "number": "11", "title": "AUDITORY FILTERING",        "ref": "SEC-110-K", "game": "coin_toss",          "difficulty": 4, "risk": 4 },
	{ "number": "12", "title": "SOCIAL BOND TERMINATION",   "ref": "SEC-221-L", "game": "react",              "difficulty": 4, "risk": 4 },
	{ "number": "13", "title": "STANDARDIZED RESPONSE",     "ref": "SEC-332-M", "game": "flappy",             "difficulty": 4, "risk": 4 },
	{ "number": "14", "title": "INTERNAL CLOCK SYNC",       "ref": "SEC-443-N", "game": "shellgame",          "difficulty": 4, "risk": 4 },
	{ "number": "15", "title": "PHYSICAL COMPLIANCE FINAL", "ref": "SEC-554-O", "game": "virus_agree_popups", "difficulty": 4, "risk": 4 },
]

func _ready() -> void:
	_ft = _load_font(FONT_TITLE)
	_fb = _load_font(FONT_BOLD)
	_fm = _load_font(FONT_MEDIUM)
	_fr = _load_font(FONT_REG)

	_find_nodes()
	_style_all_scene_nodes()

	if accept_button == null:
		push_error("AcceptButton not found"); return

	accept_button.focus_mode   = Control.FOCUS_NONE
	accept_button.mouse_filter = Control.MOUSE_FILTER_STOP
	accept_button.pressed.connect(_on_accept_pressed)

	var index := GameManager.get_current_article_index()
	_populate(index)

# ── NODE FINDING ──────────────────────────────────────────────────────────────
func _find_nodes() -> void:
	scroll_container     = _find_node(self, "ScrollContainer")
	article_number_label = _find_node(self, "ArticleNumberLabel")
	article_title_label  = _find_node(self, "ArticleTitleLabel")
	description_label    = _find_node(self, "DescriptionLabel")
	minigame_title       = _find_node(self, "MinigameTitle")
	difficulty_value     = _find_node(self, "DifficultyValue")
	risk_value           = _find_node(self, "RiskValue")
	accept_button        = _find_node(self, "AcceptButton")

func _find_node(root: Node, node_name: String) -> Node:
	if root.name == node_name: return root
	for child in root.get_children():
		var r = _find_node(child, node_name)
		if r != null: return r
	return null

# ── STYLE ALL SCENE NODES ─────────────────────────────────────────────────────
func _style_all_scene_nodes() -> void:
	# ── Header ──────────────────────────────────────────────────────────────
	var header_panel : Panel = _find_node(self, "HeaderPanel")
	if header_panel:
		var sb := StyleBoxFlat.new()
		sb.bg_color          = Color(0.027, 0.035, 0.051, 1)
		sb.border_color      = COLOR_CYAN
		sb.border_width_bottom = 2
		header_panel.add_theme_stylebox_override("panel", sb)

	var terminal_icon : Label = _find_node(self, "TerminalIcon")
	if terminal_icon:
		terminal_icon.text = ">_"
		terminal_icon.add_theme_font_override("font", _fb)
		terminal_icon.add_theme_font_size_override("font_size", 32)
		terminal_icon.add_theme_color_override("font_color", COLOR_CYAN)

	var app_title : Label = _find_node(self, "AppTitle")
	if app_title:
		app_title.text = "  CODERAGE_TERMINAL"
		app_title.add_theme_font_override("font", _fb)
		app_title.add_theme_font_size_override("font_size", 28)
		app_title.add_theme_color_override("font_color", COLOR_TEXT)

	var status_title : Label = _find_node(self, "StatusTitle")
	if status_title:
		status_title.add_theme_font_override("font", _fr)
		status_title.add_theme_font_size_override("font_size", 18)
		status_title.add_theme_color_override("font_color", COLOR_MUTED)

	var status_value : Label = _find_node(self, "StatusValue")
	if status_value:
		status_value.add_theme_font_override("font", _fb)
		status_value.add_theme_font_size_override("font_size", 18)
		status_value.add_theme_color_override("font_color", COLOR_GREEN)
		# Animated pulse
		var tw := create_tween(); tw.set_loops()
		tw.tween_property(status_value, "modulate:a", 0.4, 0.9)
		tw.tween_property(status_value, "modulate:a", 1.0, 0.9)

	# ── Title section — module number huge, title bold ────────────────────────
	var mission_label : Label = _find_node(self, "MissionLabel")
	if mission_label:
		mission_label.add_theme_font_override("font", _fr)
		mission_label.add_theme_font_size_override("font_size", 20)
		mission_label.add_theme_color_override("font_color", COLOR_MUTED)
		mission_label.text = "——  MISSION INITIALIZATION SEQUENCE"

	if article_number_label:
		article_number_label.add_theme_font_override("font", _ft)
		article_number_label.add_theme_font_size_override("font_size", 82)
		article_number_label.add_theme_color_override("font_color", COLOR_TEXT)

	if article_title_label:
		article_title_label.add_theme_font_override("font", _ft)
		article_title_label.add_theme_font_size_override("font_size", 72)
		article_title_label.add_theme_color_override("font_color", COLOR_CYAN)

	# ── Briefing section ──────────────────────────────────────────────────────
	var briefing_title : Label = _find_node(self, "BriefingTitle")
	if briefing_title:
		briefing_title.add_theme_font_override("font", _fm)
		briefing_title.add_theme_font_size_override("font_size", 22)
		briefing_title.add_theme_color_override("font_color", COLOR_BLACK)
		briefing_title.text = "TACTICAL_BRIEFING"

	var ref_label : Label = _find_node(self, "RefLabel")
	if ref_label:
		ref_label.add_theme_font_override("font", _fr)
		ref_label.add_theme_font_size_override("font_size", 20)
		ref_label.add_theme_color_override("font_color", COLOR_GHOST)

	# Description styled via populate
	if description_label:
		description_label.add_theme_color_override("default_color", COLOR_TEXT)
		description_label.add_theme_font_size_override("normal_font_size", 28)
		description_label.add_theme_font_size_override("bold_font_size",   28)
		if _fb: description_label.add_theme_font_override("bold_font", _fb)
		if _fr: description_label.add_theme_font_override("normal_font", _fr)

	# Add left-border panel behind description area
	var briefing_vbox = _find_node(self, "BriefingVBox")
	if briefing_vbox:
		# Style the BriefingMargin container to have a left cyan accent line
		var bm = briefing_vbox.get_parent()  # BriefingMargin
		if bm:
			var accent := ColorRect.new()
			accent.color    = COLOR_LIGHT_BLACK
			accent.size     = Vector2(3, 0)
			accent.anchor_top    = 0; accent.anchor_bottom = 1
			accent.offset_left   = 0; accent.offset_right  = 3
			accent.size_flags_vertical = Control.SIZE_EXPAND_FILL
			bm.add_child(accent)
			bm.move_child(accent, 0)

	# ── Notice box ────────────────────────────────────────────────────────────
	var notice_title : Label = _find_node(self, "NoticeTitleLabel")
	if notice_title:
		notice_title.add_theme_font_override("font", _fm)
		notice_title.add_theme_font_size_override("font_size", 20)
		notice_title.add_theme_color_override("font_color", COLOR_BLACK)

	var notice_text : Label = _find_node(self, "NoticeTextLabel")
	if notice_text:
		notice_text.add_theme_font_override("font", _fr)
		notice_text.add_theme_font_size_override("font_size", 22)
		notice_text.add_theme_color_override("font_color", COLOR_GHOST)

	var notice_margin = _find_node(self, "NoticeMargin")
	if notice_margin:
		# Subtle dark inset box for the notice
		var notice_panel := Panel.new()
		notice_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		notice_panel.z_index = -1
		notice_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var nsb := StyleBoxFlat.new()
		nsb.bg_color         = COLOR_BG3
		nsb.border_color     = COLOR_BORDER
		nsb.border_width_left = 2
		nsb.set_border_width_all(1)
		notice_panel.add_theme_stylebox_override("panel", nsb)
		notice_margin.add_child(notice_panel)
		notice_margin.move_child(notice_panel, 0)

	# ── Targeting section ─────────────────────────────────────────────────────
	var targeting_caption : Label = _find_node(self, "TargetingCaption")
	if targeting_caption:
		targeting_caption.add_theme_font_override("font", _fm)
		targeting_caption.add_theme_font_size_override("font_size", 20)
		targeting_caption.add_theme_color_override("font_color", COLOR_MUTED)

	var minigame_caption : Label = _find_node(self, "MinigameCaption")
	if minigame_caption:
		minigame_caption.add_theme_font_override("font", _fr)
		minigame_caption.add_theme_font_size_override("font_size", 20)
		minigame_caption.add_theme_color_override("font_color", COLOR_MUTED)
		minigame_caption.text = "MINI-GAME PROTOCOL:"

	if minigame_title:
		minigame_title.add_theme_font_override("font", _ft)
		minigame_title.add_theme_font_size_override("font_size", 48)
		minigame_title.add_theme_color_override("font_color", COLOR_TEXT)

	# ── Parameters section ────────────────────────────────────────────────────
	var params_caption : Label = _find_node(self, "ParamsCaption")
	if params_caption:
		params_caption.add_theme_font_override("font", _fm)
		params_caption.add_theme_font_size_override("font_size", 20)
		params_caption.add_theme_color_override("font_color", COLOR_MUTED)

	for cap_name in ["DifficultyCaption", "RiskCaption"]:
		var cap : Label = _find_node(self, cap_name)
		if cap:
			cap.add_theme_font_override("font", _fr)
			cap.add_theme_font_size_override("font_size", 20)
			cap.add_theme_color_override("font_color", COLOR_MUTED)

	if difficulty_value:
		difficulty_value.add_theme_font_override("font", _fb)
		difficulty_value.add_theme_font_size_override("font_size", 48)
		difficulty_value.add_theme_color_override("font_color", COLOR_TEXT)

	if risk_value:
		risk_value.add_theme_font_override("font", _fb)
		risk_value.add_theme_font_size_override("font_size", 48)

	# ── Encryption bar ────────────────────────────────────────────────────────
	var enc_label : Label = _find_node(self, "EncryptionLabel")
	if enc_label:
		enc_label.add_theme_font_override("font", _fr)
		enc_label.add_theme_font_size_override("font_size", 20)
		enc_label.add_theme_color_override("font_color", COLOR_MUTED)

	# ── Accept section ────────────────────────────────────────────────────────
	var accept_section : Panel = _find_node(self, "AcceptSection")
	if accept_section:
		var asb := StyleBoxFlat.new()
		asb.bg_color          = Color(0.027, 0.035, 0.051, 1)
		asb.border_color      = COLOR_BORDER
		asb.border_width_top  = 2
		accept_section.add_theme_stylebox_override("panel", asb)
		accept_section.custom_minimum_size = Vector2(0, 260)

	if accept_button:
		accept_button.add_theme_font_override("font", _ft)
		accept_button.add_theme_font_size_override("font_size", 44)
		accept_button.add_theme_color_override("font_color", COLOR_BG)
		accept_button.text = "INITIATE_COMPLIANCE"
		# Normal style — solid cyan
		var btn_sb := StyleBoxFlat.new()
		btn_sb.bg_color = COLOR_CYAN
		btn_sb.set_corner_radius_all(4)
		accept_button.add_theme_stylebox_override("normal",  btn_sb)
		accept_button.add_theme_stylebox_override("hover",   btn_sb)
		accept_button.add_theme_stylebox_override("pressed", btn_sb)
		# Disabled style
		var btn_dis := StyleBoxFlat.new()
		btn_dis.bg_color      = COLOR_BG3
		btn_dis.border_color  = COLOR_BORDER
		btn_dis.set_border_width_all(2)
		btn_dis.set_corner_radius_all(4)
		accept_button.add_theme_stylebox_override("disabled", btn_dis)
		accept_button.add_theme_color_override("font_disabled_color", COLOR_MUTED)
		accept_button.custom_minimum_size = Vector2(0, 160)

	var neural_label : Label = _find_node(self, "NeuralLinkLabel")
	if neural_label:
		neural_label.add_theme_font_override("font", _fr)
		neural_label.add_theme_font_size_override("font_size", 20)
		neural_label.add_theme_color_override("font_color", COLOR_MUTED)
		neural_label.text = "NEURAL LINK AUTHORIZATION REQUIRED"

# ── DATA POPULATION ───────────────────────────────────────────────────────────
func _populate(index: int) -> void:
	if index >= article_data.size(): return
	var data = article_data[index]

	if article_number_label:
		article_number_label.text = "MODULE " + data["number"] + ":"

	if article_title_label:
		article_title_label.text = data["title"]

	var ref_lbl : Label = _find_node(self, "RefLabel")
	if ref_lbl: ref_lbl.text = "REF: " + data["ref"]

	var desc_texts := _get_descriptions()
	if description_label and index < desc_texts.size():
		description_label.bbcode_enabled = true
		description_label.text = _reformat_description(desc_texts[index])

	if minigame_title:
		minigame_title.text = MINIGAME_NAMES.get(data["game"], MINIGAME_NAMES["default"])

	if difficulty_value:
		difficulty_value.text = DIFFICULTY_NAMES[data["difficulty"]]

	if risk_value:
		risk_value.text = RISK_LEVELS[data["risk"]]
		risk_value.add_theme_color_override("font_color", RISK_COLORS[data["risk"]])

func _reformat_description(raw: String) -> String:
	var text := raw
	text = text.replace("[color=#333333]", "[color=#c8d5e8]")
	text = text.replace("[color=red]",     "[color=#e83322]")
	return text

# ── ACCEPT ────────────────────────────────────────────────────────────────────
func _on_accept_pressed() -> void:
	if accept_button:
		accept_button.disabled = true
		accept_button.text     = "AUTHENTICATING..."
	await get_tree().create_timer(0.3).timeout
	GameManager.start_current_game()
	var game_path : String = GameManager.get_current_game_scene()
	if game_path != "":
		get_tree().change_scene_to_file(game_path)
	else:
		push_error("No game scene for index %d" % GameManager.current_article_index)

# ── HELPERS ───────────────────────────────────────────────────────────────────
func _load_font(path: String) -> FontFile:
	if ResourceLoader.exists(path):
		var f = load(path)
		if f is FontFile: return f
	return null

func block_escape() -> void: pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		shake_screen()

func shake_screen() -> void:
	var orig := position
	var tw   := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT)
	for i in range(4):
		tw.tween_property(self, "position:x", orig.x + 25, 0.05)
		tw.tween_property(self, "position:x", orig.x - 25, 0.05)
	tw.tween_property(self, "position", orig, 0.05)

func _process(_delta: float) -> void:
	if not _scroll_reset_done and scroll_container != null:
		scroll_container.scroll_vertical = 0
		scroll_container.follow_focus    = false
		_scroll_reset_done = true

func _get_descriptions() -> Array:
	return [
		"""[b]EFFECTIVE DATE:[/b] January 1, 2025

[b]1. ACCEPTANCE OF TERMS[/b]
By clicking "I Accept These Terms", you acknowledge that you have read, understood, and agree to be bound by these Terms of Service. If you do not agree, you must immediately discontinue use of our services.

[b]2. DATA COLLECTION AND USAGE[/b]
We collect, process, store, analyze, and share your identity, biometric, location, device, usage, communication, financial and health data.

[b]3. HOW WE USE YOUR INFORMATION[/b]
We may use your information for any purpose including selling to third-party data brokers, sharing with government agencies, and training AI models.

[color=#e83322][b]BY CLICKING "I ACCEPT", YOU AGREE TO ALL TERMS.[/b][/color]""",
		"""[b]ARTICLE 2.3: COOKIE USAGE POLICY[/b]

We use cookies and tracking technologies including browser fingerprinting, tracking pixels, and device fingerprinting to track everything you do across all devices.

[color=#e83322][b]BY CONTINUING, YOU CONSENT TO OUR COOKIE PRACTICES.[/b][/color]""",
		"""[b]ARTICLE 3.7: THIRD-PARTY INFORMATION SHARING[/b]

We share your personal information with 847+ advertising partners, data brokers, analytics providers, social media platforms, and government agencies.

[color=#e83322][b]BY ACCEPTING, YOUR DATA WILL BE SHARED WITH COUNTLESS THIRD PARTIES.[/b][/color]""",
		"""[b]ARTICLE 4.2: ACCOUNT TERMINATION RIGHTS[/b]

We reserve the right to suspend, terminate, or delete your account at any time, for any reason, without prior notice, explanation, or refund.""",
		"""[b]ARTICLE 5.1: INTELLECTUAL PROPERTY[/b]

All content you create or upload becomes our exclusive property in perpetuity throughout the universe.""",
		"""[b]ARTICLE 6.4: BINDING ARBITRATION[/b]

You waive all rights to participate in class action lawsuits and agree to binding arbitration.""",
		"""[b]ARTICLE 7.8: LIABILITY LIMITATIONS[/b]

Under no circumstances shall we be liable for any damages, losses, or claims arising from your use of our services.""",
		"""[b]ARTICLE 8.3: USER CONTENT OWNERSHIP[/b]

By posting content, you grant us a worldwide, perpetual, irrevocable license to use, modify, and distribute your content.""",
		"""[b]ARTICLE 9.2: GDPR COMPLIANCE[/b]

We comply with GDPR requirements subject to our own interpretation of what compliance means.""",
		"""[b]ARTICLE 10.5: CCPA PRIVACY RIGHTS[/b]

California residents have specific privacy rights which may be exercised through our deliberately convoluted process.""",
		"""[b]ARTICLE 11.1: CHILDREN\'S PRIVACY[/b]

We do not knowingly collect information from children under 13, but we are not actively verifying ages.""",
		"""[b]ARTICLE 12.6: AUTOMATIC RENEWAL[/b]

Your subscription automatically renews unless you cancel 30 days before renewal through our deliberately hidden settings.""",
		"""[b]ARTICLE 13.3: CLASS ACTION WAIVER[/b]

You agree to resolve all disputes individually and permanently waive your right to participate in class actions.""",
		"""[b]ARTICLE 14.9: GOVERNING LAW[/b]

These terms are governed by the laws of our preferred jurisdiction, regardless of where you actually reside.""",
		"""[b]ARTICLE 15.0: FINAL AGREEMENT[/b]

By clicking accept, you confirm that you have read, understood, and agree to be legally bound by all 15 articles of this agreement in perpetuity.""",
	]