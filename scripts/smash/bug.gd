class_name SmashBug
extends Area2D

signal bug_smashed(bug: SmashBug)
signal friendly_smashed(bug: SmashBug)

enum State { IDLE, PANIC, CELEBRATE, DEAD }

@export var kind: String = "beetle" # "beetle", "fly", "mosquito", or "bee"
@export var is_friendly: bool = false
@export var move_mode: String = "none" # "none", "hover", "patrol", "circle", "zigzag", "figure8", "swoop"
@export var move_range: float = 60.0
@export var move_speed: float = 1.0

var state: State = State.IDLE
var base_position: Vector2
var time_passed: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _anim_timer: float = 0.0
var _anim_frame: int = 0
var _base_scale: Vector2 = Vector2(0.22, 0.22)
var _splat_particles: CPUParticles2D
var _celebrate_particles: CPUParticles2D
var _celebrate_label: Label
var _phase_offset: float = 0.0

const TAUNT_TEXTS := ["HAHA! 😂", "MISSED! 😜", "YAY! 🎉", "TOO SLOW! 🕺"]

func _ready() -> void:
	_ensure_nodes()
	base_position = global_position
	# Unique phase offset per bug so multiple bugs move naturally without robotic sync
	_phase_offset = fmod(absf(global_position.x * 0.05 + global_position.y * 0.03), TAU)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# Setup sprite texture and visual style based on kind
	var sheet_path := "res://assets/sprites/beetle_sheet.png"
	var custom_scale := Vector2(0.22, 0.22)
	var custom_modulate := Color(1, 1, 1, 1)

	if kind == "fly":
		sheet_path = "res://assets/sprites/fly_sheet.png"
	elif kind == "mosquito":
		sheet_path = "res://assets/sprites/fly_sheet.png"
		custom_scale = Vector2(0.18, 0.24) # Slender elongated silhouette
		custom_modulate = Color(1.15, 0.42, 0.42, 1.0) # Aggressive reddish mosquito hue
	elif kind == "bee":
		sheet_path = "res://assets/sprites/bee_sheet.png"
		is_friendly = true

	if sprite:
		sprite.texture = load(sheet_path)
		sprite.hframes = 4
		sprite.vframes = 3
		sprite.frame = 0
		_base_scale = custom_scale
		sprite.scale = custom_scale
		sprite.modulate = custom_modulate

	_create_particles()
	_create_celebrate_ui()

func _ensure_nodes() -> void:
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape2D")
	if not _celebrate_label:
		_create_celebrate_ui()

func _create_particles() -> void:
	_splat_particles = CPUParticles2D.new()
	_splat_particles.emitting = false
	_splat_particles.one_shot = true
	_splat_particles.explosiveness = 0.95
	_splat_particles.amount = 20
	_splat_particles.lifetime = 0.6
	_splat_particles.spread = 180.0
	_splat_particles.initial_velocity_min = 80.0
	_splat_particles.initial_velocity_max = 160.0
	_splat_particles.scale_amount_min = 3.0
	_splat_particles.scale_amount_max = 6.0
	if kind == "bee":
		_splat_particles.color = Color(1.0, 0.85, 0.2) # Golden pollen
	elif kind == "fly":
		_splat_particles.color = Color(0.2, 0.9, 0.2) # Green goo
	elif kind == "mosquito":
		_splat_particles.color = Color(0.92, 0.16, 0.16) # Red blood splat
	else:
		_splat_particles.color = Color(0.95, 0.75, 0.1) # Yellow beetle goo
	add_child(_splat_particles)

func _create_celebrate_ui() -> void:
	if _celebrate_label:
		return
	_celebrate_particles = CPUParticles2D.new()
	_celebrate_particles.emitting = false
	_celebrate_particles.one_shot = false
	_celebrate_particles.explosiveness = 0.4
	_celebrate_particles.amount = 14
	_celebrate_particles.lifetime = 0.75
	_celebrate_particles.direction = Vector2(0, -1)
	_celebrate_particles.spread = 75.0
	_celebrate_particles.gravity = Vector2(0, 180)
	_celebrate_particles.initial_velocity_min = 90.0
	_celebrate_particles.initial_velocity_max = 150.0
	_celebrate_particles.scale_amount_min = 3.5
	_celebrate_particles.scale_amount_max = 6.0
	_celebrate_particles.color = Color(1.0, 0.84, 0.15)
	add_child(_celebrate_particles)

	_celebrate_label = Label.new()
	_celebrate_label.visible = false
	_celebrate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_celebrate_label.custom_minimum_size = Vector2(110, 26)
	_celebrate_label.position = Vector2(-55.0, -58.0)
	_celebrate_label.add_theme_font_size_override("font_size", 14)
	_celebrate_label.add_theme_color_override("font_color", Color("#fff59d"))
	_celebrate_label.add_theme_color_override("font_outline_color", Color("#1b1b1b"))
	_celebrate_label.add_theme_constant_override("outline_size", 5)
	add_child(_celebrate_label)

