class_name UIPalette
extends RefCounted

const THEMES := [
	{"id": "Classic", "price": 0, "color": Color("#ffffff"), "description": "The original jungle look"},
	{"id": "Sunset", "price": 100, "color": Color("#ffd6a0"), "description": "Warm golden glow"},
	{"id": "Ocean", "price": 150, "color": Color("#a7dcf5"), "description": "Cool blue glow"},
	{"id": "Night", "price": 200, "color": Color("#b7a8db"), "description": "Soft violet glow"}
]

static func color_for(theme_id: String) -> Color:
	for theme_data in THEMES:
		if theme_data["id"] == theme_id:
			return theme_data["color"]
	return Color.WHITE

static func apply_background(background: TextureRect, theme_id: String) -> void:
	background.modulate = color_for(theme_id)
