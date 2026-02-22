extends Control

@onready var click_blocker = $ClickBlocker
@onready var post_feed = $MarginContainer/VBoxContainer/Posts/ScrollContainer/PostFeed
@onready var scroll = $MarginContainer/VBoxContainer/Posts/ScrollContainer

var login_popup_scene = preload("res://scenes/core/login.tscn")
var post_card_scene = preload("res://scenes/core/postCard.tscn")

var posts_data: Array = []

func _ready() -> void:
	print("=== MAIN SCENE READY ===")
	print("Click blocker exists: ", click_blocker != null)
	print("Post feed exists: ", post_feed != null)
	print("Scroll container exists: ", scroll != null)
	
	setup_ui()
	load_posts_data()
	generate_posts()
	setup_click_blocker()
	animate_posts_in()  

func load_posts_data():
	print("\n=== LOADING POSTS DATA ===")
	var file_path = "res://assets/data/fake_posts.json"
	
	print("Checking file: ", file_path)
	print("File exists: ", FileAccess.file_exists(file_path))
	
	if not FileAccess.file_exists(file_path):
		push_error("Posts JSON file not found!")
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	print("JSON string length: ", json_string.length())
	print("First 100 chars: ", json_string.substr(0, 100))
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error == OK:
		var data = json.data
		print("JSON parsed successfully")
		print("Data type: ", typeof(data))
		print("Has 'posts' key: ", data.has("posts"))
		
		if data.has("posts"):
			posts_data = data["posts"]
			print("✅ Loaded ", posts_data.size(), " posts")
			
			# Print first post data
			if posts_data.size() > 0:
				print("First post data: ", posts_data[0])
	else:
		push_error("JSON Parse Error: ", json.get_error_message())

func generate_posts():
	print("\n=== GENERATING POSTS ===")
	print("Posts data array size: ", posts_data.size())
	print("Post feed node: ", post_feed)
	print("Post feed child count before: ", post_feed.get_child_count())
	
	# Clear existing
	for child in post_feed.get_children():
		print("Removing child: ", child.name)
		child.queue_free()
	
	# Generate posts from data
	for i in range(posts_data.size()):
		var post_data = posts_data[i]
		print("\nCreating post ", i, ":")
		print("  Username: ", post_data.get("username", "NONE"))
		print("  Likes: ", post_data.get("likes", 0))
		
		var post_card = post_card_scene.instantiate()
		print("  Post card instantiated: ", post_card)
		print("  Post card type: ", post_card.get_class())
		print("  Has setup method: ", post_card.has_method("setup"))
		
		post_feed.add_child(post_card)
		
		await get_tree().process_frame
		
		if post_card.has_method("setup"):
			print("  Calling setup...")
			post_card.setup(post_data)
			print("  ✅ Setup complete")
		else:
			print("  ❌ NO SETUP METHOD!")
		
		print("  Post card visible: ", post_card.visible)
		print("  Post card size: ", post_card.size)
		print("  Post card position: ", post_card.position)
	
	print("\n=== GENERATION COMPLETE ===")
	print("Post feed child count after: ", post_feed.get_child_count())
	print("Post feed children:")
	for child in post_feed.get_children():
		print("  - ", child.name, " | Visible: ", child.visible, " | Size: ", child.size)

func setup_ui():
	print("\n=== SETUP UI ===")
	$ColorRect.color = Color(0.98, 0.98, 0.98) 
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	print("Scroll container size: ", scroll.size)
	print("Post feed size: ", post_feed.size)

func setup_click_blocker():
	print("\n=== SETUP CLICK BLOCKER ===")
	click_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	click_blocker.gui_input.connect(_on_screen_clicked)
	click_blocker.color = Color(0, 0, 0, 0.01)
	print("Click blocker size: ", click_blocker.size)
	print("Click blocker visible: ", click_blocker.visible)

func _on_screen_clicked(event: InputEvent):
	if event is InputEventScreenTouch and event.pressed:
		print("Touch detected")
		show_login_popup()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Mouse click detected")
		show_login_popup()

func show_login_popup():
	print("\n=== SHOWING LOGIN POPUP ===")
	var login_popup = login_popup_scene.instantiate()
	add_child(login_popup)
	click_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_login_popup_closed():
	click_blocker.mouse_filter = Control.MOUSE_FILTER_STOP

func animate_posts_in():
	var posts = post_feed.get_children()
	
	for i in range(posts.size()):
		var post = posts[i]
		post.modulate.a = 0
		await get_tree().create_timer(i * 0.1).timeout
		var tween = create_tween()
		tween.tween_property(post, "modulate:a", 1.0, 0.3)
