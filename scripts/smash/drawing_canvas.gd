class_name SmashDrawingCanvas
extends Control

signal stroke_started
signal stroke_completed(points: PackedVector2Array)

@export var max_ink: float = 1000.0
@export var max_strokes: int = 1
@export var stroke_width: float = 14.0
@export var stroke_color: Color = Color("#111111")

var is_drawing: bool = false
var is_locked: bool = false
var strokes_used: int = 0
var points: PackedVector2Array = PackedVector2Array()
var used_ink: float = 0.0

var hint_points: PackedVector2Array = PackedVector2Array()
var is_hint_visible: bool = false

@onready var preview_line: Line2D = $PreviewLine

func _ready() -> void:
	if not preview_line:
		preview_line = get_node_or_null("PreviewLine")
	if is_instance_valid(preview_line):
		preview_line.width = stroke_width
		preview_line.default_color = stroke_color
		preview_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		preview_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		preview_line.joint_mode = Line2D.LINE_JOINT_ROUND
		preview_line.clear_points()

func set_hint_pattern(pts: PackedVector2Array) -> void:
	hint_points = pts
	is_hint_visible = false
	queue_redraw()

func toggle_hint() -> bool:
	is_hint_visible = not is_hint_visible
	queue_redraw()
	return is_hint_visible

func show_hint_pattern() -> void:
	is_hint_visible = true
	queue_redraw()

func _process(_delta: float) -> void:
	if is_hint_visible:
		queue_redraw()

func reset_canvas() -> void:
	is_drawing = false
	is_locked = false
	strokes_used = 0
	points.clear()
	if not preview_line:
		preview_line = get_node_or_null("PreviewLine")
	if is_instance_valid(preview_line):
		preview_line.clear_points()
	used_ink = 0.0
	_update_canvas_status_label()
	queue_redraw()

