extends Control

const UISuiteScene = preload("res://scenes/ui_suite.tscn")
const Palette = preload("res://scripts/ui_palette.gd")
const PrivacyDialogScene = preload("res://scenes/privacy_dialog.tscn")
const GAME_SCENE_PATH := "res://scenes/smash/SmashGame.tscn"

var ui: GameUISuite
var _reward_callback: Callable
var _unavailable_callback: Callable
var _ad_pending := false
var _loading_scene := false
var _loading_overlay: Control
var _loading_bar: ProgressBar
var _loading_label: Label

func _ready() -> void:
	ui = UISuiteScene.instantiate()
	ui.game_title = "SMASH FLIES"
	ui.tagline = "DRAW TO CRUSH"
	ui.score_title = "LEVELS CLEARED"
	add_child(ui)
	ui.play_requested.connect(_play)
	ui.daily_challenge_requested.connect(_daily_challenge)
	ui.daily_reward_requested.connect(_daily_reward)
	ui.rewarded_coins_requested.connect(_watch_reward_ad)
	ui.setting_changed.connect(_setting_changed)
	ui.settings_action_requested.connect(_settings_action)
	ui.shop_action_requested.connect(_shop_action)
	ui.purchase_requested.connect(_purchase_requested)
	ui.mission_claim_requested.connect(_claim_mission)
	ui.leaderboard_signin_requested.connect(_leaderboard_signin)
	ui.privacy_requested.connect(_open_privacy)
	ResourceLoader.load_threaded_request(GAME_SCENE_PATH)
	_refresh_ui()
	var ad_mgr = get_node_or_null("/root/AdManager")
	if ad_mgr and ad_mgr.has_method("show_banner"):
		ad_mgr.show_banner()
	_init_google_play_billing()
	var state = _get_game_state()
	if not state or not state.privacy_accepted or state.show_privacy_on_start:
		_open_privacy()

func _get_game_state() -> Node:
	if is_inside_tree():
		var s = get_node_or_null("/root/GameState")
		if s: return s
	var p = get_parent()
	if p:
		var s = p.get_node_or_null("GameState")
		if s: return s
	return null

func _open_privacy() -> void:
	var privacy := PrivacyDialogScene.instantiate()
	add_child(privacy)

func _refresh_ui() -> void:
	ui.set_background_tint(Palette.color_for(GameState.selected_theme))
	var themed_items: Array = []
	for theme_data in Palette.THEMES:
		var theme_id := str(theme_data["id"])
		themed_items.append({
			"id": theme_id,
			"name": theme_id,
			"category": "Themes",
			"icon": "◆",
			"color": theme_data["color"],
			"cost": theme_data["price"],
			"owned": GameState.owned_themes.has(theme_id),
			"equipped": GameState.selected_theme == theme_id
		})
	var mission_data: Array = []
	for definition in [
		{"id": "play_one", "name": "Complete 1 level", "target": 1, "reward": 15},
		{"id": "earn_three_stars", "name": "Earn 3 stars", "target": 3, "reward": 20},
		{"id": "play_three", "name": "Complete 3 levels", "target": 3, "reward": 25}
	]:
		var progress := GameState.daily_mission_progress(str(definition["id"]))
		mission_data.append({
			"id": definition["id"],
			"name": definition["name"],
			"target": definition["target"],
			"reward": definition["reward"],
			"progress": progress,
			"complete": progress >= int(definition["target"]),
			"claimed": GameState.claimed_missions.has(str(definition["id"]))
		})
	ui.update_data({
		"coins": GameState.coins,
		"stars": GameState.total_stars,
		"best_score": maxi(0, GameState.highest_level - 1),
		"daily_reward_available": GameState.can_claim_daily_reward(),
		"daily_reward_amount": 10,
		"show_daily_challenge": true,
		"rewarded_label": "▶  Watch Ad · Get 10 Coins",
		"settings_options": [
			{"id": "music", "label": "Music", "enabled": GameState.music_enabled},
			{"id": "sound", "label": "Sound Effects", "enabled": GameState.sfx_enabled}
		],
		"settings_actions": [
			{
				"id": "remove_ads",
				"label": "Remove Ads" if not GameState.ads_removed else "Ads Removed ✓",
				"button_text": "BUY $4.99" if not GameState.ads_removed else "OWNED",
				"button_color": Color("#ff9800") if not GameState.ads_removed else Color("#4caf50")
			}
		],
		"shop_items": themed_items,
		"store_products": [
			{
				"id": "remove_ads",
				"name": "Remove Ads" if not GameState.ads_removed else "Ads Removed",
				"description": "No Banner or Interstitial Ads" if not GameState.ads_removed else "Owned",
				"price": "$4.99" if not GameState.ads_removed else "OWNED"
			},
			{"id": "coins_500", "name": "Pouch of Coins", "description": "500 coins", "price": "Price in Google Play"},
			{"id": "coins_1200", "name": "Starter Bundle", "description": "1,200 coins", "price": "Price in Google Play"},
			{"id": "coins_3000", "name": "Bag of Coins", "description": "3,000 coins", "price": "Price in Google Play"}
		],
		"missions": mission_data,
		"leaderboard_signed_in": false
	})

