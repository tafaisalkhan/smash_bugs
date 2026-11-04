extends Control

signal screen_requested(screen: String)
signal play_requested
signal daily_challenge_requested
signal daily_reward_requested
signal rewarded_coins_requested

const MENU_ART = preload("res://assets/generated/ui/menu-screen.png")
const BUTTON_ART = preload("res://assets/generated/ui/menu-button.png")
const SETTINGS_ART = preload("res://assets/generated/ui/settings-button.png")
const FONT = preload("res://resources/ui_overlay_font.tres")

var _art: TextureRect
var _coin_label: Label
var _message_label: Label

func _ready() -> void:
	_art = TextureRect.new()
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.texture = MENU_ART
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_SCALE
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	_coin_label = _label(Rect2(0.78, 0.026, 0.18, 0.05), "0", 28, Color("#3e2b09"))
	_message_label = _label(Rect2(0.1, 0.79, 0.8, 0.037), "", 17, Color.WHITE)
	var coins_art := TextureRect.new()
	_place(coins_art, Rect2(0.015, 0.087, 0.30, 0.055))
	coins_art.texture = BUTTON_ART
	coins_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coins_art.stretch_mode = TextureRect.STRETCH_SCALE
	coins_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(coins_art)
	_label(Rect2(0.045, 0.091, 0.24, 0.045), "FREE COINS", 14, Color.WHITE)
	_hotspot(Rect2(0.015, 0.087, 0.30, 0.055), Callable(self, "_watch_ad"))
	var settings_icon := TextureRect.new()
	_place(settings_icon, Rect2(0.015, 0.018, 0.18, 0.057))
	settings_icon.texture = SETTINGS_ART
	settings_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	settings_icon.stretch_mode = TextureRect.STRETCH_SCALE
	settings_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(settings_icon)
	_label(Rect2(0.027, 0.024, 0.155, 0.044), "SETTINGS", 13, Color.WHITE)
	_hotspot(Rect2(0.015, 0.018, 0.18, 0.057), Callable(self, "_open").bind("settings"))
	_hotspot(Rect2(0.19, 0.535, 0.62, 0.14), Callable(self, "_play"))
	_hotspot(Rect2(0.22, 0.69, 0.55, 0.12), Callable(self, "_daily"))
	for index in range(4):
		var screen: String = ["shop", "store", "missions", "leaderboard"][index]
		_hotspot(Rect2(0.03 + 0.25 * index, 0.827, 0.22, 0.13), Callable(self, "_open").bind(screen))
	# The coin capsule also gives access to the daily reward.
	_hotspot(Rect2(0.7, 0.015, 0.28, 0.07), Callable(self, "_claim_daily"))
	_label(Rect2(0.7, 0.08, 0.28, 0.027), "DAILY REWARD", 13, Color("#fff0a0"))

func set_data(data: Dictionary, _title: String, _tagline: String, _score_title: String, _score_unit: String) -> void:
	if is_instance_valid(_coin_label):
		_coin_label.text = "%d" % int(data.get("coins", 0))

func set_background_tint(tint: Color) -> void:
	if is_instance_valid(_art):
		_art.modulate = tint

func show_message(message: String) -> void:
	if is_instance_valid(_message_label):
		_message_label.text = message.to_upper()

func _label(box: Rect2, value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	_place(label, box)
	label.text = value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#23372a") if color.get_luminance() > 0.65 else Color("#fff8df"))
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

func _open(screen: String) -> void:
	screen_requested.emit(screen)

func _play() -> void:
	play_requested.emit()

func _daily() -> void:
	daily_challenge_requested.emit()

func _claim_daily() -> void:
	daily_reward_requested.emit()

func _watch_ad() -> void:
	rewarded_coins_requested.emit()
