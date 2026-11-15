extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var canvas := SmashDrawingCanvas.new()
	var preview := Line2D.new()
	preview.name = "PreviewLine"
	canvas.add_child(preview)
	root.add_child(canvas)
	canvas.size = Vector2(500, 240)
	canvas.set_ink_budgets(600.0, 600.0)
	canvas.set_active_ink_type("elastic")
	canvas._start_drawing(Vector2(80, 80))
	canvas._continue_drawing(Vector2(180, 80))
	var okay := canvas.is_drawing and canvas.points.size() == 2 and canvas.elastic_used_ink >= 99.0 and canvas.normal_used_ink == 0.0 and preview.default_color == Color("#111111")
	if not okay:
		printerr("Elastic drawing failed: drawing=%s points=%d elastic=%f solid=%f preview=%s" % [canvas.is_drawing, canvas.points.size(), canvas.elastic_used_ink, canvas.normal_used_ink, preview.default_color])
		quit(1)
		return
	canvas.reset_canvas()
	canvas.set_ink_budgets(600.0, 600.0)
	canvas.set_active_ink_type("elastic")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(80, 80)
	canvas._gui_input(press)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(180, 80)
	canvas._gui_input(motion)
	if preview.points.size() != 2 or canvas.elastic_used_ink < 99.0:
		printerr("Elastic GUI input did not produce a stroke")
		quit(1)
		return
	canvas.reset_canvas()
	canvas.set_ink_budgets(600.0, 600.0)
	canvas.set_active_ink_type("normal")
	canvas._gui_input(press)
	canvas._gui_input(motion)
	if preview.points.size() != 2 or canvas.normal_used_ink < 99.0 or canvas.elastic_used_ink != 0.0:
		printerr("Solid GUI input did not produce the same stroke")
		quit(1)
		return
	print("Solid and Elastic GUI drags both produce the same visible stroke")
	quit(0)
