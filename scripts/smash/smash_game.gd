class_name SmashGame
extends Control

const LevelGen = preload("res://scripts/smash/level_generator.gd")
const GlyphStrokes = preload("res://scripts/smash/glyph_strokes.gd")
const CityBackdropScript = preload("res://scripts/smash/city_backdrop.gd")
const LevelStore = preload("res://scripts/smash/level_store.gd")
const BugScene = preload("res://scenes/smash/Bug.tscn")
const PlatformScript = preload("res://scripts/smash/platform.gd")
const PropScript = preload("res://scripts/smash/prop.gd")
const MovingObstacleScript = preload("res://scripts/smash/hard_moving_obstacle.gd")
const WindFanScript = preload("res://scripts/smash/hard_wind_fan.gd")
const DrawnBodyScript = preload("res://scripts/smash/drawn_body.gd")
const CoinTexture = preload("res://assets/generated/reward-coin.png")
const NoticePaperTex = preload("res://assets/smash/notice_paper.png")
const MonsterPeekTex = preload("res://assets/smash/monster_peek.png")
const HeadingFont = preload("res://resources/ui_heading_font.tres")
const BoldFont = preload("res://resources/ui_bold_font.tres")
const ElasticInkIcon = preload("res://assets/generated/ui_elastic_ink_icon.svg")
const SolidInkIcon = preload("res://assets/generated/ui_solid_ink_icon.svg")
const AutoDropIcon = preload("res://assets/generated/ui_drop_auto_icon.svg")
const ManualDropIcon = preload("res://assets/generated/ui_drop_manual_icon.svg")
const CompassIcon = preload("res://assets/generated/ui_compass_icon.svg")
const CAMPAIGN_LEVEL_COUNT := 300
const LEVELS_PER_DIFFICULTY := 100
const AUTO_DROP_DELAY := 0.35
const ELASTIC_INK_REFILL_AMOUNT := 1000
const ELASTIC_INK_REFILL_COST := 20
const MANUAL_DROP_COST := 20
const FREE_MANUAL_DROPS_PER_LEVEL := 5
const MANUAL_DROP_PACK_SIZE := 5

@export var start_level: int = 1
@export var verify_generated_levels: bool = true

var current_level: int = 1
var active_bugs: Array[SmashBug] = []
var active_props: Array[RigidBody2D] = []
var active_drawn_body: SmashDrawnBody = null
var active_drawn_bodies: Array[SmashDrawnBody] = []
var _held_drawn_bodies: Array[SmashDrawnBody] = []
var active_anchors: Array[StaticBody2D] = []
var is_level_cleared: bool = false
var _stroke_elapsed: float = 0.0
var _settle_timer: float = 0.0
var _has_triggered_miss: bool = false
var _pending_win: bool = false
var _win_wait: float = 0.0
var _verification_running := false
var _verification_failed := false
var _candidate_attempt := 0
var _loading_overlay: ColorRect
var _loading_label: Label
var selected_glyph := ""
var _campaign_level := 1
var _glyph_dialog: ConfirmationDialog
var _glyph_entry: LineEdit
var _load_serial := 0
var _required_letter := ""
var _required_letter_pattern := PackedVector2Array()
var _awaiting_drop := false
var _drop_btn: Button
var _auto_drop_btn: Button
var _elastic_ink_btn: Button
var _solid_ink_btn: Button
var _draw_material := "solid"
var _auto_mode_btn: Button
var _manual_mode_btn: Button
var _drop_mode := "auto"
var _tool_toggle_btn: Button
var _tools_panel: Panel
var _tools_menu_serial := 0
var _solid_ink_bar: ProgressBar
var _elastic_ink_bar: ProgressBar
var _solid_ink_marker: Label
var _elastic_ink_marker: Label
var _elastic_ink_at_level_start := 0
var _elastic_ink_spent_this_level := 0
var _elastic_ink_dialog: Control
var _elastic_ink_body: Label
var _elastic_buy_button: Button
var _elastic_ad_button: Button
var _ad_reward_target: String = "coins"
var _manual_drop_dialog: Control
var _manual_drop_body: Label
var _manual_drop_buy_button: Button
var _manual_drop_ad_button: Button
var _manual_drop_credits := FREE_MANUAL_DROPS_PER_LEVEL
var _random_difficulties: Dictionary = {}
var _random_catalog_levels: Dictionary = {}

# UI Nodes
@onready var background_sky: ColorRect = %BackgroundSky
@onready var city_silhouette: ColorRect = %CitySilhouette
@onready var level_label: Label = %LevelLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var hint_label: Label = %HintLabel
@onready var ink_bar: ProgressBar = %InkBar
@onready var drawing_canvas: SmashDrawingCanvas = %DrawingCanvas
@onready var canvas_holder: Control = $CanvasHolder
@onready var world_container: Node2D = %WorldContainer
@onready var platforms_container: Node2D = %PlatformsContainer
@onready var bugs_container: Node2D = %BugsContainer
@onready var victory_panel: PanelContainer = %VictoryPanel
@onready var victory_title: Label = %VictoryTitle
@onready var coins_reward: Label = %CoinsReward
@onready var star1: TextureRect = %Star1
@onready var star2: TextureRect = %Star2
@onready var star3: TextureRect = %Star3
@onready var next_level_btn: Button = %NextLevelBtn
@onready var restart_btn: Button = %RestartBtn
@onready var menu_btn: Button = %MenuBtn
@onready var hint_btn: Button = %HintBtn
@onready var top_coin_pill: PanelContainer = %TopCoinPill
@onready var top_coin_icon: TextureRect = %TopCoinIcon
@onready var top_coin_label: Label = %TopCoinLabel
@onready var fail_panel: PanelContainer = %FailPanel
@onready var fail_title: Label = %FailTitle
@onready var fail_message: Label = %FailMessage
@onready var try_again_btn: Button = %TryAgainBtn
@onready var watch_ad_btn: Button = %WatchAdBtn
@onready var mode_btn: Button = %ModeBtn
@onready var glyph_dropdown: OptionButton = %GlyphDropdown
@onready var mode_dialog: PanelContainer = %ModeDialog
@onready var mode_dialog_title: Label = %ModeDialogTitle
@onready var mode_dialog_subtitle: Label = %ModeDialogSubtitle
@onready var child_mode_btn: Button = %ChildModeBtn
@onready var adult_mode_btn: Button = %AdultModeBtn
@onready var hard_mode_btn: Button = %HardModeBtn
@onready var mode_continue_btn: Button = %ModeContinueBtn

func _ready() -> void:
	_ensure_nodes()
	_setup_city_backdrop()
	_setup_loading_overlay()
	_setup_drop_button()
	_setup_tools_panel()
	_setup_draw_item_selector()
	_setup_drop_mode_selector()
	_setup_ink_hud()
	_setup_elastic_ink_dialog()
	_setup_manual_drop_dialog()
	_update_top_coin_hud()
	if is_instance_valid(top_coin_pill):
		top_coin_pill.visible = true
		top_coin_pill.remove_theme_stylebox_override("panel")
	if is_instance_valid(top_coin_label):
		top_coin_label.add_theme_color_override("font_color", Color("#20242b"))
	if is_instance_valid(top_coin_icon):
		var startup_state = get_node_or_null("/root/GameState")
		top_coin_icon.visible = not (startup_state and startup_state.game_mode == "daily")
	if is_instance_valid(mode_btn):
		mode_btn.visible = false
	for top_button in [restart_btn, menu_btn, hint_btn]:
		if is_instance_valid(top_button):
			top_button.flat = false
			top_button.custom_minimum_size = Vector2(56.0, 56.0)
			top_button.add_theme_font_size_override("font_size", 28)
			top_button.add_theme_color_override("font_color", Color("#20242b"))
	if is_instance_valid(restart_btn):
		restart_btn.text = ""
	if is_instance_valid(menu_btn):
		menu_btn.text = ""
	if is_instance_valid(hint_btn):
		hint_btn.text = ""
	var level_pill := get_node_or_null("TopBar/LevelPill") as PanelContainer
	if is_instance_valid(level_pill):
		level_pill.remove_theme_stylebox_override("panel")
	_apply_top_hud_style()
	var state = get_node_or_null("/root/GameState")
	if state:
		if state.game_mode == "daily":
			current_level = state.requested_level
		elif state.game_mode == "selected":
			current_level = state.requested_level
		else:
			current_level = state.highest_level
	else:
		current_level = start_level
	# Campaign difficulty is automatic: 100 Easy, then 100 Medium, then
	# 100 Hard. After that, each level is a random challenge.
	if current_level < 1:
		current_level = 1
	var startup_difficulty := _campaign_difficulty_for_level(current_level)
	if current_level <= CAMPAIGN_LEVEL_COUNT and not LevelGen.has_level(current_level, startup_difficulty):
		current_level = 1
	_campaign_level = current_level
	_setup_glyph_dropdown()
	if drawing_canvas and not drawing_canvas.stroke_completed.is_connected(_on_stroke_completed):
		drawing_canvas.stroke_completed.connect(_on_stroke_completed)
	if drawing_canvas and not drawing_canvas.ink_depleted.is_connected(_on_ink_depleted):
		drawing_canvas.ink_depleted.connect(_on_ink_depleted)
	if restart_btn and not restart_btn.pressed.is_connected(_on_restart_pressed):
		restart_btn.pressed.connect(_on_restart_pressed)
	if menu_btn and not menu_btn.pressed.is_connected(_on_menu_pressed):
		menu_btn.pressed.connect(_on_menu_pressed)
	if hint_btn:
		hint_btn.visible = true
		hint_btn.icon = CompassIcon
		hint_btn.expand_icon = true
		hint_btn.tooltip_text = "Open drawing tools"
		if not hint_btn.pressed.is_connected(_on_tool_toggle_pressed):
			hint_btn.pressed.connect(_on_tool_toggle_pressed)
	if hint_label:
		hint_label.visible = false
	if next_level_btn and not next_level_btn.pressed.is_connected(_on_next_level_pressed):
		next_level_btn.pressed.connect(_on_next_level_pressed)
	if try_again_btn and not try_again_btn.pressed.is_connected(_on_try_again_pressed):
		try_again_btn.pressed.connect(_on_try_again_pressed)
	if watch_ad_btn and not watch_ad_btn.pressed.is_connected(_on_watch_ad_pressed):
		watch_ad_btn.pressed.connect(_on_watch_ad_pressed)
	if mode_btn and not mode_btn.pressed.is_connected(_on_mode_toggle_pressed):
		mode_btn.pressed.connect(_on_mode_toggle_pressed)
	if child_mode_btn and not child_mode_btn.pressed.is_connected(_on_select_child_mode):
		child_mode_btn.pressed.connect(_on_select_child_mode)
	if adult_mode_btn and not adult_mode_btn.pressed.is_connected(_on_select_adult_mode):
		adult_mode_btn.pressed.connect(_on_select_adult_mode)
	if hard_mode_btn and not hard_mode_btn.pressed.is_connected(_on_select_hard_mode):
		hard_mode_btn.pressed.connect(_on_select_hard_mode)
	if mode_continue_btn and not mode_continue_btn.pressed.is_connected(_on_mode_continue_pressed):
		mode_continue_btn.pressed.connect(_on_mode_continue_pressed)
	_update_mode_ui()

	# Show banner ad if ads not removed
	if is_inside_tree():
		var ad_mgr = get_node_or_null("/root/AdManager")
		if ad_mgr and ad_mgr.has_method("show_banner"):
			ad_mgr.show_banner()
	load_level(current_level)

