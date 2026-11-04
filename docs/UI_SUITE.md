# Reusable game screens

`res://scenes/ui_suite.tscn` is the menu and secondary-screen controller. `scripts/menu.gd` supplies the Math Mind data and actions.

## Edit the visuals

Each visible screen is a portrait PNG in `res://assets/generated/ui/`: `menu-screen.png`, `settings-screen.png`, `shop-screen.png`, `store-screen.png`, `missions-screen.png`, `leaderboard-screen.png`, and `reward-generic-screen.png`. The level-complete screen also has one, two, and three-star variants. The screen scenes in `res://scenes/ui_screens/` display these textures. Their controls are transparent tap regions; live balance, item names, prices, progress, and rewards are text overlays. Edit the PNG to change the visual design and the corresponding `textured_*_screen.gd` file to adjust tap regions or live-text placement.

Gameplay's level-complete overlay is created in `scripts/main.gd` and uses `level-complete-one-star.png`, `level-complete-two-stars.png`, and `level-complete-next-screen.png`. The separate `level-complete-screen.png` supplies the COLLECT variant used by the reusable reward screen.

The separate advanced settings scene uses `advanced-settings-screen.png`. World selection uses five full-screen PNGs (`level-select-screen.png` and the ice, ocean, mountain, and volcano variants); transparent tap regions handle play, back, and world changes. The empty progress capsule holds the live completion count.

Live labels use `res://resources/ui_overlay_font.tres` for a bold display face and outlines so names, prices, progress, and balances stay readable over the artwork.

The older item scenes in `res://scenes/ui_items/` remain for other users of the suite, but the Math Mind menu screens use the full-screen PNGs. The artwork is designed for the project viewport of 540 × 960. Godot scales it to fill portrait screens.

The screen scene references are exported on `ui_suite.tscn`, so a new game can replace any screen without changing the controller script.

## Connect a game

Instantiate `ui_suite.tscn`, set `game_title`, `tagline`, `score_title`, and `score_unit` before adding it to the tree, then connect its signals. `scripts/menu.gd` is a working Math Mind adapter.

```gdscript
var ui = preload("res://scenes/ui_suite.tscn").instantiate()
ui.game_title = "MY GAME"
ui.score_title = "BEST SCORE"
add_child(ui)
ui.play_requested.connect(_start_game)
ui.purchase_requested.connect(_start_verified_purchase)
ui.update_data({"coins": player_coins, "best_score": best_score})
```

The suite emits `play_requested`, `daily_challenge_requested`, `daily_reward_requested`, `rewarded_coins_requested`, `setting_changed(id, enabled)`, `settings_action_requested(id)`, `shop_action_requested(id)`, `purchase_requested(id)`, `mission_claim_requested(id)`, `leaderboard_signin_requested`, `leaderboard_full_requested`, and `privacy_requested`.

`update_data()` accepts `coins`, `stars`, `best_score`, `daily_reward_available`, `daily_reward_amount`, `show_daily_challenge`, `rewarded_label`, `settings_options`, `settings_actions`, `shop_items`, `store_products`, `missions`, `leaderboard_rows`, `leaderboard_user`, and `leaderboard_signed_in`. Missing keys retain their current values. Shop items use `id`, `name`, `category`, `icon`, `color`, `cost`, `owned`, and `equipped`. Store products use `id`, `name`, `description`, and `price`. Missions use `id`, `name`, `target`, `progress`, `reward`, `complete`, and `claimed`. Leaderboard rows use `name`, `score`, and `reward`; the optional user row also uses `rank`.

Call `show_reward(title, coins, detail, stars)` after the game saves a reward. The reward screen displays the saved result but does not change the balance. Connect purchase and leaderboard signals to the game's services. Demo prices and rankings are sample data.
