extends Control

const PrivacyDialogScene = preload("res://scenes/privacy_dialog.tscn")
const FONT = preload("res://resources/ui_overlay_font.tres")

var _status: Label
var _leaving := false

func _ready() -> void:
	for row in [0, 1, 5, 6]:
		_hotspot(_row_box(row), Callable(self, "_toggle").bind(row))
	for row in [2, 3, 4]:
		_hotspot(_row_box(row), Callable(self, "_cycle").bind(row))
	_hotspot(_row_box(7), Callable(self, "_remove_ads"))
	_hotspot(Rect2(0.22, 0.84, 0.56, 0.105), Callable(self, "_go_back"))
	_status = _label("", Rect2(0.11, 0.795, 0.78, 0.035), 14, Color("#fff2be"))
	_refresh_values()

func _row_box(row: int) -> Rect2:
	return Rect2(0.12, 0.22 + float(row) * 0.071, 0.76, 0.067)

func _refresh_values() -> void:
	for child in get_children():
		if child.has_meta("value_label"):
			remove_child(child)
			child.queue_free()
	for entry in [
		[0, "ON" if GameState.music_enabled else "OFF"],
		[1, "ON" if GameState.sfx_enabled else "OFF"],
		[2, ["EASY", "MEDIUM", "HARD"][clampi(GameState.difficulty_index, 0, 2)]],
		[3, GameState.multiply_symbol],
		[4, GameState.divide_symbol],
		[5, "ON" if GameState.daily_notifications else "OFF"],
		[6, "ON" if GameState.show_privacy_on_start else "OFF"]
	]:
		var row: int = entry[0]
		var value: String = entry[1]
		var box := Rect2(0.63, 0.226 + float(row) * 0.071, 0.17, 0.05)
		var label := _label(value, box, 16 if row >= 2 and row <= 4 else 13, Color("#073e3d") if row in [0, 1, 5, 6] else Color("#553400"))
		label.set_meta("value_label", true)

func _toggle(row: int) -> void:
	match row:
		0:
			GameState.music_enabled = not GameState.music_enabled
			AudioManager.set_music_enabled(GameState.music_enabled)
		1: GameState.sfx_enabled = not GameState.sfx_enabled
		5:
			GameState.daily_notifications = not GameState.daily_notifications
			if GameState.daily_notifications and OS.get_name() == "Android":
				OS.request_permissions()
		6:
			GameState.show_privacy_on_start = not GameState.show_privacy_on_start
			if GameState.show_privacy_on_start:
				add_child(PrivacyDialogScene.instantiate())
	GameState.save_progress()
	_refresh_values()

func _cycle(row: int) -> void:
	match row:
		2:
			var next := (GameState.difficulty_index + 1) % 3
			if not GameState.set_difficulty(next):
				_status.text = "Complete all levels in the previous difficulty first."
				return
		3: GameState.multiply_symbol = "*" if GameState.multiply_symbol == "×" else "×"
		4: GameState.divide_symbol = "/" if GameState.divide_symbol == "÷" else "÷"
	_status.text = ""
	GameState.save_progress()
	_refresh_values()

func _remove_ads() -> void:
	_status.text = "Ads already removed." if GameState.ads_removed else "Google Play Billing is not connected yet."

func _go_back() -> void:
	if _leaving:
		return
	_leaving = true
	GameState.save_progress()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

func _label(value: String, box: Rect2, size: int, color: Color) -> Label:
	var label := Label.new()
	_place(label, box)
	label.text = value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#203431") if color.get_luminance() > 0.65 else Color("#fff8df"))
	label.add_theme_constant_override("outline_size", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _hotspot(box: Rect2, action: Callable) -> void:
	var button := Button.new()
	_place(button, box)
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	add_child(button)

func _place(control: Control, box: Rect2) -> void:
	control.anchor_left = box.position.x
	control.anchor_top = box.position.y
	control.anchor_right = box.end.x
	control.anchor_bottom = box.end.y
