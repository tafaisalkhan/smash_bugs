class_name SmashDrawnBody
extends RigidBody2D

@export var stroke_width: float = 14.0
@export var stroke_color: Color = Color("#181818")

var line: Line2D

func build_from_points(global_pts: PackedVector2Array) -> void:
	if global_pts.size() < 2:
		queue_free()
		return

	# Calculate center of mass / centroid to position the body cleanly
	var center := Vector2.ZERO
	for pt in global_pts:
		center += pt
	center /= float(global_pts.size())

	global_position = center

	# Create local points relative to body center
	var local_pts := PackedVector2Array()
	var total_length := 0.0
	for i in range(global_pts.size()):
		var local_pt = global_pts[i] - center
		local_pts.append(local_pt)
		if i > 0:
			total_length += (global_pts[i] - global_pts[i-1]).length()

	# 1. Visual Line
	line = Line2D.new()
	line.points = local_pts
	line.width = stroke_width
	line.default_color = stroke_color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(line)

	# 2. Physics Collision: Capsule/Segment on every segment
	var radius := stroke_width * 0.5
	for i in range(local_pts.size() - 1):
		var p1 := local_pts[i]
		var p2 := local_pts[i+1]
		var seg_len := (p2 - p1).length()
		if seg_len < 2.0:
			continue

		var col := CollisionShape2D.new()
		var capsule := CapsuleShape2D.new()
		capsule.radius = radius
		capsule.height = seg_len + radius * 2.0

		col.shape = capsule
		col.position = (p1 + p2) * 0.5
		col.rotation = (p2 - p1).angle() + PI * 0.5
		add_child(col)

	# 3. Setup Physics Properties
	mass = clampf(total_length * 0.08, 2.0, 60.0)
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY

	var phys_mat := PhysicsMaterial.new()
	phys_mat.friction = 0.22
	phys_mat.bounce = 0.18
	physics_material_override = phys_mat

	# Collision layer: 2 (drawn shapes), mask: 1 (platforms) + 2 (movable stones/props) + 4 (bugs)
	collision_layer = 2
	collision_mask = 1 | 2 | 4
