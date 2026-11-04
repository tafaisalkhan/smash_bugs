class_name SmashPlatform
extends StaticBody2D

@export var size: Vector2 = Vector2(200, 50)
@export var style: String = "brick" # "brick", "stone", "moss_stone", "wood_log", "mushroom_bouncy", "flower_pedestal"

var collision_shape: CollisionShape2D

func _ready() -> void:
	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape2D")
		if not collision_shape:
			collision_shape = CollisionShape2D.new()
			add_child(collision_shape)

	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	collision_shape.shape = rect_shape

	# Collision layer: 1 (platforms)
	collision_layer = 1
	collision_mask = 2 # interacts with drawn shapes

	# Bouncy Mushroom physics!
	if style == "mushroom_bouncy":
		var mat := PhysicsMaterial.new()
		mat.bounce = 0.90
		mat.friction = 0.15
		physics_material_override = mat

	queue_redraw()

func _draw() -> void:
	var r := Rect2(-size * 0.5, size)

	match style:
		"brick":
			_draw_brick(r)
		"stone":
			_draw_stone(r)
		"moss_stone":
			_draw_moss_stone(r)
		"wood_log":
			_draw_wood_log(r)
		"mushroom_bouncy":
			_draw_mushroom_bouncy(r)
		"flower_pedestal":
			_draw_flower_pedestal(r)
		_:
			_draw_brick(r)

func _draw_brick(r: Rect2) -> void:
	# 1. Main blue brick fill
	draw_rect(r, Color("#2b7cd3")) # Vibrant stylized blue brick base

	# 2. Mortar lines and individual bricks
	var brick_h := 16.0
	var brick_w := 34.0
	var mortar_color := Color("#d6e9ff") # Clean ice-blue mortar
	var shadow_color := Color("#1a5296") # Deep blue shadow

	var rows := int(ceil(size.y / brick_h))
	for row in range(rows):
		var y := r.position.y + float(row) * brick_h
		# Horizontal mortar line
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), mortar_color, 2.0)

		var x_offset := (brick_w * 0.5) if (row % 2 == 1) else 0.0
		var x := r.position.x + x_offset
		while x < r.end.x:
			# Vertical mortar line
			draw_line(Vector2(x, y), Vector2(x, min(y + brick_h, r.end.y)), mortar_color, 2.0)
			# Subtle shadow
			draw_line(Vector2(x + 2, y + brick_h - 1), Vector2(min(x + brick_w - 2, r.end.x), y + brick_h - 1), shadow_color, 1.5)
			x += brick_w

	# 3. Top concrete ledge cap
	var cap_h := 10.0
	var cap_rect := Rect2(r.position.x - 2, r.position.y, size.x + 4, cap_h)
	draw_rect(cap_rect, Color("#1f5ca8")) # Rich slate-blue cap stone
	draw_rect(Rect2(r.position.x - 2, r.position.y, size.x + 4, 3), Color("#62a8ff")) # Cap bright blue highlight

	# 4. Outer border outline
	draw_rect(r, Color("#0d2847"), false, 2.5) # Dark midnight blue outline

func _draw_stone(r: Rect2) -> void:
	draw_rect(r, Color("#6d7a82"))
	draw_rect(Rect2(r.position.x, r.position.y, size.x, 6), Color("#8c9ba3"))
	draw_rect(r, Color("#262e33"), false, 2.5)

func _draw_moss_stone(r: Rect2) -> void:
	# Ancient garden stone covered in moss and hanging vines
	draw_rect(r, Color("#556066"))
	# Stone cracks / facets
	draw_line(Vector2(r.position.x + size.x * 0.3, r.position.y + 12), Vector2(r.position.x + size.x * 0.35, r.end.y - 8), Color("#3c464c"), 1.8)
	draw_line(Vector2(r.position.x + size.x * 0.7, r.position.y + 10), Vector2(r.position.x + size.x * 0.65, r.end.y - 12), Color("#3c464c"), 1.8)

	# Lush undulating moss on top
	var moss_h := minf(14.0, size.y * 0.35)
	var moss_rect := Rect2(r.position.x, r.position.y, size.x, moss_h)
	draw_rect(moss_rect, Color("#43a047"))
	draw_rect(Rect2(r.position.x, r.position.y, size.x, 3), Color("#76d275")) # Top highlight

	# Hanging ivy droplets
	var vines := int(maxf(size.x / 24.0, 2.0))
	for i in range(vines):
		var vx := r.position.x + 12.0 + float(i) * (size.x - 24.0) / maxf(float(vines - 1), 1.0)
		var vh := 6.0 + fmod(float(i * 7), 12.0)
		draw_line(Vector2(vx, r.position.y + moss_h), Vector2(vx, r.position.y + moss_h + vh), Color("#2e7d32"), 2.5)
		draw_circle(Vector2(vx, r.position.y + moss_h + vh), 3.0, Color("#388e3c"))

	draw_rect(r, Color("#1f272a"), false, 2.5)