func _setup_city_backdrop() -> void:
	if not is_instance_valid(city_silhouette):
		return
	var backdrop := Control.new()
	backdrop.set_script(CityBackdropScript)
	city_silhouette.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _setup_glyph_dropdown() -> void:
	if not is_instance_valid(glyph_dropdown):
		return
	glyph_dropdown.visible = false

func _setup_glyph_dialog() -> void:
	_glyph_dialog = ConfirmationDialog.new()
	_glyph_dialog.title = "Combine glyphs"
	_glyph_dialog.ok_button_text = "Play"
	add_child(_glyph_dialog)
	var box := VBoxContainer.new()
	_glyph_dialog.add_child(box)
	var instruction := Label.new()
	instruction.text = "Enter 2 to 4 letters or numbers (A-Z, a-z, 0-9)"
	box.add_child(instruction)
	_glyph_entry = LineEdit.new()
	_glyph_entry.max_length = 4
	_glyph_entry.placeholder_text = "Ab3"
	box.add_child(_glyph_entry)
	_glyph_dialog.confirmed.connect(_on_custom_glyph_confirmed)
	_glyph_dialog.canceled.connect(_sync_glyph_dropdown)

func _sync_glyph_dropdown() -> void:
	if selected_glyph.is_empty():
		glyph_dropdown.select(0)
	elif selected_glyph.length() > 1:
		glyph_dropdown.set_item_text(1, "Mix %s" % selected_glyph)
		glyph_dropdown.select(1)
	else:
		glyph_dropdown.select(GlyphStrokes.CHARACTERS.find(selected_glyph) + 2)

func _on_custom_glyph_confirmed() -> void:
	var glyph := _glyph_entry.text.strip_edges()
	if glyph.length() < 2 or not GlyphStrokes.is_supported(glyph):
		_glyph_entry.text = ""
		_glyph_entry.placeholder_text = "Use 2 to 4 letters or numbers"
		_glyph_dialog.popup_centered(Vector2i(380, 160))
		return
	selected_glyph = glyph
	_sync_glyph_dropdown()
	load_level(LevelGen.GLYPH_PRACTICE_LEVEL)

func _on_glyph_selected(index: int) -> void:
	if index == 0:
		selected_glyph = ""
		load_level(_campaign_level)
		return
	if index == 1:
		_glyph_entry.text = selected_glyph if selected_glyph.length() > 1 else ""
		_glyph_dialog.popup_centered(Vector2i(380, 160))
		return
	selected_glyph = GlyphStrokes.CHARACTERS.substr(index - 2, 1)
	load_level(LevelGen.GLYPH_PRACTICE_LEVEL)

func _reload_current_level() -> void:
	load_level(LevelGen.GLYPH_PRACTICE_LEVEL if not selected_glyph.is_empty() else current_level)

func _ensure_nodes() -> void:
	if not background_sky:
		background_sky = get_node_or_null("BackgroundSky")
	if not city_silhouette:
		city_silhouette = get_node_or_null("CitySilhouette")
	if not level_label:
		level_label = get_node_or_null("TopBar/LevelPill/LevelLabel")
	if not objective_label:
		objective_label = get_node_or_null("TopBar/ObjectiveLabel")
	if not hint_label:
		hint_label = get_node_or_null("TopBar/HintLabel")
	if not ink_bar:
		ink_bar = get_node_or_null("TopBar/InkBar")
	if not drawing_canvas:
		drawing_canvas = get_node_or_null("CanvasHolder/DrawingCanvas")
	if not world_container:
		world_container = get_node_or_null("WorldContainer")
	if not platforms_container:
		platforms_container = get_node_or_null("WorldContainer/PlatformsContainer")
	if not bugs_container:
		bugs_container = get_node_or_null("WorldContainer/BugsContainer")
	if not victory_panel:
		victory_panel = get_node_or_null("VictoryPanel")
	if not victory_title:
		victory_title = get_node_or_null("VictoryPanel/VBox/VictoryTitle")
	if not coins_reward:
		coins_reward = get_node_or_null("VictoryPanel/VBox/CoinsReward")
	if not star1:
		star1 = get_node_or_null("VictoryPanel/VBox/StarsHBox/Star1")
	if not star2:
		star2 = get_node_or_null("VictoryPanel/VBox/StarsHBox/Star2")
	if not star3:
		star3 = get_node_or_null("VictoryPanel/VBox/StarsHBox/Star3")
	if not next_level_btn:
		next_level_btn = get_node_or_null("VictoryPanel/VBox/NextLevelBtn")
	if not restart_btn:
		restart_btn = get_node_or_null("TopBar/RestartBtn")
	if not menu_btn:
		menu_btn = get_node_or_null("TopBar/MenuBtn")
	if not hint_btn:
		hint_btn = get_node_or_null("TopBar/HintBtn")
	if not fail_panel:
		fail_panel = get_node_or_null("FailPanel")
	if not fail_title:
		fail_title = get_node_or_null("FailPanel/VBox/FailTitle")
	if not fail_message:
		fail_message = get_node_or_null("FailPanel/VBox/FailMessage")
	if not try_again_btn:
		try_again_btn = get_node_or_null("FailPanel/VBox/TryAgainBtn")
	if not watch_ad_btn:
		watch_ad_btn = get_node_or_null("FailPanel/VBox/WatchAdBtn")
	if not top_coin_pill:
		top_coin_pill = get_node_or_null("TopBar/TopCoinPill")
	if not top_coin_icon:
		top_coin_icon = get_node_or_null("TopBar/TopCoinPill/Margin/HBox/TopCoinIcon")
	if not top_coin_label:
		top_coin_label = get_node_or_null("TopBar/TopCoinPill/Margin/HBox/TopCoinLabel")
	if not mode_btn:
		mode_btn = get_node_or_null("TopBar/ModeBtn")
	if not glyph_dropdown:
		glyph_dropdown = get_node_or_null("TopBar/GlyphDropdown")
	if not mode_dialog:
		mode_dialog = get_node_or_null("ModeDialog")
	if not mode_dialog_title:
		mode_dialog_title = get_node_or_null("ModeDialog/VBox/ModeDialogTitle")
	if not mode_dialog_subtitle:
		mode_dialog_subtitle = get_node_or_null("ModeDialog/VBox/ModeDialogSubtitle")
	if not child_mode_btn:
		child_mode_btn = get_node_or_null("ModeDialog/VBox/ChildModeBtn")
	if not adult_mode_btn:
		adult_mode_btn = get_node_or_null("ModeDialog/VBox/AdultModeBtn")
	if not hard_mode_btn:
		hard_mode_btn = get_node_or_null("ModeDialog/VBox/HardModeBtn")
	if not mode_continue_btn:
		mode_continue_btn = get_node_or_null("ModeDialog/VBox/ModeContinueBtn")

func _get_game_state() -> Node:
	if is_inside_tree():
		if get_tree() and get_tree().root:
			var s_root = get_tree().root.get_node_or_null("GameState")
			if s_root:
				return s_root
		return get_node_or_null("/root/GameState")
	var p = get_parent()
	if p:
		var s_parent = p.get_node_or_null("GameState")
		if s_parent:
			return s_parent
	return null

