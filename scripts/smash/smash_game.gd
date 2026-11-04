class_name SmashGame
extends Control

const LevelGen = preload("res://scripts/smash/level_generator.gd")
const BugScene = preload("res://scenes/smash/Bug.tscn")
const PlatformScript = preload("res://scripts/smash/platform.gd")
const PropScript = preload("res://scripts/smash/prop.gd")
const DrawnBodyScript = preload("res://scripts/smash/drawn_body.gd")
const CoinTexture = preload("res://assets/generated/reward-coin.png")

@export var start_level: int = 1

var current_level: int = 1
var active_bugs: Array[SmashBug] = []
var active_props: Array[RigidBody2D] = []
var active_drawn_body: SmashDrawnBody = null
var is_level_cleared: bool = false
var _stroke_elapsed: float = 0.0
var _settle_timer: float = 0.0
var _has_triggered_miss: bool = false

# UI Nodes
@onready var background_sky: ColorRect = %BackgroundSky
@onready var city_silhouette: ColorRect = %CitySilhouette
@onready var level_label: Label = %LevelLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var hint_label: Label = %HintLabel
@onready var ink_bar: ProgressBar = %InkBar
@onready var drawing_canvas: SmashDrawingCanvas = %DrawingCanvas
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
@onready var mode_dialog: PanelContainer = %ModeDialog
@onready var mode_dialog_title: Label = %ModeDialogTitle
@onready var mode_dialog_subtitle: Label = %ModeDialogSubtitle
@onready var child_mode_btn: Button = %ChildModeBtn
@onready var adult_mode_btn: Button = %AdultModeBtn
@onready var hard_mode_btn: Button = %HardModeBtn
@onready var mode_continue_btn: Button = %ModeContinueBtn

func _ready() -> void:
	_ensure_nodes()
	_update_top_coin_hud()
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
	if drawing_canvas and not drawing_canvas.stroke_completed.is_connected(_on_stroke_completed):
		drawing_canvas.stroke_completed.connect(_on_stroke_completed)
	if restart_btn and not restart_btn.pressed.is_connected(_on_restart_pressed):
		restart_btn.pressed.connect(_on_restart_pressed)
	if menu_btn and not menu_btn.pressed.is_connected(_on_menu_pressed):
		menu_btn.pressed.connect(_on_menu_pressed)
	if hint_btn:
		hint_btn.visible = false
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

func load_level(lvl: int) -> void:
	_update_top_coin_hud()
	_ensure_nodes()
	if is_inside_tree():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("stop_bug_anxious"):
			audio.stop_bug_anxious()
	current_level = lvl
	is_level_cleared = false
	_stroke_elapsed = 0.0
	_settle_timer = 0.0
	_has_triggered_miss = false
	active_bugs.clear()
	active_props.clear()

	if is_instance_valid(victory_panel):
		victory_panel.visible = false
	if is_instance_valid(fail_panel):
		fail_panel.visible = false

	if is_instance_valid(active_drawn_body):
		active_drawn_body.queue_free()
		active_drawn_body = null

	# Clear previous level objects
	if is_instance_valid(platforms_container):
		for child in platforms_container.get_children():
			child.queue_free()

	if is_instance_valid(bugs_container):
		for child in bugs_container.get_children():
			child.queue_free()

	if is_instance_valid(mode_dialog):
		mode_dialog.visible = false
	_update_mode_ui()
	# 1. Generate level layout using unlimited generator (adapts for Child vs Adult mode)
	var state = _get_game_state()
	var diff_idx: int = int(state.difficulty_index) if (state and "difficulty_index" in state) else 0
	var is_child: bool = (diff_idx == 0) or (state.is_child_mode() if (state and state.has_method("is_child_mode")) else false)
	var level_data: Dictionary = LevelGen.generate(lvl, is_child, diff_idx)
	var is_daily: bool = (state != null and state.game_mode == "daily")

	if is_instance_valid(level_label):
		if is_daily:
			level_label.text = "Daily Challenge"
		else:
			level_label.text = "Level %d" % lvl

	# Apply Stage Environment Theming (Plant Garden, Jungle Canopy, City)
	var stage_theme: String = level_data.get("theme", "city")
	_apply_stage_theme(stage_theme)

	var has_bee: bool = false
	for b in level_data.get("bugs", []):
		if b.get("kind", "") == "bee":
			has_bee = true
			break

	if is_instance_valid(objective_label):
		if has_bee:
			objective_label.text = "🎯 1 Draw Only: Smash Flies | 🐝 Save Bee!"
		else:
			objective_label.text = "🎯 1 Draw Only: Smash All Bad Flies!"

	if is_instance_valid(hint_label):
		hint_label.text = ""
		hint_label.visible = false
	if is_instance_valid(hint_btn):
		hint_btn.visible = false

	if is_instance_valid(drawing_canvas):
		drawing_canvas.reset_canvas()
		drawing_canvas.max_ink = level_data.get("ink", 1000.0)
		drawing_canvas.set_hint_pattern(PackedVector2Array())

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
	for prop_data in level_data.get("props", []):
		var prop := RigidBody2D.new()
		prop.set_script(PropScript)
		prop.position = prop_data.get("pos", Vector2.ZERO)
		prop.prop_kind = prop_data.get("kind", "stone_boulder")
		prop.prop_size = prop_data.get("size", Vector2(52.0, 52.0))
		prop.rotation_degrees = prop_data.get("rot", 0.0)
		platforms_container.add_child(prop)
		active_props.append(prop)

	# 3. Spawn Bugs
	for b_data in level_data.get("bugs", []):
		var bug: SmashBug = BugScene.instantiate()
		bug.position = b_data.get("pos", Vector2.ZERO)
		bug.kind = b_data.get("kind", "beetle")
		bug.is_friendly = (bug.kind == "bee")
		bug.move_mode = b_data.get("move", "none")
		bug.move_range = b_data.get("range", 0.0)
		bug.move_speed = b_data.get("speed", 1.0)
		bug.bug_smashed.connect(_on_bug_smashed)
		bug.friendly_smashed.connect(_on_friendly_smashed)

		bugs_container.add_child(bug)
		active_bugs.append(bug)

