class_name HardWindFan
extends Node2D

@export var zone_size := Vector2(185.0, 210.0)
@export var wind_force := Vector2(580.0, 0.0)
var game: Node
var elapsed := 0.0

func _physics_process(delta: float) -> void:
	elapsed += delta
	if game == null:
		return
	var zone := Rect2(global_position - zone_size * 0.5, zone_size)
	var body: RigidBody2D = game.active_drawn_body
	if is_instance_valid(body) and not body.freeze and zone.has_point(body.global_position):
		body.apply_central_force(wind_force)
	for prop in game.active_props:
		if is_instance_valid(prop) and not prop.freeze and zone.has_point(prop.global_position):
			prop.apply_central_force(wind_force * 0.35)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 23.0, Color("#196b91"))
	draw_circle(Vector2.ZERO, 17.0, Color("#b8e9f4"))
	for i in range(3):
		var angle := elapsed * 5.0 + float(i) * TAU / 3.0
		draw_line(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * 14.0, Color("#196b91"), 5.0)
	var direction := signf(wind_force.x)
	for i in range(3):
		var y := -18.0 + float(i) * 18.0
		draw_line(Vector2(28.0 * direction, y), Vector2(63.0 * direction, y), Color("#8bdbf2", 0.8), 3.0)