func load_level(lvl: int, preset_data: Dictionary = {}) -> void:
	_load_serial += 1
	_update_top_coin_hud()
	_ensure_nodes()
	if is_inside_tree():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("stop_bug_anxious"):
			audio.stop_bug_anxious()
	current_level = lvl
	if selected_glyph.is_empty():
		_campaign_level = lvl
	is_level_cleared = false
	_pending_win = false
	_win_wait = 0.0
	_stroke_elapsed = 0.0
	_settle_timer = 0.0
	_has_triggered_miss = false
	_awaiting_drop = false
	_manual_drop_credits = FREE_MANUAL_DROPS_PER_LEVEL
	if is_instance_valid(_drop_btn):
		_drop_btn.visible = false
	if is_instance_valid(_auto_drop_btn):
		_auto_drop_btn.visible = false
		_auto_drop_btn.disabled = false
	active_bugs.clear()
	active_props.clear()

	if is_instance_valid(victory_panel):
		victory_panel.visible = false
	if is_instance_valid(next_level_btn):
		next_level_btn.text = "NEXT LEVEL"
		next_level_btn.disabled = false
	if is_instance_valid(fail_panel):
		fail_panel.visible = false

	for body in active_drawn_bodies:
		if is_instance_valid(body):
			body.queue_free()
	active_drawn_bodies.clear()
	_held_drawn_bodies.clear()
	active_drawn_body = null

	# Clear previous level objects
	if is_instance_valid(platforms_container):
		for child in platforms_container.get_children():
			child.queue_free()
	active_anchors.clear()

	if is_instance_valid(bugs_container):
		for child in bugs_container.get_children():
			child.queue_free()

	if is_instance_valid(mode_dialog):
		mode_dialog.visible = false
	_update_mode_ui()
	# 1. Load the exact authored letter level from JSON.
	var state = _get_game_state()
	var is_daily: bool = (state != null and state.game_mode == "daily")
	var diff_idx := 0 if is_daily else _campaign_difficulty_for_level(lvl)
	if state and not is_daily:
		state.difficulty_index = diff_idx
		state.player_mode = "child" if diff_idx == 0 else "adult"
	var daily_key := Time.get_date_string_from_system() if is_daily else ""
	var catalog_level := _catalog_level_for_campaign(lvl, diff_idx)
	var needs_verification := false
	var level_data: Dictionary = preset_data
	if level_data.is_empty():
		if not selected_glyph.is_empty():
			level_data = LevelGen.make_glyph_practice(selected_glyph, diff_idx)
		else:
			level_data = LevelGen.generate(catalog_level, diff_idx == 0, diff_idx, 0, daily_key)
	if level_data.is_empty():
		_show_generation_error()
		return
	if needs_verification and is_instance_valid(_loading_overlay):
		_loading_overlay.visible = true
	_configure_drawing_area(lvl, is_daily, diff_idx, level_data)

	if is_instance_valid(level_label):
		if not selected_glyph.is_empty():
			level_label.text = "Glyph %s" % selected_glyph
			level_label.add_theme_font_size_override("font_size", 18 if selected_glyph.length() > 2 else 24)
		elif is_daily:
			level_label.text = "Daily Challenge"
			level_label.remove_theme_font_size_override("font_size")
		elif lvl > CAMPAIGN_LEVEL_COUNT:
			level_label.text = "Random Challenge"
			level_label.remove_theme_font_size_override("font_size")
		else:
			level_label.text = "Level %d" % lvl
			level_label.remove_theme_font_size_override("font_size")

	# Apply Stage Environment Theming (Plant Garden, Jungle Canopy, City)
	var stage_theme: String = level_data.get("theme", "city")
	_apply_stage_theme(stage_theme)

	var required_letter := str(level_data.get("required_letter", ""))
	_required_letter = required_letter
	_required_letter_pattern = PackedVector2Array()
	for point in level_data.get("hint_pattern", PackedVector2Array()):
		_required_letter_pattern.append(Vector2(20.0, 171.0) + point)
	var has_bee: bool = false
	for b in level_data.get("bugs", []):
		if b.get("kind", "") == "bee":
			has_bee = true
			break

	if is_instance_valid(objective_label):
		if not required_letter.is_empty():
			objective_label.text = "DRAW LETTER %s TO SMASH THE BUGS" % required_letter
		elif has_bee:
			objective_label.text = "SMASH FLIES | SAVE THE BEE!"
		else:
			objective_label.text = "SMASH ALL BAD BUGS!"

	if is_instance_valid(hint_label):
		hint_label.text = str(level_data.get("hint", ""))
		hint_label.visible = false
	if is_instance_valid(hint_btn):
		hint_btn.visible = true

	if is_instance_valid(drawing_canvas):
		drawing_canvas.reset_canvas()
		var normal_ink := float(level_data.get("ink", 1000.0))
		var elastic_ink := int(state.elastic_ink) if state and "elastic_ink" in state else 0
		_elastic_ink_at_level_start = elastic_ink
		_elastic_ink_spent_this_level = 0
		drawing_canvas.set_ink_budgets(normal_ink, elastic_ink)
		drawing_canvas.set_active_ink_type(_draw_material)
		drawing_canvas.max_strokes = 999
		_update_ink_selector_labels()
		var hint_points := PackedVector2Array()
		for point in level_data.get("hint_pattern", PackedVector2Array()):
			hint_points.append(Vector2(20.0, 171.0) + point - drawing_canvas.global_position)
		drawing_canvas.set_hint_pattern(hint_points)
		if not required_letter.is_empty():
			drawing_canvas.show_hint_pattern()
	_position_draw_controls()

	# 2. Build platforms
	for p_data in level_data.get("platforms", []):
		var platform := StaticBody2D.new()
		platform.set_script(PlatformScript)
		platform.position = p_data.get("pos", Vector2.ZERO)
		platform.size = p_data.get("size", Vector2(100, 40))
		platform.rotation_degrees = p_data.get("rot", 0.0)
		platform.style = p_data.get("style", "brick")
		platforms_container.add_child(platform)

	# 2b. Spawn Movable Physics Props (Stones, Boulders, Big Shapes, Logs)
	for anchor_data in level_data.get("anchors", []):
		var anchor := StaticBody2D.new()
		anchor.position = anchor_data.get("pos", Vector2.ZERO)
		var anchor_shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = float(anchor_data.get("radius", 22.0))
		anchor_shape.shape = circle
		anchor.add_child(anchor_shape)
		platforms_container.add_child(anchor)
		active_anchors.append(anchor)
	var named_props: Dictionary = {}
	for prop_data in level_data.get("props", []):
		var prop := RigidBody2D.new()
		prop.set_script(PropScript)
		prop.name = str(prop_data.get("name", "PhysicsObject"))
		prop.position = prop_data.get("pos", Vector2.ZERO)
		prop.prop_kind = prop_data.get("kind", "stone_boulder")
		prop.prop_size = prop_data.get("size", Vector2(52.0, 52.0))
		prop.starts_frozen = bool(prop_data.get("starts_frozen", false))
		prop.rotation_degrees = prop_data.get("rot", 0.0)
		platforms_container.add_child(prop)
		active_props.append(prop)
		named_props[prop.name] = prop
	for joint_data in level_data.get("joints", []):
		if str(joint_data.get("type", "")) != "pin":
			continue
		var body_name := str(joint_data.get("body", ""))
		var body: RigidBody2D = named_props.get(body_name)
		if not is_instance_valid(body):
			continue
		var joint := PinJoint2D.new()
		joint.position = joint_data.get("pos", body.position)
		joint.node_b = body.get_path()
		joint.softness = 0.05
		platforms_container.add_child(joint)

	# Hard mode hazards: solid moving gates and wind that pushes physics bodies.
	for obstacle_data in level_data.get("moving_obstacles", []):
		var obstacle := AnimatableBody2D.new()
		obstacle.set_script(MovingObstacleScript)
		obstacle.position = obstacle_data.get("pos", Vector2.ZERO)
		obstacle.obstacle_size = obstacle_data.get("size", Vector2(26.0, 105.0))
		obstacle.travel = obstacle_data.get("travel", 44.0)
		obstacle.speed = obstacle_data.get("speed", 1.5)
		platforms_container.add_child(obstacle)
	for fan_data in level_data.get("fans", []):
		var fan := Node2D.new()
		fan.set_script(WindFanScript)
		fan.position = fan_data.get("pos", Vector2.ZERO)
		fan.zone_size = fan_data.get("size", Vector2(195.0, 215.0))
		fan.wind_force = fan_data.get("force", Vector2(650.0, 0.0))
		fan.game = self
		platforms_container.add_child(fan)

	# 3. Spawn Bugs
	for b_data in level_data.get("bugs", []):
		var bug: SmashBug = BugScene.instantiate()
		var bug_position: Vector2 = b_data.get("pos", Vector2.ZERO)
		var suspended := bool(b_data.get("suspended", false))
		bug.position = Vector2.ZERO if suspended else bug_position
		bug.kind = b_data.get("kind", "beetle")
		bug.is_friendly = (bug.kind == "bee")
		bug.move_mode = b_data.get("move", "none")
		bug.move_range = b_data.get("range", 0.0)
		bug.move_speed = b_data.get("speed", 1.0)
		bug.bug_smashed.connect(_on_bug_smashed)
		bug.friendly_smashed.connect(_on_friendly_smashed)

		if suspended:
			var rope_body := RigidBody2D.new()
			rope_body.position = bug_position
			rope_body.mass = 0.8
			rope_body.angular_damp = 0.3
			var rope_collision := CollisionShape2D.new()
			var rope_shape := CircleShape2D.new()
			rope_shape.radius = 22.0
			rope_collision.shape = rope_shape
			rope_body.add_child(rope_collision)
			bugs_container.add_child(rope_body)
			rope_body.add_child(bug)
			var rope_joint := PinJoint2D.new()
			rope_joint.global_position = b_data.get("rope_pivot", bug_position + Vector2(0, -140))
			rope_joint.node_b = rope_body.get_path()
			rope_joint.softness = 0.03
			world_container.add_child(rope_joint)
		else:
			bugs_container.add_child(bug)
		active_bugs.append(bug)
	if needs_verification and not _verification_running:
		call_deferred("_verify_new_level", lvl, diff_idx, daily_key, level_data)

func _apply_top_hud_style() -> void:
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color("#26384b")
	button_style.border_color = Color("#182735")
	button_style.set_border_width_all(2)
	button_style.set_corner_radius_all(14)
	button_style.shadow_color = Color(0.05, 0.08, 0.12, 0.22)
	button_style.shadow_size = 4
	button_style.shadow_offset = Vector2(0, 3)
	var hover_style := button_style.duplicate()
	hover_style.bg_color = Color("#344d66")
	for button in [restart_btn, menu_btn, hint_btn]:
		if is_instance_valid(button):
			button.add_theme_stylebox_override("normal", button_style)
			button.add_theme_stylebox_override("hover", hover_style)
			button.add_theme_stylebox_override("pressed", hover_style)
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = Color("#FFF8E7")
	pill_style.border_color = Color("#E9D8A6")
	pill_style.set_border_width_all(2)
	pill_style.set_corner_radius_all(24)
	pill_style.shadow_color = Color(0.12, 0.16, 0.22, 0.12)
	pill_style.shadow_size = 4
	pill_style.shadow_offset = Vector2(0, 2)
	var level_pill := get_node_or_null("TopBar/LevelPill") as PanelContainer
	if is_instance_valid(level_pill):
		level_pill.add_theme_stylebox_override("panel", pill_style)
	if is_instance_valid(top_coin_pill):
		top_coin_pill.add_theme_stylebox_override("panel", pill_style)

func _configure_drawing_area(level: int, is_daily: bool, difficulty: int = 0, level_data: Dictionary = {}) -> void:
	if not is_instance_valid(canvas_holder) or not is_instance_valid(drawing_canvas):
		return
	# Keep the canvas input hierarchy active. An IGNORE parent prevents child
	# controls from reliably receiving touch events on some mobile devices.
	canvas_holder.mouse_filter = Control.MOUSE_FILTER_STOP
	drawing_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_holder.set_offsets_preset(Control.PRESET_FULL_RECT)
	drawing_canvas.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var stage := level if not is_daily else 16
	var top := 171.0
	var bottom := 411.0
	var draw_area := str(level_data.get("draw_area", "auto"))
	if draw_area == "full" or (draw_area == "auto" and (is_daily or difficulty >= 1 or stage >= 16)):
		top = 110.0
		bottom = 830.0
	elif draw_area == "top" or stage < 4:
		pass
	elif stage >= 9:
		top = 130.0
		bottom = 760.0
	elif stage >= 4:
		top = 150.0
		bottom = 520.0
	drawing_canvas.position = Vector2(20.0, top)
	drawing_canvas.size = Vector2(500.0, bottom - top)
	drawing_canvas.show_paper = difficulty == 0 and stage < 9
	drawing_canvas.queue_redraw()

func _setup_loading_overlay() -> void:
	_loading_overlay = ColorRect.new()
	_loading_overlay.color = Color(0.08, 0.12, 0.18, 1.0)
	_loading_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_loading_overlay.z_index = 1000
	add_child(_loading_overlay)
	_loading_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_loading_overlay.visible = false
	_loading_label = Label.new()
	_loading_label.text = "Preparing a solvable level..."
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_loading_overlay.add_child(_loading_label)
	_loading_label.position = Vector2(40.0, 420.0)
	_loading_label.size = Vector2(460.0, 100.0)

func _setup_drop_button() -> void:
	_drop_btn = Button.new()
	_drop_btn.name = "DropBtn"
	_drop_btn.text = "DROP"
	_drop_btn.tooltip_text = "Drop all held items"
	_drop_btn.position = Vector2(412.0, 276.0)
	_drop_btn.size = Vector2(104.0, 44.0)
	_drop_btn.z_index = 20
	_drop_btn.visible = false
	_drop_btn.add_theme_font_size_override("font_size", 14)
	_drop_btn.add_theme_color_override("font_color", Color.WHITE)
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color("#e87522")
	button_style.border_color = Color("#8e3d12")
	button_style.set_border_width_all(3)
	button_style.set_corner_radius_all(16)
	_drop_btn.add_theme_stylebox_override("normal", button_style)
	var pressed_style := button_style.duplicate()
	pressed_style.bg_color = Color("#bd5517")
	_drop_btn.add_theme_stylebox_override("pressed", pressed_style)
	add_child(_drop_btn)
	_drop_btn.pressed.connect(_on_drop_pressed)

	_auto_drop_btn = Button.new()
	_auto_drop_btn.name = "AutoDropBtn"
	_auto_drop_btn.icon = AutoDropIcon
	_auto_drop_btn.expand_icon = true
	_auto_drop_btn.position = Vector2(184.0, 776.0)
	_auto_drop_btn.size = Vector2(172.0, 54.0)
	_auto_drop_btn.z_index = 20
	_auto_drop_btn.visible = false
	_auto_drop_btn.add_theme_font_size_override("font_size", 17)
	_auto_drop_btn.add_theme_color_override("font_color", Color.WHITE)
	var auto_style := StyleBoxFlat.new()
	auto_style.bg_color = Color("#407cc5")
	auto_style.border_color = Color("#1d477e")
	auto_style.set_border_width_all(3)
	auto_style.set_corner_radius_all(16)
	_auto_drop_btn.add_theme_stylebox_override("normal", auto_style)
	var auto_pressed_style := auto_style.duplicate()
	auto_pressed_style.bg_color = Color("#2e629f")
	_auto_drop_btn.add_theme_stylebox_override("pressed", auto_pressed_style)
	add_child(_auto_drop_btn)
	_auto_drop_btn.pressed.connect(_on_auto_drop_pressed)

