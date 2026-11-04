@tool
extends SceneTree

func _init() -> void:
	var dir = DirAccess.open("res://")
	var scripts: Array[String] = []
	_scan_dir("res://", scripts)
	print("Checking ", scripts.size(), " scripts...")
	var errors = 0
	for path in scripts:
		var scr = load(path)
		if scr == null:
			printerr("ERROR in script: ", path)
			errors += 1
		else:
			print("OK: ", path)
	if errors > 0:
		printerr("FAILED with ", errors, " errors.")
		quit(1)
	else:
		print(">>> ALL SCRIPTS COMPILED CLEANLY <<<")
		quit(0)

func _scan_dir(path: String, out_scripts: Array[String]) -> void:
	var d = DirAccess.open(path)
	if d:
		d.list_dir_begin()
		var fname = d.get_next()
		while fname != "":
			if fname != "." and fname != ".." and fname != ".godot":
				var full = path.path_join(fname)
				if d.current_is_dir():
					_scan_dir(full, out_scripts)
				elif fname.ends_with(".gd"):
					out_scripts.append(full)
			fname = d.get_next()
