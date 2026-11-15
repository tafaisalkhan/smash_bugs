class_name HardMovingObstacle
extends AnimatableBody2D

@export var obstacle_size := Vector2(26.0, 110.0)
@export var travel := 35.0
@export var speed := 1.5

var anchor: Vector2
var elapsed := 0.0

func _ready() -> void:
	anchor = position
	collision_layer = 1
	collision_mask = 2
	sync_to_physics = true
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = obstacle_size
	shape.shape = rectangle
	add_child(shape)
	queue_redraw()

func _physics_process(delta: float) -> void:
	elapsed += delta
	position = anchor + Vector2(sin(elapsed * speed) * travel, 0.0)

func _draw() -> void:
	var rect := Rect2(-obstacle_size * 0.5, obstacle_size)
	draw_rect(rect, Color("#ed6c36"))
	draw_rect(rect, Color("#663319"), false, 3.0)
	for y in range(-35, 36, 35):
		draw_line(Vector2(-8, y), Vector2(8, y), Color("#ffe0a8"), 3.0)
