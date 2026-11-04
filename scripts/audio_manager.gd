extends Node

var music_player: AudioStreamPlayer = AudioStreamPlayer.new()
var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
var anxious_player: AudioStreamPlayer = AudioStreamPlayer.new()
var kill_player: AudioStreamPlayer = AudioStreamPlayer.new()
var victory_player: AudioStreamPlayer = AudioStreamPlayer.new()
var fail_player: AudioStreamPlayer = AudioStreamPlayer.new()
var coin_player: AudioStreamPlayer = AudioStreamPlayer.new()
var star_player: AudioStreamPlayer = AudioStreamPlayer.new()
var celebrate_player: AudioStreamPlayer = AudioStreamPlayer.new()

# Preloaded sound resources
var bgm_stream: AudioStream = preload("res://assets/sounds/back_groud_sound.mp3")
var sfx_celebrate: AudioStream = preload("res://assets/sounds/bugs_celebreaty.mp3")
var sfx_bug_kill: AudioStream = preload("res://assets/sounds/bugs_kill.wav")
var sfx_bug_anxious: AudioStream = preload("res://assets/sounds/bug_anxios.mp3")
var sfx_coin: AudioStream = preload("res://assets/sounds/coin_sound.wav")
var sfx_level_complete: AudioStream = preload("res://assets/sounds/level_complete.mp3")
var sfx_level_fail: AudioStream = preload("res://assets/sounds/level_fail.mp3")
var sfx_star: AudioStream = preload("res://assets/sounds/star_sound.mp3")

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

func _init() -> void:
	if bgm_stream is AudioStreamMP3:
		bgm_stream.loop = true
	music_player.stream = bgm_stream
	anxious_player.stream = sfx_bug_anxious
	kill_player.stream = sfx_bug_kill
	victory_player.stream = sfx_level_complete
	fail_player.stream = sfx_level_fail
	coin_player.stream = sfx_coin
	star_player.stream = sfx_star
	celebrate_player.stream = sfx_celebrate
	sfx_player.max_polyphony = 8
	kill_player.max_polyphony = 8
	coin_player.max_polyphony = 8
	star_player.max_polyphony = 8

func _enter_tree() -> void:
	_setup_players()

func _setup_players() -> void:
	for p in [music_player, sfx_player, anxious_player, kill_player, victory_player, fail_player, coin_player, star_player, celebrate_player]:
		if is_instance_valid(p) and not p.is_inside_tree():
			add_child(p)

func _ready() -> void:
	_setup_players()
	update_volumes()

	if not music_player.finished.is_connected(_restart_music):
		music_player.finished.connect(_restart_music)
	if _is_music_enabled():
		ensure_music_playing()

func _process(_delta: float) -> void:
	# Keep background music active if enabled and not currently playing (recovers after sleep/device change)
	if _is_music_enabled() and is_instance_valid(music_player):
		if not music_player.playing:
			music_player.play()

func update_volumes() -> void:
	var state = get_node_or_null("/root/GameState")
	var m_vol: float = 0.8
	var s_vol: float = 0.9
	if state:
		if "music_volume" in state:
			m_vol = clampf(float(state.music_volume), 0.0, 1.0)
		if "sfx_volume" in state:
			s_vol = clampf(float(state.sfx_volume), 0.0, 1.0)
	
	if is_instance_valid(music_player):
		music_player.volume_db = -4.0 if m_vol > 0.5 else (-10.0 if m_vol > 0.0 else -80.0)
	
	var sfx_db: float = 0.0 if s_vol > 0.5 else (-6.0 if s_vol > 0.0 else -80.0)
	for p in [sfx_player, anxious_player, kill_player, victory_player, fail_player, coin_player, star_player, celebrate_player]:
		if is_instance_valid(p):
			p.volume_db = sfx_db

func ensure_music_playing() -> void:
	if _is_music_enabled() and is_instance_valid(music_player):
		if not music_player.playing:
			if music_player.is_inside_tree():
				music_player.play()
			else:
				music_player.call_deferred("play")

func play_music() -> void:
	ensure_music_playing()

func _restart_music() -> void:
	if _is_music_enabled() and is_instance_valid(music_player) and music_player.is_inside_tree():
		music_player.play()

func set_music_enabled(enabled: bool) -> void:
	if not is_instance_valid(music_player):
		return
	if enabled:
		ensure_music_playing()
	else:
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

# UI Button Click Sound
func play_button() -> void:
	play_coin()

func play_place(correct: bool) -> void:
	if correct:
		play_bug_kill()
	else:
		play_fail()

func play_error() -> void:
	play_fail()

func play_undo() -> void:
	play_coin()

func play_hint() -> void:
	play_button()
