extends VBoxContainer
class_name PostCard

@onready var avatar = $PostHeader/Avatar
@onready var username = $PostHeader/Username
@onready var post_image = $PostImage
@onready var like_count = $LikeCount
@onready var caption = $PostDescription

var post_data: Dictionary

func setup(data: Dictionary): 
	post_data = data
	
	# Username
	if username: 
		var u_name = data.get("username", "Unknown")
		var u_handle = data.get("handle", "Unknown")
		username.text = u_name + "\n" + u_handle
	
	# Avatar 
	if avatar and data.has("avatar"):  
		var avatar_texture = load(data["avatar"])  
		if avatar_texture: 
			avatar.texture = avatar_texture
	
	if post_image and data.has("post_image"):
		var post_texture = load(data["post_image"])
		if post_texture: 
			post_image.texture = post_texture
	
	# Like Count
	if like_count: 
		like_count.text = format_number(data.get("likes", 0)) + " Likes"
	
	# Caption
	if caption:
		var caption_text = data.get("caption", "")
		caption.text = data.get("username", "") + " " + caption_text

func format_number(num: int) -> String:
	if num >= 1000000:
		return str(num / 1000000.0).pad_decimals(1) + "M"
	elif num >= 1000:
		return str(num / 1000.0).pad_decimals(1) + "K"
	else:
		return str(num)
