# ── GuessRaceGame ─────────────────────────────────────────────────────────────
# Show a face image + clothing & food hints, pick the correct nationality.
# 5 random questions per session. One wrong answer ends the game.
# ─────────────────────────────────────────────────────────────────────────────
extends MiniGamesTemplate
class_name GuessRaceGame

# ── QUESTION BANK ─────────────────────────────────────────────────────────────
const ALL_QUESTIONS := [
	{"image":"res://assets/minigames/sprites/guessRace/indonesia.jpg","answer":2,"choices":["Malaysia","Indonesia","Brunei","Pakistan"],"wearing":"hijab, batik","food":"nasi goreng, satay","landmark":"Borobudur"},
	{"image":"res://assets/minigames/sprites/guessRace/india.jpg","answer":2,"choices":["Philippines","India","Indonesia","Sri Lanka"],"wearing":"barong","food":"biryani, dosa","landmark":"Taj Mahal"},
	{"image":"res://assets/minigames/sprites/guessRace/malaysia.jpg","answer":3,"choices":["Indonesia","Thailand","Malaysia","India"],"wearing":"baju kurung","food":"nasi lemak, laksa","landmark":"Petronas Towers"},
	{"image":"res://assets/minigames/sprites/guessRace/china.jpg","answer":3,"choices":["Japan","Korea","China","Vietnam"],"wearing":"qipao","food":"dumplings, fried rice","landmark":"Great Wall"},
	{"image":"res://assets/minigames/sprites/guessRace/japan.jpg","answer":1,"choices":["Japan","Korea","China","Vietnam"],"wearing":"kimono","food":"sushi, ramen","landmark":"Mount Fuji"},
	{"image":"res://assets/minigames/sprites/guessRace/india2.jpg","answer":4,"choices":["Pakistan","Nepal","Bangladesh","India"],"wearing":"sherwani","food":"butter chicken, naan","landmark":"Taj Mahal"},
	{"image":"res://assets/minigames/sprites/guessRace/korea.jpg","answer":3,"choices":["Japan","Mongolia","Korea","China"],"wearing":"hanbok","food":"kimchi, bibimbap","landmark":"Gyeongbokgung Palace"},
	{"image":"res://assets/minigames/sprites/guessRace/usa.jpg","answer":4,"choices":["Canada","UK","Australia","US"],"wearing":"flag","food":"burger, hot dog","landmark":"Statue of Liberty"},
	{"image":"res://assets/minigames/sprites/guessRace/spain.jpg","answer":2,"choices":["Italy","Spain","Portugal","Mexico"],"wearing":"matador","food":"paella, tapas","landmark":"Sagrada Familia"},
	{"image":"res://assets/minigames/sprites/guessRace/egypt.jpg","answer":4,"choices":["India","Pakistan","Morocco","Egypt"],"wearing":"galabeya","food":"koshari, falafel","landmark":"Pyramids of Giza"},
	{"image":"res://assets/minigames/sprites/guessRace/brazil.jpg","answer":2,"choices":["Argentina","Brazil","Colombia","Portugal"],"wearing":"football kit","food":"feijoada, pão de queijo","landmark":"Christ the Redeemer"},
	{"image":"res://assets/minigames/sprites/guessRace/saudi.jpg","answer":1,"choices":["Saudi Arabia","UAE","Qatar","Jordan"],"wearing":"thobe, keffiyeh","food":"kabsa, shawarma","landmark":"Kaaba"},
	{"image":"res://assets/minigames/sprites/guessRace/russia.jpg","answer":4,"choices":["Finland","Mongolia","Ukraine","Russia"],"wearing":"ushanka","food":"borscht, pelmeni","landmark":"Saint Basil's Cathedral"},
	{"image":"res://assets/minigames/sprites/guessRace/germany.jpg","answer":3,"choices":["Austria","Switzerland","Germany","Netherlands"],"wearing":"dirndl","food":"sausages, pretzel","landmark":"Brandenburg Gate"},
	{"image":"res://assets/minigames/sprites/guessRace/mexico.jpg","answer":2,"choices":["Peru","Mexico","Chile","Spain"],"wearing":"sombrero","food":"tacos, burrito","landmark":"Chichen Itza"},
	{"image":"res://assets/minigames/sprites/guessRace/france.jpg","answer":3,"choices":["Italy","Netherlands","France","UK"],"wearing":"beret","food":"croissant, baguette","landmark":"Eiffel Tower"},
	{"image":"res://assets/minigames/sprites/guessRace/vietnam.jpg","answer":1,"choices":["Vietnam","China","Thailand","Philippines"],"wearing":"non la","food":"pho, banh mi","landmark":"Ha Long Bay"},
	{"image":"res://assets/minigames/sprites/guessRace/mongolia.jpg","answer":2,"choices":["Kazakhstan","Mongolia","Nepal","China"],"wearing":"deel","food":"buuz, khuushuur","landmark":"Genghis Khan Statue"},
	{"image":"res://assets/minigames/sprites/guessRace/netherlands.jpg","answer":3,"choices":["Germany","Belgium","Netherlands","Denmark"],"wearing":"clogs","food":"stroopwafel, herring","landmark":"Windmills of Kinderdijk"},
	{"image":"res://assets/minigames/sprites/guessRace/greece.jpg","answer":4,"choices":["Italy","Turkey","Albania","Greece"],"wearing":"evzone","food":"gyros, moussaka","landmark":"Acropolis"},
	{"image":"res://assets/minigames/sprites/guessRace/peru.jpg","answer":2,"choices":["Bolivia","Peru","Chile","Ecuador"],"wearing":"chullo, poncho","food":"ceviche, lomo saltado","landmark":"Machu Picchu"},
	{"image":"res://assets/minigames/sprites/guessRace/australia.jpg","answer":3,"choices":["USA","Canada","Australia","South Africa"],"wearing":"outback hat","food":"meat pie, pavlova","landmark":"Sydney Opera House"},
	{"image":"res://assets/minigames/sprites/guessRace/turkey.jpg","answer":1,"choices":["Turkey","Morocco","Tunisia","Egypt"],"wearing":"fez","food":"kebab, baklava","landmark":"Hagia Sophia"},
	{"image":"res://assets/minigames/sprites/guessRace/nigeria.jpg","answer":4,"choices":["Ghana","Kenya","Ethiopia","Nigeria"],"wearing":"agbada","food":"jollof rice, suya","landmark":"Zuma Rock"},
	{"image":"res://assets/minigames/sprites/guessRace/poland.jpg","answer":1,"choices":["Poland","Ukraine","Lithuania","Hungary"],"wearing":"flower crown","food":"pierogi, bigos","landmark":"Wawel Castle"},
	{"image":"res://assets/minigames/sprites/guessRace/hungary.jpg","answer":2,"choices":["Austria","Hungary","Czech Republic","Slovakia"],"wearing":"embroidered vest","food":"goulash, paprika chicken","landmark":"Parliament Budapest"},
	{"image":"res://assets/minigames/sprites/guessRace/czech_republic.jpg","answer":3,"choices":["Poland","Slovakia","Czech Republic","Hungary"],"wearing":"folk headscarf","food":"svíčková, trdelník","landmark":"Charles Bridge"},
	{"image":"res://assets/minigames/sprites/guessRace/kenya.jpg","answer":2,"choices":["Tanzania","Kenya","Uganda","Ethiopia"],"wearing":"maasai beads","food":"ugali, nyama choma","landmark":"Maasai Mara"},
	{"image":"res://assets/minigames/sprites/guessRace/southafrica.jpg","answer":4,"choices":["Nigeria","Ghana","Kenya","South Africa"],"wearing":"ndebele patterns","food":"bobotie, biltong","landmark":"Table Mountain"},
	{"image":"res://assets/minigames/sprites/guessRace/portugal.jpg","answer":1,"choices":["Portugal","Spain","Italy","Greece"],"wearing":"fisherman cap","food":"bacalhau, pastel de nata","landmark":"Belem Tower"},
	{"image":"res://assets/minigames/sprites/guessRace/argentina.jpg","answer":3,"choices":["Chile","Uruguay","Argentina","Brazil"],"wearing":"gaucho hat","food":"asado, empanadas","landmark":"Obelisk of Buenos Aires"},
	{"image":"res://assets/minigames/sprites/guessRace/chile.jpg","answer":2,"choices":["Peru","Chile","Bolivia","Argentina"],"wearing":"huaso hat","food":"completo, pastel de choclo","landmark":"Moai Statues"}
]

