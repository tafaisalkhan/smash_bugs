class_name SmashProp
extends RigidBody2D

@export var prop_kind: String = "stone_boulder" # "stone_boulder", "stone_block", "big_triangle", "log_roller", "heavy_hexagon"
@export var prop_size: Vector2 = Vector2(52.0, 52.0)

var spawn_pos: Vector2 = Vector2.ZERO
var has_been_displaced: bool = false
var collision_shape: CollisionShape2D

func _ready() -> void:
	spawn_pos = global_position
	_setup_physics()
	queue_redraw()

func _setup_physics() -> void:
	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape2D")
		if not collision_shape:
			collision_shape = CollisionShape2D.new()
			add_child(collision_shape)

	var phys_mat := PhysicsMaterial.new()

	match prop_kind:
		"stone_boulder", "log_roller", "heavy_hexagon":
			var circle := CircleShape2D.new()
			circle.radius = maxf(prop_size.x, prop_size.y) * 0.5
			collision_shape.shape = circle
			mass = 4.5
			phys_mat.friction = 0.16
			phys_mat.bounce = 0.22
		"big_triangle":
			var poly := ConvexPolygonShape2D.new()
			var hw := prop_size.x * 0.5
			var hh := prop_size.y * 0.5
			poly.points = PackedVector2Array([
				Vector2(0.0, -hh),
				Vector2(hw, hh),
				Vector2(-hw, hh)
			])
			collision_shape.shape = poly
			mass = 5.0
			phys_mat.friction = 0.20
			phys_mat.bounce = 0.18
		_: # "stone_block"
			var rect := RectangleShape2D.new()
			rect.size = prop_size
			collision_shape.shape = rect
			mass = 5.5
			phys_mat.friction = 0.22
			phys_mat.bounce = 0.15

	physics_material_override = phys_mat
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY

	# Layer 2: interacts with platforms (1), drawn shapes & other props (2), and bugs (4)
	collision_layer = 2
	collision_mask = 1 | 2 | 4

func _physics_process(_delta: float) -> void:
	if not has_been_displaced:
		if global_position.distance_to(spawn_pos) > 5.0 or linear_velocity.length() > 10.0 or absf(angular_velocity) > 0.3:
			has_been_displaced = true

func is_moving_hazard() -> bool:
	return has_been_displaced or linear_velocity.length() > 8.0 or absf(angular_velocity) > 0.25

func is_actively_moving() -> bool:
	return linear_velocity.length() > 25.0 or absf(angular_velocity) > 0.8

func _draw() -> void:
	match prop_kind:
		"stone_boulder":
			_draw_stone_boulder()
		"stone_block":
			_draw_stone_block()
		"big_triangle":
			_draw_big_triangle()
		"log_roller":
			_draw_log_roller()
		"heavy_hexagon":
			_draw_heavy_hexagon()
		_:
			_draw_stone_boulder()

func _draw_stone_boulder() -> void:
	var radius := maxf(prop_size.x, prop_size.y) * 0.5
	# Outer dark rim
	draw_circle(Vector2.ZERO, radius, Color("#263238"))
	# Main granite body
	draw_circle(Vector2.ZERO, radius - 2.5, Color("#78909c"))
	# Top-left 3D rocky highlight
	draw_circle(Vector2(-radius * 0.22, -radius * 0.22), radius * 0.55, Color("#90a4ae"))
	# Bottom-right shadow crescent
	draw_arc(Vector2.ZERO, radius - 5.0, PI * 0.15, PI * 0.85, 16, Color("#546e7a"), 4.0)
	# Cracks & stone facets
	draw_line(Vector2(-radius * 0.4, -radius * 0.1), Vector2(0.0, radius * 0.15), Color("#37474f"), 2.0)
	draw_line(Vector2(0.0, radius * 0.15), Vector2(radius * 0.35, -radius * 0.2), Color("#37474f"), 2.0)
	draw_line(Vector2(0.0, radius * 0.15), Vector2(-radius * 0.1, radius * 0.5), Color("#37474f"), 1.8)

func _draw_stone_block() -> void:
	var r := Rect2(-prop_size * 0.5, prop_size)
	# Main stone slab fill
	draw_rect(r, Color("#607d8b"))
	# Inner chiseled bevel
	var inset := r.grow(-5.0)
	if inset.size.x > 4.0 and inset.size.y > 4.0:
		draw_rect(inset, Color("#78909c"))
		draw_rect(inset, Color("#455a64"), false, 1.8)
	# Top highlight
	draw_rect(Rect2(r.position.x + 2, r.position.y + 2, r.size.x - 4, 4), Color("#b0bec5"))
	# Stone cracks
	draw_line(Vector2(r.position.x + 6, r.position.y + r.size.y * 0.35), Vector2(r.position.x + r.size.x * 0.45, r.position.y + r.size.y * 0.55), Color("#37474f"), 2.0)
	# Outer dark outline
	draw_rect(r, Color("#263238"), false, 2.5)

func _draw_big_triangle() -> void:
	var hw := prop_size.x * 0.5
	var hh := prop_size.y * 0.5
	var pts := PackedVector2Array([
		Vector2(0.0, -hh),
		Vector2(hw, hh),
		Vector2(-hw, hh)
	])
	var cols := PackedColorArray([
		Color("#ffb74d"),
		Color("#f57c00"),
		Color("#ef6c00")
	])
	draw_polygon(pts, cols)
	# Inner geometric bevel
	var inner_pts := PackedVector2Array([
		Vector2(0.0, -hh * 0.45),
		Vector2(hw * 0.48, hh * 0.65),
		Vector2(-hw * 0.48, hh * 0.65)
	])
	draw_colored_polygon(inner_pts, Color("#ffe082"))
	# Outline
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color("#3e2723"), 2.5)

func _draw_log_roller() -> void:
	var radius := maxf(prop_size.x, prop_size.y) * 0.5
	# Bark outer ring
	draw_circle(Vector2.ZERO, radius, Color("#4e342e"))
	# Inner golden heartwood
	draw_circle(Vector2.ZERO, radius - 4.5, Color("#d7ccc8"))
	draw_circle(Vector2.ZERO, radius - 6.0, Color("#bcaaa4"))
	# Concentric growth rings
	draw_arc(Vector2.ZERO, radius * 0.58, 0.0, TAU, 20, Color("#8d6e63"), 2.0)
	draw_arc(Vector2.ZERO, radius * 0.30, 0.0, TAU, 16, Color("#6d4c41"), 2.0)
	draw_circle(Vector2.ZERO, 3.0, Color("#4e342e"))

func _draw_heavy_hexagon() -> void:
	var radius := maxf(prop_size.x, prop_size.y) * 0.5
	var pts := PackedVector2Array()
	var inner_pts := PackedVector2Array()
	for i in range(6):
		var a := float(i) * TAU / 6.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
		inner_pts.append(Vector2(cos(a), sin(a)) * (radius * 0.62))
	draw_colored_polygon(pts, Color("#5c6bc0"))
	draw_colored_polygon(inner_pts, Color("#7986cb"))
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color("#1a237e"), 2.5)
