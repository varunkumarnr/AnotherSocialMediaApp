extends PopupPanel

signal popup_closed

const FONT_PATH := "res://assets/fonts/JetBrainsMono-Regular.ttf"
var mono_font: FontFile = null

@onready var username_field  = $MainVBox/ContentMargin/ContentVBox/FieldsVBox/UsernameField
@onready var password_field  = $MainVBox/ContentMargin/ContentVBox/FieldsVBox/PasswordField
@onready var toc_checkbox    = $MainVBox/ContentMargin/ContentVBox/TOCContainer/TOCCheckbox
@onready var toc_link_button = $MainVBox/ContentMargin/ContentVBox/TOCContainer/TOCLinkButton
@onready var login_button    = $MainVBox/ContentMargin/ContentVBox/LoginButton
@onready var time_label      = $MainVBox/ContentMargin/ContentVBox/FooterMargin/FooterHBox/TimeLabel
@onready var protocol_label  = $MainVBox/ContentMargin/ContentVBox/ProtocolLabel

func _ready() -> void:
	_load_font()
	setup_popup()
	setup_ui()
	setup_checkbox_icons()
	connect_signals()
	popup_centered()
	await get_tree().process_frame
	username_field.grab_focus()

func _load_font() -> void:
	if ResourceLoader.exists(FONT_PATH):
		mono_font = load(FONT_PATH)
	_apply_font_recursive(self)

func _apply_font_recursive(node: Node) -> void:
	if mono_font == null:
		return
	if node is Label or node is LineEdit or node is Button or node is CheckBox:
		node.add_theme_font_override("font", mono_font)
	for child in node.get_children():
		_apply_font_recursive(child)

func _process(_delta: float) -> void:
	if time_label:
		var t := Time.get_time_dict_from_system()
		var ms := Time.get_ticks_msec() % 1000
		time_label.text = "TIME: %02d:%02d:%02d:%03d" % [t.hour, t.minute, t.second, ms]

func setup_popup() -> void:
	borderless = false
	transient = false
	exclusive = true
	unresizable = true
	size = Vector2(800, 1400)
	min_size = Vector2(800, 1400)
	close_requested.connect(_on_close_attempt)
	popup_hide.connect(_on_hide_attempt)

func setup_ui() -> void:
	username_field.placeholder_text = "ENTER IDENTIFIER"
	password_field.placeholder_text = "••••••••••••"
	password_field.secret = true
	password_field.secret_character = "•"
	toc_link_button.flat = true
	login_button.disabled = true
	login_button.text = "INITIATE LOGIN"

func setup_checkbox_icons() -> void:
	toc_checkbox.custom_minimum_size = Vector2(60, 60)
	var unchecked_icon = _create_unchecked_icon()
	var checked_icon   = _create_checked_icon()
	toc_checkbox.add_theme_icon_override("checked", checked_icon)
	toc_checkbox.add_theme_icon_override("unchecked", unchecked_icon)
	toc_checkbox.add_theme_constant_override("h_separation", 12)
	toc_checkbox.add_theme_font_size_override("font_size", 28)

func _create_unchecked_icon() -> ImageTexture:
	var sz = 60
	var img = Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var border_color = Color(0.29, 0.353, 0.439, 1)
	var bw = 4
	for x in range(sz):
		for y in range(sz):
			if x < bw or x >= sz - bw or y < bw or y >= sz - bw:
				img.set_pixel(x, y, border_color)
	return ImageTexture.create_from_image(img)

func _create_checked_icon() -> ImageTexture:
	var sz = 60
	var img = Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.6, 0.9, 1))
	var check_color = Color(1, 1, 1, 1)
	for i in range(15):
		var x = 15 + i
		var y = 30 + i
		if x < sz and y < sz:
			for o in range(-2, 3):
				if x + o >= 0 and x + o < sz:
					img.set_pixel(x + o, y, check_color)
	for i in range(20):
		var x = 30 + i
		var y = 45 - i
		if x < sz and y < sz and y >= 0:
			for o in range(-2, 3):
				if x + o >= 0 and x + o < sz:
					img.set_pixel(x + o, y, check_color)
	return ImageTexture.create_from_image(img)

func connect_signals() -> void:
	login_button.pressed.connect(_on_login_pressed)
	toc_link_button.pressed.connect(_on_toc_link_pressed)
	toc_checkbox.toggled.connect(_on_toc_toggled)
	username_field.text_submitted.connect(_try_submit)
	password_field.text_submitted.connect(_try_submit)

func _on_toc_toggled(is_checked: bool) -> void:
	login_button.disabled = not is_checked

func _on_toc_link_pressed() -> void:
	_navigate_to_articles()

func _on_login_pressed() -> void:
	if username_field.text.strip_edges().is_empty():
		shake_popup()
		_flash_protocol("ERROR: NO IDENTIFIER PROVIDED")
		username_field.grab_focus()
		return
	if password_field.text.is_empty():
		shake_popup()
		_flash_protocol("ERROR: SECURITY KEY REQUIRED")
		password_field.grab_focus()
		return
	if not toc_checkbox.button_pressed:
		shake_popup()
		_flash_protocol("ERROR: TERMS NOT ACCEPTED")
		return
	login_button.text = "AUTHENTICATING..."
	login_button.disabled = true
	await get_tree().create_timer(0.8).timeout
	_navigate_to_articles()

func _flash_protocol(msg: String) -> void:
	if protocol_label:
		protocol_label.text = msg
		protocol_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1, 1))

func _navigate_to_articles() -> void:
	emit_signal("popup_closed")
	queue_free()
	get_tree().change_scene_to_file("res://scenes/core/ArticleProgress.tscn")

func _try_submit(_text: String = "") -> void:
	if not login_button.disabled:
		_on_login_pressed()

func _on_close_attempt() -> void:
	shake_popup()
	_flash_protocol("PROTOCOL 09-B: ACCESS DENIED")

func _on_hide_attempt() -> void:
	show()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		shake_popup()
		_flash_protocol("NICE TRY — ACCESS DENIED")
		get_viewport().set_input_as_handled()

func shake_popup() -> void:
	var original_pos = Vector2(position)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	for i in range(3):
		tween.tween_property(self, "position:x", original_pos.x + 15, 0.05)
		tween.tween_property(self, "position:x", original_pos.x - 15, 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)