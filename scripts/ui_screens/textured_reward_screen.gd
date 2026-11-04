extends Control

signal collect_requested

const GENERIC_ART = preload("res://assets/generated/ui/reward-generic-screen.png")
const COMPLETE_ART = preload("res://assets/generated/ui/level-complete-screen.png")
const STAR_ART = preload("res://assets/generated/victory-star.png")
const FONT = preload("res://resources/ui_overlay_font.tres")

var _art: TextureRect

func _ready() -> void:
	_art = TextureRect.new()
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_SCALE
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)

func set_data(title: String, coins: int, detail: String, stars: int) -> void:
	for child in get_children():
		if child != _art:
			remove_child(child)
			child.queue_free()
	var show_complete := title.to_lower() == "level complete" and stars == 3
	_art.texture = COMPLETE_ART if show_complete else GENERIC_ART
	if not show_complete:
		_label(title.to_upper(), Rect2(0.15, 0.33, 0.70, 0.075), 30, Color("#254b2d"))
		for index in range(clampi(stars, 0, 3)):
			var star := TextureRect.new()
			_place(star, Rect2(0.27 + float(index) * 0.18, 0.42, 0.17, 0.09))
			star.texture = STAR_ART
			star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			star.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(star)
	if coins > 0:
		_label("+%d COINS" % coins, Rect2(0.37, 0.49, 0.40, 0.07), 28, Color("#68430b"))
	if not detail.is_empty():
		_label(detail.to_upper(), Rect2(0.19, 0.405, 0.62, 0.065), 17, Color("#315238"))
	var button := Button.new()
	_place(button, Rect2(0.19, 0.70, 0.62, 0.12))
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func(): collect_requested.emit())
	add_child(button)

func _label(value: String, box: Rect2, size: int, color: Color) -> void:
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
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func _place(control: Control, box: Rect2) -> void:
	control.anchor_left = box.position.x
	control.anchor_top = box.position.y
	control.anchor_right = box.end.x
	control.anchor_bottom = box.end.y