func _process(delta: float) -> void:
	if state == State.DEAD:
		return

	time_passed += delta
	_update_movement(delta)
	_update_animation(delta)

func _update_movement(delta: float) -> void:
	if state == State.CELEBRATE:
		# Joyful victory dance when the player fails/misses!
		var hop := absf(sin(time_passed * 10.0)) * 20.0
		var sway := sin(time_passed * 6.0) * 10.0
		var target_pos := base_position + Vector2(sway, -hop)
		position = position.lerp(target_pos, clampf(delta * 14.0, 0.0, 1.0))

		if sprite:
			var target_rot := sin(time_passed * 12.0) * 0.22
			sprite.rotation = lerpf(sprite.rotation, target_rot, clampf(delta * 14.0, 0.0, 1.0))
			var stretch := 1.0 + sin(time_passed * 18.0) * 0.12
			var target_scale := Vector2(_base_scale.x / stretch, _base_scale.y * stretch)
			sprite.scale = sprite.scale.lerp(target_scale, clampf(delta * 14.0, 0.0, 1.0))
			# Smooth facing flip
			if absf(sway) > 1.5:
				sprite.flip_h = sway < 0.0
		if _celebrate_label:
			var target_lbl_y := -60.0 - absf(cos(time_passed * 8.0)) * 8.0
			_celebrate_label.position.y = lerpf(_celebrate_label.position.y, target_lbl_y, clampf(delta * 14.0, 0.0, 1.0))
		return

	var t := (time_passed + _phase_offset) * move_speed
	var target_pos := base_position
	var target_rot := 0.0
	var target_scale := _base_scale
	var target_flip := sprite.flip_h if sprite else false

	match move_mode:
		"hover":
			# Gentle organic vertical float with breathing squash
			target_pos.x = base_position.x + sin(t * 1.2) * 5.0
			target_pos.y = base_position.y + sin(t * 2.2) * 14.0
			var breathe := sin(t * 4.4) * 0.04
			target_scale = Vector2(_base_scale.x * (1.0 + breathe), _base_scale.y * (1.0 - breathe))
			target_rot = sin(t * 1.8) * 0.05
			target_flip = cos(t * 1.2) < 0.0

		"patrol":
			# Continuous harmonic sine patrol with smooth tilt banking
			var offset_x = sin(t * 1.2) * move_range
			target_pos.x = base_position.x + offset_x
			target_pos.y = base_position.y + sin(t * 2.4) * 5.0 # gentle vertical float
			var vel_x := cos(t * 1.2)
			target_flip = vel_x < 0.0
			target_rot = vel_x * 0.10

		"circle":
			# Smooth circular / elliptical orbit
			target_pos.x = base_position.x + cos(t * 1.4) * move_range
			target_pos.y = base_position.y + sin(t * 1.4) * (move_range * 0.45)
			var vx := -sin(t * 1.4)
			target_flip = vx < 0.0
			target_rot = vx * 0.14

		"zigzag":
			# Smooth fluid zigzag (curved harmonic sines, perfectly continuous)
			var cur_x := sin(t * 1.6) * move_range
			var cur_y := sin(t * 3.8) * 16.0
			target_pos = base_position + Vector2(cur_x, cur_y)
			var vx := cos(t * 1.6)
			target_flip = vx < 0.0
			target_rot = vx * 0.12 + cos(t * 3.8) * 0.06

		"figure8":
			# Smooth Lissajous curve with continuous velocity
			var fx := sin(t * 1.3) * move_range
			var fy := sin(t * 2.6) * (move_range * 0.38)
			target_pos = base_position + Vector2(fx, fy)
			var vx := cos(t * 1.3)
			target_flip = vx < 0.0
			target_rot = vx * 0.12

		"swoop":
			# Smooth pendulum swoop
			var sx := sin(t * 1.3) * move_range
			var sy := (1.0 - cos(t * 1.3)) * 20.0
			target_pos = base_position + Vector2(sx, sy)
			var vx := cos(t * 1.3)
			target_flip = vx < 0.0
			target_rot = vx * 0.16

		_:
			# Ground bugs: subtle living breathing motion
			target_pos = base_position
			var breathe := sin(time_passed * 3.0 + _phase_offset) * 0.03
			target_scale = Vector2(_base_scale.x * (1.0 + breathe), _base_scale.y * (1.0 - breathe))

	# Panic state: subtle flutter overlay
	if state == State.PANIC:
		var flutter := Vector2(sin(time_passed * 30.0), cos(time_passed * 35.0)) * 2.5
		target_pos += flutter
		target_rot += sin(time_passed * 24.0) * 0.12
		target_scale *= Vector2(0.95, 1.05)

	# Smooth exponential blend (delta independent)
	var pos_blend := 1.0 - exp(-delta * 8.0)
	var rot_blend := 1.0 - exp(-delta * 9.0)
	var sca_blend := 1.0 - exp(-delta * 8.0)

	position = position.lerp(target_pos, pos_blend)
	if sprite:
		sprite.flip_h = target_flip
		sprite.rotation = lerpf(sprite.rotation, target_rot, rot_blend)
		sprite.scale = sprite.scale.lerp(target_scale, sca_blend)

