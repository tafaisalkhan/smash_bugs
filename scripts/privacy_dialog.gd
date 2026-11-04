extends Control

signal accepted

@onready var continue_button: Button = %ContinueButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Style the green pill button matching the reference screenshot
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color("#69d275")
	btn_normal.border_color = Color("#2e7d32")
	btn_normal.set_border_width_all(3)
	btn_normal.set_corner_radius_all(22)
	btn_normal.shadow_color = Color(0, 0, 0, 0.25)
	btn_normal.shadow_size = 6
	btn_normal.shadow_offset = Vector2(0, 4)

	var btn_pressed := StyleBoxFlat.new()
	btn_pressed.bg_color = Color("#54b860")
	btn_pressed.border_color = Color("#1b5e20")
	btn_pressed.set_border_width_all(3)
	btn_pressed.set_corner_radius_all(22)
	btn_pressed.shadow_size = 2
	btn_pressed.shadow_offset = Vector2(0, 2)

	continue_button.add_theme_stylebox_override("normal", btn_normal)
	continue_button.add_theme_stylebox_override("hover", btn_normal)
	continue_button.add_theme_stylebox_override("pressed", btn_pressed)
	continue_button.add_theme_color_override("font_color", Color("#ffffff"))
	continue_button.add_theme_color_override("font_outline_color", Color("#1b5e20"))
	continue_button.add_theme_constant_override("outline_size", 4)

	continue_button.pressed.connect(_on_continue_pressed)

func _on_continue_pressed() -> void:
	var state = get_node_or_null("/root/GameState")
	if state:
		state.privacy_accepted = true
		state.save_progress()
	accepted.emit()
	queue_free()