func _update_canvas_status_label() -> void:
	var lbl: Label = get_node_or_null("HintLabel")
	if is_instance_valid(lbl):
		if is_locked:
			lbl.text = "1 STROKE USED — WATCH OR PRESS ↻"
		else:
			lbl.text = "DRAW HERE (1 STROKE ONLY)"

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drawing(event.position)
			else:
				_finish_drawing()
	elif event is InputEventMouseMotion and is_drawing:
		_continue_drawing(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_start_drawing(event.position)
		else:
			_finish_drawing()
	elif event is InputEventScreenDrag and is_drawing:
		_continue_drawing(event.position)

func _start_drawing(pos: Vector2) -> void:
	if is_locked or strokes_used >= max_strokes:
		return
	if not _is_inside_canvas(pos):
		return

	is_drawing = true
	points.clear()
	points.append(pos)
	preview_line.clear_points()
	preview_line.add_point(pos)
	used_ink = 0.0
	stroke_started.emit()

func _continue_drawing(pos: Vector2) -> void:
	if not _is_inside_canvas(pos):
		return

	var last_pt := points[points.size() - 1]
	var dist := last_pt.distance_to(pos)

	# Avoid tiny point clusters (at least 6 pixels between points)
	if dist >= 6.0:
		if used_ink + dist <= max_ink:
			used_ink += dist
			points.append(pos)
			preview_line.add_point(pos)
		else:
			# Ran out of ink! Auto finish
			_finish_drawing()

func _finish_drawing() -> void:
	if not is_drawing:
		return

	is_drawing = false

	# Must have at least 2 points and minimum length
	if points.size() >= 2 and used_ink >= 15.0:
		strokes_used += 1
		if strokes_used >= max_strokes:
			is_locked = true
		_update_canvas_status_label()
		queue_redraw()

		var global_points := PackedVector2Array()
		for pt in points:
			global_points.append(global_position + pt)

		stroke_completed.emit(global_points)
	else:
		# Tiny accidental tap didn't spawn a shape, refund ink
		used_ink = 0.0

	preview_line.clear_points()

func _is_inside_canvas(pos: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(pos)

func _draw() -> void:
	# Draw the grid canvas styling matching the reference image!
	var r := Rect2(Vector2.ZERO, size)

	# 1. Background paper (slightly dimmed when stroke is used/locked)
	var bg_col := Color(0.92, 0.93, 0.95, 0.90) if is_locked else Color(1, 1, 1, 0.95)
	draw_rect(r, bg_col, true)

	# 2. Grid lines
	var cell_size := 18.0
	var grid_color := Color(0.85, 0.88, 0.92, 0.75)

	var x := cell_size
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
		x += cell_size

	var y := cell_size
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)
		y += cell_size

	# 3. Outer border with reference style dots
	var border_color := Color(0.78, 0.45, 0.42) if is_locked else Color(0.55, 0.62, 0.72)
	draw_rect(r, border_color, false, 2.0)

	var dot_spacing := 22.0
	var dot_r := 3.5

	# Horizontal dots
	var dx := dot_spacing * 0.5
	while dx < size.x:
		draw_circle(Vector2(dx, 0), dot_r, border_color)
		draw_circle(Vector2(dx, size.y), dot_r, border_color)
		dx += dot_spacing

	# Vertical dots
	var dy := dot_spacing * 0.5
	while dy < size.y:
		draw_circle(Vector2(0, dy), dot_r, border_color)
		draw_circle(Vector2(size.x, dy), dot_r, border_color)
		dy += dot_spacing

	# 4. Ghost hint pattern if enabled
	if is_hint_visible and hint_points.size() >= 2:
		var pulse: float = sin(Time.get_ticks_msec() * 0.006) * 0.2 + 0.8
		var glow_col := Color(1.0, 0.76, 0.18, 0.35 * pulse) # Golden glow
		var dash_col := Color(0.95, 0.52, 0.05, 0.9 * pulse) # Amber dash

		# Soft wide glow underlay
		draw_polyline(hint_points, glow_col, 20.0)

		# Dashed guide line
		_draw_dashed_polyline(hint_points, dash_col, 4.5, 12.0, 8.0)

		# Directional arrows along segments
		for i in range(hint_points.size() - 1):
			var p1 := hint_points[i]
			var p2 := hint_points[i + 1]
			var seg := p2 - p1
			if seg.length() > 35.0:
				var mid := (p1 + p2) * 0.5
				var dir := seg.normalized()
				var perp := Vector2(-dir.y, dir.x)
				var tip := mid + dir * 7.0
				var left_wing := mid - dir * 5.0 + perp * 6.0
				var right_wing := mid - dir * 5.0 - perp * 6.0
				draw_line(left_wing, tip, dash_col, 3.0)
				draw_line(right_wing, tip, dash_col, 3.0)

		# Start point green ripple beacon
		var p_start := hint_points[0]
		draw_circle(p_start, 7.0, Color(0.18, 0.82, 0.35, 0.95))
		draw_circle(p_start, 13.0 * pulse, Color(0.18, 0.82, 0.35, 0.35 * pulse))

		# End point target ring
		var p_end := hint_points[hint_points.size() - 1]
		draw_circle(p_end, 6.0, Color(0.95, 0.35, 0.2, 0.9))

		# Animated tracer dot moving along the hint path
		var tracer_pos := _sample_path_at_time(hint_points, fmod(Time.get_ticks_msec() * 0.00055, 1.0))
		draw_circle(tracer_pos, 8.0, Color(1.0, 0.95, 0.4, 0.95))
		draw_circle(tracer_pos, 4.5, Color(1.0, 1.0, 1.0, 1.0))

func _sample_path_at_time(pts: PackedVector2Array, t: float) -> Vector2:
	var total_len := 0.0
	for i in range(pts.size() - 1):
		total_len += pts[i].distance_to(pts[i + 1])
	if total_len <= 0.001:
		return pts[0]
	var target_d := clampf(t, 0.0, 1.0) * total_len
	var accum := 0.0
	for i in range(pts.size() - 1):
		var seg_d := pts[i].distance_to(pts[i + 1])
		if accum + seg_d >= target_d:
			var local_t := (target_d - accum) / maxf(seg_d, 0.001)
			return pts[i].lerp(pts[i + 1], local_t)
		accum += seg_d
	return pts[pts.size() - 1]

func _draw_dashed_polyline(pts: PackedVector2Array, col: Color, line_w: float, dash_len: float, gap_len: float) -> void:
	for i in range(pts.size() - 1):
		var p1 := pts[i]
		var p2 := pts[i + 1]
		var seg_vec := p2 - p1
		var seg_len := seg_vec.length()
		if seg_len < 1.0:
			continue
		var dir := seg_vec / seg_len
		var cur := 0.0
		var drawing_dash := true
		while cur < seg_len:
			var step := dash_len if drawing_dash else gap_len
			var next_pos := minf(cur + step, seg_len)
			if drawing_dash:
				draw_line(p1 + dir * cur, p1 + dir * next_pos, col, line_w, true)
			cur = next_pos
			drawing_dash = not drawing_dash