func _update_animation(delta: float) -> void:
	_anim_timer += delta
	var frame_duration := 0.08 if state == State.CELEBRATE else (0.12 if state == State.PANIC else 0.18)

	if _anim_timer >= frame_duration:
		_anim_timer = 0.0
		_anim_frame = (_anim_frame + 1) % 4

		match state:
			State.IDLE, State.CELEBRATE:
				# Row 0 (frames 0..3): idle / fast celebratory wing flap
				sprite.frame = _anim_frame
			State.PANIC:
				# Row 1 (frames 4..7): panic sweating / darting
				sprite.frame = 4 + _anim_frame

func set_panic(panic: bool) -> void:
	if state == State.DEAD or state == State.CELEBRATE:
		return
	if panic and state != State.PANIC:
		state = State.PANIC
		_anim_frame = 0
	elif not panic and state != State.IDLE:
		state = State.IDLE
		_anim_frame = 0

func celebrate() -> void:
	if state == State.DEAD or is_friendly:
		return
	_ensure_nodes()
	state = State.CELEBRATE
	base_position = position
	_anim_frame = 0
	if _celebrate_label:
		var idx: int = int(absf(base_position.x + base_position.y)) % TAUNT_TEXTS.size()
		_celebrate_label.text = TAUNT_TEXTS[idx]
		_celebrate_label.visible = true
	if _celebrate_particles:
		_celebrate_particles.emitting = true

func reset_celebration() -> void:
	if state != State.CELEBRATE:
		return
	state = State.IDLE
	position = base_position
	if sprite:
		sprite.rotation = 0.0
		sprite.scale = _base_scale
	if _celebrate_label:
		_celebrate_label.visible = false
	if _celebrate_particles:
		_celebrate_particles.emitting = false

func _physics_process(_delta: float) -> void:
	if state == State.DEAD:
		return
	if is_friendly:
		if global_position.y > 960.0 or global_position.y < -300.0 or global_position.x < -150.0 or global_position.x > 690.0:
			smash()
			return
	for body in get_overlapping_bodies():
		_try_smash_from_body(body)
		if state == State.DEAD:
			return

func _on_body_entered(body: Node2D) -> void:
	_try_smash_from_body(body)

func _try_smash_from_body(body: Node2D) -> void:
	if state == State.DEAD or not is_instance_valid(body):
		return

	# Movable level props (stones, boulders, big shapes, logs):
	# Moving hazards kill any bug they crush (bad bugs die, friendly bees die -> fails level)
	if body.has_method("is_moving_hazard"):
		if body.call("is_moving_hazard"):
			smash()
		return

	# Player's falling drawn shape smashes any bug it hits (bad bugs die, friendly bees die -> fails level)
	if body is RigidBody2D:
		smash()

func smash() -> void:
	if state == State.DEAD:
		return

	_ensure_nodes()
	state = State.DEAD
	if _celebrate_label:
		_celebrate_label.visible = false
	if _celebrate_particles:
		_celebrate_particles.emitting = false
	if sprite:
		sprite.rotation = 0.0
		sprite.scale = _base_scale
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	# Play dying animation frames: 8 (hit) -> 9 (flattened) -> 10 (splat) -> 11 (flat dead)
	_play_death_sequence()

func _play_death_sequence() -> void:
	if _splat_particles:
		_splat_particles.restart()

	# Play bug kill splat audio
	if is_inside_tree():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_bug_kill"):
			audio.play_bug_kill()

	if sprite and is_inside_tree():
		sprite.frame = 8
		var tween := create_tween()
		if tween:
			# Smooth squash impact: brief pop up -> heavy pancake squash
			var orig_s := _base_scale
			var pop_s := Vector2(orig_s.x * 1.25, orig_s.y * 0.75)
			var flat_s := Vector2(orig_s.x * 1.45, orig_s.y * 0.40)
			tween.tween_property(sprite, "scale", pop_s, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_callback(func(): if sprite: sprite.frame = 9)
			tween.tween_property(sprite, "scale", flat_s, 0.07).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tween.tween_callback(func(): if sprite: sprite.frame = 10)
			tween.tween_interval(0.06)
			tween.tween_callback(func(): if sprite: sprite.frame = 11)

	if is_friendly:
		friendly_smashed.emit(self)
	else:
		bug_smashed.emit(self)
