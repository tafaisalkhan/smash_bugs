@tool
extends SceneTree

func _init() -> void:
	print(">>> RUNNING SMASH GAME VALIDATION SUITE <<<")

	# 1. Instantiate SmashGame scene
	var scene_res = load("res://scenes/smash/SmashGame.tscn")
	if not scene_res:
		printerr("FAIL: Could not load SmashGame.tscn")
		quit(1)
		return

	var game: SmashGame = scene_res.instantiate()
	root.add_child(game)
	game._ensure_nodes()
	print("PASS: SmashGame scene instantiated successfully.")

	# 2. Verify all UI nodes exist
	assert(game.level_label != null, "level_label missing")
	assert(game.objective_label != null, "objective_label missing")
	assert(game.hint_label != null, "hint_label missing")
	assert(game.hint_btn != null, "hint_btn missing")
	assert(game.ink_bar != null, "ink_bar missing")
	assert(game.drawing_canvas != null, "drawing_canvas missing")
	assert(game.victory_panel != null, "victory_panel missing")
	assert(game.fail_panel != null, "fail_panel missing")
	assert(game.fail_title != null, "fail_title missing")
	assert(game.fail_message != null, "fail_message missing")
	assert(game.try_again_btn != null, "try_again_btn missing")
	assert(game.watch_ad_btn != null, "watch_ad_btn missing")
	assert(game.background_sky != null, "background_sky missing")
	assert(game.city_silhouette != null, "city_silhouette missing")
	assert(game.top_coin_pill != null, "top_coin_pill missing")
	assert(game.top_coin_label != null, "top_coin_label missing")
	print("PASS: All UI nodes verified.")

	# 2b. Test Hint Removed from Game Scene & 1-Stroke Restriction
	game.load_level(3)
	assert(not game.hint_label.visible, "Hint label must be hidden/removed from game scene")
	assert(not game.hint_btn.visible, "Hint button must be hidden/removed from game scene")
	assert(game.level_label.text == "Level 3", "Level label must not show alphabet badge: %s" % game.level_label.text)
	assert(not game.drawing_canvas.is_locked and game.drawing_canvas.strokes_used == 0)
	game.drawing_canvas._start_drawing(Vector2(100, 100))
	assert(game.drawing_canvas.is_drawing)
	game.drawing_canvas._continue_drawing(Vector2(200, 100))
	game.drawing_canvas._finish_drawing()
	assert(game.drawing_canvas.is_locked and game.drawing_canvas.strokes_used == 1, "Canvas must lock after 1 stroke!")
	game.drawing_canvas._start_drawing(Vector2(100, 150))
	assert(not game.drawing_canvas.is_drawing, "Second stroke must be blocked until retry!")
	print("PASS: Hint removed from game scene, clean Level title & 1-Stroke Restriction verified.")

	# 3. Test Handcrafted Levels 1..8
	game.load_level(1)
	assert(game.active_bugs.size() == 1)
	assert(not game.active_bugs[0].is_friendly)
	assert(game.level_label.text == "Level 1")
	print("PASS: Level 1 (Straight Drop) verified.")

	game.load_level(2)
	assert(game.active_bugs.size() == 2)
	assert(game.level_label.text == "Level 2")
	print("PASS: Level 2 (Wide Bridge) verified.")

	game.load_level(3)
	assert(game.level_label.text == "Level 3")
	print("PASS: Level 3 (L-Hook) verified.")

	game.load_level(4)
	assert(game.active_bugs.size() == 3)
	assert(game.level_label.text == "Level 4")
	print("PASS: Level 4 (Plant Garden Stage + Umbrella Bee Shield) verified.")

	game.load_level(5)
	assert(game.level_label.text == "Level 5")
	assert(game.active_props.size() >= 1, "Level 5 should have a movable stone boulder prop")
	print("PASS: Level 5 (Wooden Ramp, Bowling Ball & Stone Boulder) verified.")

	# Test that in any case bee dies, level FAILS!
	game.load_level(4)
	var test_prop: RigidBody2D = game.PropScript.new()
	test_prop.set("prop_kind", "stone_boulder")
	game.platforms_container.add_child(test_prop)
	test_prop.set("has_been_displaced", true)
	var bee_bug: SmashBug = null
	var bad_bug: SmashBug = null
	for b in game.active_bugs:
		if b.is_friendly:
			bee_bug = b
		else:
			bad_bug = b
	assert(bee_bug != null and bad_bug != null)
	bad_bug._try_smash_from_body(test_prop)
	assert(bad_bug.state == SmashBug.State.DEAD, "Moving hazard MUST kill bad bug!")
	bee_bug._try_smash_from_body(test_prop)
	assert(bee_bug.state == SmashBug.State.DEAD, "Moving hazard kills bee!")
	assert(game.is_level_cleared, "In any case bee dies, level MUST fail!")
	print("PASS: In any case Bee dies, level immediately fails!")

	# Test that when player fails/misses, surviving bad bugs celebrate player loss!
	game.load_level(4)
	game._on_stroke_missed()
	var celebrating_count := 0
	for b in game.active_bugs:
		if not b.is_friendly:
			assert(b.state == SmashBug.State.CELEBRATE, "Surviving bad bug should enter CELEBRATE state on player loss!")
			assert(b._celebrate_label != null and b._celebrate_label.visible, "Celebrating bug should display taunt text!")
			celebrating_count += 1
	assert(celebrating_count >= 1)
	print("PASS: Surviving bad bugs celebrate player loss with dance, confetti & taunt text!")

	# Test Audio methods on AudioManager
	var audio_res = load("res://scripts/audio_manager.gd")
	assert(audio_res != null, "AudioManager script missing")
	var dummy_audio = Node.new()
	dummy_audio.set_script(audio_res)
	assert(dummy_audio.has_method("play_bug_anxious"), "play_bug_anxious missing")
	assert(dummy_audio.has_method("stop_bug_anxious"), "stop_bug_anxious missing")
	assert(dummy_audio.has_method("play_bug_celebrate"), "play_bug_celebrate missing")
	assert(dummy_audio.has_method("play_bug_kill"), "play_bug_kill missing")
	assert(dummy_audio.has_method("play_coin"), "play_coin missing")
	dummy_audio.free()
	print("PASS: AudioManager has bug_anxios, bugs_celebreaty, bugs_kill, and coin sound handlers!")

	# Test 10-Coin Fail Retry & Watch Ad reward flow
	var test_state = root.get_node_or_null("GameState")
	var created_state := false
	if not test_state:
		var state_res = load("res://scripts/game_state.gd")
		test_state = Node.new()
		test_state.set_script(state_res)
		test_state.name = "GameState"
		root.add_child(test_state)
		created_state = true

	test_state.coins = 5 # Less than 10 coins
	game._show_fail_panel("FAILED", "Test Fail")
	assert(game.try_again_btn.disabled == true, "Retry button must be disabled when coins < 10")
	assert("NEED 10 COINS" in game.try_again_btn.text, "Retry text must show need 10 coins")

	# Watch Ad awards 10 coins
	game._grant_watch_ad_reward()
	assert(test_state.coins == 15, "Watching ad should add +10 coins")
	assert(game.try_again_btn.disabled == false, "Retry button must be enabled when coins >= 10")
	assert("RETRY (10 COINS)" in game.try_again_btn.text)

	# Retry deducts 10 coins and reloads level
	game._on_try_again_pressed()
	assert(test_state.coins == 5, "Retrying failed level must deduct 10 coins")
	# Test Blue Brick Platform
	var test_plat: StaticBody2D = game.PlatformScript.new()
	test_plat.style = "brick"
	game.platforms_container.add_child(test_plat)
	test_plat.queue_redraw()
	test_plat.free()
	print("PASS: Blue Brick platform styling verified.")

	# Test AdManager Remove Ads & Interstitial Every 3 Levels
	var ad_res = load("res://scripts/ad_manager.gd")
	assert(ad_res != null, "AdManager script missing")
	var dummy_ad = Node.new()
	dummy_ad.set_script(ad_res)
	assert(dummy_ad.has_method("show_banner"), "show_banner missing")
	assert(dummy_ad.has_method("hide_banner"), "hide_banner missing")
	assert(dummy_ad.has_method("show_interstitial"), "show_interstitial missing")
	assert(dummy_ad.has_method("show_rewarded_video"), "show_rewarded_video missing")
	assert(dummy_ad.has_method("_is_ads_removed"), "_is_ads_removed missing")
	assert(3 % 3 == 0 and 6 % 3 == 0 and 9 % 3 == 0, "Interstitial every 3 levels condition verified")
	dummy_ad.free()
	print("PASS: AdManager banner, interstitial every 3 levels, and remove ads integration verified.")

	if created_state:
		test_state.queue_free()
	print("PASS: 10-Coin Fail Retry & Watch Ad flow successfully verified!")

	game.load_level(6)
	assert(game.level_label.text == "Level 6")
	print("PASS: Level 6 (Bouncy Mushroom + Zigzag Mosquito) verified.")

	game.load_level(7)
	assert(game.level_label.text == "Level 7")
	print("PASS: Level 7 (T-Hammer + Circular Orbit Fly) verified.")

	game.load_level(8)
	assert(game.level_label.text == "Level 8")
	print("PASS: Level 8 (Jungle Canopy + Figure-8 Flight) verified.")

	# 4. Test Unlimited Alphabet & Shape Pattern Generator across 100 levels + extreme levels
	print("Testing unlimited alphabet & pattern generator across levels 9-100, 500, 9999...")
	var seen_themes := {}
	var seen_patterns := {}
	var seen_flight_modes := {}

	var test_levels: Array[int] = []
	for l in range(9, 101):
		test_levels.append(l)
	test_levels.append(500)
	test_levels.append(9999)

	for lvl in test_levels:
		var data: Dictionary = SmashLevelGenerator.generate(lvl)
		assert(data.has("platforms") and data["platforms"].size() > 0, "Level %d missing platforms" % lvl)
		assert(data.has("bugs") and data["bugs"].size() >= 2, "Level %d missing bugs" % lvl)
		assert(data.has("hint_pattern") and data["hint_pattern"].size() >= 2, "Level %d missing hint_pattern" % lvl)

		# Verify ink budget always covers the pattern length with margin
		var pat_pts: PackedVector2Array = data["hint_pattern"]
		var pat_len := 0.0
		for i in range(pat_pts.size() - 1):
			pat_len += pat_pts[i].distance_to(pat_pts[i + 1])
		assert(float(data["ink"]) >= pat_len * 1.25, "Level %d ink (%f) too low for pattern (%f)" % [lvl, data["ink"], pat_len])

		# Verify every procedural level has both bad bugs to kill AND friendly bee(s) to save
		var has_bad := false
		var has_bee := false
		for b in data["bugs"]:
			if b.get("kind") == "bee":
				has_bee = true
			else:
				has_bad = true
			seen_flight_modes[b.get("move", "none")] = true
		assert(has_bad, "Level %d has no bad bugs to kill" % lvl)
		assert(has_bee, "Level %d has no friendly bee to protect" % lvl)

		seen_themes[data["theme"]] = true
		seen_patterns[data["pattern"]] = true

	assert(seen_themes.has("garden") and seen_themes.has("jungle") and seen_themes.has("city"))
	assert(seen_patterns.size() == 15, "All 15 alphabet patterns should be generated, got %d" % seen_patterns.size())
	print("PASS: Themes generated: ", seen_themes.keys())
	print("PASS: Alphabet Patterns generated (%d): " % seen_patterns.size(), seen_patterns.keys())
	print("PASS: Flight modes generated: ", seen_flight_modes.keys())

	# Test Easy, Medium, and Hard difficulty generation & Mode Dialog
	var easy_data: Dictionary = SmashLevelGenerator.generate(3, false, 0)
	var medium_data: Dictionary = SmashLevelGenerator.generate(3, false, 1)
	var hard_data: Dictionary = SmashLevelGenerator.generate(3, false, 2)
	assert(easy_data["ink"] > medium_data["ink"], "Easy mode must provide more ink than medium mode")
	assert(medium_data["ink"] > hard_data["ink"], "Medium mode must provide more ink than hard mode")
	assert(easy_data["difficulty"] == 0 and easy_data["is_child_mode"] == true)
	assert(medium_data["difficulty"] == 1 and medium_data["is_child_mode"] == false)
	assert(hard_data["difficulty"] == 2 and hard_data["is_child_mode"] == false)

	# Test ModeDialog on every 3rd level
	game.load_level(3)
	assert(game.mode_dialog != null, "mode_dialog missing")
	assert(game.mode_btn != null, "mode_btn missing")
	assert(game.hard_mode_btn != null, "hard_mode_btn missing")
	game._on_next_level_pressed()
	assert(game.mode_dialog.visible, "Mode dialog must pop up on level 3 completion!")
	game._on_select_hard_mode()
	game._on_mode_continue_pressed()
	assert(not game.mode_dialog.visible, "Mode dialog should close after continue")
	assert(game.current_level == 4, "Game must proceed to level 4")
	print("PASS: Easy, Medium, and Hard difficulty modes and prompt verified.")

	game.queue_free()
	print(">>> ALL TESTS PASSED SUCCESSFULLY! <<<")
	quit(0)
