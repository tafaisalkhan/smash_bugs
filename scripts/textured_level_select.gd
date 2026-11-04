extends Control

const WORLD_TEXTURES := [
	preload("res://assets/generated/ui/level-select-screen.png"),
	preload("res://assets/generated/ui/level-select-ice-screen.png"),
	preload("res://assets/generated/ui/level-select-ocean-screen.png"),
	preload("res://assets/generated/ui/level-select-mountain-screen.png"),
	preload("res://assets/generated/ui/level-select-volcano-screen.png")
]
const FONT = preload("res://resources/ui_overlay_font.tres")

@onready var artwork: TextureRect = $Artwork

var _world_index := 0
var _touch_start := Vector2.ZERO
var _touch_active := false
var _interacted := false
var _selection_made := false
var _progress: Label
var _play: Button

func _ready() -> void:
	_progress = _label(Rect2(0.24, 0.64, 0.24, 0.045), "", 22, Color("#5d3908"))
	_play = _hotspot(Rect2(0.28, 0.70, 0.44, 0.095), Callable(self, "_open_world"))
	_hotspot(Rect2(0.22, 0.86, 0.56, 0.09), Callable(self, "_go_back"))
	_hotspot(Rect2(0.0, 0.29, 0.14, 0.42), Callable(self, "_previous_world"))
	_hotspot(Rect2(0.86, 0.29, 0.14, 0.42), Callable(self, "_next_world"))
	_refresh_world()
	_auto_start_remembered_level()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = event.position
			_touch_active = true
		elif _touch_active:
			_handle_swipe(event.position - _touch_start)
			_touch_active = false
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_touch_start = event.position
			_touch_active = true
		elif _touch_active:
			_handle_swipe(event.position - _touch_start)
			_touch_active = false

func _handle_swipe(delta: Vector2) -> void:
	if absf(delta.x) < 55.0 or absf(delta.x) < absf(delta.y) * 1.3:
		return
	if delta.x < 0.0:
		_next_world()
	else:
		_previous_world()

func _previous_world() -> void:
	_interacted = true
	_world_index = maxi(0, _world_index - 1)
	_refresh_world()

func _next_world() -> void:
	_interacted = true
	_world_index = mini(WORLD_TEXTURES.size() - 1, _world_index + 1)
	_refresh_world()

func _refresh_world() -> void:
	artwork.texture = WORLD_TEXTURES[_world_index]
	var first_level := _world_index * 200 + 1
	var unlocked := GameState.highest_level >= first_level
	var completed := clampi(GameState.highest_level - first_level, 0, 200)
	_progress.text = "%d/200" % completed if unlocked else "LOCKED"
	_play.disabled = not unlocked

func _open_world() -> void:
	if _selection_made:
		return
	_selection_made = true
	var first_level := _world_index * 200 + 1
	var next_level := clampi(GameState.highest_level, first_level, first_level + 199)
	GameState.start_selected_level(next_level)
	get_tree().change_scene_to_file("res://scenes/smash/SmashGame.tscn")

func _go_back() -> void:
	if _selection_made:
		return
	_selection_made = true
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _auto_start_remembered_level() -> void:
	await get_tree().create_timer(5.0).timeout
	if _selection_made or _interacted or not is_inside_tree():
		return
	_selection_made = true
	GameState.start_selected_level(GameState.requested_level)
	get_tree().change_scene_to_file("res://scenes/smash/SmashGame.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

func _label(box: Rect2, value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	_place(label, box)
	label.text = value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#fff8df"))
	label.add_theme_constant_override("outline_size", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _hotspot(box: Rect2, action: Callable) -> Button:
	var button := Button.new()
	_place(button, box)
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	add_child(button)
	return button

func _place(control: Control, box: Rect2) -> void:
	control.anchor_left = box.position.x
	control.anchor_top = box.position.y
	control.anchor_right = box.end.x
	control.anchor_bottom = box.end.y