const QUESTIONS_PER_GAME := 5

# ── COLOURS ───────────────────────────────────────────────────────────────────
const C_BTN_DEFAULT  := Color(0.082, 0.102, 0.133, 1)
const C_BTN_CORRECT  := Color(0.0,   0.55,  0.25,  1)
const C_BTN_WRONG    := Color(0.72,  0.08,  0.08,  1)
const C_BTN_BORDER   := Color(0.18,  0.24,  0.34,  1)
const C_TEXT         := Color(0.78,  0.83,  0.91,  1)
const C_ACCENT       := Color(0.35,  0.65,  1.00,  1)
const C_GOLD         := Color(1.00,  0.80,  0.20,  1)
const C_HINT_BG      := Color(0.06,  0.08,  0.12,  1)
const C_HINT_TEXT    := Color(0.60,  0.70,  0.85,  1)

# ── STATE ─────────────────────────────────────────────────────────────────────
var session_questions : Array = []
var current_q_idx     : int   = 0
var answered          : bool  = false

var popup             : GamePopup
var face_texture_rect : TextureRect
var hint_wearing_lbl  : Label
var hint_food_lbl     : Label
var hint_landmark_lbl : Label
var choice_buttons    : Array = []
var progress_labels   : Array = []

var rng := RandomNumberGenerator.new()

