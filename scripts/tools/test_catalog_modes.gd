extends SceneTree

const LevelGen = preload("res://scripts/smash/level_generator.gd")
const LevelCatalog = preload("res://scripts/smash/level_catalog.gd")

var game: SmashGame
var state: Node
var cases: Array[Dictionary] = []
var index := 0
var frames := 0
var failures: Array[String] = []
var begin_pending := true

func _initialize() -> void:
	Engine.time_scale = 4.0
	for level in range(1, 101):
		cases.append({"difficulty": 0, "level": level, "name": "easy_%03d" % level})
	for level in range(101, 201):
		cases.append({"difficulty": 1, "level": level, "name": "medium_%d" % level})
	for level in range(201, 301):
		cases.append({"difficulty": 2, "level": level, "name": "hard_%d" % level})
	state = root.get_node("GameState")
	game = load("res://scenes/smash/SmashGame.tscn").instantiate()
	game.verify_generated_levels = false
	root.add_child(game)

func _begin() -> void:
	assert(cases.size() == 300)
	assert(LevelCatalog.count(0) >= 100 and LevelCatalog.count(1) >= 100 and LevelCatalog.count(2) >= 100)
	_start_case()

func _start_case() -> void:
	if index >= cases.size():
		print("Handcrafted JSON levels checked: ", cases.size())
		print("Handcrafted JSON level failures: ", failures)
		quit(0 if failures.is_empty() else 1)
		return
	var case: Dictionary = cases[index]
	state.difficulty_index = int(case["difficulty"])
	var data := LevelGen.generate(int(case["level"]), int(case["difficulty"]) == 0, int(case["difficulty"]))
	if data.is_empty() or not str(data.get("template", "")).begins_with(str(case["name"])):
		failures.append("%s did not load from JSON" % case["name"])
		index += 1
		_start_case()
		return
	for bug in data.get("bugs", []):
		for prop in data.get("props", []):
			var clearance_x: float = float(prop["size"].x) * 0.5 + 28.0
			var clearance_y: float = float(prop["size"].y) * 0.5 + 28.0
			var offset: Vector2 = bug["pos"] - prop["pos"]
			if absf(offset.x) < clearance_x and absf(offset.y) < clearance_y:
				failures.append("%s places %s inside %s" % [case["name"], bug.get("kind", "bug"), prop.get("name", "prop")])
	game.load_level(int(case["level"]), data)
	frames = 0

func _physics_process(_delta: float) -> bool:
	if begin_pending:
		begin_pending = false
		_begin()
	if index >= cases.size():
		return true
	frames += 1
	if frames == 80:
		for bug in game.active_bugs:
			if is_instance_valid(bug) and not bug.is_friendly and bug.state == SmashBug.State.DEAD:
				failures.append("%s killed a bug before player input" % cases[index]["name"])
	if frames == 90:
		var points := PackedVector2Array()
		for point in game.drawing_canvas.hint_points:
			points.append(game.drawing_canvas.global_position + point)
		game._on_stroke_completed(points)
	if frames > 3:
		var bad_alive := 0
		var bee_dead := 0
		for bug in game.active_bugs:
			if not is_instance_valid(bug):
				continue
			if bug.is_friendly and bug.state == SmashBug.State.DEAD:
				bee_dead += 1
			elif not bug.is_friendly and bug.state != SmashBug.State.DEAD:
				bad_alive += 1
		if game.is_level_cleared or bee_dead > 0 or frames >= 700:
			if bad_alive > 0 or bee_dead > 0 or not game.is_level_cleared:
				var details := []
				for bug in game.active_bugs:
					if is_instance_valid(bug) and not bug.is_friendly and bug.state != SmashBug.State.DEAD:
						details.append("%s@%s" % [bug.kind, str(bug.global_position)])
				for prop in game.active_props:
					if is_instance_valid(prop):
						details.append("%s@%s frozen=%s moving=%s" % [prop.name, str(prop.global_position), str(prop.starts_frozen), str(prop.is_moving_hazard())])
				if is_instance_valid(game.active_drawn_body):
					details.append("drawn@%s" % str(game.active_drawn_body.global_position))
				failures.append("%s bad=%d bee=%d frames=%d %s" % [cases[index]["name"], bad_alive, bee_dead, frames, str(details)])
			index += 1
			_start_case()
	return false