func _play() -> void:
	_open_game_scene()

func _open_game_scene() -> void:
	if _loading_scene:
		return
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(GAME_SCENE_PATH, progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed := ResourceLoader.load_threaded_get(GAME_SCENE_PATH) as PackedScene
		if packed:
			get_tree().change_scene_to_packed(packed)
			return
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE or status == ResourceLoader.THREAD_LOAD_FAILED:
		ResourceLoader.load_threaded_request(GAME_SCENE_PATH)
	_loading_scene = true
	_show_loading_overlay()

func _show_loading_overlay() -> void:
	if not is_instance_valid(_loading_overlay):
		_loading_overlay = Control.new()
		_loading_overlay.z_index = 400
		_loading_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		var dimmer := ColorRect.new()
		dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
		dimmer.color = Color(0.08, 0.12, 0.16, 0.78)
		dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
		_loading_overlay.add_child(dimmer)

		var panel := PanelContainer.new()
		panel.anchor_left = 0.5
		panel.anchor_top = 0.5
		panel.anchor_right = 0.5
		panel.anchor_bottom = 0.5
		panel.offset_left = -160.0
		panel.offset_top = -65.0
		panel.offset_right = 160.0
		panel.offset_bottom = 65.0
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#182433")
		style.border_color = Color("#587596")
		style.set_border_width_all(2)
		style.set_corner_radius_all(18)
		panel.add_theme_stylebox_override("panel", style)
		dimmer.add_child(panel)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 24)
		margin.add_theme_constant_override("margin_top", 20)
		margin.add_theme_constant_override("margin_right", 24)
		margin.add_theme_constant_override("margin_bottom", 20)
		panel.add_child(margin)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 12)
		margin.add_child(vbox)

		_loading_label = Label.new()
		_loading_label.text = "Loading..."
		_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_loading_label.add_theme_font_size_override("font_size", 20)
		_loading_label.add_theme_color_override("font_color", Color.WHITE)
		vbox.add_child(_loading_label)

		_loading_bar = ProgressBar.new()
		_loading_bar.min_value = 0.0
		_loading_bar.max_value = 100.0
		_loading_bar.value = 10.0
		_loading_bar.show_percentage = false
		_loading_bar.custom_minimum_size = Vector2(0.0, 18.0)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color("#26384d")
		bg.set_corner_radius_all(9)
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color("#69d275")
		fill.set_corner_radius_all(9)
		_loading_bar.add_theme_stylebox_override("background", bg)
		_loading_bar.add_theme_stylebox_override("fill", fill)
		vbox.add_child(_loading_bar)
		add_child(_loading_overlay)
	_loading_overlay.visible = true

