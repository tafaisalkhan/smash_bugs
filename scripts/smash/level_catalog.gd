class_name SmashLevelCatalog
extends RefCounted

const DATA_PATH := "res://assets/data/smash_level_types.json"
const DIFFICULTIES := ["easy", "medium", "hard"]
static var _levels: Dictionary = {}

static func count(difficulty: int = -1) -> int:
	_ensure_loaded()
	if difficulty < 0:
		return _levels.size()
	var prefix := "%s:" % _difficulty_name(difficulty)
	var result := 0
	for key in _levels:
		if str(key).begins_with(prefix):
			result += 1
	return result

static func has_level(level: int, difficulty: int = 0) -> bool:
	_ensure_loaded()
	return _levels.has(_key(difficulty, level))

static func get_level(level: int, difficulty: int) -> Dictionary:
	_ensure_loaded()
	var key := _key(difficulty, level)
	if not _levels.has(key):
		return {}
	return _decode_level(_levels[key], difficulty)

static func _difficulty_name(difficulty: int) -> String:
	return DIFFICULTIES[clampi(difficulty, 0, DIFFICULTIES.size() - 1)]

static func _key(difficulty: int, level: int) -> String:
	return "%s:%d" % [_difficulty_name(difficulty), level]

static func _ensure_loaded() -> void:
	if not _levels.is_empty():
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Missing handcrafted level JSON: %s" % DATA_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("schema_version", 0)) != 3:
		push_error("Invalid handcrafted level JSON")
		return
	for entry in parsed.get("levels", []):
		if not entry is Dictionary:
			continue
		var difficulty := str(entry.get("difficulty", ""))
		var number := int(entry.get("level", 0))
		if DIFFICULTIES.has(difficulty) and number > 0:
			_levels["%s:%d" % [difficulty, number]] = entry

static func _decode_level(source: Dictionary, difficulty: int) -> Dictionary:
	var data := {
		"level": int(source.get("level", 1)),
		"template": str(source.get("id", "handcrafted")),
		"layout_type": str(source.get("id", "handcrafted")),
		"pattern": str(source.get("mechanic", "gravity_drop")),
		"required_letter": "",
		"mechanic": str(source.get("mechanic", "gravity_drop")),
		"theme": str(source.get("theme", "city")),
		"hint": str(source.get("hint", "")),
		"ink": float(source.get("ink", 600.0)),
		"draw_area": str(source.get("draw_area", "auto")),
		"hint_pattern": PackedVector2Array(),
		"platforms": [], "props": [], "joints": [], "anchors": [],
		"moving_obstacles": [], "fans": [], "bugs": [],
		"difficulty": difficulty, "is_child_mode": difficulty == 0
	}
	for point in source.get("solution_points", []):
		if point is Array and point.size() >= 2:
			data["hint_pattern"].append(Vector2(float(point[0]), float(point[1])))
	for item in source.get("platforms", []):
		data["platforms"].append({
			"pos": _position(item), "size": _size(item),
			"rot": float(item.get("rotation", 0)), "style": str(item.get("style", "brick"))
		})
	for item in source.get("physics_objects", []):
		data["props"].append({
			"name": str(item.get("name", "physics_object")), "pos": _position(item),
			"kind": str(item.get("kind", "stone_boulder")), "size": _size(item),
			"rot": float(item.get("rotation", 0)), "starts_frozen": bool(item.get("starts_frozen", false))
		})
	for item in source.get("joints", []):
		data["joints"].append({
			"type": str(item.get("type", "pin")), "body": str(item.get("body", "")),
			"pos": _position(item)
		})
	for item in source.get("anchors", []):
		data["anchors"].append({"pos": _position(item), "radius": float(item.get("radius", 22.0))})
	for item in source.get("bugs", []):
		data["bugs"].append({
			"pos": _position(item), "kind": str(item.get("kind", "beetle")),
			"move": str(item.get("move", "none")), "range": float(item.get("range", 0)),
			"speed": float(item.get("speed", 1.0)),
			"suspended": bool(item.get("suspended", false)),
			"rope_pivot": Vector2(float(item.get("rope_x", item.get("x", 0))), float(item.get("rope_y", item.get("y", 0))))
		})
	_separate_bugs_from_bees(data["bugs"])
	for item in source.get("moving_obstacles", []):
		data["moving_obstacles"].append({
			"pos": _position(item), "size": _size(item),
			"travel": float(item.get("travel", 30)), "speed": float(item.get("speed", 1.0))
		})
	for item in source.get("fans", []):
		data["fans"].append({
			"pos": _position(item), "size": _size(item),
			"force": Vector2(float(item.get("force_x", 0)), float(item.get("force_y", 0)))
		})
	return data

static func _separate_bugs_from_bees(bugs: Array) -> void:
	var bees: Array = []
	for b in bugs:
		if str(b.get("kind", "")) == "bee":
			bees.append(b)
	if bees.is_empty():
		return
	for b in bugs:
		if str(b.get("kind", "")) == "bee":
			continue
		var pos: Vector2 = b["pos"]
		for bee in bees:
			var bpos: Vector2 = bee["pos"]
			if pos.distance_to(bpos) < 90.0:
				var shift := -110.0 if bpos.x > 270.0 else 110.0
				pos.x = clampf(bpos.x + shift, 65.0, 475.0)
				b["pos"] = pos

static func _position(item: Dictionary) -> Vector2:
	return Vector2(float(item.get("x", 0)), float(item.get("y", 0)))

static func _size(item: Dictionary) -> Vector2:
	return Vector2(float(item.get("width", 100)), float(item.get("height", 20)))
