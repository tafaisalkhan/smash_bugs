class_name SmashLevelGenerator
extends RefCounted
## Unlimited Alphabet & Shape Pattern Level Generator.
##
## Every level challenges the player to draw a specific Alphabet Letter or
## Geometric Pattern ('A', 'C', 'H', 'J', 'L', 'M', 'N', 'O', 'S', 'T', 'U',
## 'V', 'W', 'Y', 'Z', '━', '∩') to smash all bad bugs (beetles, flies,
## mosquitoes) while sparing/protecting all friendly bees!

const VIEW_W := 540.0
const CANVAS_X0 := 20.0        # World X of DrawingCanvas left edge
const CANVAS_W := 500.0
const GROUND_Y := 830.0        # Top surface of the main floor
const FLOOR_H := 160.0
const BUG_HALF := 30.0         # Distance from a surface to a standing bug's center
const MIN_BUG_GAP := 72.0

const ALPHABET_PATTERNS := [
	"A", "C", "H", "J", "L", "M", "N", "O", "S", "T", "U", "V", "W", "Y", "Z"
]

const FLIGHT_MODES := [
	"hover", "patrol", "circle", "zigzag", "figure8", "swoop"
]

static func generate(level: int, is_child: bool = false, difficulty: int = -1) -> Dictionary:
	level = max(level, 1)
	var diff: int = difficulty
	if diff < 0:
		diff = 0 if is_child else 1
	diff = clampi(diff, 0, 2)
	var is_easy: bool = (diff == 0)
	var is_hard: bool = (diff == 2)
	var ink_mult: float = 2.2 if is_easy else (1.05 if is_hard else 1.35)
	var min_ink: float = 450.0 if is_easy else (190.0 if is_hard else 260.0)

	var hand := _handcrafted(level)
	if not hand.is_empty():
		var h_len: float = _calc_pattern_length(hand["hint_pattern"])
		hand["ink"] = maxf(h_len * ink_mult, min_ink)
		var spd_mult: float = 0.65 if is_easy else (1.25 if is_hard else 1.0)
		for b in hand.get("bugs", []):
			if b.has("speed"):
				b["speed"] = maxf(float(b["speed"]) * spd_mult, 0.4)
		hand["is_child_mode"] = is_easy
		hand["difficulty"] = diff
		return hand

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("smash_bugs_alphabet_level_%d" % level)

	# Rotate stage themes across Garden, Jungle, and City
	var themes := ["garden", "jungle", "city"]
	var stage_theme: String = themes[(level / 3) % themes.size()]

	# Pick an Alphabet / Shape pattern deterministically, cycling through all 15 letters
	var pat_idx: int = (level - 9) % ALPHABET_PATTERNS.size()
	var letter: String = ALPHABET_PATTERNS[pat_idx]

	# Procedural horizontal shift (-24..+24 px) and speed scaling
	var dx: float = rng.randf_range(-22.0, 22.0)
	var spd: float = 0.9
	if is_easy:
		spd = clampf(0.65 + float(level) * 0.008, 0.65, 1.15)
	elif is_hard:
		spd = clampf(1.1 + float(level) * 0.02, 1.1, 2.1)
	else:
		spd = clampf(0.9 + float(level) * 0.015, 0.9, 1.75)
	var fly_mode: String = FLIGHT_MODES[level % FLIGHT_MODES.size()]

	var data := _build_alphabet_level(level, letter, stage_theme, dx, spd, fly_mode, rng)

	var pat_len: float = _calc_pattern_length(data["hint_pattern"])
	data["ink"] = maxf(pat_len * ink_mult, min_ink)
	data["is_child_mode"] = is_easy
	data["difficulty"] = diff
	return data

