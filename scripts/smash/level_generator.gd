class_name SmashLevelGenerator
extends RefCounted

const LevelCatalog = preload("res://scripts/smash/level_catalog.gd")
const GLYPH_PRACTICE_LEVEL := 1

## Campaign levels are authored completely in JSON. This class only loads them;
## it does not choose templates, randomize positions, or generate geometry.
static func generate(level: int, _is_child: bool = false, _difficulty: int = -1, _variant: int = 0, _daily_key: String = "") -> Dictionary:
	var difficulty := clampi(_difficulty if _difficulty >= 0 else (0 if _is_child else 1), 0, 2)
	return LevelCatalog.get_level(level, difficulty)

static func make_glyph_practice(glyph: String, _difficulty: int, _level: int = GLYPH_PRACTICE_LEVEL, _variant: int = 0) -> Dictionary:
	return {}

static func count(difficulty: int = -1) -> int:
	return LevelCatalog.count(difficulty)

static func has_level(level: int, difficulty: int = 0) -> bool:
	return LevelCatalog.has_level(level, difficulty)
