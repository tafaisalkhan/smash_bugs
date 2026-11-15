extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var buildings := [
		{"x": 0.04, "width": 0.13, "height": 0.55},
		{"x": 0.17, "width": 0.18, "height": 0.72},
		{"x": 0.38, "width": 0.14, "height": 0.44},
		{"x": 0.54, "width": 0.16, "height": 0.66},
		{"x": 0.74, "width": 0.20, "height": 0.80}
	]
	for building in buildings:
		var left: float = float(building["x"]) * w
		var width: float = float(building["width"]) * w
		var top: float = h - float(building["height"]) * h
		draw_rect(Rect2(left, top, width, h - top), Color(0.65, 0.72, 0.84, 0.15))
		var window_x := left + 12.0
		while window_x < left + width - 8.0:
			var window_y := top + 18.0
			while window_y < h - 24.0:
				draw_rect(Rect2(window_x, window_y, 5.0, 10.0), Color(1.0, 1.0, 1.0, 0.20))
				window_y += 28.0
			window_x += 20.0
	draw_rect(Rect2(0.0, h - 55.0, w, 55.0), Color(0.78, 0.80, 0.87, 0.17))
	for i in range(4):
		var road_x := float(i) * w / 4.0 + 20.0
		draw_line(Vector2(road_x, h - 20.0), Vector2(road_x + 48.0, h - 20.0), Color(1, 1, 1, 0.42), 3.0)