# ── ENTRY ─────────────────────────────────────────────────────────────────────
func on_game_started() -> void:
	rng.randomize()
	play_game_music()
	_pick_questions()
	await _build_ui()
	add_child(TCBackground.new())
	_load_question()

# ── QUESTION SELECTION ────────────────────────────────────────────────────────
func _pick_questions() -> void:
	var pool : Array = ALL_QUESTIONS.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j : int = rng.randi() % (i + 1)
		var tmp = pool[i]; pool[i] = pool[j]; pool[j] = tmp
	session_questions = pool.slice(0, QUESTIONS_PER_GAME)

# ── BUILD UI ──────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var config               := PopupConfig.new()
	config.title             = "Guess the Nationality!"
	config.panel_color       = "blue"
	config.show_close_button = false
	config.popup_width       = 460
	config.popup_height      = 0
	config.content_rows      = [{type = "separator"}]
	config.buttons           = []

	popup = POPUP_SCENE.instantiate()
	add_child(popup)
	popup.configure(config)

	await get_tree().process_frame
	await get_tree().process_frame

	var cc : VBoxContainer = popup.get_node(
		"Control/CenterContainer/Panel/VBoxContainer/ContentMargin/ContentContainer"
	)

	_build_progress_bar(cc)
	_build_face_area(cc)
	_build_hints(cc)
	_build_choice_buttons(cc)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 10)
	cc.add_child(sp)

# ── PROGRESS DOTS ─────────────────────────────────────────────────────────────
func _build_progress_bar(cc: VBoxContainer) -> void:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 6)
	cc.add_child(sp)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(center)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	center.add_child(hbox)

	progress_labels.clear()
	for i in range(QUESTIONS_PER_GAME):
		var dot := Label.new()
		dot.text = "●"
		dot.add_theme_font_size_override("font_size", 22)
		dot.add_theme_color_override("font_color",
			C_ACCENT if i == 0 else Color(0.25, 0.30, 0.40, 1))
		hbox.add_child(dot)
		progress_labels.append(dot)

	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 6)
	cc.add_child(sp2)

