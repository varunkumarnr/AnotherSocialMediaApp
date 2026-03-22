extends VBoxContainer
class_name PostCard

const COLOR_CYAN  := Color(0.0,   0.831, 1.0,   1)
const COLOR_MUTED := Color(0.29,  0.353, 0.439, 1)
const COLOR_TEXT  := Color(0.784, 0.831, 0.910, 1)
const COLOR_DIM   := Color(0.478, 0.561, 0.659, 1)

const FONT_PATH := "res://assets/fonts/JetBrainsMono-Regular.ttf"

@onready var avatar     = $PostHeader/HeaderMargin/HeaderHBox/Avatar
@onready var username   = $PostHeader/HeaderMargin/HeaderHBox/UsernameVBox/Username
@onready var handle     = $PostHeader/HeaderMargin/HeaderHBox/UsernameVBox/Handle
@onready var post_image = $PostImage
@onready var like_count = $CaptionMargin/CaptionVBox/LikeCount
@onready var caption    = $CaptionMargin/CaptionVBox/PostDescription

var post_data: Dictionary

func _ready() -> void:
	# Dark background via self_modulate since root is VBoxContainer
	self_modulate = Color(1, 1, 1, 1)
	var bg = ColorRect.new()
	bg.color = Color(0.059, 0.071, 0.094, 1)
	bg.layout_mode = 1
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.z_index = -1
	add_child(bg)
	move_child(bg, 0)
	_apply_font_to_all(self)

func setup(data: Dictionary) -> void:
	post_data = data

	if username:
		username.text = data.get("username", "Unknown")
	if handle:
		handle.text = "@" + data.get("handle", data.get("username", "unknown")).to_lower()

	if avatar and data.has("avatar"):
		var tex = load(data["avatar"])
		if tex:
			avatar.texture = tex

	if post_image and data.has("post_image"):
		var tex = load(data["post_image"])
		if tex:
			post_image.texture = tex

	if like_count:
		like_count.text = format_number(data.get("likes", 0)) + " Likes"

	if caption:
		caption.text = data.get("username", "") + "  " + data.get("caption", "")

func format_number(num: int) -> String:
	if num >= 1000000:
		return "%.1fM" % (num / 1000000.0)
	elif num >= 1000:
		return "%.1fK" % (num / 1000.0)
	return str(num)

func _apply_font_to_all(node: Node) -> void:
	if not ResourceLoader.exists(FONT_PATH):
		return
	var font = load(FONT_PATH)
	_set_font_recursive(node, font)

func _set_font_recursive(node: Node, font: FontFile) -> void:
	if node is Label:
		node.add_theme_font_override("font", font)
	for child in node.get_children():
		_set_font_recursive(child, font)
