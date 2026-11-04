extends Control

signal close_requested
signal setting_changed(id: String, enabled: bool)
signal settings_action_requested(id: String)
signal shop_action_requested(id: String)
signal purchase_requested(id: String)
signal mission_claim_requested(id: String)
signal leaderboard_signin_requested
signal leaderboard_full_requested
signal privacy_requested

@export_enum("shop", "store") var screen_kind := "shop"
@export var screen_texture: Texture2D

const OVERLAY_FONT = preload("res://resources/ui_overlay_font.tres")

var _data: Dictionary = {}
var _category := ""
var _art: TextureRect

func _ready() -> void:
	_art = TextureRect.new()
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.texture = screen_texture
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_SCALE
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	_render()

func set_data(data: Dictionary) -> void:
	_data = data
	if is_node_ready():
		_render()

func _render() -> void:
	for child in get_children():
		if child != _art:
			remove_child(child)
			child.queue_free()
	var coin_box := Rect2(0.39, 0.77, 0.28, 0.055) if screen_kind == "shop" else Rect2(0.39, 0.18, 0.28, 0.06)
	_add_label("%d" % int(_data.get("coins", 0)), coin_box, 29, Color.WHITE, true)
	_add_hotspot(Rect2(0.29, 0.84, 0.42, 0.09), Callable(self, "_close"))
	if screen_kind == "shop":
		_render_shop()
	else:
		_render_store()

func _render_shop() -> void:
	var categories: Array[String] = []
	for item in _data.get("shop_items", []):
		var category := str(item.get("category", "Themes"))
		if not categories.has(category):
			categories.append(category)
	if categories.is_empty():
		categories.append("Themes")
	if not categories.has(_category):
		_category = categories[0]
	for index in range(mini(categories.size(), 3)):
		var category := categories[index]
		var x := 0.07 + float(index) * 0.31
		_add_label(category.to_upper(), Rect2(x, 0.226, 0.15, 0.03), 16, Color.WHITE, true)
		_add_hotspot(Rect2(x, 0.175, 0.28, 0.09), Callable(self, "_select_category").bind(category))
	var visible_items: Array = []
	for item in _data.get("shop_items", []):
		if str(item.get("category", "Themes")) == _category:
			visible_items.append(item)
	for index in range(mini(visible_items.size(), 4)):
		var item: Dictionary = visible_items[index]
		var x := 0.12 + float(index % 2) * 0.40
		var y := 0.30 + float(floori(float(index) / 2.0)) * 0.235
		var icon_color: Color = item.get("color", Color("#8656bc"))
		_add_label(str(item.get("icon", "◆")), Rect2(x, y, 0.31, 0.09), 43, icon_color, true)
		_add_label(str(item.get("name", "Item")).to_upper(), Rect2(x, y + 0.09, 0.31, 0.045), 24, Color("#26382b"), true)
		var action := "EQUIPPED" if bool(item.get("equipped", false)) else ("SELECT" if bool(item.get("owned", false)) else "%d" % int(item.get("cost", 0)))
		_add_label(action, Rect2(x + 0.12, y + 0.145, 0.19, 0.045), 16, Color("#42240d"), true)
		_add_hotspot(Rect2(x, y, 0.33, 0.20), Callable(self, "_activate_shop").bind(str(item.get("id", ""))))

func _render_store() -> void:
	var products: Array = _data.get("store_products", [])
	for index in range(mini(products.size(), 3)):
		var product: Dictionary = products[index]
		var y := 0.275 + float(index) * 0.197
		_add_label(str(product.get("name", "Coins")).to_upper(), Rect2(0.15, y, 0.46, 0.055), 23, Color("#26382b"), false)
		_add_label(str(product.get("description", "")).to_upper(), Rect2(0.15, y + 0.055, 0.45, 0.045), 18, Color("#40574b"), false)
		_add_label(str(product.get("price", "")).to_upper(), Rect2(0.15, y + 0.106, 0.45, 0.04), 16, Color("#68410d"), false)
		_add_hotspot(Rect2(0.61, y + 0.055, 0.26, 0.09), Callable(self, "_activate_store").bind(str(product.get("id", ""))))

func _add_label(value: String, box: Rect2, font_size: int, color: Color, centered: bool) -> void:
	var label := Label.new()
	_place(label, box)
	label.text = value
	label.add_theme_font_override("font", OVERLAY_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#28341b") if color.get_luminance() > 0.65 else Color("#fff8df"))
	label.add_theme_constant_override("outline_size", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func _add_hotspot(box: Rect2, action: Callable) -> void:
	var button := Button.new()
	_place(button, box)
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	add_child(button)

func _place(control: Control, box: Rect2) -> void:
	control.anchor_left = box.position.x
	control.anchor_top = box.position.y
	control.anchor_right = box.end.x
	control.anchor_bottom = box.end.y

func _select_category(category: String) -> void:
	_category = category
	_render()

func _activate_shop(id: String) -> void:
	shop_action_requested.emit(id)

func _activate_store(id: String) -> void:
	purchase_requested.emit(id)

func _close() -> void:
	close_requested.emit()
