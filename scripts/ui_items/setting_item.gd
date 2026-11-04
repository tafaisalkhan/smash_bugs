extends Control

signal changed(id: String, enabled: bool)
signal activated(id: String)
signal difficulty_selected(index: int)

var item_id := ""
var _diff_index := 0

func set_data(data: Dictionary) -> void:
	item_id = str(data.get("id", ""))
	%NameLabel.text = str(data.get("label", item_id))
	var is_difficulty := (str(data.get("type", "")) == "difficulty" or item_id == "difficulty")
	var is_action := bool(data.get("action", false)) and not is_difficulty

	if is_difficulty:
		if has_node("%Toggle"):
			%Toggle.visible = false
		if has_node("%ActionButton"):
			%ActionButton.visible = false
		if has_node("%DifficultyBox"):
			%DifficultyBox.visible = true
		_diff_index = int(data.get("value", 0))
		_update_difficulty_buttons()
	elif is_action:
		if has_node("%Toggle"):
			%Toggle.visible = false
		if has_node("%ActionButton"):
			%ActionButton.visible = true
		if has_node("%DifficultyBox"):
			%DifficultyBox.visible = false
		var btn_txt := str(data.get("button_text", "OPEN"))
		%ActionButton.text = btn_txt
		if data.has("button_color"):
			%ActionButton.modulate = data["button_color"]
		else:
			%ActionButton.modulate = Color.WHITE
	else:
		if has_node("%Toggle"):
			%Toggle.visible = true
			%Toggle.set_pressed_no_signal(bool(data.get("enabled", false)))
			_update_knob(bool(data.get("enabled", false)))
		if has_node("%ActionButton"):
			%ActionButton.visible = false
		if has_node("%DifficultyBox"):
			%DifficultyBox.visible = false

func _ready() -> void:
	if has_node("%Toggle"):
		%Toggle.toggled.connect(_on_toggled)
	if has_node("%ActionButton"):
		%ActionButton.pressed.connect(func(): activated.emit(item_id))
	if has_node("%EasyBtn"):
		%EasyBtn.pressed.connect(_on_diff_pressed.bind(0))
	if has_node("%MedBtn"):
		%MedBtn.pressed.connect(_on_diff_pressed.bind(1))
	if has_node("%HardBtn"):
		%HardBtn.pressed.connect(_on_diff_pressed.bind(2))
	_update_difficulty_buttons()

func _on_diff_pressed(idx: int) -> void:
	_diff_index = idx
	_update_difficulty_buttons()
	var state = get_node_or_null("/root/GameState")
	if state and state.has_method("set_difficulty"):
		state.set_difficulty(idx)
	difficulty_selected.emit(idx)
	changed.emit("difficulty", idx == 0)

func _update_difficulty_buttons() -> void:
	if not has_node("%EasyBtn") or not has_node("%MedBtn") or not has_node("%HardBtn"):
		return
	var buttons = [%EasyBtn, %MedBtn, %HardBtn]
	var active_colors = [Color("#2e7d32"), Color("#1565c0"), Color("#c62828")]
	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		if i == _diff_index:
			btn.modulate = Color.WHITE
			var style := StyleBoxFlat.new()
			style.bg_color = active_colors[i]
			style.set_corner_radius_all(10)
			style.set_border_width_all(2)
			style.border_color = Color.WHITE
			style.content_margin_left = 6
			style.content_margin_right = 6
			style.content_margin_top = 4
			style.content_margin_bottom = 4
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_stylebox_override("pressed", style)
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			btn.modulate = Color(1, 1, 1, 0.7)
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.18, 0.24, 0.32, 0.55)
			style.set_corner_radius_all(10)
			style.content_margin_left = 6
			style.content_margin_right = 6
			style.content_margin_top = 4
			style.content_margin_bottom = 4
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_stylebox_override("pressed", style)
			btn.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92, 1.0))

func _on_toggled(enabled: bool) -> void:
	_update_knob(enabled)
	changed.emit(item_id, enabled)

func _update_knob(enabled: bool) -> void:
	if has_node("%Knob"):
		%Knob.position.x = 35.0 if enabled else 3.0
