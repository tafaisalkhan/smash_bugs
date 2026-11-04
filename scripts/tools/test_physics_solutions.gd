extends SceneTree

var game: SmashGame
var test_levels := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23]
var idx := 0
var frames_waited := 0
var failures := 0

func _initialize() -> void:
	Engine.time_scale = 4.0
	var scene_res = load("res://scenes/smash/SmashGame.tscn")
	game = scene_res.instantiate()
	root.add_child(game)
	_start_next_level()

func _start_next_level() -> void:
	if idx >= test_levels.size():
		print("\n=== PHYSICS SIMULATION SUMMARY: %d failures out of %d levels ===" % [failures, test_levels.size()])
		quit(1 if failures > 0 else 0)
		return

	var lvl: int = test_levels[idx]
	game.load_level(lvl)
	frames_waited = 0

func _physics_process(_delta: float) -> bool:
	if idx >= test_levels.size():
		return true

	frames_waited += 1

	# Wait 3 physics frames after loading level so old nodes queue_free and new shapes register
	if frames_waited == 3:
		var canvas_origin := Vector2(20.0, 171.0)
		var global_pts := PackedVector2Array()
		for pt in game.drawing_canvas.hint_points:
			global_pts.append(canvas_origin + pt)
		game._on_stroke_completed(global_pts)

	# Check if won or failed or timed out (220 physics frames = ~3.6 seconds of physics)
	if frames_waited > 3:
		var bad_alive := 0
		var bee_dead := 0
		for b in game.active_bugs:
			if is_instance_valid(b):
				if b.is_friendly and b.state == SmashBug.State.DEAD:
					bee_dead += 1
				elif not b.is_friendly and b.state != SmashBug.State.DEAD:
					bad_alive += 1

		if bad_alive == 0 and bee_dead == 0:
			var lvl: int = test_levels[idx]
			var pat: String = game.level_label.text
			print("PASS [Physics Solved]: %s in %d frames" % [pat, frames_waited])
			idx += 1
			_start_next_level()
		elif bee_dead > 0 or frames_waited >= 220:
			var lvl: int = test_levels[idx]
			var pat: String = game.level_label.text
			print("FAIL [Physics]: %s -> bad_alive=%d, bee_dead=%d" % [pat, bad_alive, bee_dead])
			for b in game.active_bugs:
				if is_instance_valid(b):
					print("   Bug kind=%s friendly=%s state=%d pos=%s" % [b.kind, b.is_friendly, b.state, b.global_position])
			if is_instance_valid(game.active_drawn_body):
				print("   DrawnBody pos=%s vel=%s" % [game.active_drawn_body.global_position, game.active_drawn_body.linear_velocity])
			failures += 1
			idx += 1
			_start_next_level()

	return false
