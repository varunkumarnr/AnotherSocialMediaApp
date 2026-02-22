extends Control

@onready var article_label = $CenterContainer/VBoxContainer/ArticleLabel
@onready var instruction_label = $CenterContainer/VBoxContainer/InstructionLabel
@onready var agree_button = $CenterContainer/VBoxContainer/AgreeButton
@onready var background = $ColorRect

func _ready():
	# Set random background color for variety
	background.color = Color(
		randf_range(0.7, 0.9),
		randf_range(0.7, 0.9),
		randf_range(0.7, 0.9)
	)
	
	# Show which article this is
	var article_num = GameManager.current_article_index + 1
	article_label.text = "Article %d Challenge" % article_num
	instruction_label.text = "Article %d/15 - Click to complete" % article_num
	
	# Connect button
	agree_button.pressed.connect(_on_agree_pressed)
	
	print("🎮 Test level loaded for article ", article_num)

func _on_agree_pressed():
	print("✅ User clicked agree!")
	
	# Visual feedback
	agree_button.disabled = true
	agree_button.text = "Completing..."
	
	# Small delay for satisfaction
	await get_tree().create_timer(0.5).timeout
	
	# Tell GameManager we completed this article
	GameManager.complete_current_article()