func _apply_stage_theme(theme_name: String) -> void:
	if not is_instance_valid(background_sky) or not is_instance_valid(city_silhouette):
		return

	match theme_name:
		"garden":
			# Soft botanical morning sky with fresh garden foliage silhouette
			background_sky.color = Color(0.91, 0.96, 0.91, 1.0)
			city_silhouette.color = Color(0.70, 0.85, 0.74, 0.45)
		"jungle":
			# Tropical mist sky with lush canopy silhouette
			background_sky.color = Color(0.88, 0.94, 0.93, 1.0)
			city_silhouette.color = Color(0.60, 0.78, 0.70, 0.50)
		_:
			# Urban city rooftop
			background_sky.color = Color(0.89, 0.92, 0.96, 1.0)
			city_silhouette.color = Color(0.84, 0.87, 0.92, 0.45)

func _process(delta: float) -> void:
	# Update ink meter (stays depleted after drawing your 1 stroke until retry/next level)
	if is_instance_valid(drawing_canvas) and is_instance_valid(ink_bar):
		var pct: float = (1.0 - (drawing_canvas.used_ink / maxf(drawing_canvas.max_ink, 1.0))) * 100.0
		ink_bar.value = clampf(pct, 0.0, 100.0)

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
		# Detect when a dropped stroke & props have settled without killing all bad bugs -> Bugs Celebrate!
		if is_instance_valid(active_drawn_body) and not _has_triggered_miss:
			_stroke_elapsed += delta
			var body_still: bool = active_drawn_body.global_position.y > 980.0 or (
				active_drawn_body.linear_velocity.length() < 12.0 and absf(active_drawn_body.angular_velocity) < 0.35
			)
			var props_still: bool = true
			for prop in active_props:
				if is_instance_valid(prop) and prop.global_position.y <= 980.0:
					if prop.linear_velocity.length() >= 12.0 or absf(prop.angular_velocity) >= 0.35:
						props_still = false
						break
			if _stroke_elapsed >= 1.4 and body_still and props_still:
				_settle_timer += delta
				if _settle_timer >= 0.75:
					_has_triggered_miss = true
					_on_stroke_missed()
			else:
				_settle_timer = 0.0

func _on_stroke_completed(global_pts: PackedVector2Array) -> void:
	if is_instance_valid(active_drawn_body):
		active_drawn_body.queue_free()

	_stroke_elapsed = 0.0
	_settle_timer = 0.0
	_has_triggered_miss = false
	if is_instance_valid(fail_panel) and not is_level_cleared:
		fail_panel.visible = false
	for b in active_bugs:
		if is_instance_valid(b):
			b.reset_celebration()

	# Spawn falling physics body from drawn points!
	var body := RigidBody2D.new()
	body.set_script(DrawnBodyScript)
	world_container.add_child(body)
	body.build_from_points(global_pts)

	active_drawn_body = body

	# Play drop sound
	if is_inside_tree():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_undo"):
			audio.play_undo()

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
		is_level_cleared = true
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
		var timer := get_tree().create_timer(0.95)
		timer.timeout.connect(func():
			if not is_level_cleared and _has_triggered_miss:
				_show_fail_panel("BUGS CELEBRATE! 😂", "Surviving bugs are laughing at your miss!\nTry Again!")
		)
	else:
		_show_fail_panel("BUGS CELEBRATE! 😂", "Surviving bugs are laughing at your miss!\nTry Again!")