func _process(_delta: float) -> void:
	if not _loading_scene:
		return
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(GAME_SCENE_PATH, progress)
	if is_instance_valid(_loading_bar) and not progress.is_empty():
		_loading_bar.value = clampf(float(progress[0]) * 100.0, 10.0, 100.0)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_loading_scene = false
		var packed := ResourceLoader.load_threaded_get(GAME_SCENE_PATH) as PackedScene
		if packed:
			get_tree().change_scene_to_packed(packed)
			return
		get_tree().change_scene_to_file(GAME_SCENE_PATH)
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_loading_scene = false
		get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _daily_challenge() -> void:
	GameState.start_mode("daily")
	_open_game_scene()

func _daily_reward() -> void:
	_watch_reward_ad()

func _watch_reward_ad() -> void:
	_play_rewarded_ad(Callable(self, "_grant_ad_reward"))

func _play_rewarded_ad(on_completed: Callable) -> void:
	if _ad_pending:
		return
	_ad_pending = true
	_reward_callback = on_completed
	_unavailable_callback = Callable(self, "_ad_unavailable")
	AdManager.rewarded_video_completed.connect(_reward_callback, CONNECT_ONE_SHOT)
	AdManager.rewarded_video_unavailable.connect(_unavailable_callback, CONNECT_ONE_SHOT)
	AdManager.show_rewarded_video()

func _finish_rewarded_ad_success() -> void:
	_ad_pending = false
	if AdManager.rewarded_video_unavailable.is_connected(_unavailable_callback):
		AdManager.rewarded_video_unavailable.disconnect(_unavailable_callback)

func _grant_ad_reward() -> void:
	_finish_rewarded_ad_success()
	GameState.coins += 10
	GameState.save_progress()
	_refresh_ui()
	ui.show_reward("Bonus Coins", 10, "Thanks for watching!")

func _ad_unavailable(message: String) -> void:
	_ad_pending = false
	if AdManager.rewarded_video_completed.is_connected(_reward_callback):
		AdManager.rewarded_video_completed.disconnect(_reward_callback)
	ui.show_message(message)

func _setting_changed(id: String, enabled: bool) -> void:
	match id:
		"difficulty":
			_refresh_ui()
		"music":
			GameState.music_enabled = enabled
			AudioManager.set_music_enabled(enabled)
		"sound": GameState.sfx_enabled = enabled
	GameState.save_progress()

const REMOVE_ADS_PRODUCT_ID := "remove_ads"
var _billing: Object = null
var _billing_connected := false

func _init_google_play_billing() -> void:
	if not Engine.has_singleton("GodotGooglePlayBilling"):
		return
	_billing = Engine.get_singleton("GodotGooglePlayBilling")
	if _billing.has_signal("connected"):
		_billing.connect("connected", Callable(self, "_on_billing_connected"))
	if _billing.has_signal("purchases_updated"):
		_billing.connect("purchases_updated", Callable(self, "_on_purchases_updated"))
	if _billing.has_signal("purchase_error"):
		_billing.connect("purchase_error", Callable(self, "_on_purchase_error"))
	if _billing.has_signal("query_purchases_response"):
		_billing.connect("query_purchases_response", Callable(self, "_on_query_purchases_response"))
	if _billing.has_method("startConnection"):
		_billing.startConnection()

func _on_billing_connected() -> void:
	_billing_connected = true
	if _billing and _billing.has_method("querySkuDetails"):
		_billing.querySkuDetails([REMOVE_ADS_PRODUCT_ID], "inapp")
	if _billing and _billing.has_method("queryPurchases"):
		_billing.queryPurchases("inapp")

func _on_query_purchases_response(result: Dictionary) -> void:
	if int(result.get("status", -1)) != OK:
		return
	_handle_billing_purchases(result.get("purchases", []))

func _on_purchases_updated(purchases: Array) -> void:
	_handle_billing_purchases(purchases)

