extends Control

const COLOR_BG    := Color(0.039, 0.047, 0.063, 1)
const COLOR_BG2   := Color(0.059, 0.071, 0.094, 1)
const COLOR_CYAN  := Color(0.0,   0.831, 1.0,   1)
const COLOR_GREEN := Color(0.0,   1.0,   0.533, 1)
const COLOR_RED   := Color(0.9,   0.2,   0.1,   1)
const COLOR_MUTED := Color(0.29,  0.353, 0.439, 1)
const COLOR_TEXT  := Color(0.784, 0.831, 0.910, 1)

const FONT_PATH := "res://assets/fonts/JetBrainsMono-Regular.ttf"
var mono_font: FontFile = null

# Don't use @onready — find nodes safely in _ready instead
var article_number_label: Label
var article_title_label: Label
var description_label: RichTextLabel
var minigame_title: Label
var difficulty_value: Label
var risk_value: Label
var accept_button: Button
var scroll_container: ScrollContainer

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
	_load_font()
	_find_nodes()
	if accept_button == null:
		push_error("AcceptButton not found")
		return
	accept_button.focus_mode = Control.FOCUS_NONE
	accept_button.mouse_filter = Control.MOUSE_FILTER_STOP
	accept_button.pressed.connect(_on_accept_pressed)
	var index := GameManager.get_current_article_index()
	_populate(index)
	# Disable follow_focus immediately


func _fix_section_backgrounds() -> void:
	var sections := [
		["TitleSection",    COLOR_BG,  false],
		["BriefingSection", COLOR_BG2, true],
		["TargetingSection",COLOR_BG2, true],
		["ParamsSection",   COLOR_BG2, true],
		["EncryptionBar",   COLOR_BG2, false],
	]
	for s in sections:
		var node: Panel = _find_node(self, s[0])
		if node == null:
			continue
		var sb := StyleBoxFlat.new()
		sb.bg_color = s[1]
		if s[2]:
			sb.border_color          = Color(0.118, 0.137, 0.176, 1)
			sb.border_width_left     = 3
			sb.border_width_top      = 1
			sb.border_width_right    = 1
			sb.border_width_bottom   = 1
		node.add_theme_stylebox_override("panel", sb)

func _reset_scroll() -> void:
	# Wait multiple frames for layout to fully settle
	for i in range(10):
		await get_tree().process_frame
	if scroll_container:
		scroll_container.scroll_vertical = 0

func _find_nodes() -> void:
	# Walk the tree safely instead of hardcoded paths
	scroll_container     = _find_node(self, "ScrollContainer")
	article_number_label = _find_node(self, "ArticleNumberLabel")
	article_title_label  = _find_node(self, "ArticleTitleLabel")
	description_label    = _find_node(self, "DescriptionLabel")
	minigame_title       = _find_node(self, "MinigameTitle")
	difficulty_value     = _find_node(self, "DifficultyValue")
	risk_value           = _find_node(self, "RiskValue")
	accept_button        = _find_node(self, "AcceptButton")

func _find_node(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child in root.get_children():
		var result = _find_node(child, node_name)
		if result != null:
			return result
	return null


func _load_font() -> void:
	if ResourceLoader.exists(FONT_PATH):
		mono_font = load(FONT_PATH)

func _af(node: Node) -> void:
	if mono_font == null:
		return
	if node is Label or node is Button:
		node.add_theme_font_override("font", mono_font)
	if node is RichTextLabel:
		node.add_theme_font_override("normal_font", mono_font)
	for child in node.get_children():
		_af(child)

func _populate(index: int) -> void:
	_fix_section_backgrounds()
	if index >= article_data.size():
		return
	var data = article_data[index]

	if article_number_label:
		article_number_label.text = "MODULE " + data["number"] + ":"
	if article_title_label:
		article_title_label.text = data["title"]

	var ref_lbl: Label = _find_node(self, "RefLabel")
	if ref_lbl:
		ref_lbl.text = "REF: " + data["ref"]

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

	_af(self)

func _reformat_description(raw: String) -> String:
	var text = raw
	text = text.replace("[font_size=20]", "")
	text = text.replace("[color=#333333]", "[color=#9aafc0]")
	text = text.replace("[color=red]", "[color=#e83322]")
	return text

func _on_accept_pressed() -> void:
	if accept_button:
		accept_button.disabled = true
		accept_button.text = "AUTHENTICATING..."
	await get_tree().create_timer(0.3).timeout
	GameManager.start_current_game()
	var game_path: String = GameManager.get_current_game_scene()
	if game_path != "":
		get_tree().change_scene_to_file(game_path)
	else:
		push_error("No game scene for index %d" % GameManager.current_article_index)

func block_escape() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		shake_screen()

func shake_screen() -> void:
	var original_pos = position
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	for i in range(4):
		tween.tween_property(self, "position:x", original_pos.x + 25, 0.05)
		tween.tween_property(self, "position:x", original_pos.x - 25, 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)

func _get_descriptions() -> Array:
	return [
		"""[b]EFFECTIVE DATE:[/b] January 1, 2025

[b]1. ACCEPTANCE OF TERMS[/b]
By clicking "I Accept These Terms", you acknowledge that you have read, understood, and agree to be bound by these Terms of Service. If you do not agree, you must immediately discontinue use of our services.

[b]2. DATA COLLECTION AND USAGE[/b]
We collect, process, store, analyze, and share the following categories of personal information including identity, biometric, location, device, usage, communication, financial and health data.

[b]3. HOW WE USE YOUR INFORMATION[/b]
We may use your information for any purpose including selling to third-party data brokers, sharing with government agencies, and training AI models.

[color=#e83322][b]BY CLICKING "I ACCEPT", YOU AGREE TO ALL TERMS.[/b][/color]""",
		"""[b]ARTICLE 2.3: COOKIE USAGE POLICY[/b]

We use cookies and similar tracking technologies including browser fingerprinting, tracking pixels, and device fingerprinting to track everything you do across all devices.

[color=#e83322][b]BY CONTINUING TO USE OUR SERVICE, YOU CONSENT TO OUR COOKIE PRACTICES.[/b][/color]""",
		"""[b]ARTICLE 3.7: THIRD-PARTY INFORMATION SHARING[/b]

We share your personal information with 847+ advertising partners, data brokers, analytics providers, social media platforms, government agencies, and intelligence services.

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
		"""[b]ARTICLE 11.1: CHILDREN'S PRIVACY[/b]

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

func _process(_delta: float) -> void:
	if not _scroll_reset_done and scroll_container != null:
		scroll_container.scroll_vertical = 0
		scroll_container.follow_focus = false
		_scroll_reset_done = true
