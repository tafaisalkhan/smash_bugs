class_name SmashLevelStore
extends RefCounted

const SAVE_DIR := "user://smash_levels_v5"
const FORMAT_VERSION := 5
const MAX_CANDIDATES := 120
static var _session_levels: Dictionary = {}
static var _session_signatures: Dictionary = {}

static func load_saved(level: int, difficulty: int, daily_key: String = "") -> Dictionary:
	var key := _level_key(level, difficulty, daily_key)
	if _session_levels.has(key):
		return _session_levels[key].duplicate(true)
	var path := "%s/%s.json" % [SAVE_DIR, key]
	if FileAccess.file_exists(path):
		var saved := _read_json(path)
		if int(saved.get("format_version", 0)) == FORMAT_VERSION and saved.has("layout"):
			return _decode(saved["layout"])
	return {}

static func make_candidate(level: int, difficulty: int, daily_key: String, attempt: int) -> Dictionary:
	var candidate := SmashLevelGenerator.generate(level, difficulty == 0, difficulty, attempt, daily_key)
	if not _basic_checks(candidate):
		return {}
	var used := _read_signatures()
	if used.has(_signature(candidate)):
		return {}
	return candidate

static func save_accepted(level: int, difficulty: int, daily_key: String, data: Dictionary) -> void:
	var key := _level_key(level, difficulty, daily_key)
	var path := "%s/%s.json" % [SAVE_DIR, key]
	var signature := _signature(data)
	_session_levels[key] = data.duplicate(true)
	_session_signatures[signature] = key
	var dir_path := ProjectSettings.globalize_path(SAVE_DIR)
	DirAccess.make_dir_recursive_absolute(dir_path)
	var used := _read_signatures()
	used[signature] = key
	_write_json("%s/index.json" % SAVE_DIR, used)
	_write_json(path, {
		"format_version": FORMAT_VERSION,
		"id": key,
		"signature": signature,
		"layout": _encode(data)
	})

static func _level_key(level: int, difficulty: int, daily_key: String) -> String:
	if not daily_key.is_empty():
		return "daily_%s_%d" % [daily_key, difficulty]
	return "normal_%d_%d" % [difficulty, level]

static func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

static func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save level data: %s" % path)
		return
	file.store_string(JSON.stringify(data))

static func _read_signatures() -> Dictionary:
	var saved := _read_json("%s/index.json" % SAVE_DIR)
	for signature in _session_signatures:
		saved[signature] = _session_signatures[signature]
	return saved

static func _encode(value: Variant) -> Variant:
	if value is Vector2:
		return {"_type": "Vector2", "x": value.x, "y": value.y}
	if value is PackedVector2Array:
		var points := []
		for point in value:
			points.append(_encode(point))
		return {"_type": "PackedVector2Array", "points": points}
	if value is Dictionary:
		var encoded := {}
		for key in value:
			encoded[key] = _encode(value[key])
		return encoded
	if value is Array:
		var encoded := []
		for item in value:
			encoded.append(_encode(item))
		return encoded
	return value

static func _decode(value: Variant) -> Variant:
	if value is Dictionary:
		if value.get("_type", "") == "Vector2":
			return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))
		if value.get("_type", "") == "PackedVector2Array":
			var points := PackedVector2Array()
			for point in value.get("points", []):
				points.append(_decode(point))
			return points
		var decoded := {}
		for key in value:
			decoded[key] = _decode(value[key])
		return decoded
	if value is Array:
		var decoded := []
		for item in value:
			decoded.append(_decode(item))
		return decoded
	return value

static func _signature(data: Dictionary) -> String:
	var parts := []
	parts.append("pattern:%s" % str(data.get("pattern", "")))
	parts.append("difficulty:%d" % int(data.get("difficulty", 0)))
	for bug in data.get("bugs", []):
		parts.append("b:%s:%d:%d:%s:%d:%d" % [
			bug.get("kind", ""), roundi(bug["pos"].x / 18.0), roundi(bug["pos"].y / 18.0), bug.get("move", "none"),
			roundi(float(bug.get("range", 0.0)) / 8.0), roundi(float(bug.get("speed", 1.0)) * 4.0)
		])
	for platform in data.get("platforms", []):
		if platform["size"].y >= 150.0 and platform["size"].x >= 500.0:
			continue # The shared floor does not distinguish puzzles.
		parts.append("p:%s:%d:%d:%d:%d" % [
			platform.get("style", ""), roundi(platform["pos"].x / 18.0), roundi(platform["pos"].y / 18.0),
			roundi(platform["size"].x / 18.0), roundi(platform["size"].y / 18.0)
		])
	for prop in data.get("props", []):
		parts.append("r:%s:%d:%d" % [prop.get("kind", ""), roundi(prop["pos"].x / 18.0), roundi(prop["pos"].y / 18.0)])
	for obstacle in data.get("moving_obstacles", []):
		parts.append("o:%d:%d:%d" % [roundi(obstacle["pos"].x / 18.0), roundi(obstacle["pos"].y / 18.0), roundi(float(obstacle.get("travel", 0.0)) / 12.0)])
	for fan in data.get("fans", []):
		parts.append("f:%d:%d:%d" % [roundi(fan["pos"].x / 18.0), roundi(fan["pos"].y / 18.0), signf(fan["force"].x)])
	parts.sort()
	return "|".join(parts)

static func _basic_checks(data: Dictionary) -> bool:
	var good_count := 0
	var bees := []
	for bug in data.get("bugs", []):
		var pos: Vector2 = bug["pos"]
		if pos.x < 24.0 or pos.x > 516.0 or pos.y < 180.0 or pos.y > 830.0:
			return false
		if bug.get("kind", "") == "bee":
			bees.append(bug)
		else:
			good_count += 1
	if good_count == 0:
		return false
	for bug in data.get("bugs", []):
		if bug.get("kind", "") == "bee":
			continue
		for bee in bees:
			if bug["pos"].distance_to(bee["pos"]) < 68.0:
				return false
	var hint: PackedVector2Array = data.get("hint_pattern", PackedVector2Array())
	if hint.size() < 2 or float(data.get("ink", 0.0)) < _path_length(hint):
		return false
	var stage: int = int(data.get("level", 1))
	var top := 171.0
	var bottom := 411.0
	if stage >= 16:
		top = 110.0
		bottom = 830.0
	elif stage >= 9:
		top = 130.0
		bottom = 680.0
	elif stage >= 4:
		top = 150.0
		bottom = 520.0
	for point in hint:
		var world_point := Vector2(20.0, 171.0) + point
		if world_point.x < 20.0 or world_point.x > 520.0 or world_point.y < top or world_point.y > bottom:
			return false
	return true

static func _path_length(points: PackedVector2Array) -> float:
	var length := 0.0
	for i in range(points.size() - 1):
		length += points[i].distance_to(points[i + 1])
	return length
