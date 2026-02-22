extends PopupPanel

signal popup_closed

@onready var username_field = $MarginContainer/VBoxContainer/UsernameField
@onready var password_field = $MarginContainer/VBoxContainer/PasswordField
@onready var toc_checkbox = $MarginContainer/VBoxContainer/TOCContainer/TOCCheckbox
@onready var toc_link_button = $MarginContainer/VBoxContainer/TOCContainer/TOCLinkButton
@onready var login_button = $MarginContainer/VBoxContainer/LoginButton

func _ready() -> void:
	setup_popup()
	setup_ui()
	setup_checkbox_icons()
	connect_signals()
	
	popup_centered()
	
	await get_tree().process_frame
	username_field.grab_focus()

func setup_popup():
	borderless = false
	transient = false  
	exclusive = true
	unresizable = true  
	size = Vector2(800, 800)
	min_size = Vector2(800, 800)
	
	close_requested.connect(_on_close_attempt)  
	popup_hide.connect(_on_hide_attempt)  
func setup_ui():
	
	username_field.placeholder_text = "Username or email"
	username_field.custom_minimum_size.y = 100
	username_field.clear_button_enabled = true

	password_field.placeholder_text = "Password"
	password_field.secret = true
	password_field.secret_character = "•"
	password_field.custom_minimum_size.y = 100

	toc_link_button.flat = true
	toc_link_button.text = "I agree to the Terms & Conditions"
	toc_link_button.alignment = HORIZONTAL_ALIGNMENT_LEFT

	login_button.disabled = true
	login_button.text = "Log In"
	login_button.custom_minimum_size.y = 100

func setup_checkbox_icons():
	toc_checkbox.custom_minimum_size = Vector2(100, 100)
	
	var unchecked_icon = create_unchecked_icon()
	var checked_icon = create_checked_icon()
	
	toc_checkbox.add_theme_icon_override("checked", checked_icon)
	toc_checkbox.add_theme_icon_override("unchecked", unchecked_icon)
	toc_checkbox.add_theme_constant_override("h_separation", 12)
	toc_checkbox.add_theme_font_size_override("font_size", 48)

func create_unchecked_icon() -> ImageTexture:
	var c_size = 100
	var img = Image.create(c_size, c_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var border_color = Color(0.4, 0.4, 0.4, 1)
	var border_width = 6
	
	for x in range(c_size):
		for y in range(c_size):
			if (x < border_width or x >= c_size - border_width or 
				y < border_width or y >= c_size - border_width):
				img.set_pixel(x, y, border_color)
	
	return ImageTexture.create_from_image(img)

func create_checked_icon() -> ImageTexture:
	var c_size = 100  
	var img = Image.create(c_size, c_size, false, Image.FORMAT_RGBA8)
	
	var fill_color = Color(0.22, 0.59, 0.94, 1)  
	img.fill(fill_color)
	
	var check_color = Color(1, 1, 1, 1)
	
	for i in range(25):
		var x = 25 + i
		var y = 50 + i
		if x < c_size and y < c_size:
			for offset in range(-3, 4):
				if x + offset >= 0 and x + offset < c_size:
					img.set_pixel(x + offset, y, check_color)
	
	for i in range(35):
		var x = 50 + i
		var y = 75 - i
		if x < c_size and y < c_size and y >= 0:
			for offset in range(-3, 4):
				if x + offset >= 0 and x + offset < c_size:
					img.set_pixel(x + offset, y, check_color)
	
	return ImageTexture.create_from_image(img)

func connect_signals():
	login_button.pressed.connect(_on_login_pressed)
	toc_link_button.pressed.connect(_on_toc_link_pressed)
	toc_checkbox.toggled.connect(_on_toc_toggled)
	username_field.text_submitted.connect(_try_submit)
	password_field.text_submitted.connect(_try_submit)

func _on_toc_toggled(is_checked: bool):
	login_button.disabled = not is_checked
	_navigate_to_articles()
	if is_checked:
		login_button.modulate = Color(1, 1, 1, 1)
	else:
		login_button.modulate = Color(0.6, 0.6, 0.6, 1)

func _on_toc_link_pressed():
	_navigate_to_articles()

func _on_login_pressed():
	if username_field.text.strip_edges().is_empty():
		shake_popup()
		show_error("Please enter a username")
		username_field.grab_focus()
		return
	
	if password_field.text.is_empty():
		shake_popup()
		show_error("Please enter a password")
		password_field.grab_focus()
		return
	
	if not toc_checkbox.button_pressed:
		shake_popup()
		show_error("Please accept Terms & Conditions")
		return
	
	login_button.text = "Logging in..."
	login_button.disabled = true
	
	await get_tree().create_timer(0.8).timeout
	
	_navigate_to_articles()

func _navigate_to_articles():
	emit_signal("popup_closed")
	queue_free()
	get_tree().change_scene_to_file("res://scenes/core/ArticleProgress.tscn")

func _try_submit(_text: String = ""):
	if not login_button.disabled:
		_on_login_pressed()

func _on_close_attempt():
	shake_popup()
	show_error("You must log in to continue")

func _on_hide_attempt():
	show()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):  
		shake_popup()
		show_error("Nice try! You must log in")
		get_viewport().set_input_as_handled()

func shake_popup():
	var original_pos = Vector2(position)
	var shake_amount = 15
	var shake_duration = 0.05
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	for i in range(3):
		tween.tween_property(self, "position:x", original_pos.x + shake_amount, shake_duration)
		tween.tween_property(self, "position:x", original_pos.x - shake_amount, shake_duration)
	
	tween.tween_property(self, "position", original_pos, shake_duration)

func show_error(message: String):
	print("Error: ", message)
