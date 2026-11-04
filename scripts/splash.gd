extends Control

@onready var logo: Control = $Center/LogoPanel
@onready var subtitle: Label = $Center/LogoPanel/VBox/Subtitle
@onready var progress: ProgressBar = $Bottom/Loader/ProgressBar
@onready var loading_label: Label = $Bottom/Loader/LoadingLabel

func _ready() -> void:
	_style_loader()
	logo.modulate.a = 0.0
	logo.scale = Vector2(0.72, 0.72)
	logo.pivot_offset = logo.size * 0.5
	progress.value = 0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(logo, "modulate:a", 1.0, 0.55)
	tween.tween_property(logo, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(progress, "value", 100.0, 1.8)
	await tween.finished
	var pulse := create_tween()
	pulse.tween_property(subtitle, "modulate:a", 0.35, 0.18)
	pulse.tween_property(subtitle, "modulate:a", 1.0, 0.18)
	await pulse.finished
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _style_loader() -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#0c2340")
	background.border_color = Color("#38bdf8")
	background.set_border_width_all(5)
	background.set_corner_radius_all(22)
	background.shadow_color = Color(0, 0, 0, 0.58)
	background.shadow_size = 10
	background.shadow_offset = Vector2(0, 7)
	background.content_margin_left = 8
	background.content_margin_right = 8
	background.content_margin_top = 8
	background.content_margin_bottom = 8
	progress.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#00a2ff")
	fill.border_color = Color("#b3e5fc")
	fill.set_border_width_all(3)
	fill.set_corner_radius_all(17)
	fill.shadow_color = Color(0.01, 0.08, 0.22, 0.7)
	fill.shadow_size = 5
	progress.add_theme_stylebox_override("fill", fill)
	progress.add_theme_color_override("font_color", Color("#e1f5fe"))
	progress.add_theme_color_override("font_outline_color", Color("#032040"))
	progress.add_theme_constant_override("outline_size", 4)
	var label_pulse := create_tween().set_loops()
	label_pulse.tween_property(loading_label, "modulate", Color(1.2, 1.2, 1.2, 1), 0.6).set_trans(Tween.TRANS_SINE)
	label_pulse.tween_property(loading_label, "modulate", Color.WHITE, 0.6).set_trans(Tween.TRANS_SINE)