func _setup_tools_panel() -> void:
	_tools_panel = Panel.new()
	_tools_panel.name = "ToolsPanel"
	_tools_panel.position = Vector2(396.0, 102.0)
	_tools_panel.size = Vector2(128.0, 116.0)
	_tools_panel.z_index = 20
	_tools_panel.visible = false
	# The panel owns tool selection, so a choice is registered even if an icon
	# control does not receive a platform-specific touch event.
	_tools_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_tools_panel.gui_input.connect(_on_tools_panel_gui_input)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#1d2b3a")
	panel_style.border_color = Color("#526b84")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(16)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	panel_style.shadow_size = 8
	panel_style.shadow_offset = Vector2(0.0, 4.0)
	_tools_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_tools_panel)

func _make_tool_button(icon: Texture2D, tooltip: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(48.0, 48.0)
	button.size = Vector2(48.0, 48.0)
	button.icon = icon
	button.expand_icon = true
	button.tooltip_text = tooltip
	button.z_index = 20
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#26384b")
	normal.border_color = Color("#172432")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)
	var hover := normal.duplicate()
	hover.bg_color = Color("#344d66")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	_tools_panel.add_child(button)
	return button

func _setup_draw_item_selector() -> void:
	_elastic_ink_btn = _make_tool_button(ElasticInkIcon, "Elastic ink")
	_elastic_ink_btn.name = "ElasticInkBtn"
	_elastic_ink_btn.position = Vector2(10.0, 10.0)
	_elastic_ink_btn.pressed.connect(_select_draw_material.bind("elastic"))
	_solid_ink_btn = _make_tool_button(SolidInkIcon, "Solid ink")
	_solid_ink_btn.name = "SolidInkBtn"
	_solid_ink_btn.position = Vector2(70.0, 10.0)
	_solid_ink_btn.pressed.connect(_select_draw_material.bind("solid"))

func _setup_drop_mode_selector() -> void:
	_auto_mode_btn = _make_tool_button(AutoDropIcon, "Auto drop")
	_auto_mode_btn.name = "AutoDropModeBtn"
	_auto_mode_btn.position = Vector2(10.0, 58.0)
	_auto_mode_btn.pressed.connect(_select_drop_mode.bind("auto"))
	_manual_mode_btn = _make_tool_button(ManualDropIcon, "Manual drop")
	_manual_mode_btn.name = "ManualDropModeBtn"
	_manual_mode_btn.position = Vector2(70.0, 58.0)
	_manual_mode_btn.pressed.connect(_select_drop_mode.bind("manual"))

	# Tools occupy the former Hint button slot in the top bar.
	_tool_toggle_btn = hint_btn

func _make_ink_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#e5e9ef")
	background.corner_radius_top_left = 6
	background.corner_radius_top_right = 6
	background.corner_radius_bottom_left = 6
	background.corner_radius_bottom_right = 6
	var fill := background.duplicate()
	fill.bg_color = fill_color
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _setup_ink_hud() -> void:
	# Replace the ambiguous combined meter with one visible meter per material.
	if is_instance_valid(ink_bar):
		ink_bar.visible = false
	_solid_ink_bar = _make_ink_bar(Color("#14171c"))
	_solid_ink_bar.tooltip_text = "◆ Solid ink"
	_solid_ink_bar.position = Vector2(46.0, 144.0)
	_solid_ink_bar.size = Vector2(470.0, 10.0)
	$TopBar.add_child(_solid_ink_bar)
	_elastic_ink_bar = _make_ink_bar(Color("#d94141"))
	_elastic_ink_bar.tooltip_text = "● Elastic ink"
	_elastic_ink_bar.position = Vector2(46.0, 144.0)
	_elastic_ink_bar.size = Vector2(470.0, 10.0)
	$TopBar.add_child(_elastic_ink_bar)
	for data in [["◆", Color("#14171c"), "Solid ink"], ["●", Color("#d94141"), "Elastic ink"]]:
		var icon := Label.new()
		icon.text = data[0]
		icon.tooltip_text = data[2]
		icon.position = Vector2(24.0, 138.0)
		icon.size = Vector2(18.0, 20.0)
		icon.add_theme_color_override("font_color", data[1])
		icon.add_theme_font_size_override("font_size", 17)
		$TopBar.add_child(icon)
		if data[2] == "Solid ink":
			_solid_ink_marker = icon
		else:
			_elastic_ink_marker = icon

func _position_draw_controls() -> void:
	# The tools are a fixed dropdown from the compass button, not floating controls.
	if is_instance_valid(_drop_btn):
		_drop_btn.position = Vector2(412.0, 226.0)

func _select_draw_material(material: String) -> void:
	_extend_tools_menu_timeout()
	if material == "elastic" and is_instance_valid(drawing_canvas) and drawing_canvas.remaining_ink("elastic") < drawing_canvas.MIN_STROKE_LENGTH:
		# Prevent selecting Elastic when empty; prompt coin purchase or ad refill instead.
		_draw_material = "solid"
		drawing_canvas.set_active_ink_type("normal")
		_update_ink_selector_labels()
		_show_elastic_ink_store()
		return
	_draw_material = "elastic" if material == "elastic" else "solid"
	if is_instance_valid(drawing_canvas):
		drawing_canvas.set_active_ink_type("elastic" if _draw_material == "elastic" else "normal")
	_update_ink_selector_labels()

func _select_drop_mode(mode: String) -> void:
	_extend_tools_menu_timeout()
	_drop_mode = "auto" if mode == "auto" else "manual"
	_update_tool_button_states()

func _on_tool_toggle_pressed() -> void:
	var opening := not _tools_panel.visible
	_tools_menu_serial += 1
	_tools_panel.visible = opening
	_tool_toggle_btn.tooltip_text = "Close drawing tools" if opening else "Open drawing tools"
	if opening:
		_auto_hide_tools(_tools_menu_serial)

func _on_tools_panel_gui_input(event: InputEvent) -> void:
	var position := Vector2.ZERO
	if event is InputEventMouseButton:
		if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
			return
		position = event.position
	elif event is InputEventScreenTouch:
		if not event.pressed:
			return
		position = event.position
	else:
		return
	if Rect2(10.0, 10.0, 48.0, 48.0).has_point(position):
		_select_draw_material("elastic")
	elif Rect2(70.0, 10.0, 48.0, 48.0).has_point(position):
		_select_draw_material("solid")
	elif Rect2(10.0, 58.0, 48.0, 48.0).has_point(position):
		_select_drop_mode("auto")
	elif Rect2(70.0, 58.0, 48.0, 48.0).has_point(position):
		_select_drop_mode("manual")

func _auto_hide_tools(serial: int) -> void:
	await get_tree().create_timer(5.0).timeout
	if serial == _tools_menu_serial and is_instance_valid(_tools_panel):
		_tools_panel.visible = false
		_tool_toggle_btn.tooltip_text = "Open drawing tools"

func _extend_tools_menu_timeout() -> void:
	if not is_instance_valid(_tools_panel) or not _tools_panel.visible:
		return
	_tools_menu_serial += 1
	_auto_hide_tools(_tools_menu_serial)

func _style_pill_button(button: Button, bg: Color, border: Color, font_col: Color, outline_col: Color = Color.TRANSPARENT) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = border
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(22)
	normal.shadow_color = Color(0, 0, 0, 0.22)
	normal.shadow_size = 6
	normal.shadow_offset = Vector2(0, 4)
	var pressed := normal.duplicate()
	pressed.bg_color = bg.darkened(0.12)
	pressed.shadow_size = 2
	pressed.shadow_offset = Vector2(0, 2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_font_override("font", BoldFont)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", font_col)
	if outline_col.a > 0.0:
		button.add_theme_color_override("font_outline_color", outline_col)
		button.add_theme_constant_override("outline_size", 4)

func _create_store_popup(title_text: String) -> Dictionary:
	var root := Control.new()
	root.visible = false
	root.z_index = 500
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.08, 0.12, 0.16, 0.78)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dimmer)

	var center_box := Control.new()
	center_box.anchor_left = 0.5
	center_box.anchor_top = 0.5
	center_box.anchor_right = 0.5
	center_box.anchor_bottom = 0.5
	center_box.offset_left = -220.0
	center_box.offset_top = -225.0
	center_box.offset_right = 220.0
	center_box.offset_bottom = 225.0
	dimmer.add_child(center_box)

	var monster := TextureRect.new()
	monster.anchor_left = 0.5
	monster.anchor_right = 0.5
	monster.offset_left = -70.0
	monster.offset_top = -30.0
	monster.offset_right = 70.0
	monster.offset_bottom = 90.0
	monster.texture = MonsterPeekTex
	monster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	monster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	center_box.add_child(monster)

	var paper := NinePatchRect.new()
	paper.set_anchors_preset(Control.PRESET_FULL_RECT)
	paper.offset_top = 40.0
	paper.texture = NoticePaperTex
	paper.patch_margin_left = 40
	paper.patch_margin_top = 55
	paper.patch_margin_right = 40
	paper.patch_margin_bottom = 60
	center_box.add_child(paper)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 44)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 48)
	paper.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", HeadingFont)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.18, 0.18, 0.22, 1.0))
	vbox.add_child(title)

	var underline := ColorRect.new()
	underline.custom_minimum_size = Vector2(160.0, 3.0)
	underline.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	underline.color = Color(0.38, 0.65, 0.95, 1.0)
	vbox.add_child(underline)

	var body := Label.new()
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", BoldFont)
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color(0.24, 0.26, 0.32, 1.0))
	vbox.add_child(body)

	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(0.0, 48.0)
	_style_pill_button(buy_btn, Color("#69d275"), Color("#2e7d32"), Color.WHITE, Color("#1b5e20"))
	vbox.add_child(buy_btn)

	var ad_btn := Button.new()
	ad_btn.custom_minimum_size = Vector2(0.0, 48.0)
	_style_pill_button(ad_btn, Color("#69d275"), Color("#2e7d32"), Color.WHITE, Color("#1b5e20"))
	vbox.add_child(ad_btn)

	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(0.0, 42.0)
	_style_pill_button(close_btn, Color("#e4eaf1"), Color("#9aa7b8"), Color("#2c3645"))
	close_btn.pressed.connect(func(): root.visible = false)
	vbox.add_child(close_btn)

	add_child(root)
	return {"root": root, "body": body, "buy_btn": buy_btn, "ad_btn": ad_btn}

func _refresh_store_popup(body_lbl: Label, buy_btn: Button, ad_btn: Button, cost: int, buy_text: String, ad_text: String, buy_msg: String, ad_msg: String) -> void:
	var state = _get_game_state()
	var coins: int = int(state.coins) if state else 0
	var can_buy: bool = coins >= cost
	if is_instance_valid(buy_btn):
		buy_btn.visible = can_buy
		buy_btn.text = buy_text
	if is_instance_valid(ad_btn):
		ad_btn.visible = not can_buy
		ad_btn.text = ad_text
	if is_instance_valid(body_lbl):
		body_lbl.text = buy_msg if can_buy else ad_msg

