# Ten blue-brick physics levels

The current level slice is stored in `assets/data/smash_level_types.json` and
contains ten fixed, manually authored puzzles for visual and gameplay review:

- Easy 1: direct gravity drop.
- Easy 2: trigger a boulder on an angled ramp.
- Medium 1: reach three targets at different heights.
- Hard 1: cross a divided corridor while protecting a bee.
- Medium 2: navigate an offset side pocket around a protected bee.
- Medium 3: redirect a falling ball through two target heights.
- Hard 2: deflect a heavy ball around a central wall.
- Hard 3: climb a wind-powered staircase.
- Hard 4: strike targets with a player-created pendulum shape.
- Hard 5: clear three targets while protecting three bees.

The JSON contains the complete platform, physics object, joint, bug, hint, and
solution data. The catalog maps Easy, Medium, and Hard independently. Procedural
generation is intentionally not used.

`scripts/tools/test_catalog_modes.gd` idles each level before drawing to detect
automatic wins, then executes its authored solution with the normal drawn-body
physics. A level passes only when every enemy dies and every friendly bee lives.