static func _calc_pattern_length(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(pts.size() - 1):
		total += pts[i].distance_to(pts[i + 1])
	return total

# ---------------------------------------------------------------- procedural alphabet builders

static func _build_alphabet_level(
	level: int,
	letter: String,
	theme: String,
	dx: float,
	spd: float,
	fly_mode: String,
	rng: RandomNumberGenerator
) -> Dictionary:
	var d := _empty(level, "pattern_" + letter, theme)
	d["pattern"] = letter
	var floor_style := "moss_stone" if theme != "city" else "brick"
	var ledge_style := "wood_log" if theme == "garden" else ("moss_stone" if theme == "jungle" else "stone")

	match letter:
		"A":
			# Letter 'A': Tent arch over center Friendly Bee; outer legs smash left & right bugs + stone blocks
			d["hint"] = "💡 Pattern 'A': Draw letter 'A' to dome over the Bee and smash the sides!"
			d["hint_pattern"] = _shift_pts([
				Vector2(95, 205), Vector2(250, 38), Vector2(405, 205),
				Vector2(315, 95), Vector2(185, 95)
			], dx)
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, floor_style)
			# Protective cap over the center flower pedestal keeps the Bee safe from the A crossbar
			_add_platform(d, Vector2(270.0 + dx, 730.0), Vector2(86.0, 18.0), 0.0, "flower_pedestal")
			_add_bug(d, Vector2(270.0 + dx, GROUND_Y - BUG_HALF), "bee", "none")
			_add_prop(d, Vector2(155.0 + dx, GROUND_Y - 22.0), "big_triangle", Vector2(44.0, 44.0))
			_add_bug(d, Vector2(115.0 + dx, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(425.0 + dx, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(175.0 + dx, 680.0), "fly", fly_mode, 22.0, spd)
			_add_bug(d, Vector2(365.0 + dx, 680.0), "mosquito", "zigzag", 22.0, spd)

		"C":
			# Letter 'C': Left tilted bouncy mushroom ricochets over center wall; Bee safe under left roof
			d["hint"] = "💡 Pattern 'C': Draw letter 'C' to bounce off the Mushroom 🍄 over the wall!"
			d["hint_pattern"] = _shift_pts([
				Vector2(215, 50), Vector2(115, 50), Vector2(95, 120),
				Vector2(115, 195), Vector2(395, 195)
			], dx * 0.4)
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, floor_style)
			# Roof protecting friendly bee on far-left
			_add_platform(d, Vector2(55.0, 710.0), Vector2(85.0, 22.0), 0.0, ledge_style)
			_add_bug(d, Vector2(45.0, GROUND_Y - BUG_HALF), "bee", "none")
			# Tilted bouncy mushroom + low center wall + movable boulder
			_add_platform(d, Vector2(150.0 + dx * 0.4, 715.0), Vector2(115.0, 38.0), 18.0, "mushroom_bouncy")
			_add_platform(d, Vector2(275.0 + dx * 0.4, 775.0), Vector2(24.0, 110.0), 0.0, floor_style)
			_add_prop(d, Vector2(335.0 + dx * 0.4, GROUND_Y - 24.0), "stone_boulder", Vector2(48.0, 48.0))
			_add_bug(d, Vector2(385.0 + dx * 0.4, 660.0), "mosquito", "hover", 20.0, spd)
			_add_bug(d, Vector2(395.0 + dx * 0.4, GROUND_Y - BUG_HALF), "beetle")

		"H":
			# Letter 'H': Two tall side pillars crush left & right lanes; high crossbar bridges over center Bee
			d["hint"] = "💡 Pattern 'H': Draw letter 'H' to bridge the center Bee and smash both lanes!"
			d["hint_pattern"] = _shift_pts([
				Vector2(105, 205), Vector2(105, 45), Vector2(105, 65),
				Vector2(395, 65), Vector2(395, 45), Vector2(395, 205)
			], dx)
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, floor_style)
			_add_platform(d, Vector2(270.0 + dx, 765.0), Vector2(90.0, 34.0), 0.0, "flower_pedestal")
			_add_bug(d, Vector2(270.0 + dx, 732.0), "bee", "hover", 8.0, 0.8)
			_add_bug(d, Vector2(125.0 + dx, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(415.0 + dx, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(125.0 + dx, 650.0), "fly", "hover", 20.0, spd)
			_add_bug(d, Vector2(415.0 + dx, 650.0), "mosquito", fly_mode, 20.0, spd)

		"J":
			# Letter 'J': Right vertical spine + bottom-center hook; Friendly Bee safe on far-left flower
			d["hint"] = "💡 Pattern 'J': Draw letter 'J' on the right to spare the left Bee!"
			d["hint_pattern"] = _shift_pts([
				Vector2(395, 45), Vector2(395, 195), Vector2(220, 195), Vector2(185, 140)
			], dx * 0.5)
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, floor_style)
			# Protected friendly bee on far-left flower pedestal with canopy shield
			_add_platform(d, Vector2(80.0, 740.0), Vector2(95.0, 34.0), 0.0, "flower_pedestal")
			_add_platform(d, Vector2(80.0, 620.0), Vector2(110.0, 22.0), 0.0, ledge_style)
			_add_bug(d, Vector2(80.0, 705.0), "bee", "hover", 6.0, 0.8)
			# Bad bugs along the 'J' strike path
			_add_bug(d, Vector2(415.0 + dx * 0.5, 640.0), "mosquito", fly_mode, 22.0, spd)
			_add_bug(d, Vector2(415.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(265.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(215.0 + dx * 0.5, 735.0), "fly", "hover", 18.0, spd)

		"L":
			# Letter 'L': Left vertical spine + bottom sweep; Friendly Bee safe on far-right flower
			d["hint"] = "💡 Pattern 'L': Draw letter 'L' to smash left & center bugs while sparing the right Bee!"
			d["hint_pattern"] = _shift_pts([
				Vector2(100, 45), Vector2(100, 195), Vector2(315, 195)
			], dx * 0.5)
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, floor_style)
			# Friendly bee on far-right flower with overhead leaf shield
			_add_platform(d, Vector2(460.0, 740.0), Vector2(95.0, 34.0), 0.0, "flower_pedestal")
			_add_platform(d, Vector2(460.0, 620.0), Vector2(110.0, 22.0), 0.0, ledge_style)
			_add_bug(d, Vector2(460.0, 705.0), "bee", "hover", 6.0, 0.8)
			# Movable stone block pushed by the 'L' sweep
			_add_prop(d, Vector2(215.0 + dx * 0.5, GROUND_Y - 22.0), "stone_block", Vector2(44.0, 44.0))
			# Bad bugs along the 'L' strike path
			_add_bug(d, Vector2(120.0 + dx * 0.5, 640.0), "fly", fly_mode, 22.0, spd)
			_add_bug(d, Vector2(120.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(285.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")

		"M":
			# Letter 'M': Two high arches protect 2 Friendly Bees; 3 downward legs crush 3 bad bugs!
			d["hint"] = "💡 Pattern 'M': Draw letter 'M' to arch over 2 Bees and crush 3 bad bugs!"
			d["hint_pattern"] = _shift_pts([
				Vector2(65, 205), Vector2(155, 38), Vector2(250, 205),
				Vector2(345, 38), Vector2(435, 205)
			], dx * 0.5)
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, floor_style)
			# 2 Friendly Bees under the two high peaks of 'M'
			_add_platform(d, Vector2(175.0 + dx * 0.5, 775.0), Vector2(72.0, 30.0), 0.0, "flower_pedestal")
			_add_bug(d, Vector2(175.0 + dx * 0.5, 745.0), "bee", "hover", 6.0, 0.8)
			_add_platform(d, Vector2(365.0 + dx * 0.5, 775.0), Vector2(72.0, 30.0), 0.0, "flower_pedestal")
			_add_bug(d, Vector2(365.0 + dx * 0.5, 745.0), "bee", "hover", 6.0, 0.8)
			# 3 Bad Bugs at the 3 low tips of 'M'
			_add_bug(d, Vector2(85.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(270.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(455.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")

		"N":
			# Letter 'N': Left leg + high diagonal + right leg; Bee sheltered under left arch
			d["hint"] = "💡 Pattern 'N': Draw letter 'N' to arch over the left Bee and strike both sides!"
			d["hint_pattern"] = _shift_pts([
				Vector2(85, 205), Vector2(85, 42), Vector2(395, 205), Vector2(395, 42)
			], dx * 0.5)
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, floor_style)
			# Roofed sanctuary under the left-center arch of 'N'
			_add_platform(d, Vector2(190.0 + dx * 0.5, 725.0), Vector2(90.0, 20.0), 0.0, ledge_style)
			_add_bug(d, Vector2(190.0 + dx * 0.5, GROUND_Y - BUG_HALF), "bee", "none")
			# Bad bugs on left column, diagonal, and right column
			_add_bug(d, Vector2(105.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(300.0 + dx * 0.5, 680.0), "mosquito", fly_mode, 20.0, spd)
			_add_bug(d, Vector2(415.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")

		"O":
			# Letter 'O': Closed circle wheel rolls down slanted log ramp and knocks the boulder into the pit!
			d["hint"] = "💡 Pattern 'O': Draw a round 'O' wheel to roll down the ramp and push the Stone 🪨!"
			var c_pts := PackedVector2Array()
			for i in range(25):
				var a := float(i) * TAU / 24.0
				c_pts.append(Vector2(115.0 + dx * 0.2, 110.0) + Vector2(cos(a), sin(a)) * 48.0)
			d["hint_pattern"] = c_pts
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, floor_style)
			# Long slanted ramp launches the rolling 'O' wheel cleanly under the high right roof across both beetles!
			_add_platform(d, Vector2(185.0, 705.0), Vector2(280.0, 22.0), 24.0, ledge_style)
			_add_bug(d, Vector2(75.0, GROUND_Y - BUG_HALF), "bee", "none")
			# High shelter roof on right blocks vertical drops, but lets the rolling 'O' & stone boulder pass underneath!
			_add_platform(d, Vector2(420.0, 560.0), Vector2(180.0, 22.0), 0.0, ledge_style)
			_add_prop(d, Vector2(315.0, GROUND_Y - 24.0), "stone_boulder", Vector2(48.0, 48.0))
			_add_bug(d, Vector2(365.0, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(430.0, GROUND_Y - BUG_HALF), "beetle")

		"S":
			# Letter 'S': Stepped cascade with sheltered Bee under upper-left terrace + rolling log
			d["hint"] = "💡 Pattern 'S': Draw letter 'S' to sweep the upper shelf, log, and lower floor!"
			d["hint_pattern"] = _shift_pts([
				Vector2(360, 50), Vector2(130, 50), Vector2(130, 120),
				Vector2(370, 120), Vector2(370, 195), Vector2(140, 195)
			], dx * 0.5)
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, floor_style)
			# Upper-left shelf shields the friendly bee on the far-left floor
			_add_platform(d, Vector2(80.0, 680.0), Vector2(120.0, 22.0), 0.0, ledge_style)
			_add_bug(d, Vector2(65.0, GROUND_Y - BUG_HALF), "bee", "none")
			_add_prop(d, Vector2(295.0 + dx * 0.5, GROUND_Y - 22.0), "log_roller", Vector2(44.0, 44.0))
			# Bad bugs along S path
			_add_bug(d, Vector2(270.0 + dx * 0.5, 650.0), "mosquito", fly_mode, 35.0, spd)
			_add_bug(d, Vector2(220.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(380.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")

		"T":
			# Letter 'T': Single-stroke T plunges down center chute while 2 Bees sit safely on side flowers
			d["hint"] = "💡 Pattern 'T': Draw letter 'T' to drop down the center chute and spare both Bees!"
			d["hint_pattern"] = _shift_pts([
				Vector2(105, 42), Vector2(395, 42), Vector2(260, 42),
				Vector2(250, 215), Vector2(240, 42)
			], dx * 0.5)
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, floor_style)
			# Left & Right friendly bees on flower pedestals
			_add_platform(d, Vector2(95.0, 740.0), Vector2(90.0, 34.0), 0.0, "flower_pedestal")
			_add_bug(d, Vector2(95.0, 705.0), "bee", "hover", 6.0, 0.8)
			_add_platform(d, Vector2(445.0, 740.0), Vector2(90.0, 34.0), 0.0, "flower_pedestal")
			_add_bug(d, Vector2(445.0, 705.0), "bee", "hover", 6.0, 0.8)
			# Low chute walls allow the 173px T-stem to reach the floor beetle before catching the crossbar
			_add_platform(d, Vector2(205.0 + dx * 0.5, 765.0), Vector2(20.0, 130.0), 0.0, ledge_style)
			_add_platform(d, Vector2(335.0 + dx * 0.5, 765.0), Vector2(20.0, 130.0), 0.0, ledge_style)
			_add_bug(d, Vector2(270.0 + dx * 0.5, 510.0), "fly", "circle", 30.0, spd)
			_add_bug(d, Vector2(270.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")

		"U":
			# Letter 'U': Deep cradle hits high side flies and bottom center pit; outer Bees protected
			d["hint"] = "💡 Pattern 'U': Draw a deep 'U' cradle to hit the high flies and center pit!"
			d["hint_pattern"] = _shift_pts([
				Vector2(135, 45), Vector2(150, 195), Vector2(350, 195), Vector2(365, 45)
			], dx * 0.4)
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, floor_style)
			# Outer canopy shields for friendly bees
			_add_platform(d, Vector2(55.0, 680.0), Vector2(85.0, 22.0), 0.0, ledge_style)
			_add_bug(d, Vector2(50.0, GROUND_Y - BUG_HALF), "bee", "none")
			_add_platform(d, Vector2(485.0, 680.0), Vector2(85.0, 22.0), 0.0, ledge_style)
			_add_bug(d, Vector2(490.0, GROUND_Y - BUG_HALF), "bee", "none")
			# Bad bugs in the U path
			_add_bug(d, Vector2(165.0 + dx * 0.4, 640.0), "fly", "hover", 20.0, spd)
			_add_bug(d, Vector2(375.0 + dx * 0.4, 640.0), "mosquito", fly_mode, 20.0, spd)
			_add_bug(d, Vector2(270.0 + dx * 0.4, GROUND_Y - BUG_HALF), "beetle")

		"V":
			# Letter 'V': Sharp V-wedge stabs center floor and mid-slopes while sparing 2 side Bees!
			d["hint"] = "💡 Pattern 'V': Draw a sharp 'V' wedge to strike the center and spare side Bees!"
			d["hint_pattern"] = _shift_pts([
				Vector2(90, 42), Vector2(250, 208), Vector2(410, 42)
			], dx * 0.5)
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, floor_style)
			# 2 Friendly Bees under the high outer wings of 'V'
			_add_platform(d, Vector2(105.0 + dx * 0.5, 775.0), Vector2(80.0, 32.0), 0.0, "flower_pedestal")
			_add_bug(d, Vector2(105.0 + dx * 0.5, 742.0), "bee", "hover", 6.0, 0.8)
			_add_platform(d, Vector2(435.0 + dx * 0.5, 775.0), Vector2(80.0, 32.0), 0.0, "flower_pedestal")
			_add_bug(d, Vector2(435.0 + dx * 0.5, 742.0), "bee", "hover", 6.0, 0.8)
			# Bad bugs along V vertex and slopes
			_add_bug(d, Vector2(270.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(195.0 + dx * 0.5, 680.0), "fly", "hover", 16.0, spd)
			_add_bug(d, Vector2(345.0 + dx * 0.5, 680.0), "mosquito", "hover", 16.0, spd)

		"W":
			# Letter 'W': Two deep valleys smash left & right pits while center peak domes over Friendly Bee!
			d["hint"] = "💡 Pattern 'W': Draw letter 'W' to dome over the center Bee and hit both valleys!"
			d["hint_pattern"] = _shift_pts([
				Vector2(65, 45), Vector2(155, 205), Vector2(250, 42),
				Vector2(345, 205), Vector2(435, 45)
			], dx * 0.5)
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, floor_style)
			# Center Friendly Bee under the center peak of 'W'
			_add_platform(d, Vector2(270.0 + dx * 0.5, 775.0), Vector2(82.0, 32.0), 0.0, "flower_pedestal")
			_add_bug(d, Vector2(270.0 + dx * 0.5, 742.0), "bee", "hover", 6.0, 0.8)
			# Bad bugs in the two deep valleys of 'W'
			_add_bug(d, Vector2(175.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(365.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(95.0 + dx * 0.5, 650.0), "fly", "hover", 18.0, spd)
			_add_bug(d, Vector2(445.0 + dx * 0.5, 650.0), "mosquito", fly_mode, 18.0, spd)

		"Y":
			# Letter 'Y': Forked upper arms catch high flies, center stem plunges between 2 Friendly Bees
			d["hint"] = "💡 Pattern 'Y': Draw letter 'Y' to catch high flies and plunge down the center!"
			d["hint_pattern"] = _shift_pts([
				Vector2(110, 45), Vector2(250, 125), Vector2(250, 208),
				Vector2(250, 125), Vector2(390, 45)
			], dx * 0.5)
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, floor_style)
			# 2 Friendly Bees on lower-left and lower-right flowers
			_add_platform(d, Vector2(115.0 + dx * 0.5, 775.0), Vector2(82.0, 32.0), 0.0, "flower_pedestal")
			_add_bug(d, Vector2(115.0 + dx * 0.5, 742.0), "bee", "hover", 6.0, 0.8)
			_add_platform(d, Vector2(425.0 + dx * 0.5, 775.0), Vector2(82.0, 32.0), 0.0, "flower_pedestal")
			_add_bug(d, Vector2(425.0 + dx * 0.5, 742.0), "bee", "hover", 6.0, 0.8)
			# Center beetle + 2 upper-wing flies
			_add_bug(d, Vector2(270.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(150.0 + dx * 0.5, 590.0), "fly", "hover", 15.0, spd)
			_add_bug(d, Vector2(390.0 + dx * 0.5, 590.0), "mosquito", "hover", 15.0, spd)

		_: # "Z"
			# Letter 'Z': Top bar, diagonal slash, bottom bar; Friendly Bee under left overhang + heavy hexagon stone
			d["hint"] = "💡 Pattern 'Z': Draw letter 'Z' to sweep the sky, stone & floor while sparing the Bee!"
			d["hint_pattern"] = _shift_pts([
				Vector2(120, 50), Vector2(385, 50), Vector2(135, 195), Vector2(395, 195)
			], dx * 0.5)
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, floor_style)
			# Left overhang shields friendly bee
			_add_platform(d, Vector2(65.0, 680.0), Vector2(95.0, 22.0), 0.0, ledge_style)
			_add_bug(d, Vector2(55.0, GROUND_Y - BUG_HALF), "bee", "none")
			_add_prop(d, Vector2(290.0 + dx * 0.5, GROUND_Y - 24.0), "heavy_hexagon", Vector2(48.0, 48.0))
			# Bad bugs along Z
			_add_bug(d, Vector2(270.0 + dx * 0.5, 620.0), "mosquito", fly_mode, 35.0, spd)
			_add_bug(d, Vector2(180.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(395.0 + dx * 0.5, GROUND_Y - BUG_HALF), "beetle")

	return d

static func _shift_pts(pts: Array, dx: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		var v: Vector2 = p
		out.append(Vector2(clampf(v.x + dx, 25.0, CANVAS_W - 25.0), v.y))
	return out

# ---------------------------------------------------------------- handcrafted levels (1-8)

static func _handcrafted(level: int) -> Dictionary:
	match level:
		1:
			var d := _empty(1, "tutorial_straight", "city")
			d["pattern"] = "━"
			d["hint"] = "💡 Pattern '━': Draw a straight line or heavy block to drop!"
			d["hint_pattern"] = PackedVector2Array([Vector2(160, 110), Vector2(340, 110)])
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, "brick")
			_add_bug(d, Vector2(VIEW_W * 0.5, GROUND_Y - BUG_HALF), "beetle")
			d["ink"] = 1200.0
			return d

		2:
			# Two towers with a center gap: straight line falls in gap! Player must draw wide bridge ━
			var d := _empty(2, "tutorial_bridge", "city")
			d["pattern"] = "I"
			d["hint"] = "💡 Pattern '━': Draw a wide bar ━ to span across both towers!"
			d["hint_pattern"] = PackedVector2Array([Vector2(60, 100), Vector2(440, 100)])
			_add_platform(d, Vector2(130.0, GROUND_Y - 75.0), Vector2(160.0, 150.0), 0.0, "brick")
			_add_platform(d, Vector2(410.0, GROUND_Y - 75.0), Vector2(160.0, 150.0), 0.0, "brick")
			_add_floor(d, 0.0, VIEW_W, GROUND_Y + 70.0, "brick")
			_add_bug(d, Vector2(130.0, GROUND_Y - 150.0 - BUG_HALF), "beetle")
			_add_bug(d, Vector2(410.0, GROUND_Y - 150.0 - BUG_HALF), "beetle")
			d["ink"] = 1200.0
			return d

		3:
			# Level 3: Letter 'L' (L-Hook) — left spine hits upper-left beetle, bottom bar pushes stone & sweeps right fly!
			var d := _empty(3, "tutorial_hook", "city")
			d["pattern"] = "L"
			d["hint"] = "💡 Pattern 'L': Draw an L-Hook |_ to smash the bugs and push the Stone Block!"
			d["hint_pattern"] = PackedVector2Array([
				Vector2(105, 45), Vector2(105, 195), Vector2(355, 195)
			])
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, "brick")
			# Right side roof ledge framing the alcove
			_add_platform(d, Vector2(465.0, 580.0), Vector2(150.0, 24.0), 0.0, "stone")
			_add_prop(d, Vector2(245.0, GROUND_Y - 22.0), "stone_block", Vector2(44.0, 44.0))
			# Bad beetle on upper-left + bad fly patrolling on center-right floor
			_add_bug(d, Vector2(125.0, 640.0), "beetle")
			_add_bug(d, Vector2(365.0, GROUND_Y - BUG_HALF), "fly", "patrol", 35.0, 1.0)
			d["ink"] = 1100.0
			return d

		4:
			# Plant Garden Stage begins! Bee on flower pedestal. Player draws Umbrella '∩' / 'A'
			var d := _empty(4, "tutorial_bee_umbrella", "garden")
			d["pattern"] = "∩"
			d["hint"] = "💡 Pattern '∩': Draw an Umbrella ∩ to dome over the Bee while hitting sides!"
			d["hint_pattern"] = PackedVector2Array([
				Vector2(95, 200), Vector2(105, 55), Vector2(250, 38), Vector2(395, 55), Vector2(405, 200)
			])
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, "moss_stone")
			# Center flower pedestal with friendly bee
			_add_platform(d, Vector2(VIEW_W * 0.5, 765.0), Vector2(90.0, 36.0), 0.0, "flower_pedestal")
			_add_bug(d, Vector2(VIEW_W * 0.5, 732.0), "bee", "hover", 8.0, 0.8)
			# Bad beetles on left and right
			_add_bug(d, Vector2(110.0, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(430.0, GROUND_Y - BUG_HALF), "beetle")
			d["ink"] = 1200.0
			return d

		5:
			# Slanted wooden log ramp into sheltered pit: player draws letter 'O' / Circle ◯ to knock the Stone Boulder!
			var d := _empty(5, "tutorial_ramp_ball", "garden")
			d["pattern"] = "O"
			d["hint"] = "💡 Pattern 'O': Draw a round Circle ◯ to roll down the ramp and push the Stone 🪨!"
			var c_pts := PackedVector2Array()
			for i in range(25):
				var a := float(i) * TAU / 24.0
				c_pts.append(Vector2(115, 110) + Vector2(cos(a), sin(a)) * 48.0)
			d["hint_pattern"] = c_pts
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, "moss_stone")
			# Long slanted wood ramp launches the rolling 'O' wheel cleanly under the high right roof across both beetles!
			_add_platform(d, Vector2(185.0, 705.0), Vector2(280.0, 22.0), 24.0, "wood_log")
			# High pit shelter roof blocks direct vertical drops from above, but lets the rolling 'O' & stone boulder pass under!
			_add_platform(d, Vector2(420.0, 560.0), Vector2(180.0, 22.0), 0.0, "wood_log")
			_add_prop(d, Vector2(315.0, GROUND_Y - 24.0), "stone_boulder", Vector2(48.0, 48.0))
			_add_bug(d, Vector2(365.0, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(430.0, GROUND_Y - BUG_HALF), "beetle")
			d["ink"] = 1200.0
			return d

		6:
			# Springy Bouncy Mushroom bank-shot: tilted mushroom launches shape over the center wall!
			var d := _empty(6, "tutorial_mushroom_bounce", "garden")
			d["pattern"] = "△"
			d["hint"] = "💡 Pattern '△': Drop a heavy wedge onto Mushroom 🍄 to bounce over the wall!"
			d["hint_pattern"] = PackedVector2Array([
				Vector2(115, 55), Vector2(195, 55), Vector2(395, 195), Vector2(115, 195), Vector2(115, 55)
			])
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, "moss_stone")
			# Tilted Bouncy Mushroom on left bounces shapes up and to the right!
			_add_platform(d, Vector2(150.0, 715.0), Vector2(115.0, 38.0), 18.0, "mushroom_bouncy")
			# Dividing mossy stone wall in center + movable big triangle prop
			_add_platform(d, Vector2(275.0, 775.0), Vector2(24.0, 110.0), 0.0, "moss_stone")
			_add_prop(d, Vector2(345.0, GROUND_Y - 22.0), "big_triangle", Vector2(44.0, 44.0))
			# Flying mosquito darting behind wall + floor beetle
			_add_bug(d, Vector2(395.0, 660.0), "mosquito", "zigzag", 30.0, 1.4)
			_add_bug(d, Vector2(415.0, GROUND_Y - BUG_HALF), "beetle")
			d["ink"] = 1150.0
			return d

		7:
			# Letter 'T' (T-Hammer) chute: friendly bees on left/right flowers, bad beetle at chute bottom
			var d := _empty(7, "tutorial_t_hammer", "garden")
			d["pattern"] = "T"
			d["hint"] = "💡 Pattern 'T': Draw a T-Hammer ┳ to drop down the center chute safely!"
			d["hint_pattern"] = PackedVector2Array([
				Vector2(110, 42), Vector2(390, 42), Vector2(260, 42),
				Vector2(250, 215), Vector2(240, 42)
			])
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, "moss_stone")
			# Left and right side flower pedestals with friendly bees
			_add_platform(d, Vector2(90.0, 740.0), Vector2(90.0, 36.0), 0.0, "flower_pedestal")
			_add_bug(d, Vector2(90.0, 705.0), "bee", "hover", 6.0, 0.8)
			_add_platform(d, Vector2(450.0, 740.0), Vector2(90.0, 36.0), 0.0, "flower_pedestal")
			_add_bug(d, Vector2(450.0, 705.0), "bee", "hover", 6.0, 0.8)
			# Chute walls allow the 173px T-stem to reach the floor beetle before catching the crossbar
			_add_platform(d, Vector2(205.0, 765.0), Vector2(20.0, 130.0), 0.0, "wood_log")
			_add_platform(d, Vector2(335.0, 765.0), Vector2(20.0, 130.0), 0.0, "wood_log")
			# Flying fly orbiting above chute
			_add_bug(d, Vector2(270.0, 510.0), "fly", "circle", 30.0, 1.2)
			# Bad beetle at bottom of chute
			_add_bug(d, Vector2(270.0, GROUND_Y - BUG_HALF), "beetle")
			d["ink"] = 1150.0
			return d

		8:
			# Letter 'M' in Jungle Canopy: Figure-8 flying mosquito, swooping fly, and Friendly Bee!
			var d := _empty(8, "tutorial_canopy_figure8", "jungle")
			d["pattern"] = "M"
			d["hint"] = "💡 Pattern 'M': Draw an angled M-hook to sweep the flying canopy bugs!"
			d["hint_pattern"] = PackedVector2Array([
				Vector2(70, 200), Vector2(160, 45), Vector2(250, 200),
				Vector2(340, 45), Vector2(430, 200)
			])
			_add_floor(d, 0.0, VIEW_W, GROUND_Y, "moss_stone")
			# Friendly bee sheltered on right-center flower
			_add_platform(d, Vector2(360.0, 775.0), Vector2(76.0, 32.0), 0.0, "flower_pedestal")
			_add_bug(d, Vector2(360.0, 742.0), "bee", "hover", 6.0, 0.8)
			# Fast mosquito flying in figure-8 + swooping fly + floor beetles
			_add_bug(d, Vector2(270.0, 600.0), "mosquito", "figure8", 45.0, 1.3)
			_add_bug(d, Vector2(95.0, 650.0), "fly", "swoop", 25.0, 1.2)
			_add_bug(d, Vector2(270.0, GROUND_Y - BUG_HALF), "beetle")
			_add_bug(d, Vector2(450.0, GROUND_Y - BUG_HALF), "beetle")
			d["ink"] = 1250.0
			return d

	return {}

# ---------------------------------------------------------------- helpers

static func _empty(level: int, template: String, theme: String = "city") -> Dictionary:
	return {
		"level": level,
		"template": template,
		"pattern": "",
		"theme": theme,
		"hint": "",
		"hint_pattern": PackedVector2Array(),
		"ink": 1000.0,
		"platforms": [],
		"props": [],
		"bugs": []
	}

static func _add_floor(d: Dictionary, x0: float, x1: float, top: float = GROUND_Y, style: String = "brick") -> void:
	_add_platform(d, Vector2((x0 + x1) * 0.5, top + FLOOR_H * 0.5), Vector2(x1 - x0, FLOOR_H), 0.0, style)

static func _add_platform(d: Dictionary, center: Vector2, size: Vector2, rot_deg: float, style: String) -> void:
	d["platforms"].append({"pos": center, "size": size, "rot": rot_deg, "style": style})

static func _add_prop(d: Dictionary, pos: Vector2, kind: String = "stone_boulder", size: Vector2 = Vector2(48.0, 48.0), rot_deg: float = 0.0) -> void:
	d["props"].append({"pos": pos, "kind": kind, "size": size, "rot": rot_deg})

static func _add_bug(d: Dictionary, pos: Vector2, kind: String, move: String = "none", move_range: float = 0.0, speed: float = 1.0) -> void:
	d["bugs"].append({"pos": pos, "kind": kind, "move": move, "range": move_range, "speed": speed})
