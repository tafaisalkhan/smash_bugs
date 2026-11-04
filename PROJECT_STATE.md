# Math Mind project state

Updated: 2026-10-23. This file is a handoff for the next agent working in this folder.

## Current user direction

- The user wants the menu and related screens to look like complete PNG artwork. Headings, panels, and buttons are painted into the PNGs. Transparent Godot buttons are used only as tap areas; changing values remain live text.
- The user approved the current bold, readable font treatment after seeing rendered menu, shop, and reward screenshots.
- The project currently supports portrait UI. The user asked how landscape would work and explicitly requested a solution only, with no implementation. The answer given was: keep the data and actions, create separate 16:9 PNGs, and switch textures plus text/tap coordinates by orientation. **Do not implement landscape unless asked.**
- Temporary previews and unused image drafts were deleted at the user's request.

## Project and entry points

- Godot 4.7.2 project, portrait viewport **540 × 960**, `canvas_items` stretch. See `project.godot`.
- Godot executable on this machine: `C:\Users\Supreme Traders\Downloads\Godot_Engine\Godot_v4.7.2-stable_win64.exe`.
- Main scene is `scenes/splash.tscn`. `scenes/menu.tscn` runs `scripts/menu.gd`, which creates `scenes/ui_suite.tscn` and supplies live game data.
- `scripts/ui_suite.gd` owns navigation and relays signals. `scripts/menu.gd` handles Math Mind actions and persistence through `GameState`.
- This folder has **no `.git` directory**; changes are direct workspace edits.

## Active portrait UI

| Screen | Scene / script | Artwork |
| --- | --- | --- |
| Home | `scenes/ui_screens/home_ui.tscn`, `scripts/ui_screens/textured_home_screen.gd` | `assets/generated/ui/menu-screen.png` |
| Settings | `scenes/ui_screens/settings_ui.tscn`, `scripts/ui_screens/textured_info_screen.gd` | `settings-screen.png` |
| Shop and store | `shop_ui.tscn`, `store_ui.tscn`, `scripts/ui_screens/textured_market_screen.gd` | `shop-screen.png`, `store-screen.png` |
| Missions and leaderboard | `missions_ui.tscn`, `leaderboard_ui.tscn`, `scripts/ui_screens/textured_info_screen.gd` | `missions-screen.png`, `leaderboard-screen.png` |
| General reward | `reward_ui.tscn`, `scripts/ui_screens/textured_reward_screen.gd` | `reward-generic-screen.png`; `level-complete-screen.png` for its COLLECT variant |
| Advanced settings | `scenes/settings.tscn`, `scripts/textured_advanced_settings.gd` | `advanced-settings-screen.png` |
| World selection | `scenes/level_select.tscn`, `scripts/textured_level_select.gd` | `level-select-screen.png` and ice, ocean, mountain, volcano variants |
| Gameplay level complete | `scripts/main.gd` adds an overlay over `scenes/main.tscn` | `level-complete-one-star.png`, `level-complete-two-stars.png`, `level-complete-next-screen.png` |

The artwork filenames in the last column are under `assets/generated/ui/`. The live labels use `resources/ui_overlay_font.tres`, based on `LuckiestGuy-Regular.ttf`, with font outlines. The artwork fills each screen; tap regions and labels use normalized coordinates in their scripts. `docs/UI_SUITE.md` describes the suite API and data keys.

The older `scenes/ui_items/` and their scripts/resources remain as reusable source files, but the active Math Mind screens above use the full-screen PNGs. `menu-button.png` and `settings-button.png` are still referenced by the active home/completion screens, and some item-scene button PNGs remain referenced.

## Functionality and limits

- Menu: play, daily challenge/reward, rewarded coins, settings, shop, store, missions, leaderboard.
- World selection: five PNG variants, swipe or side tap to change worlds, live progress and locked-world handling.
- Advanced settings: live option values and transparent tap regions, saving through `GameState`.
- Shop, store, missions, leaderboard, and reward display live values and use existing suite signals. Store billing and leaderboard sign-in are not connected; `scripts/menu.gd` shows an unavailable reward message for those actions.
- Gameplay completion awards stars and coins via `GameState`, then shows the matching PNG with live level, coin, and streak labels plus next-level/ad tap regions. `scripts/main.gd` still contains unreachable legacy completion animation code after the early `return` in `_play_level_complete_sequence`; the active path is `_show_textured_victory`.
- Gameplay grid, pause/failure UI, and privacy dialog were not rebuilt as full-screen PNGs in this work. Do not claim that every Godot Control in the project is image-based.

## Verification and cleanup

- `node scripts\tools\check_ui_assets.js` passes; it checks screen resource paths, script preloads, PNG headers, and minimum sizes.
- The active screens were rendered with Godot's OpenGL compatibility renderer and inspected. The final menu also launched in headless mode after cleanup. Headless movie capture crashed in Godot's dummy renderer, so use the normal renderer for captures.
- This sandbox cannot write Godot's usual user log/cache directory, so Godot may print `user://logs` or editor-cache errors even when the scene runs. Desktop AdManager reports ads disabled, as expected.
- Temporary `.preview-*` files, `docs/ui-previews/`, the preview harness, unused heading/reward image drafts, and replaced legacy settings/world-selection scripts were removed. Do not assume those preview screenshots still exist.

## If work resumes

1. Read the latest user request and `docs/UI_SUITE.md` before changing the UI contract.
2. Keep the portrait PNG artwork as the visible layer and use live text only where game data changes.
3. Run `node scripts\tools\check_ui_assets.js` and open affected scenes with the Godot executable above. For visual captures, use `--rendering-driver opengl3 --write-movie <name>.png --quit-after 2`, then remove temporary captures.
4. If asked for landscape, make separate 16:9 artwork and matching normalized text/tap layouts; reuse the existing data and signal wiring.
