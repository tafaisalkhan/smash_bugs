extends Control

signal screen_requested(screen: String)
signal play_requested
signal daily_challenge_requested
signal daily_reward_requested
signal rewarded_coins_requested

func _ready() -> void:
	%SettingsButton.pressed.connect(func():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_button"): audio.play_button()
		screen_requested.emit("settings")
	)
	%ScoreLink.pressed.connect(func():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_button"): audio.play_button()
		screen_requested.emit("leaderboard")
	)
	%PlayButton.pressed.connect(func():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_button"): audio.play_button()
		play_requested.emit()
	)
	%DailyChallengeButton.pressed.connect(func():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_button"): audio.play_button()
		daily_challenge_requested.emit()
	)
	%DailyRewardButton.pressed.connect(func():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_button"): audio.play_button()
		daily_reward_requested.emit()
	)
	%RewardedButton.pressed.connect(func():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_button"): audio.play_button()
		rewarded_coins_requested.emit()
	)
	%ShopButton.pressed.connect(func():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_button"): audio.play_button()
		screen_requested.emit("shop")
	)
	%StoreButton.pressed.connect(func():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_button"): audio.play_button()
		screen_requested.emit("store")
	)
	%MissionsButton.pressed.connect(func():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_button"): audio.play_button()
		screen_requested.emit("missions")
	)
	%ScoreButton.pressed.connect(func():
		var audio = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_button"): audio.play_button()
		screen_requested.emit("leaderboard")
	)
	if has_node("%DifficultyModeButton"):
		_update_mode_button()
		%DifficultyModeButton.pressed.connect(_on_mode_button_pressed)

func _update_mode_button() -> void:
	if not has_node("%DifficultyModeButton"):
		return
	var state = get_node_or_null("/root/GameState")
	var diff_idx: int = int(state.difficulty_index) if (state and "difficulty_index" in state) else 0
	match diff_idx:
		0:
			%DifficultyModeButton.text = "🎮 DIFFICULTY: 🟢 EASY (CHILD) • TAP TO CHANGE"
		1:
			%DifficultyModeButton.text = "🎮 DIFFICULTY: 🔵 MEDIUM • TAP TO CHANGE"
		2:
			%DifficultyModeButton.text = "🎮 DIFFICULTY: 🔴 HARD • TAP TO CHANGE"
		_:
			%DifficultyModeButton.text = "🎮 DIFFICULTY: 🟢 EASY • TAP TO CHANGE"

func _on_mode_button_pressed() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_button"): audio.play_button()
	var state = get_node_or_null("/root/GameState")
	if state and state.has_method("set_difficulty"):
		var next_diff: int = (int(state.difficulty_index) + 1) % 3
		state.set_difficulty(next_diff)
	_update_mode_button()

func set_data(data: Dictionary, title: String, tagline: String, score_title: String, score_unit: String) -> void:
	_update_mode_button()
	%TitleLabel.text = title
	%TaglineLabel.text = tagline
	%ScoreCaption.text = score_title
	%ScoreLabel.text = "%d" % int(data.get("best_score", 0))
	%ScoreUnit.text = score_unit.strip_edges()
	%ScoreUnit.visible = not score_unit.strip_edges().is_empty()
	%CoinLabel.text = "●  %d" % int(data.get("coins", 0))
	%StarLabel.text = "★  %d" % int(data.get("stars", 0))
	var ready := bool(data.get("daily_reward_available", true))
	%RewardIcon.text = "🎁" if ready else "✓"
	%RewardTitle.text = "Daily Reward Ready" if ready else "Reward Claimed"
	%RewardSubtitle.text = "Claim %d coins now" % int(data.get("daily_reward_amount", 10)) if ready else "Come back tomorrow"
	%RewardArrow.visible = ready
	%DailyRewardButton.tooltip_text = "Claim today's daily reward" if ready else "Daily reward already claimed"
	%DailyRewardButton.disabled = not ready
	%DailyChallengeButton.visible = bool(data.get("show_daily_challenge", false))
	%RewardedButton.text = str(data.get("rewarded_label", "▶  Watch Ad · Get 3 Boosts"))

func show_message(message: String) -> void:
	%MessageLabel.text = message

func set_background_tint(tint: Color) -> void:
	%Background.modulate = tint
