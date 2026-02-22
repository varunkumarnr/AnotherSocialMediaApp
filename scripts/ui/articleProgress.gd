extends Control

# References
@onready var progress_label = $MarginContainer/VBoxContainer/HeaderPanel/VBoxContainer/ProgressLabel
@onready var article_list = $MarginContainer/VBoxContainer/ArticleScrollContainer/ArticleListContainer

# Article data (titles and previews)
var article_data = [
	{
		"number": "1.1",
		"title": "Data Privacy & Collection",
		"preview": "By accepting these terms, you acknowledge that we may collect, process, and share your personal information..."
	},
	{
		"number": "2.3",
		"title": "Cookie Usage Policy",
		"preview": "We use cookies and similar tracking technologies to enhance your experience and analyze usage patterns..."
	},
	{
		"number": "3.7",
		"title": "Third-Party Information Sharing",
		"preview": "Your information may be shared with third-party advertisers, data brokers, and analytics providers..."
	},
	{
		"number": "4.2",
		"title": "Account Termination Rights",
		"preview": "We reserve the right to suspend or terminate your account at any time, for any reason, without prior notice..."
	},
	{
		"number": "5.1",
		"title": "Intellectual Property Clauses",
		"preview": "All content you create, upload, or share becomes our exclusive property in perpetuity throughout the universe..."
	},
	{
		"number": "6.4",
		"title": "Binding Arbitration Agreement",
		"preview": "You waive all rights to participate in class action lawsuits and agree to binding arbitration..."
	},
	{
		"number": "7.8",
		"title": "Liability Limitations",
		"preview": "Under no circumstances shall we be liable for any damages, losses, or claims arising from your use..."
	},
	{
		"number": "8.3",
		"title": "User Content Ownership",
		"preview": "By posting content, you grant us a worldwide, perpetual, irrevocable license to use, modify, and distribute..."
	},
	{
		"number": "9.2",
		"title": "GDPR Compliance Standards",
		"preview": "We comply with GDPR requirements for users in the European Economic Area, subject to our interpretation..."
	},
	{
		"number": "10.5",
		"title": "CCPA Privacy Rights",
		"preview": "California residents have specific privacy rights, which may be exercised through our convoluted process..."
	},
	{
		"number": "11.1",
		"title": "Children's Privacy Protection",
		"preview": "We do not knowingly collect information from children under 13, but we're not actively verifying ages..."
	},
	{
		"number": "12.6",
		"title": "Automatic Renewal Terms",
		"preview": "Your subscription automatically renews unless you cancel 30 days before renewal through hidden settings..."
	},
	{
		"number": "13.3",
		"title": "Class Action Waiver",
		"preview": "You agree to resolve all disputes individually and waive your right to participate in class actions..."
	},
	{
		"number": "14.9",
		"title": "Governing Law & Jurisdiction",
		"preview": "These terms are governed by the laws of our preferred jurisdiction, regardless of where you reside..."
	},
	{
		"number": "15.0",
		"title": "Final Agreement & Acceptance",
		"preview": "By clicking accept, you confirm that you have read, understood, and agree to be bound by all terms..."
	}
]

func _ready():
	# Initialize game if needed
	if GameManager.game_sequence.is_empty():
		GameManager.start_new_game()
	
	generate_article_cards()
	update_progress_display()
	
	# Block escape
	block_escape()
	
	print("📋 ArticleProgress loaded - Article ", GameManager.current_article_index + 1, "/15")

func generate_article_cards():
	# Clear existing cards
	for child in article_list.get_children():
		child.queue_free()
	
	# Create 15 article cards
	for i in range(15):
		var card = create_article_card(i)
		article_list.add_child(card)

func create_article_card(index: int) -> PanelContainer:
	var card = PanelContainer.new()
	card.name = "ArticleCard" + str(index + 1)
	card.custom_minimum_size = Vector2(1000, 400)
	
	# Determine state
	var is_current = (index == GameManager.current_article_index)
	var is_completed = (index < GameManager.current_article_index)
	var is_locked = (index > GameManager.current_article_index)
	
	# Styling based on state
	var style = StyleBoxFlat.new()
	if is_current:
		style.bg_color = Color(1, 1, 1, 1)
		style.border_color = Color(0.22, 0.59, 0.94, 1)  # Blue
		style.set_border_width_all(4)
	elif is_completed:
		style.bg_color = Color(0.9, 1, 0.9, 1)  # Light green
		style.border_color = Color(0.4, 0.7, 0.4, 1)
		style.set_border_width_all(2)
	else:  # locked
		style.bg_color = Color(0.85, 0.85, 0.85, 0.5)
		style.border_color = Color(0.6, 0.6, 0.6, 1)
		style.set_border_width_all(2)
	
	style.set_corner_radius_all(12)
	card.add_theme_stylebox_override("panel", style)
	
	# Content container
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	# Header (Status + Number)
	var header = HBoxContainer.new()
	vbox.add_child(header)
	 
	# Status icon
	var status = Label.new()
	if is_completed:
		status.text = "✓"
		status.add_theme_color_override("font_color", Color(0.2, 0.7, 0.2))
	elif is_current:
		status.text = "○"
		status.add_theme_color_override("font_color", Color(0.22, 0.59, 0.94))
	else:
		status.text = "🔒"
		status.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	status.add_theme_font_size_override("font_size", 36)
	header.add_child(status)
	
	# Article number
	var number_label = Label.new()
	number_label.text = "Article " + article_data[index]["number"]
	number_label.add_theme_font_size_override("font_size", 24)
	if is_locked:
		number_label.modulate = Color(0.5, 0.5, 0.5)
	header.add_child(number_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	# Title
	var title = Label.new()
	title.text = article_data[index]["title"]
	title.add_theme_font_size_override("font_size", 28)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	if is_locked:
		title.modulate = Color(0.5, 0.5, 0.5)
	vbox.add_child(title)
	
	# Preview
	var preview = Label.new()
	preview.text = article_data[index]["preview"]
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD
	preview.add_theme_font_size_override("font_size", 20)
	preview.modulate = Color(0.4, 0.4, 0.4)
	vbox.add_child(preview)
	
	# Separator
	var sep = Control.new()
	sep.custom_minimum_size.y = 10
	vbox.add_child(sep)
	
	# Button
	var button = Button.new()
	if is_current:
		button.text = "Review Article →"
		button.disabled = false
		button.pressed.connect(_on_view_article.bind(index))
	elif is_completed:
		button.text = "✓ Completed"
		button.disabled = true
	else:
		button.text = "🔒 Locked"
		button.disabled = true
	
	button.custom_minimum_size.y = 90
	button.add_theme_font_size_override("font_size", 26)
	vbox.add_child(button)
	
	return card

func _on_view_article(index: int):
	print("📖 Opening article ", index + 1)
	# Navigate to article detail view
	get_tree().change_scene_to_file("res://scenes/core/articleView.tscn")

func update_progress_display():
	var completed = GameManager.current_article_index
	progress_label.text = "Article %d/15 Accepted" % completed

func block_escape():
	get_tree().root.set_input_as_handled()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		shake_screen()

func shake_screen():
	var original_pos = position
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	
	for i in range(3):
		tween.tween_property(self, "position:x", original_pos.x + 20, 0.05)
		tween.tween_property(self, "position:x", original_pos.x - 20, 0.05)
	
	tween.tween_property(self, "position", original_pos, 0.05)
