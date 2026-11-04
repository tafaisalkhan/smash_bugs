extends Node

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var anxious_player: AudioStreamPlayer
var kill_player: AudioStreamPlayer
var victory_player: AudioStreamPlayer
var fail_player: AudioStreamPlayer
var coin_player: AudioStreamPlayer
var star_player: AudioStreamPlayer
var celebrate_player: AudioStreamPlayer

# Preloaded sound resources
const BGM = preload("res://assets/sounds/back_groud_sound.mp3")
const SFX_CELEBRATE = preload("res://assets/sounds/bugs_celebreaty.mp3")
const SFX_BUG_KILL = preload("res://assets/sounds/bugs_kill.wav")
const SFX_BUG_ANXIOUS = preload("res://assets/sounds/bug_anxios.mp3")
const SFX_COIN = preload("res://assets/sounds/coin_sound.wav")
const SFX_LEVEL_COMPLETE = preload("res://assets/sounds/level_complete.mp3")
const SFX_LEVEL_FAIL = preload("res://assets/sounds/level_fail.mp3")
const SFX_STAR = preload("res://assets/sounds/star_sound.mp3")

func _is_sfx_enabled() -> bool:
	if is_inside_tree():
		var state = get_node_or_null("/root/GameState")
		if state and "sfx_enabled" in state:
			return state.sfx_enabled
	return true

func _is_music_enabled() -> bool:
	if is_inside_tree():
		var state = get_node_or_null("/root/GameState")
		if state and "music_enabled" in state:
			return state.music_enabled
	return true

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	sfx_player.max_polyphony = 8
	anxious_player = AudioStreamPlayer.new()
	kill_player = AudioStreamPlayer.new()
	victory_player = AudioStreamPlayer.new()
	fail_player = AudioStreamPlayer.new()
	coin_player = AudioStreamPlayer.new()
	star_player = AudioStreamPlayer.new()
	celebrate_player = AudioStreamPlayer.new()

	add_child(music_player)
	add_child(sfx_player)
	add_child(anxious_player)
	add_child(kill_player)
	add_child(victory_player)
	add_child(fail_player)
	add_child(coin_player)
	add_child(star_player)
	add_child(celebrate_player)

	music_player.volume_db = -4.0
	sfx_player.volume_db = 0.0
	anxious_player.volume_db = -2.0
	kill_player.volume_db = 0.0
	victory_player.volume_db = 0.0
	fail_player.volume_db = 0.0
	coin_player.volume_db = 0.0
	star_player.volume_db = 0.0
	celebrate_player.volume_db = 0.0

	music_player.stream = BGM
	anxious_player.stream = SFX_BUG_ANXIOUS
	kill_player.stream = SFX_BUG_KILL
	victory_player.stream = SFX_LEVEL_COMPLETE
	fail_player.stream = SFX_LEVEL_FAIL
	coin_player.stream = SFX_COIN
	star_player.stream = SFX_STAR
	celebrate_player.stream = SFX_CELEBRATE

	# Loop music cleanly on all platforms
	music_player.finished.connect(_restart_music)
	if _is_music_enabled():
		music_player.call_deferred("play")

func _restart_music() -> void:
	if _is_music_enabled() and is_instance_valid(music_player) and music_player.is_inside_tree():
		music_player.call_deferred("play")

func set_music_enabled(enabled: bool) -> void:
	if not is_instance_valid(music_player):
		return
	if enabled and not music_player.playing:
		if music_player.is_inside_tree():
			music_player.play()
		else:
			music_player.call_deferred("play")
	elif not enabled:
		music_player.stop()

# 1. Bug Splat Kill Sound
func play_bug_kill() -> void:
	if _is_sfx_enabled() and is_instance_valid(kill_player):
		if kill_player.is_inside_tree():
			kill_player.play()
		else:
			kill_player.call_deferred("play")

# 2. Bugs Celebrate Victory Sound
func play_bug_celebrate() -> void:
	stop_bug_anxious()
	if _is_sfx_enabled() and is_instance_valid(celebrate_player):
		if celebrate_player.is_inside_tree():
			celebrate_player.play()
		else:
			celebrate_player.call_deferred("play")

# 3. Bug Anxious Sound (when player's falling shape/bar comes near bugs)
func play_bug_anxious() -> void:
	if _is_sfx_enabled() and is_instance_valid(anxious_player):
		if not anxious_player.playing:
			if anxious_player.is_inside_tree():
				anxious_player.play()
			else:
				anxious_player.call_deferred("play")

func stop_bug_anxious() -> void:
	if is_instance_valid(anxious_player) and anxious_player.playing:
		anxious_player.stop()

# 4. Coin Reward Sound
func play_coin() -> void:
	if _is_sfx_enabled() and is_instance_valid(coin_player):
		if coin_player.is_inside_tree():
			coin_player.play()
		else:
			coin_player.call_deferred("play")

# 5. Star Sound
func play_star(_pitch: float = 1.0) -> void:
	if _is_sfx_enabled() and is_instance_valid(star_player):
		if star_player.is_inside_tree():
			star_player.play()
		else:
			star_player.call_deferred("play")

# 6. Level Complete Sound
func play_victory() -> void:
	stop_bug_anxious()
	if _is_sfx_enabled() and is_instance_valid(victory_player):
		if victory_player.is_inside_tree():
			victory_player.play()
		else:
			victory_player.call_deferred("play")

# 7. Level Fail Sound
func play_fail() -> void:
	stop_bug_anxious()
	if _is_sfx_enabled() and is_instance_valid(fail_player):
		if fail_player.is_inside_tree():
			fail_player.play()
		else:
			fail_player.call_deferred("play")

# Legacy aliases for UI button and place tones
func play_place(correct: bool) -> void:
	if correct:
		play_bug_kill()
	else:
		play_fail()

func play_button() -> void:
	play_star()

func play_error() -> void:
	play_fail()

func play_undo() -> void:
	play_coin()

func play_hint() -> void:
	play_button()
