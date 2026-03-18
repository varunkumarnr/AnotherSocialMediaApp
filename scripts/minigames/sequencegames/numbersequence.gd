extends SequenceGame
class_name  NumberSequenceGame

const NUMBER_ITEMS := [
    {id = "1", label = "1", color = Color(0.90, 0.20, 0.20)},   # red
    {id = "2", label = "2", color = Color(0.95, 0.55, 0.10)},   # orange
    {id = "3", label = "3", color = Color(0.95, 0.88, 0.10)},   # yellow
    {id = "4", label = "4", color = Color(0.15, 0.75, 0.30)},   # green
    {id = "5", label = "5", color = Color(0.10, 0.72, 0.65)},   # teal
    {id = "6", label = "6", color = Color(0.18, 0.45, 0.90)},   # blue
    {id = "7", label = "7", color = Color(0.58, 0.20, 0.85)},   # purple
    {id = "8", label = "8", color = Color(0.92, 0.30, 0.65)},   # pink 
    {id = "9", label = "9", color = Color(0.50, 0.50, 0.50)},   # gray
]

func get_items() -> Array:
	return NUMBER_ITEMS

func get_columns() -> int:
	return 3  


func get_button_size() -> int:
	var vp_w : float = get_viewport().get_visible_rect().size.x
	var avail : float = min(vp_w, 700.0) - 80.0 - 30.0
	return int(avail / 3.0)

func get_display_height() -> int:
	return 300

func get_item_color(id: String) -> Color:
	for item in NUMBER_ITEMS:
		if item["id"] == id:
			return item["color"]
	return Color(0.5, 0.5, 0.5)

func get_item_label(id: String) -> String:
	for item in NUMBER_ITEMS:
		if item["id"] == id:
			return item["label"]
	return id

func get_max_rounds() -> int:
	return 7