func _setup_elastic_ink_dialog() -> void:
	var popup := _create_store_popup("Elastic Ink Empty")
	_elastic_ink_dialog = popup["root"]
	_elastic_ink_body = popup["body"]
	_elastic_buy_button = popup["buy_btn"]
	_elastic_ad_button = popup["ad_btn"]
	_elastic_buy_button.pressed.connect(_on_buy_elastic_ink)
	_elastic_ad_button.pressed.connect(_on_elastic_ad_pressed)

func _on_elastic_ad_pressed() -> void:
	_ad_reward_target = "elastic_ink"
	_on_watch_ad_pressed()

func _show_elastic_ink_store() -> void:
	if not is_instance_valid(_elastic_ink_dialog):
		return
	_refresh_elastic_ink_store()
	_elastic_ink_dialog.visible = true

func _refresh_elastic_ink_store() -> void:
	if not is_instance_valid(_elastic_ink_dialog):
		return
	var state = _get_game_state()
	var coins: int = int(state.coins) if state else 0
	_refresh_store_popup(
		_elastic_ink_body,
		_elastic_buy_button,
		_elastic_ad_button,
		ELASTIC_INK_REFILL_COST,
		"BUY +%d INK (%d COINS)" % [ELASTIC_INK_REFILL_AMOUNT, ELASTIC_INK_REFILL_COST],
		"WATCH AD  +%d INK" % ELASTIC_INK_REFILL_AMOUNT,
		"Elastic Ink is empty.\nBuy %d Elastic Ink for %d coins.\nYour wallet: %d coins" % [ELASTIC_INK_REFILL_AMOUNT, ELASTIC_INK_REFILL_COST, coins],
		"Elastic Ink is empty.\nNeed %d coins (Wallet: %d).\nWatch an ad to get +%d Elastic Ink!" % [ELASTIC_INK_REFILL_COST, coins, ELASTIC_INK_REFILL_AMOUNT]
	)

func _setup_manual_drop_dialog() -> void:
	var popup := _create_store_popup("Manual Drop")
	_manual_drop_dialog = popup["root"]
	_manual_drop_body = popup["body"]
	_manual_drop_buy_button = popup["buy_btn"]
	_manual_drop_ad_button = popup["ad_btn"]
	_manual_drop_buy_button.pressed.connect(_buy_manual_drop)
	_manual_drop_ad_button.pressed.connect(_on_manual_drop_ad_pressed)

func _on_manual_drop_ad_pressed() -> void:
	_ad_reward_target = "manual_drop"
	_on_watch_ad_pressed()

func _show_manual_drop_store() -> void:
	if not is_instance_valid(_manual_drop_dialog):
		return
	_refresh_manual_drop_store()
	_manual_drop_dialog.visible = true

func _refresh_manual_drop_store() -> void:
	if not is_instance_valid(_manual_drop_dialog):
		return
	var state = _get_game_state()
	var coins: int = int(state.coins) if state else 0
	_refresh_store_popup(
		_manual_drop_body,
		_manual_drop_buy_button,
		_manual_drop_ad_button,
		MANUAL_DROP_COST,
		"BUY %d DROPS (%d COINS)" % [MANUAL_DROP_PACK_SIZE, MANUAL_DROP_COST],
		"WATCH AD  +%d DROPS" % MANUAL_DROP_PACK_SIZE,
		"Free manual drops used.\nBuy %d more drops for %d coins.\nYour wallet: %d coins" % [MANUAL_DROP_PACK_SIZE, MANUAL_DROP_COST, coins],
		"Free manual drops used.\nNeed %d coins (Wallet: %d).\nWatch an ad to get +%d Manual Drops!" % [MANUAL_DROP_COST, coins, MANUAL_DROP_PACK_SIZE]
	)

func _buy_manual_drop() -> void:
	var state = _get_game_state()
	if not state or state.coins < MANUAL_DROP_COST:
		_show_manual_drop_store()
		return
	state.coins -= MANUAL_DROP_COST
	state.save_progress()
	_update_top_coin_hud()
	if is_instance_valid(_manual_drop_dialog):
		_manual_drop_dialog.visible = false
	_manual_drop_credits += MANUAL_DROP_PACK_SIZE
	_complete_manual_drop()

func _grant_elastic_ink_refill() -> void:
	var state = _get_game_state()
	if state:
		state.elastic_ink += ELASTIC_INK_REFILL_AMOUNT
		state.save_progress()
	_elastic_ink_at_level_start += ELASTIC_INK_REFILL_AMOUNT
	if is_instance_valid(drawing_canvas):
		drawing_canvas.add_elastic_ink(ELASTIC_INK_REFILL_AMOUNT)
		drawing_canvas.set_active_ink_type("elastic")
	_draw_material = "elastic"
	if is_instance_valid(_elastic_ink_dialog) and _elastic_ink_dialog.visible:
		_elastic_ink_dialog.hide()
	_update_tool_button_states()
	_update_ink_selector_labels()
	_update_top_coin_hud()

func _on_buy_elastic_ink() -> void:
	var state = _get_game_state()
	if not state or state.coins < ELASTIC_INK_REFILL_COST:
		_show_elastic_ink_store()
		return
	state.coins -= ELASTIC_INK_REFILL_COST
	_grant_elastic_ink_refill()

func _on_ink_depleted(ink_type: String) -> void:
	if ink_type == "elastic":
		_show_elastic_ink_store()

func _update_ink_selector_labels() -> void:
	if not is_instance_valid(drawing_canvas):
		return
	if is_instance_valid(_elastic_ink_btn):
		_elastic_ink_btn.tooltip_text = "Elastic ink: %d remaining" % roundi(drawing_canvas.remaining_ink("elastic"))
	if is_instance_valid(_solid_ink_btn):
		_solid_ink_btn.tooltip_text = "Solid ink: %d remaining" % roundi(drawing_canvas.remaining_ink("normal"))
	_update_tool_button_states()
	_update_ink_hud()

func _update_tool_button_states() -> void:
	for data in [[_elastic_ink_btn, _draw_material == "elastic"], [_solid_ink_btn, _draw_material == "solid"], [_auto_mode_btn, _drop_mode == "auto"], [_manual_mode_btn, _drop_mode == "manual"]]:
		var button: Button = data[0] as Button
		if not is_instance_valid(button):
			continue
		var selected: bool = data[1]
		button.modulate = Color("#ffffff") if selected else Color("#aeb8c4")

func _update_ink_hud() -> void:
	if not is_instance_valid(drawing_canvas):
		return
	var elastic_selected: bool = _draw_material == "elastic"
	if is_instance_valid(_solid_ink_bar):
		_solid_ink_bar.visible = not elastic_selected
		_solid_ink_bar.value = clampf(drawing_canvas.remaining_ink("normal") / maxf(drawing_canvas.normal_max_ink, 1.0) * 100.0, 0.0, 100.0)
	if is_instance_valid(_elastic_ink_bar):
		_elastic_ink_bar.visible = elastic_selected
		var elastic_capacity := maxf(float(ELASTIC_INK_REFILL_AMOUNT), drawing_canvas.elastic_max_ink)
		_elastic_ink_bar.value = clampf(drawing_canvas.remaining_ink("elastic") / elastic_capacity * 100.0, 0.0, 100.0)
	if is_instance_valid(_solid_ink_marker):
		_solid_ink_marker.visible = not elastic_selected
	if is_instance_valid(_elastic_ink_marker):
		_elastic_ink_marker.visible = elastic_selected

func _show_generation_error() -> void:
	if not is_instance_valid(_loading_overlay):
		return
	_loading_overlay.visible = true
	_loading_label.text = "Could not prepare a unique solvable level.\nReturn to the menu and try again."
	var menu_button := Button.new()
	menu_button.text = "MENU"
	menu_button.position = Vector2(210.0, 540.0)
	menu_button.size = Vector2(120.0, 54.0)
	menu_button.pressed.connect(_on_menu_pressed)
	_loading_overlay.add_child(menu_button)

func _verify_new_level(level: int, difficulty: int, daily_key: String, first_candidate: Dictionary) -> void:
	if _verification_running or not is_inside_tree():
		return
	_verification_running = true
	var candidate := first_candidate
	while not candidate.is_empty():
		_verification_failed = false
		_loading_label.text = "Preparing a solvable level..."
		await get_tree().physics_frame
		var points := PackedVector2Array()
		for point in candidate["hint_pattern"]:
			points.append(Vector2(20.0, 171.0) + point)
		_on_stroke_completed(points)
		for _frame in range(480):
			await get_tree().physics_frame
			if not is_inside_tree() or _verification_failed or is_level_cleared:
				break
		if not is_inside_tree():
			return
		if _verified_solution_succeeded():
			_verification_running = false
			LevelStore.save_accepted(level, difficulty, daily_key, candidate)
			load_level(level, candidate)
			_loading_overlay.visible = false
			return
		candidate = {}
		while _candidate_attempt < LevelStore.MAX_CANDIDATES and candidate.is_empty():
			candidate = LevelStore.make_candidate(level, difficulty, daily_key, _candidate_attempt)
			_candidate_attempt += 1
		if not candidate.is_empty():
			load_level(level, candidate)
	_verification_running = false
	_show_generation_error()

func _verified_solution_succeeded() -> bool:
	if _verification_failed or not is_level_cleared:
		return false
	for bug in active_bugs:
		if not is_instance_valid(bug):
			return false
		if bug.is_friendly and bug.state == SmashBug.State.DEAD:
			return false
		if not bug.is_friendly and bug.state != SmashBug.State.DEAD:
			return false
	return true

func _apply_stage_theme(theme_name: String) -> void:
	if not is_instance_valid(background_sky) or not is_instance_valid(city_silhouette):
		return

	match theme_name:
		"garden":
			background_sky.color = Color(0.97, 0.96, 0.98, 1.0)
			city_silhouette.color = Color(0.83, 0.84, 0.91, 0.22)
		"jungle":
			background_sky.color = Color(0.96, 0.95, 0.99, 1.0)
			city_silhouette.color = Color(0.82, 0.82, 0.91, 0.25)
		_:
			background_sky.color = Color(0.96, 0.97, 1.0, 1.0)
			city_silhouette.color = Color(0.82, 0.86, 0.94, 0.28)