func _draw_wood_log(r: Rect2) -> void:
	# Forest cedar log / branch
	draw_rect(r, Color("#6d4c41")) # Rich bark base
	# Wood grain lines
	var grains := int(ceil(size.y / 10.0))
	for i in range(1, grains):
		var gy := r.position.y + float(i) * 10.0
		draw_line(Vector2(r.position.x + 4, gy), Vector2(r.end.x - 4, gy), Color("#4e342e"), 1.5)

	# Lighter inner heartwood highlight
	draw_rect(Rect2(r.position.x + 2, r.position.y + 2, size.x - 4, 4), Color("#8d6e63"))

	# Sprouting fresh green leaf on top right corner
	var leaf_origin := Vector2(r.end.x - 12, r.position.y)
	draw_circle(leaf_origin + Vector2(4, -5), 5.0, Color("#66bb6a"))
	draw_circle(leaf_origin + Vector2(-3, -4), 4.0, Color("#81c784"))

	draw_rect(r, Color("#2d1f1b"), false, 2.5)

func _draw_mushroom_bouncy(r: Rect2) -> void:
	# Springy cartoon red mushroom with white polka dots and high bounce!
	# 1. Ivory stalk beneath cap
	var stalk_w := minf(size.x * 0.45, 50.0)
	var stalk_rect := Rect2(Vector2(-stalk_w * 0.5, 0), Vector2(stalk_w, size.y * 0.5))
	draw_rect(stalk_rect, Color("#fff8e1"))
	draw_rect(stalk_rect, Color("#d7ccc8"), false, 2.0)

	# 2. Cream underside gills
	var gills_rect := Rect2(r.position.x + 2, r.position.y + size.y * 0.65, size.x - 4, size.y * 0.25)
	draw_rect(gills_rect, Color("#ffe082"))

	# 3. Red Mushroom Cap
	var cap_rect := Rect2(r.position.x, r.position.y, size.x, size.y * 0.72)
	draw_rect(cap_rect, Color("#e53935")) # Bright crimson red
	draw_rect(Rect2(r.position.x + 2, r.position.y + 2, size.x - 4, 4), Color("#ff7961")) # Cap highlight

	# 4. White polka dots
	var dots := int(maxf(size.x / 32.0, 2.0))
	for i in range(dots):
		var dx := r.position.x + 16.0 + float(i) * (size.x - 32.0) / maxf(float(dots - 1), 1.0)
		var dy := r.position.y + cap_rect.size.y * (0.45 if (i % 2 == 0) else 0.55)
		var rad := 6.0 if (i % 2 == 0) else 4.5
		draw_circle(Vector2(dx, dy), rad, Color("#ffffff"))

	# 5. Outlines
	draw_rect(cap_rect, Color("#260808"), false, 2.5)

func _draw_flower_pedestal(r: Rect2) -> void:
	# Cheerful garden flower pedestal
	# Green stem
	var stem_w := minf(size.x * 0.25, 24.0)
	var stem_rect := Rect2(Vector2(-stem_w * 0.5, 0), Vector2(stem_w, size.y * 0.5))
	draw_rect(stem_rect, Color("#4caf50"))
	draw_rect(stem_rect, Color("#2e7d32"), false, 2.0)

	# Flower base & petals
	var petal_h := size.y * 0.6
	var petal_rect := Rect2(r.position.x, r.position.y, size.x, petal_h)
	draw_rect(petal_rect, Color("#ff4081")) # Vibrant pink blossom

	# Golden pollen top disk
	var pollen_rect := Rect2(r.position.x + 6, r.position.y + 2, size.x - 12, petal_h * 0.55)
	draw_rect(pollen_rect, Color("#ffca28"))
	draw_rect(Rect2(pollen_rect.position.x + 2, pollen_rect.position.y + 1, pollen_rect.size.x - 4, 3), Color("#fff9c4"))

	draw_rect(petal_rect, Color("#4a0e2e"), false, 2.5)
