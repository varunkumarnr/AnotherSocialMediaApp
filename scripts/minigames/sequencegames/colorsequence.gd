extends SequenceGame
class_name ColorSequenceGame

const COLOR_ITEMS := [
	{id = "red",    label = "", color = Color(0.90, 0.20, 0.20)},
	{id = "orange", label = "", color = Color(0.95, 0.55, 0.10)},
	{id = "yellow", label = "", color = Color(0.95, 0.88, 0.10)},
	{id = "green",  label = "", color = Color(0.15, 0.75, 0.30)},
	{id = "teal",   label = "", color = Color(0.10, 0.72, 0.65)},
	{id = "blue",   label = "", color = Color(0.18, 0.45, 0.90)},
	{id = "purple", label = "", color = Color(0.58, 0.20, 0.85)},
	{id = "pink",   label = "", color = Color(0.92, 0.30, 0.65)},
	{id = "white",  label = "", color = Color(0.92, 0.92, 0.92)},
]

func get_items() -> Array:
	return COLOR_ITEMS

func get_columns() -> int:
	return 3

func get_button_size() -> int:
	return 200  

func get_display_height() -> int:
	return 300

func get_item_color(id: String) -> Color:
	for item in COLOR_ITEMS:
		if item["id"] == id:
			return item["color"]
	return Color(0.5, 0.5, 0.5)

func get_item_label(_id: String) -> String:
	return ""