func _process(delta: float) -> void:
	for prop in active_props:
		if not is_instance_valid(prop) or not prop.has_method("try_release_from_body"):
			continue
		if is_instance_valid(active_drawn_body):
			prop.try_release_from_body(active_drawn_body)
		for other_prop in active_props:
			if other_prop != prop and is_instance_valid(other_prop):
				prop.try_release_from_body(other_prop)
	# Keep Solid and Elastic meters independent so the selected material is clear.
	_update_ink_hud()

	# Check proximity of falling drawn line or moving hazard coming directly towards the bugs
	if not is_level_cleared:
		var any_bug_panicking := false
		if is_instance_valid(active_drawn_body):
			for bug in active_bugs:
				if not is_instance_valid(bug) or bug.state == SmashBug.State.DEAD or bug.state == SmashBug.State.CELEBRATE:
					continue
				var should_panic := false

				# 1. Drawn line is in the air and falling directly towards this bug
				var vel_y: float = active_drawn_body.linear_velocity.y
				# Must have downward motion (falling, not resting on ground or bouncing up)
				if vel_y > 40.0:
					var dy: float = bug.global_position.y - active_drawn_body.global_position.y
					var dx: float = absf(active_drawn_body.global_position.x - bug.global_position.x)
					# Must be directly above the bug and within incoming plunge cone
					if dy > 10.0 and dy < 260.0 and dx < 140.0:
						should_panic = true

				# 2. Moving prop hazard actively hurtling towards this bug at real velocity
				if not should_panic and not bug.is_friendly:
					for prop in active_props:
						if is_instance_valid(prop) and prop.linear_velocity.length() > 45.0:
							var to_bug: Vector2 = bug.global_position - prop.global_position
							var dist: float = to_bug.length()
							if dist < 200.0 and dist > 10.0:
								var approach_speed: float = prop.linear_velocity.dot(to_bug.normalized())
								if approach_speed > 35.0:
									should_panic = true
									break

				bug.set_panic(should_panic)
				if should_panic:
					any_bug_panicking = true
		else:
			for bug in active_bugs:
				if is_instance_valid(bug) and bug.state == SmashBug.State.PANIC:
					bug.set_panic(false)

		if is_inside_tree():
			var audio = get_node_or_null("/root/AudioManager")
			if audio:
				if any_bug_panicking and audio.has_method("play_bug_anxious"):
					audio.play_bug_anxious()
				elif not any_bug_panicking and audio.has_method("stop_bug_anxious"):
					audio.stop_bug_anxious()

		# In any case a friendly bee died, level must fail immediately!
		if not is_level_cleared:
			for b in active_bugs:
				if is_instance_valid(b) and b.is_friendly and b.state == SmashBug.State.DEAD:
					_on_friendly_smashed(b)
					break
		var has_dropped_body := false
		for drawn in active_drawn_bodies:
			if is_instance_valid(drawn) and not drawn.freeze:
				has_dropped_body = true
				break
		if has_dropped_body and not is_level_cleared and not _awaiting_drop:
			_stroke_elapsed += delta
		if _pending_win and not is_level_cleared:
			if _stroke_elapsed >= 5.0:
				_finish_pending_win()
				return
			var bodies_settled := _are_all_bodies_settled()
			_win_wait = _win_wait + delta if bodies_settled else 0.0
			if _win_wait >= 0.75:
				_finish_pending_win()
		# Check up to 5.0s after drop: if bugs are still alive, fail the level.
		if has_dropped_body and not is_level_cleared and not _pending_win and not _awaiting_drop and not _has_triggered_miss:
			if _stroke_elapsed >= 5.0:
				_has_triggered_miss = true
				_on_stroke_missed()
			elif _stroke_elapsed >= 1.4 and _are_all_bodies_settled():
				_settle_timer += delta
				if _settle_timer >= 0.75:
					_has_triggered_miss = true
					_on_stroke_missed()
			else:
				_settle_timer = 0.0

func _is_body_settled(body: Node) -> bool:
	if not is_instance_valid(body):
		return true
	var pos: Vector2 = body.global_position
	if pos.y > 980.0 or pos.x < -80.0 or pos.x > 620.0:
		return true
	return body.linear_velocity.length() < 12.0 and absf(body.angular_velocity) < 0.35

func _are_all_bodies_settled() -> bool:
	for drawn in active_drawn_bodies:
		if not _is_body_settled(drawn):
			return false
	for prop in active_props:
		if not _is_body_settled(prop):
			return false
	return true

func _on_stroke_completed(global_pts: PackedVector2Array) -> void:
	if not _required_letter.is_empty() and not _stroke_matches_required_letter(global_pts):
		_has_triggered_miss = true
		_show_fail_panel("DRAW LETTER %s" % _required_letter, "Follow the %s shape shown on the paper." % _required_letter)
		return

	_stroke_elapsed = 0.0
	_settle_timer = 0.0
	_has_triggered_miss = false
	if _draw_material == "elastic" and is_instance_valid(drawing_canvas):
		drawing_canvas.commit_elastic_stroke()
		var spent_ink := roundi(drawing_canvas.stroke_ink)
		_elastic_ink_spent_this_level += spent_ink
		var state = _get_game_state()
		if state:
			# Elastic ink is persistent: a failed or restarted level never restores it.
			state.elastic_ink = maxi(0, int(state.elastic_ink) - spent_ink)
			state.save_progress()
			_elastic_ink_at_level_start = int(state.elastic_ink)
	_update_ink_selector_labels()
	if is_instance_valid(fail_panel) and not is_level_cleared:
		fail_panel.visible = false
	for b in active_bugs:
		if is_instance_valid(b):
			b.reset_celebration()

	# Spawn the selected physics item from the drawn points.
	var body := SmashDrawnBody.new()
	# Elastic only changes the released line's physics; drawing preview stays neutral.
	body.rubber_bounce = 0.92 if _draw_material == "elastic" else 0.0
	body.surface_friction = 0.05 if _draw_material == "elastic" else 0.45
	body.stroke_color = Color("#d95c1a") if _draw_material == "elastic" else Color("#30353b")
	world_container.add_child(body)
	body.build_from_points(global_pts)
	body.mass = 2.5 if _draw_material == "elastic" else 16.0
	if _draw_material == "elastic" and is_instance_valid(drawing_canvas) and drawing_canvas.remaining_ink("elastic") < drawing_canvas.MIN_STROKE_LENGTH:
		_draw_material = "solid"
		drawing_canvas.set_active_ink_type("normal")
		_update_ink_selector_labels()

	active_drawn_body = body
	active_drawn_bodies.append(body)
	_attach_drawn_body_to_nearest_anchor(body, global_pts)
	# Keep each item where it was drawn until its selected drop mode releases it.
	body.freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	body.freeze = true
	if _drop_mode == "manual":
		_held_drawn_bodies.append(body)
		_awaiting_drop = true
		if is_instance_valid(_drop_btn):
			_drop_btn.visible = true
	else:
		# Auto mode is a timed action. Show a disabled countdown indicator so the
		# player knows the drop was accepted and cannot trigger it twice.
		if is_instance_valid(_auto_drop_btn):
			_auto_drop_btn.tooltip_text = "Auto drop is active"
			_auto_drop_btn.disabled = true
			_auto_drop_btn.visible = true
		_schedule_auto_drop(body)

	# Play the drawing sound; the body is released by _on_drop_pressed.
	if is_inside_tree():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_undo"):
			audio.play_undo()

func _on_drop_pressed() -> void:
	if _held_drawn_bodies.is_empty():
		return
	if _manual_drop_credits <= 0:
		_show_manual_drop_store()
		return
	_complete_manual_drop()

func _complete_manual_drop() -> void:
	if _held_drawn_bodies.is_empty():
		return
	for body in _held_drawn_bodies:
		_release_drawn_body(body)
	_held_drawn_bodies.clear()
	_awaiting_drop = false
	_manual_drop_credits = maxi(0, _manual_drop_credits - 1)
	if is_instance_valid(_drop_btn):
		_drop_btn.visible = false
	if is_inside_tree():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_undo"):
			audio.play_undo()

func _schedule_auto_drop(body: SmashDrawnBody) -> void:
	var serial := _load_serial
	await get_tree().create_timer(AUTO_DROP_DELAY).timeout
	if serial == _load_serial:
		_release_drawn_body(body)
	if is_instance_valid(_auto_drop_btn):
		_auto_drop_btn.visible = false
		_auto_drop_btn.disabled = false

func _release_drawn_body(body: SmashDrawnBody) -> void:
	if not is_instance_valid(body):
		return
	body.freeze = false
	body.sleeping = false

func _on_auto_drop_pressed() -> void:
	# Kept for the legacy hidden button; manual release is handled by DROP NOW.
	_on_drop_pressed()

func _attach_drawn_body_to_nearest_anchor(body: RigidBody2D, points: PackedVector2Array) -> void:
	if active_anchors.is_empty() or points.is_empty():
		return
	var nearest: StaticBody2D
	var distance := INF
	for anchor in active_anchors:
		if not is_instance_valid(anchor):
			continue
		for point in points:
			var candidate_distance := anchor.global_position.distance_to(point)
			if candidate_distance < distance:
				distance = candidate_distance
				nearest = anchor
	if not is_instance_valid(nearest) or distance > 90.0:
		return
	var joint := PinJoint2D.new()
	joint.global_position = nearest.global_position
	joint.node_a = nearest.get_path()
	joint.node_b = body.get_path()
	joint.softness = 0.05
	world_container.add_child(joint)

func _stroke_matches_required_letter(points: PackedVector2Array) -> bool:
	if _required_letter_pattern.size() < 2 or points.size() < 4:
		return false
	var drawn := _normalize_and_sample(points, 48)
	var target := _normalize_and_sample(_required_letter_pattern, 48)
	if drawn.is_empty() or target.is_empty():
		return false
	var drawn_to_target := _average_nearest_distance(drawn, target)
	var target_to_drawn := _average_nearest_distance(target, drawn)
	return maxf(drawn_to_target, target_to_drawn) <= 0.19

func _normalize_and_sample(points: PackedVector2Array, sample_count: int) -> PackedVector2Array:
	var min_point := points[0]
	var max_point := points[0]
	for point in points:
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)
	var extent := max_point - min_point
	if extent.x < 20.0 or extent.y < 20.0:
		return PackedVector2Array()
	var normalized := PackedVector2Array()
	for point in points:
		normalized.append(Vector2((point.x - min_point.x) / extent.x, (point.y - min_point.y) / extent.y))
	var lengths := PackedFloat32Array([0.0])
	var total := 0.0
	for index in range(1, normalized.size()):
		total += normalized[index - 1].distance_to(normalized[index])
		lengths.append(total)
	if total <= 0.001:
		return PackedVector2Array()
	var sampled := PackedVector2Array()
	var segment := 1
	for sample in range(sample_count):
		var wanted := total * float(sample) / float(sample_count - 1)
		while segment < lengths.size() - 1 and lengths[segment] < wanted:
			segment += 1
		var previous_length := lengths[segment - 1]
		var segment_length := maxf(lengths[segment] - previous_length, 0.0001)
		var weight := (wanted - previous_length) / segment_length
		sampled.append(normalized[segment - 1].lerp(normalized[segment], weight))
	return sampled

func _average_nearest_distance(from_points: PackedVector2Array, to_points: PackedVector2Array) -> float:
	var total := 0.0
	for point in from_points:
		var nearest := INF
		for target in to_points:
			nearest = minf(nearest, point.distance_to(target))
		total += nearest
	return total / float(from_points.size())

func _on_bug_smashed(_bug: SmashBug) -> void:
	if is_level_cleared:
		return

	# In any case a friendly bee died, level fails immediately!
	for b in active_bugs:
		if is_instance_valid(b) and b.is_friendly and b.state == SmashBug.State.DEAD:
			_on_friendly_smashed(b)
			return

	# Level is won only if ALL bad bugs are dead AND all friendly bees are alive!
	var all_bad_dead := true
	var friendly_alive := true

	for b in active_bugs:
		if not is_instance_valid(b):
			continue
		if b.is_friendly:
			if b.state == SmashBug.State.DEAD:
				friendly_alive = false
		else:
			if b.state != SmashBug.State.DEAD:
				all_bad_dead = false

	if not friendly_alive:
		_on_friendly_smashed(_bug)
		return

	if all_bad_dead and friendly_alive:
		_pending_win = true
		_win_wait = 0.0