func _on_friendly_smashed(_bug: SmashBug) -> void:
	if is_level_cleared:
		return
	is_level_cleared = true
	_trigger_bugs_celebrate()

	if is_inside_tree():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_error"):
			audio.play_error()

	if is_inside_tree() and get_tree():
		var timer := get_tree().create_timer(0.85)
		timer.timeout.connect(func():
			_show_fail_panel("LEVEL FAILED! 💔", "Friendly Bee was harmed!\nIn any case Bee dies, Level Fails!")
		)
	else:
		_show_fail_panel("LEVEL FAILED! 💔", "Friendly Bee was harmed!\nIn any case Bee dies, Level Fails!")

func _show_fail_panel(title: String, msg: String) -> void:
	if not is_instance_valid(fail_panel):
		return
	if is_instance_valid(fail_title):
		fail_title.text = title
	if is_instance_valid(fail_message):
		var state = _get_game_state()
		var coins: int = state.coins if state else 0
		fail_message.text = "%s\nCoins: %d 🟡" % [msg, coins]
	_update_fail_panel_buttons()
	fail_panel.visible = true

func _update_fail_panel_buttons() -> void:
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

	# Show interstitial ad every 3 levels completed, unless ads removed
	if current_level % 3 == 0:
		var state_ad = _get_game_state()
		if not state_ad or not state_ad.ads_removed:
			if is_inside_tree():
				var ad_mgr = get_node_or_null("/root/AdManager")
				if ad_mgr and ad_mgr.has_method("show_interstitial"):
					ad_mgr.show_interstitial()

	# Show victory popup with star & coin animations
	if is_inside_tree() and get_tree():
		var timer := get_tree().create_timer(0.4)
		timer.timeout.connect(func():
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
	var target_pos: Vector2 = top_coin_pill.global_position + Vector2(24.0, top_coin_pill.size.y * 0.5) if is_instance_valid(top_coin_pill) else Vector2(480.0, 65.0)

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

func _on_restart_pressed() -> void:
	if is_instance_valid(fail_panel) and fail_panel.visible:
		_on_try_again_pressed()
	else:
		load_level(current_level)

func _on_try_again_pressed() -> void:
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

func _on_menu_pressed() -> void:
	if is_inside_tree():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_button"):
			audio.play_button()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_hint_pressed() -> void:
	if is_inside_tree():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_button"):
			audio.play_button()

	if is_instance_valid(drawing_canvas):
		var is_shown: bool = drawing_canvas.toggle_hint()
		if is_instance_valid(hint_label):
			hint_label.visible = is_shown or (hint_label.text != "")

func _on_next_level_pressed() -> void:
	var state = _get_game_state()
	if state and state.game_mode == "daily":
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return

	# Every 3 levels (Level 3, 6, 9, 12...): ask user if they want to switch difficulty mode!
	if current_level % 3 == 0 and is_instance_valid(mode_dialog):
		if is_instance_valid(victory_panel):
			victory_panel.visible = false
		if is_instance_valid(mode_dialog_title):
			mode_dialog_title.text = "LEVEL %d CLEARED! 🌟" % current_level
		_update_mode_ui()
		mode_dialog.visible = true
		return

	load_level(current_level + 1)

func _update_mode_ui() -> void:
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
	load_level(current_level)

func _on_select_child_mode() -> void:
	var state = _get_game_state()
	if state and state.has_method("set_difficulty"):
		state.set_difficulty(0)
	_update_mode_ui()

func _on_select_adult_mode() -> void:
	var state = _get_game_state()
	if state and state.has_method("set_difficulty"):
		state.set_difficulty(1)
	_update_mode_ui()

func _on_select_hard_mode() -> void:
	var state = _get_game_state()
	if state and state.has_method("set_difficulty"):
		state.set_difficulty(2)
	_update_mode_ui()

func _on_mode_continue_pressed() -> void:
	if is_instance_valid(mode_dialog):
		mode_dialog.visible = false
	load_level(current_level + 1)
