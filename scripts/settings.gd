extends Control

const PrivacyDialogScene = preload("res://scenes/privacy_dialog.tscn")
const Palette = preload("res://scripts/ui_palette.gd")

@onready var difficulty_dropdown: OptionButton = $Margin/VBox/Panel/Scroll/Content/DifficultyRow/DifficultyDropdown
@onready var settings_panel: PanelContainer = $Margin/VBox/Panel
@onready var back_button: Button = $Margin/VBox/Header/BackButton
@onready var music_toggle: CheckButton = $Margin/VBox/Panel/Scroll/Content/MusicToggle
@onready var sfx_toggle: CheckButton = $Margin/VBox/Panel/Scroll/Content/SfxToggle
@onready var notification_toggle: CheckButton = $Margin/VBox/Panel/Scroll/Content/NotificationToggle
@onready var privacy_toggle: CheckButton = $Margin/VBox/Panel/Scroll/Content/PrivacyToggle
@onready var remove_ads_button: Button = $Margin/VBox/Panel/Scroll/Content/RemoveAdsButton
@onready var purchase_status: Label = $Margin/VBox/Panel/Scroll/Content/PurchaseStatus


func _ready() -> void:
	Palette.apply_background($Background, GameState.selected_theme)
	_apply_popup_style()
	difficulty_dropdown.select(clampi(GameState.difficulty_index, 0, 2))
	music_toggle.button_pressed = GameState.music_enabled
	sfx_toggle.button_pressed = GameState.sfx_enabled
	notification_toggle.button_pressed = GameState.daily_notifications
	privacy_toggle.button_pressed = GameState.show_privacy_on_start
	_update_purchase_status()
	back_button.pressed.connect(_go_back)
	difficulty_dropdown.item_selected.connect(_on_difficulty_selected)
	music_toggle.toggled.connect(_on_music_toggled)
	sfx_toggle.toggled.connect(_on_sfx_toggled)
	notification_toggle.toggled.connect(_on_notifications_toggled)
	privacy_toggle.toggled.connect(_on_privacy_toggled)
	remove_ads_button.pressed.connect(_on_remove_ads_pressed)

func _apply_popup_style() -> void:
	for toggle in [music_toggle, sfx_toggle, notification_toggle, privacy_toggle]:
		toggle.add_theme_color_override("font_color", Color.BLACK)
		toggle.add_theme_color_override("font_hover_color", Color("#222222"))
		toggle.add_theme_color_override("font_pressed_color", Color.BLACK)
		toggle.add_theme_stylebox_override("normal", _button_style(Color("#fff8d9"), Color("#d7b348")))
		toggle.add_theme_stylebox_override("hover", _button_style(Color("#fffdf0"), Color("#f0c94d")))
		toggle.add_theme_stylebox_override("pressed", _pressed_button_style(Color("#f5edc8"), Color("#14865f")))
		toggle.add_theme_constant_override("outline_size", 1)
	if has_node("$Margin/VBox/Panel/Scroll/Content/DifficultyRow/Label"):
		$Margin/VBox/Panel/Scroll/Content/DifficultyRow/Label.add_theme_color_override("font_color", Color.BLACK)
	remove_ads_button.add_theme_stylebox_override("normal", _button_style(Color("#ff8a3d"), Color("#b94716")))
	remove_ads_button.add_theme_stylebox_override("hover", _button_style(Color("#ffa14f"), Color("#b94716")))
	remove_ads_button.add_theme_stylebox_override("pressed", _pressed_button_style(Color("#df6f2c"), Color("#8f3110")))
	remove_ads_button.add_theme_color_override("font_color", Color.WHITE)
	difficulty_dropdown.add_theme_stylebox_override("normal", _button_style(Color("#ffd65a"), Color("#c98112")))
	difficulty_dropdown.add_theme_stylebox_override("hover", _button_style(Color("#71dfbd"), Color("#167762")))
	difficulty_dropdown.add_theme_stylebox_override("pressed", _button_style(Color("#ffc83d"), Color("#c98112")))
	difficulty_dropdown.add_theme_color_override("font_color", Color("#35210e"))
	difficulty_dropdown.add_theme_color_override("font_hover_color", Color("#123f36"))
	var difficulty_popup := difficulty_dropdown.get_popup()
	difficulty_popup.add_theme_stylebox_override("panel", _button_style(Color("#fff4bd"), Color("#c98112")))
	difficulty_popup.add_theme_color_override("font_color", Color("#35210e"))
	difficulty_popup.add_theme_color_override("font_hover_color", Color.WHITE)
	difficulty_popup.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	difficulty_popup.add_theme_font_size_override("font_size", 20)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#fff1b8")
	panel_style.border_color = Color("#14865f")
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(24)
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	panel_style.shadow_color = Color(0.02, 0.08, 0.05, 0.65)
	panel_style.shadow_size = 18
	panel_style.shadow_offset = Vector2(0, 9)
	settings_panel.add_theme_stylebox_override("panel", panel_style)
	back_button.add_theme_stylebox_override("normal", _button_style(Color("#e94f45"), Color("#8f211d")))
	back_button.add_theme_stylebox_override("hover", _button_style(Color("#ff665b"), Color("#8f211d")))
	back_button.add_theme_stylebox_override("pressed", _pressed_button_style(Color("#cc3932"), Color("#701613")))
	back_button.add_theme_color_override("font_color", Color.WHITE)
	back_button.add_theme_font_size_override("font_size", 28)
	settings_panel.modulate.a = 0.0
	settings_panel.scale = Vector2(0.92, 0.92)
	settings_panel.pivot_offset = settings_panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(settings_panel, "modulate:a", 1.0, 0.22)
	tween.tween_property(settings_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(5)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0.02, 0.08, 0.05, 0.55)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 6)
	return style

func _pressed_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := _button_style(fill, border)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	return style

func _go_back() -> void:
	if back_button.disabled:
		return
	back_button.disabled = true
	GameState.save_progress()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

func _on_difficulty_selected(index: int) -> void:
	GameState.set_difficulty(index)
	difficulty_dropdown.select(GameState.difficulty_index)

func _on_music_toggled(enabled: bool) -> void:
	GameState.music_enabled = enabled
	AudioManager.set_music_enabled(enabled)
	GameState.save_progress()

func _on_sfx_toggled(enabled: bool) -> void:
	GameState.sfx_enabled = enabled
	GameState.save_progress()

func _on_notifications_toggled(enabled: bool) -> void:
	GameState.daily_notifications = enabled
	GameState.save_progress()
	if enabled and OS.get_name() == "Android":
		OS.request_permissions()

func _on_privacy_toggled(enabled: bool) -> void:
	GameState.show_privacy_on_start = enabled
	GameState.save_progress()
	if enabled:
		var dialog := PrivacyDialogScene.instantiate()
		add_child(dialog)

func _on_remove_ads_pressed() -> void:
	if not GameState.ads_removed:
		GameState.ads_removed = true
		GameState.save_progress()
		_update_purchase_status()
		purchase_status.text = "All ads permanently removed! ($4.99)"

func _update_purchase_status() -> void:
	if GameState.ads_removed:
		remove_ads_button.text = "✓ ADS REMOVED"
		remove_ads_button.disabled = true
		purchase_status.text = "Thank you for supporting Smash Flies!"
	else:
		purchase_status.text = "One-time purchase • Restore supported"