func _finish_pending_win() -> void:
	if not _pending_win or is_level_cleared:
		return
	for b in active_bugs:
		if is_instance_valid(b) and b.is_friendly and b.state == SmashBug.State.DEAD:
			_on_friendly_smashed(b)
			return
	_pending_win = false
	is_level_cleared = true
	for drawn_body in active_drawn_bodies:
		if is_instance_valid(drawn_body):
			drawn_body.freeze = true
			drawn_body.collision_layer = 0
			drawn_body.collision_mask = 0
	for prop in active_props:
		if is_instance_valid(prop):
			prop.freeze = true
			prop.collision_layer = 0
			prop.collision_mask = 0
	for b in active_bugs:
		if is_instance_valid(b) and b.is_friendly:
			b.set_process(false)
			b.set_physics_process(false)
			b.monitoring = false
	if not _verification_running:
		_on_level_won()

func _trigger_bugs_celebrate() -> void:
	if is_inside_tree():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_bug_celebrate"):
			audio.play_bug_celebrate()
	for b in active_bugs:
		if is_instance_valid(b) and not b.is_friendly and b.state != SmashBug.State.DEAD:
			b.celebrate()

func _on_stroke_missed() -> void:
	if is_level_cleared:
		return
	if _verification_running:
		_verification_failed = true
		return
	var any_bad_alive := false
	for b in active_bugs:
		if is_instance_valid(b) and not b.is_friendly and b.state != SmashBug.State.DEAD:
			any_bad_alive = true
			break
	if not any_bad_alive:
		return

	_trigger_bugs_celebrate()

	if is_inside_tree():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_error"):
			audio.play_error()

	if is_inside_tree() and get_tree():
		var serial := _load_serial
		var timer := get_tree().create_timer(0.95)
		timer.timeout.connect(func():
			if serial == _load_serial and not is_level_cleared and _has_triggered_miss:
				_show_fail_panel("BUGS CELEBRATE! 😂", "Surviving bugs are laughing at your miss!\nTry Again!")
		)
	else:
		_show_fail_panel("BUGS CELEBRATE! 😂", "Surviving bugs are laughing at your miss!\nTry Again!")

func _on_friendly_smashed(_bug: SmashBug) -> void:
	if is_level_cleared:
		return
	_pending_win = false
	is_level_cleared = true
	if _verification_running:
		_verification_failed = true
		return
	_trigger_bugs_celebrate()

	if is_inside_tree():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_error"):
			audio.play_error()

	if is_inside_tree() and get_tree():
		var serial := _load_serial
		var timer := get_tree().create_timer(0.85)
		timer.timeout.connect(func():
			if serial == _load_serial:
				_show_fail_panel("LEVEL FAILED! 💔", "Friendly Bee was harmed!\nIn any case Bee dies, Level Fails!")
		)
	else:
		_show_fail_panel("LEVEL FAILED! 💔", "Friendly Bee was harmed!\nIn any case Bee dies, Level Fails!")

func _show_fail_panel(title: String, msg: String) -> void:
	if not is_instance_valid(fail_panel):
		return
	# A failed level must not leave drop controls available behind its menu.
	if is_instance_valid(_auto_drop_btn):
		_auto_drop_btn.visible = false
		_auto_drop_btn.disabled = false
	if is_instance_valid(_drop_btn):
		_drop_btn.visible = false
	if is_instance_valid(_tools_panel):
		_tools_panel.visible = false
	if is_instance_valid(fail_title):
		fail_title.text = title
	if is_instance_valid(fail_message):
		if not selected_glyph.is_empty() or not _required_letter.is_empty():
			fail_message.text = msg
		else:
			var state = _get_game_state()
			var coins: int = state.coins if state else 0
			fail_message.text = "%s\nCoins: %d 🟡" % [msg, coins]
	_update_fail_panel_buttons()
	fail_panel.visible = true

func _update_fail_panel_buttons() -> void:
	if not selected_glyph.is_empty() or not _required_letter.is_empty():
		if is_instance_valid(try_again_btn):
			try_again_btn.text = "TRY LETTER AGAIN"
			try_again_btn.disabled = false
		if is_instance_valid(watch_ad_btn):
			watch_ad_btn.visible = false
		return
	var state = _get_game_state()
	var coins: int = state.coins if state else 0
	if is_instance_valid(try_again_btn):
		if coins >= 10:
			try_again_btn.text = "RETRY (10 COINS) 🔄"
			try_again_btn.disabled = false
		else:
			try_again_btn.text = "NEED 10 COINS 🔒"
			try_again_btn.disabled = true
	if is_instance_valid(watch_ad_btn):
		watch_ad_btn.text = "WATCH AD (+10 🟡)"
		watch_ad_btn.visible = true

func _on_level_won() -> void:
	if not selected_glyph.is_empty():
		if is_instance_valid(victory_title):
			victory_title.text = "GLYPH %s CLEARED!" % selected_glyph
		if is_instance_valid(coins_reward):
			coins_reward.text = "Practice complete"
		if is_instance_valid(next_level_btn):
			next_level_btn.text = "REPLAY GLYPH"
		if is_instance_valid(victory_panel):
			victory_panel.visible = true
		return
	var state = _get_game_state()
	var used_ink: float = drawing_canvas.used_ink if is_instance_valid(drawing_canvas) else 350.0

	# Minimal draw line rating:
	# Ultra minimal line (used_ink <= 220.0 px) -> 3 Stars + 10 Coins
	# Medium line (used_ink <= 420.0 px)         -> 2 Stars + 5 Coins
	# Long line (used_ink > 420.0 px)            -> 1 Star  + 2 Coins
	var stars_earned := 1
	var coins_earned := 2

	var is_child_star: bool = state.is_child_mode() if (state and state.has_method("is_child_mode")) else false
	var star3_limit: float = 380.0 if is_child_star else 220.0
	var star2_limit: float = 600.0 if is_child_star else 420.0
	if used_ink <= star3_limit:
		stars_earned = 3
		coins_earned = 10
	elif used_ink <= star2_limit:
		stars_earned = 2
		coins_earned = 5
	else:
		stars_earned = 1
		coins_earned = 2

	if is_inside_tree():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_victory"):
			audio.play_victory()

	# Award progress and coins
	if state:
		state.coins += coins_earned
		state.total_stars += stars_earned
		state.games_played += 1
		state.daily_games_played += 1
		state.daily_stars_earned += stars_earned
		if state.game_mode != "daily":
			if current_level >= state.highest_level:
				state.highest_level = current_level + 1
		state.save_progress()

	# Show victory popup with star & coin animations
	if is_inside_tree() and get_tree():
		var serial := _load_serial
		var timer := get_tree().create_timer(0.4)
		timer.timeout.connect(func():
			if serial != _load_serial:
				return
			if is_instance_valid(victory_title):
				if state and state.game_mode == "daily":
					victory_title.text = "DAILY CHALLENGE WON!"
				else:
					victory_title.text = "LEVEL %d CLEARED!" % current_level
			_animate_victory_stars_and_coins(stars_earned, coins_earned)
		)
	else:
		if is_instance_valid(victory_title):
			if state and state.game_mode == "daily":
				victory_title.text = "DAILY CHALLENGE WON!"
			else:
				victory_title.text = "LEVEL %d CLEARED!" % current_level
		_animate_victory_stars_and_coins(stars_earned, coins_earned)

func _update_top_coin_hud(amount: int = -1) -> void:
	if is_instance_valid(top_coin_label):
		var val := amount
		if val < 0:
			var state = _get_game_state()
			val = state.coins if state else 0
		top_coin_label.text = str(val)