# ── FACE IMAGE ────────────────────────────────────────────────────────────────
func _build_face_area(cc: VBoxContainer) -> void:
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(center)

	var panel := PanelContainer.new()
	var sb    := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.11, 1)
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(2)
	sb.border_color = C_BTN_BORDER
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(260, 260)
	center.add_child(panel)

	face_texture_rect              = TextureRect.new()
	face_texture_rect.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	face_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face_texture_rect.custom_minimum_size        = Vector2(240, 240)
	face_texture_rect.size_flags_horizontal      = Control.SIZE_EXPAND_FILL
	face_texture_rect.size_flags_vertical        = Control.SIZE_EXPAND_FILL
	panel.add_child(face_texture_rect)

# ── HINTS ─────────────────────────────────────────────────────────────────────
func _build_hints(cc: VBoxContainer) -> void:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 10)
	cc.add_child(sp)

	# Hint panel — rounded pill background
	var panel := PanelContainer.new()
	var sb    := StyleBoxFlat.new()
	sb.bg_color = C_HINT_BG
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.18, 0.24, 0.34, 1)
	sb.content_margin_left   = 14
	sb.content_margin_right  = 14
	sb.content_margin_top    = 8
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Wearing hint
	var wearing_row := HBoxContainer.new()
	wearing_row.add_theme_constant_override("separation", 6)
	vbox.add_child(wearing_row)

	var w_icon := Label.new()
	w_icon.text = "wearing:"
	w_icon.add_theme_font_size_override("font_size", 20)
	wearing_row.add_child(w_icon)

	hint_wearing_lbl = Label.new()
	hint_wearing_lbl.add_theme_font_size_override("font_size", 22)
	hint_wearing_lbl.add_theme_color_override("font_color", C_HINT_TEXT)
	hint_wearing_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wearing_row.add_child(hint_wearing_lbl)

	# Food hint
	var food_row := HBoxContainer.new()
	food_row.add_theme_constant_override("separation", 6)
	vbox.add_child(food_row)

	var f_icon := Label.new()
	f_icon.text = "famous food:"
	f_icon.add_theme_font_size_override("font_size", 20)
	food_row.add_child(f_icon)

	hint_food_lbl = Label.new()
	hint_food_lbl.add_theme_font_size_override("font_size", 22)
	hint_food_lbl.add_theme_color_override("font_color", C_HINT_TEXT)
	hint_food_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	food_row.add_child(hint_food_lbl)

	# landmark

	var landmark_row := HBoxContainer.new()
	landmark_row.add_theme_constant_override("separation", 6)
	vbox.add_child(landmark_row)

	var l_icon := Label.new()
	l_icon.text = "landmark:"
	l_icon.add_theme_font_size_override("font_size", 20)
	landmark_row.add_child(l_icon)

	hint_landmark_lbl = Label.new()
	hint_landmark_lbl.add_theme_font_size_override("font_size", 22)
	hint_landmark_lbl.add_theme_color_override("font_color", C_HINT_TEXT)
	hint_landmark_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	landmark_row.add_child(hint_landmark_lbl)

	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 10)
	cc.add_child(sp2)

# ── CHOICE BUTTONS ────────────────────────────────────────────────────────────
func _build_choice_buttons(cc: VBoxContainer) -> void:
	choice_buttons.clear()
	for row in range(2):
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cc.add_child(hbox)

		for col in range(2):
			var btn_idx : int = row * 2 + col
			var btn     := Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size   = Vector2(0, 68)
			btn.add_theme_font_size_override("font_size", 24)
			_style_btn(btn, "default")
			btn.pressed.connect(_on_choice_pressed.bind(btn_idx))
			hbox.add_child(btn)
			choice_buttons.append(btn)

		if row == 0:
			var sp := Control.new()
			sp.custom_minimum_size = Vector2(0, 8)
			cc.add_child(sp)

