extends Control

signal close_requested
signal setting_changed(id: String, enabled: bool)
signal settings_action_requested(id: String)
signal shop_action_requested(id: String)
signal purchase_requested(id: String)
signal mission_claim_requested(id: String)
signal leaderboard_signin_requested
signal leaderboard_full_requested
signal privacy_requested

@export_enum("settings", "missions", "leaderboard") var screen_kind := "settings"
@export var screen_texture: Texture2D

const OVERLAY_FONT = preload("res://resources/ui_overlay_font.tres")

var _data: Dictionary = {}
var _art: TextureRect

func _ready() -> void:
	_art = TextureRect.new()
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.texture = screen_texture
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_SCALE
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	_render()

func set_data(data: Dictionary) -> void:
	_data = data
	if is_node_ready():
		_render()

func _render() -> void:
	for child in get_children():
		if child != _art:
			remove_child(child)
			child.queue_free()
	match screen_kind:
		"settings": _render_settings()
		"missions": _render_missions()
		"leaderboard": _render_leaderboard()

func _render_settings() -> void:
	var options: Array = _data.get("settings_options", [])
	for index in range(mini(options.size(), 2)):
		var option: Dictionary = options[index]
		var y := 0.31 + float(index) * 0.115
		_label(str(option.get("label", "Setting")).to_upper(), Rect2(0.15, y, 0.53, 0.06), 22, Color("#124647"), false)
		_label("ON" if bool(option.get("enabled", true)) else "OFF", Rect2(0.66, y + 0.016, 0.10, 0.045), 18, Color.WHITE, true)
		_hotspot(Rect2(0.64, y - 0.01, 0.23, 0.08), Callable(self, "_toggle").bind(str(option.get("id", "")), not bool(option.get("enabled", true))))
	var actions: Array = _data.get("settings_actions", [])
	if not actions.is_empty():
		var action: Dictionary = actions[0]
		_label("MORE SETTINGS", Rect2(0.15, 0.54, 0.53, 0.06), 21, Color("#124647"), false)
		_hotspot(Rect2(0.13, 0.53, 0.75, 0.09), Callable(self, "_action").bind(str(action.get("id", ""))))
	_label("PRIVACY", Rect2(0.34, 0.77, 0.32, 0.05), 19, Color("#104449"), true)
	_hotspot(Rect2(0.34, 0.77, 0.32, 0.05), Callable(self, "_privacy"))
	_hotspot(Rect2(0.28, 0.66, 0.45, 0.11), Callable(self, "_close"))

func _render_missions() -> void:
	var missions: Array = _data.get("missions", [])
	for index in range(mini(missions.size(), 3)):
		var mission: Dictionary = missions[index]
		var y := 0.33 + float(index) * 0.17
		_label(str(mission.get("name", "Mission")).to_upper(), Rect2(0.29, y, 0.43, 0.05), 19, Color("#1d3657"), false)
		var claimed := bool(mission.get("claimed", false))
		var complete := bool(mission.get("complete", false))
		var progress_text := "Claimed" if claimed else ("Complete" if complete else "%d/%d" % [int(mission.get("progress", 0)), int(mission.get("target", 1))])
		_label(progress_text.to_upper(), Rect2(0.3, y + 0.05, 0.29, 0.04), 16, Color("#314d6c"), false)
		_label("+%d" % int(mission.get("reward", 0)), Rect2(0.11, y + 0.018, 0.16, 0.065), 20, Color("#1d3657"), true)
		if complete and not claimed:
			_hotspot(Rect2(0.68, y + 0.055, 0.23, 0.075), Callable(self, "_claim").bind(str(mission.get("id", ""))))
	_hotspot(Rect2(0.29, 0.87, 0.43, 0.09), Callable(self, "_close"))

func _render_leaderboard() -> void:
	var rows: Array = _data.get("leaderboard_rows", [])
	for index in range(mini(rows.size(), 5)):
		var player: Dictionary = rows[index]
		var y := 0.275 + float(index) * 0.092
		_label(str(player.get("name", "Player")).to_upper(), Rect2(0.34, y, 0.34, 0.055), 18, Color("#243b5c"), false)
		_label(str(player.get("score", "0")), Rect2(0.70, y, 0.14, 0.055), 18, Color("#68440e"), true)
	_hotspot(Rect2(0.26, 0.76, 0.48, 0.09), Callable(self, "_leaderboard_action"))
	_hotspot(Rect2(0.29, 0.86, 0.43, 0.09), Callable(self, "_close"))

func _label(value: String, box: Rect2, font_size: int, color: Color, centered: bool) -> void:
	var label := Label.new()
	_place(label, box)
	label.text = value
	label.add_theme_font_override("font", OVERLAY_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#203431") if color.get_luminance() > 0.65 else Color("#fff8df"))
	label.add_theme_constant_override("outline_size", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

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

func _toggle(id: String, enabled: bool) -> void:
	var options: Array = _data.get("settings_options", [])
	for option in options:
		if str(option.get("id", "")) == id:
			option["enabled"] = enabled
	setting_changed.emit(id, enabled)
	_render()

func _action(id: String) -> void:
	settings_action_requested.emit(id)

func _claim(id: String) -> void:
	mission_claim_requested.emit(id)

func _leaderboard_action() -> void:
	if bool(_data.get("leaderboard_signed_in", false)):
		leaderboard_full_requested.emit()
	else:
		leaderboard_signin_requested.emit()

func _privacy() -> void:
	privacy_requested.emit()

func _close() -> void:
	close_requested.emit()