func _handle_billing_purchases(purchases: Array) -> void:
	for p in purchases:
		if not p is Dictionary:
			continue
		var sku := str(p.get("sku", p.get("product", "")))
		var products: Array = p.get("products", [])
		var matches_remove_ads := (sku == REMOVE_ADS_PRODUCT_ID) or products.has(REMOVE_ADS_PRODUCT_ID)
		if matches_remove_ads and int(p.get("purchase_state", 1)) == 1:
			if not bool(p.get("is_acknowledged", true)) and _billing and _billing.has_method("acknowledgePurchase"):
				_billing.acknowledgePurchase(str(p.get("purchase_token", "")))
			if not GameState.ads_removed:
				_complete_remove_ads_purchase()

func _on_purchase_error(_code: int, message: String) -> void:
	ui.show_message("Google Play purchase failed: %s" % message)

func _complete_remove_ads_purchase() -> void:
	GameState.ads_removed = true
	GameState.save_progress()
	if is_inside_tree():
		var ad_mgr = get_node_or_null("/root/AdManager")
		if ad_mgr and ad_mgr.has_method("hide_banner"):
			ad_mgr.hide_banner()
	_refresh_ui()
	ui.show_reward("Purchase Successful!", 0, "All ads have been permanently removed! ($4.99)")

func _settings_action(id: String) -> void:
	if id == "advanced":
		get_tree().change_scene_to_file("res://scenes/settings.tscn")
	elif id == REMOVE_ADS_PRODUCT_ID:
		if GameState.ads_removed:
			ui.show_reward("Ads Removed", 0, "Ads are already disabled!")
			return
		if _billing != null and _billing.has_method("purchase"):
			if not _billing_connected and _billing.has_method("startConnection"):
				_billing.startConnection()
			var result = _billing.purchase(REMOVE_ADS_PRODUCT_ID)
			if typeof(result) == TYPE_DICTIONARY and int(result.get("status", OK)) != OK:
				ui.show_message("Google Play purchase cancelled or unavailable.")
			return
		if OS.get_name() == "Android":
			ui.show_message("Google Play Billing plugin is not installed in this build.")
			return
		_complete_remove_ads_purchase()

func _shop_action(id: String) -> void:
	var cost := -1
	for theme_data in Palette.THEMES:
		if str(theme_data["id"]) == id:
			cost = int(theme_data["price"])
			break
	if cost < 0:
		return
	if GameState.owned_themes.has(id):
		GameState.equip_theme(id)
		ui.show_message("%s equipped" % id)
	elif GameState.buy_theme(id, cost):
		ui.show_reward("New Theme", 0, "%s unlocked!" % id)
	else:
		ui.show_reward("Not Enough Coins", 0, "Earn more coins to unlock %s." % id)
	_refresh_ui()

func _purchase_requested(_id: String) -> void:
	if _id == "remove_ads":
		_settings_action("remove_ads")
		return
	ui.show_reward("Store Unavailable", 0, "Google Play Billing is not available yet.")

func _claim_mission(id: String) -> void:
	var definitions := {
		"play_one": [1, 15],
		"earn_three_stars": [3, 20],
		"play_three": [3, 25]
	}
	if not definitions.has(id):
		return
	var definition: Array = definitions[id]
	if GameState.claim_daily_mission(id, int(definition[0]), int(definition[1])):
		_refresh_ui()
		ui.show_reward("Mission Complete", int(definition[1]))

func _leaderboard_signin() -> void:
	ui.show_reward("Leaderboard Unavailable", 0, "Google Play Games sign-in is not connected yet.")

func _exit_tree() -> void:
	if _reward_callback.is_valid() and AdManager.rewarded_video_completed.is_connected(_reward_callback):
		AdManager.rewarded_video_completed.disconnect(_reward_callback)
	if _unavailable_callback.is_valid() and AdManager.rewarded_video_unavailable.is_connected(_unavailable_callback):
		AdManager.rewarded_video_unavailable.disconnect(_unavailable_callback)