# ── STYLE HELPER ──────────────────────────────────────────────────────────────
func _style_btn(btn: Button, state: String) -> void:
	var bg : Color
	match state:
		"correct": bg = C_BTN_CORRECT
		"wrong":   bg = C_BTN_WRONG
		_:         bg = C_BTN_DEFAULT

	for s in ["normal","hover","pressed","disabled","focus"]:
		var sb := StyleBoxFlat.new()
		match s:
			"normal":   sb.bg_color = bg
			"hover":    sb.bg_color = bg.lightened(0.18)
			"pressed":  sb.bg_color = bg.darkened(0.20)
			"disabled": sb.bg_color = bg.darkened(0.10)
			"focus":    sb.bg_color = bg.lightened(0.10)
		sb.set_corner_radius_all(10)
		sb.set_border_width_all(2)
		sb.border_color = C_BTN_BORDER if state == "default" else bg.lightened(0.30)
		btn.add_theme_stylebox_override(s, sb)
	btn.add_theme_color_override("font_color", C_TEXT)

# ── LOAD QUESTION ─────────────────────────────────────────────────────────────
func _load_question() -> void:
	if current_q_idx >= session_questions.size(): return
	answered = false
	var q : Dictionary = session_questions[current_q_idx]

	popup.title_label.text = "Guess the race?"

	# Progress dots
	for i in range(QUESTIONS_PER_GAME):
		var dot : Label = progress_labels[i]
		if i < current_q_idx:
			dot.add_theme_color_override("font_color", C_BTN_CORRECT)
			dot.text = "✓"
			dot.add_theme_font_size_override("font_size", 20)
		elif i == current_q_idx:
			dot.add_theme_color_override("font_color", C_GOLD)
			dot.text = "●"
			dot.add_theme_font_size_override("font_size", 24)
		else:
			dot.add_theme_color_override("font_color", Color(0.25, 0.30, 0.40, 1))
			dot.text = "●"
			dot.add_theme_font_size_override("font_size", 20)

	# Face image
	face_texture_rect.texture = null
	if ResourceLoader.exists(q["image"]):
		face_texture_rect.texture = load(q["image"])

	# Hints
	hint_wearing_lbl.text = q.get("wearing", "")
	hint_food_lbl.text    = q.get("food", "")
	hint_landmark_lbl.text = q.get("landmark", "")

	# Buttons
	var choices : Array = q["choices"]
	for i in range(4):
		choice_buttons[i].text     = choices[i]
		choice_buttons[i].disabled = false
		_style_btn(choice_buttons[i], "default")

# ── ANSWER HANDLING ───────────────────────────────────────────────────────────
func _on_choice_pressed(btn_idx: int) -> void:
	if answered or is_game_over: return
	answered = true

	var q           : Dictionary = session_questions[current_q_idx]
	var correct_idx : int        = q["answer"] - 1

	for b in choice_buttons:
		b.disabled = true

	if btn_idx == correct_idx:
		_on_correct(btn_idx)
	else:
		_on_wrong(btn_idx, correct_idx)

func _on_correct(btn_idx: int) -> void:
	_style_btn(choice_buttons[btn_idx], "correct")
	AudioManager.play_sfx(AudioManager.SFX.CORRECT)
	popup.title_label.text = "✅ Correct!"

	await get_tree().create_timer(0.85).timeout

	current_q_idx += 1
	if current_q_idx >= QUESTIONS_PER_GAME:
		_mark_all_done()
		popup.title_label.text = "🏆 Perfect Score!"
		await get_tree().create_timer(0.6).timeout
		win_game()
	else:
		_load_question()

func _on_wrong(wrong_idx: int, correct_idx: int) -> void:
	_style_btn(choice_buttons[wrong_idx],   "wrong")
	_style_btn(choice_buttons[correct_idx], "correct")
	AudioManager.play_sfx(AudioManager.SFX.WRONG)

	var correct_name : String = session_questions[current_q_idx]["choices"][correct_idx]
	popup.title_label.text = "❌ It was %s!" % correct_name

	await get_tree().create_timer(1.4).timeout
	fail_game("It was %s!" % correct_name)

func _mark_all_done() -> void:
	for i in range(QUESTIONS_PER_GAME):
		var dot : Label = progress_labels[i]
		dot.add_theme_color_override("font_color", C_BTN_CORRECT)
		dot.text = "✓"
		dot.add_theme_font_size_override("font_size", 20)