func _animate_victory_stars_and_coins(stars_earned: int, coins_earned: int) -> void:
	if not is_instance_valid(victory_panel):
		return

	var state = _get_game_state()
	var prev_bank_coins: int = maxi(0, (state.coins - coins_earned) if state else 0)
	_update_top_coin_hud(prev_bank_coins)

	# Disable Next Level button until coin animation reaches top HUD
	if is_instance_valid(next_level_btn):
		next_level_btn.disabled = true
		next_level_btn.modulate = Color(0.65, 0.65, 0.65, 0.7)

	# Setup panel appearance
	victory_panel.visible = true
	victory_panel.pivot_offset = victory_panel.size * 0.5
	victory_panel.scale = Vector2(0.65, 0.65)
	victory_panel.modulate.a = 0.0

	var panel_tween := create_tween()
	panel_tween.set_parallel(true)
	panel_tween.tween_property(victory_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(victory_panel, "modulate:a", 1.0, 0.25)

	# Setup initial star states
	var stars: Array[TextureRect] = [star1, star2, star3]
	for i in range(3):
		var s: TextureRect = stars[i]
		if is_instance_valid(s):
			s.pivot_offset = s.size * 0.5
			if i < stars_earned:
				s.scale = Vector2.ZERO
				s.modulate = Color.WHITE
			else:
				s.scale = Vector2.ONE
				s.modulate = Color(0.3, 0.3, 0.35, 0.4)

	# Initial coin reward label state
	if is_instance_valid(coins_reward):
		coins_reward.text = "+%d COINS" % coins_earned
		coins_reward.pivot_offset = coins_reward.size * 0.5
		coins_reward.scale = Vector2(0.8, 0.8)
		coins_reward.modulate.a = 0.0

	await panel_tween.finished

	# Animate stars popping in sequentially
	for i in range(stars_earned):
		var star_item: TextureRect = stars[i]
		if is_inside_tree():
			var sfx_audio = get_node_or_null("/root/AudioManager")
			if sfx_audio and sfx_audio.has_method("play_star"):
				sfx_audio.play_star(1.0 + i * 0.15)
		if is_instance_valid(star_item):
			var star_tween := create_tween()
			star_tween.tween_property(star_item, "scale", Vector2(1.35, 1.35), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			star_tween.tween_property(star_item, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			await star_tween.finished
		if is_inside_tree() and get_tree():
			await get_tree().create_timer(0.08).timeout

	# Reveal CoinsReward badge
	if is_instance_valid(coins_reward):
		var label_tween := create_tween()
		label_tween.set_parallel(true)
		label_tween.tween_property(coins_reward, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		label_tween.tween_property(coins_reward, "modulate:a", 1.0, 0.2)
		await label_tween.finished

	# ANIMATE FLYING COINS: From victory panel directly UP TO THE TOP COIN HUD!
	var num_flying_coins := mini(coins_earned, 8)
	if num_flying_coins < 3:
		num_flying_coins = 3

	var spawn_origin: Vector2 = coins_reward.global_position + coins_reward.size * 0.5 if is_instance_valid(coins_reward) else (victory_panel.global_position + victory_panel.size * 0.5)
	var target_pos: Vector2 = top_coin_pill.global_position + top_coin_pill.size * 0.5 if is_instance_valid(top_coin_pill) else Vector2(480.0, 65.0)

	var bank_current: int = prev_bank_coins
	var final_bank: int = state.coins if state else (prev_bank_coins + coins_earned)

	for c_idx in range(num_flying_coins):
		var coin_sprite := TextureRect.new()
		coin_sprite.texture = CoinTexture
		coin_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin_sprite.custom_minimum_size = Vector2(34, 34)
		coin_sprite.size = Vector2(34, 34)
		coin_sprite.pivot_offset = Vector2(17, 17)
		coin_sprite.position = spawn_origin - Vector2(17, 17)
		coin_sprite.scale = Vector2.ZERO
		coin_sprite.z_index = 650 # Over all dialogs
		add_child(coin_sprite)

		# Burst outwards first, then accelerate upwards to Top Coin HUD
		var burst_offset := Vector2(randf_range(-60, 60), randf_range(-40, 20))
		var ct := create_tween()
		ct.tween_property(coin_sprite, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ct.tween_property(coin_sprite, "position", spawn_origin + burst_offset, 0.1)
		ct.tween_property(coin_sprite, "position", target_pos - Vector2(17, 17), 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		ct.parallel().tween_property(coin_sprite, "rotation", randf_range(-3.14, 3.14), 0.38)
		ct.tween_property(coin_sprite, "scale", Vector2.ZERO, 0.08)
		ct.tween_callback(func():
			coin_sprite.queue_free()
			var step_bank: int = int(round(lerpf(float(prev_bank_coins), float(final_bank), float(c_idx + 1) / float(num_flying_coins))))
			_update_top_coin_hud(step_bank)
			if is_instance_valid(top_coin_pill):
				top_coin_pill.pivot_offset = top_coin_pill.size * 0.5
				var pop_pill := create_tween()
				pop_pill.tween_property(top_coin_pill, "scale", Vector2(1.18, 1.18), 0.06)
				pop_pill.tween_property(top_coin_pill, "scale", Vector2.ONE, 0.06)
			if is_inside_tree():
				var audio = get_node_or_null("/root/AudioManager")
				if audio and audio.has_method("play_coin"):
					audio.play_coin()
		)
		if is_inside_tree() and get_tree():
			await get_tree().create_timer(0.06).timeout

	if is_inside_tree() and get_tree():
		await get_tree().create_timer(0.4).timeout

	_update_top_coin_hud(final_bank)

	# Enable Next Level button ONLY after all coins have arrived at top HUD!
	if is_instance_valid(next_level_btn):
		next_level_btn.disabled = false
		var btn_tween := create_tween()
		btn_tween.set_parallel(true)
		btn_tween.tween_property(next_level_btn, "modulate", Color.WHITE, 0.2)
		btn_tween.tween_property(next_level_btn, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_BACK)
		btn_tween.chain().tween_property(next_level_btn, "scale", Vector2.ONE, 0.1)

	# Show interstitial ad every 3 levels after star/coin animations, unless ads removed
	var state_ad = _get_game_state()
	if current_level % 3 == 0 and (not state_ad or not state_ad.ads_removed):
		if is_inside_tree():
			var ad_mgr = get_node_or_null("/root/AdManager")
			if ad_mgr and ad_mgr.has_method("show_interstitial"):
				ad_mgr.show_interstitial()

func _on_restart_pressed() -> void:
	if is_instance_valid(fail_panel) and fail_panel.visible:
		_on_try_again_pressed()
	else:
		_reload_current_level()

func _on_try_again_pressed() -> void:
	if not selected_glyph.is_empty() or not _required_letter.is_empty():
		_reload_current_level()
		return
	var state = _get_game_state()
	if state:
		if state.coins >= 10:
			state.coins -= 10
			state.save_progress()
			if is_inside_tree():
				var audio = get_node_or_null("/root/AudioManager")
				if audio and audio.has_method("play_coin"):
					audio.play_coin()
			load_level(current_level)
		else:
			_update_fail_panel_buttons()
	else:
		load_level(current_level)

func _on_watch_ad_pressed() -> void:
	if not selected_glyph.is_empty():
		return
	if is_inside_tree():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_button"):
			audio.play_button()

	var ad_mgr = get_node_or_null("/root/AdManager")
	if not ad_mgr:
		_grant_watch_ad_reward()
		return

	var reward_cb := Callable(self, "_on_ad_reward_completed")
	var unavail_cb := Callable(self, "_on_ad_unavailable")

	if not ad_mgr.rewarded_video_completed.is_connected(reward_cb):
		ad_mgr.rewarded_video_completed.connect(reward_cb, CONNECT_ONE_SHOT)
	if not ad_mgr.rewarded_video_unavailable.is_connected(unavail_cb):
		ad_mgr.rewarded_video_unavailable.connect(unavail_cb, CONNECT_ONE_SHOT)

	var shown: bool = ad_mgr.show_rewarded_video()
	if not shown:
		var has_plugin: bool = bool(ad_mgr.get("_plugin_available"))
		if not has_plugin:
			_grant_watch_ad_reward()

func _on_ad_reward_completed() -> void:
	_grant_watch_ad_reward()

func _on_ad_unavailable(_msg: String) -> void:
	if not OS.has_feature("android"):
		_grant_watch_ad_reward()

func _grant_watch_ad_reward() -> void:
	if _ad_reward_target == "elastic_ink":
		_ad_reward_target = "coins"
		_grant_elastic_ink_refill()
		if is_inside_tree():
			var audio = get_node_or_null("/root/AudioManager")
			if audio and audio.has_method("play_coin"):
				audio.play_coin()
		return
	if _ad_reward_target == "manual_drop":
		_ad_reward_target = "coins"
		if is_instance_valid(_manual_drop_dialog):
			_manual_drop_dialog.visible = false
		_manual_drop_credits += MANUAL_DROP_PACK_SIZE
		_complete_manual_drop()
		if is_inside_tree():
			var audio = get_node_or_null("/root/AudioManager")
			if audio and audio.has_method("play_coin"):
				audio.play_coin()
		return
	var state = _get_game_state()
	if state:
		state.coins += 10
		state.save_progress()
		_update_top_coin_hud()
	if is_inside_tree():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_coin"):
			audio.play_coin()
	if is_instance_valid(fail_message) and state:
		fail_message.text = "Earned +10 Coins!\nCoins: %d 🟡" % state.coins
	_update_fail_panel_buttons()
	if is_instance_valid(_elastic_ink_dialog) and _elastic_ink_dialog.visible:
		_refresh_elastic_ink_store()
	if is_instance_valid(_manual_drop_dialog) and _manual_drop_dialog.visible:
		_refresh_manual_drop_store()

func _on_menu_pressed() -> void:
	if is_inside_tree():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_button"):
			audio.play_button()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_next_level_pressed() -> void:
	if not selected_glyph.is_empty():
		_reload_current_level()
		return
	var state = _get_game_state()
	if state and state.game_mode == "daily":
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return
	var diff_idx: int = int(state.difficulty_index) if state and "difficulty_index" in state else 0
	if _manual_difficulty_selection_enabled() and not LevelGen.has_level(current_level + 1, diff_idx):
		if is_instance_valid(next_level_btn):
			next_level_btn.text = "MODE COMPLETE"
			next_level_btn.disabled = true
		return

	# Every 3 levels (Level 3, 6, 9, 12...): ask user if they want to switch difficulty mode!
	if _manual_difficulty_selection_enabled() and current_level % 3 == 0 and is_instance_valid(mode_dialog):
		if is_instance_valid(victory_panel):
			victory_panel.visible = false
		if is_instance_valid(mode_dialog_title):
			mode_dialog_title.text = "LEVEL %d CLEARED! 🌟" % current_level
		_update_mode_ui()
		mode_dialog.visible = true
		return

	load_level(current_level + 1)

func _update_mode_ui() -> void:
	if is_instance_valid(mode_btn):
		mode_btn.visible = false
	if is_instance_valid(mode_dialog):
		mode_dialog.visible = false
	if is_instance_valid(adult_mode_btn):
		adult_mode_btn.visible = false
	if is_instance_valid(hard_mode_btn):
		hard_mode_btn.visible = false
	var state = _get_game_state()
	var diff_idx: int = int(state.difficulty_index) if (state and "difficulty_index" in state) else 0
	if is_instance_valid(mode_btn):
		match diff_idx:
			0: mode_btn.text = "👶 Easy"
			1: mode_btn.text = "⚡ Medium"
			2: mode_btn.text = "🔥 Hard"
			_: mode_btn.text = "👶 Easy"
	if is_instance_valid(child_mode_btn):
		child_mode_btn.text = "🟢 Easy Mode (Child • Extra Ink) %s" % ("✓ [ACTIVE]" if diff_idx == 0 else "")
	if is_instance_valid(adult_mode_btn):
		adult_mode_btn.text = "🔵 Medium Mode (Normal) %s" % ("✓ [ACTIVE]" if diff_idx == 1 else "")
	if is_instance_valid(hard_mode_btn):
		hard_mode_btn.text = "🔴 Hard Mode (Fast Bugs • Tight Ink) %s" % ("✓ [ACTIVE]" if diff_idx == 2 else "")

func _on_mode_toggle_pressed() -> void:
	var state = _get_game_state()
	if state and state.has_method("set_difficulty"):
		var next_diff: int = (int(state.difficulty_index) + 1) % 3
		state.set_difficulty(next_diff)
		current_level = _level_in_difficulty_range(int(state.requested_level), next_diff)
		load_level(current_level)

func _on_select_child_mode() -> void:
	var state = _get_game_state()
	if state and state.has_method("set_difficulty"):
		state.set_difficulty(0)
		current_level = _level_in_difficulty_range(int(state.requested_level), 0)
	_update_mode_ui()

func _on_select_adult_mode() -> void:
	var state = _get_game_state()
	if state and state.has_method("set_difficulty"):
		state.set_difficulty(1)
		current_level = _level_in_difficulty_range(int(state.requested_level), 1)
	_update_mode_ui()

func _on_select_hard_mode() -> void:
	var state = _get_game_state()
	if state and state.has_method("set_difficulty"):
		state.set_difficulty(2)
		current_level = _level_in_difficulty_range(int(state.requested_level), 2)
	_update_mode_ui()

func _level_in_difficulty_range(requested: int, difficulty: int) -> int:
	var first_level: int = int([1, 101, 201][clampi(difficulty, 0, 2)])
	return clampi(requested, first_level, first_level + maxi(LevelGen.count(difficulty), 1) - 1)

func _manual_difficulty_selection_enabled() -> bool:
	# Difficulty is assigned by the campaign order, not by a player setting.
	return false

func _campaign_difficulty_for_level(level: int) -> int:
	if _get_game_state() != null:
		if not _random_difficulties.has(level):
			_random_difficulties[level] = randi_range(0, 2)
		return int(_random_difficulties[level])
	if level <= LEVELS_PER_DIFFICULTY:
		return 0
	if level <= LEVELS_PER_DIFFICULTY * 2:
		return 1
	if level <= CAMPAIGN_LEVEL_COUNT:
		return 2
	if not _random_difficulties.has(level):
		_random_difficulties[level] = randi_range(0, 2)
	return int(_random_difficulties[level])

func _catalog_level_for_campaign(campaign_level: int, difficulty: int) -> int:
	if _get_game_state() == null and campaign_level <= CAMPAIGN_LEVEL_COUNT:
		return campaign_level
	if _random_catalog_levels.has(campaign_level):
		return int(_random_catalog_levels[campaign_level])
	var first_level := difficulty * LEVELS_PER_DIFFICULTY + 1
	var selected := randi_range(first_level, first_level + LEVELS_PER_DIFFICULTY - 1)
	_random_catalog_levels[campaign_level] = selected
	return selected

func _on_mode_continue_pressed() -> void:
	if is_instance_valid(mode_dialog):
		mode_dialog.visible = false
	if not selected_glyph.is_empty():
		_reload_current_level()
	else:
		var state = _get_game_state()
		var diff_idx: int = int(state.difficulty_index) if state and "difficulty_index" in state else 0
		if LevelGen.has_level(current_level + 1, diff_idx):
			load_level(current_level + 1)
