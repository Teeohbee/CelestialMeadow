extends CanvasLayer

## Each pilot's corner of the poster: an outlined numeral, a tracked
## "PILOT n" label and their lives as trail-shaped pills, or their kills
## when lives are unlimited.

const MARGIN: float = 34.0
const BLOCK_H: float = 56.0
const NUMERAL_GAP: float = 46.0
const PILL_STEP: float = 26.0
## Where each seat's block sits: x anchor (0 left, 0.5 centre, 1 right), top or bottom
const SLOTS: Array = [
	[0.0, true], [1.0, false], [0.0, false], [1.0, true], [0.5, true], [0.5, false],
]

var lives: Dictionary = {}
## Pill slots per pilot: the most lives they've had, so a lost life shows as
## an empty pill and unlimited lives (negative) show none
var pill_slots: Dictionary = {}
var scores: Dictionary = {}
var hidden: Dictionary = {}
## The Wanted player, whose corner says so, or -1
var wanted: int = -1
var canvas: Node2D
var clock: Label
var side_scores: Label
## The kill target under the clock, when the round has one
var goal: Label
var banner: Label

func _ready():
	# Made here, not when the script loads, so an HUD freed before it's ever in the tree leaks nothing
	canvas = Node2D.new()
	add_child(canvas)
	canvas.draw.connect(_draw_hud)

	clock = poster_label(52, 700, 4, 4)
	clock.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	clock.position.y = 18
	clock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	clock.hide()
	add_child(clock)

	side_scores = poster_label(24, 600, 6, 0)
	side_scores.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	side_scores.position.y = 84
	side_scores.grow_horizontal = Control.GROW_DIRECTION_BOTH
	side_scores.uppercase = true
	side_scores.add_theme_color_override("font_color", Color(GameConfig.CREAM, 0.85))
	side_scores.hide()
	add_child(side_scores)

	goal = poster_label(20, 600, 6, 0)
	goal.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	goal.position.y = 84
	goal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	goal.uppercase = true
	goal.add_theme_color_override("font_color", Color(GameConfig.LIGHT, 0.9))
	goal.hide()
	add_child(goal)

	banner = poster_label(120, 700, 14, 10)
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	banner.add_theme_color_override("font_shadow_color", GameConfig.ENV_INKS[1])
	banner.hide()
	# Finish fading even if the round ends and pauses mid-announcement
	banner.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(banner)

## Cream Josefin type with a flat teal offset, like the title logo; no offset
## when it's 0
func poster_label(font_size: int, weight: int, tracking: int, offset: int) -> Label:
	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", Poster.font(weight, tracking))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", GameConfig.CREAM)
	if offset > 0:
		label.add_theme_color_override("font_shadow_color", GameConfig.HUE)
		label.add_theme_constant_override("shadow_offset_x", offset)
		label.add_theme_constant_override("shadow_offset_y", offset)
	return label

func update_lives(player_number: int, remaining: int):
	lives[player_number] = remaining
	pill_slots[player_number] = maxi(pill_slots.get(player_number, 0), remaining)
	canvas.queue_redraw()

func hide_player(player_number: int):
	hidden[player_number] = true
	canvas.queue_redraw()

func update_score(player_number: int, score: int):
	scores[player_number] = score
	canvas.queue_redraw()

func set_wanted(player_number: int):
	wanted = player_number
	canvas.queue_redraw()

## The line over a pilot's lives: "PILOT n", or "WANTED"
func block_label(i: int) -> String:
	return "WANTED" if i == wanted else "PILOT %d" % (i + 1)

## Pilots whose block is drawn, in seat order
func shown_players() -> Array:
	return lives.keys().filter(func(i): return i not in hidden)

## Team totals under the clock, e.g. "Alpha 3  -  Beta 2"
func set_team_scores(totals: Dictionary):
	var parts: Array[String] = []
	for team in GameConfig.TEAM_NAMES.size():
		if team in totals:
			parts.append("%s %d" % [GameConfig.TEAM_NAMES[team], totals[team]])
	side_scores.text = "  -  ".join(parts)
	side_scores.visible = not parts.is_empty()
	canvas.queue_redraw()

## A line under the clock saying what wins, e.g. "First to 10"; team totals
## move down under it
func set_goal(text: String):
	goal.text = text
	goal.show()
	side_scores.position.y = goal.position.y + 34
	canvas.queue_redraw()

## Shows the time left as m:ss, top centre
func set_clock(seconds: float):
	if not clock.visible:
		clock.show()
		canvas.queue_redraw()
	var whole = ceili(seconds)
	clock.text = "%d:%02d" % [whole / 60, whole % 60]
	clock.add_theme_color_override("font_color", GameConfig.ENV_INKS[1] if seconds <= 10 else GameConfig.CREAM)

## Big centred announcement that fades after a moment
func show_banner(text: String):
	banner.text = text
	banner.show()
	banner.modulate.a = 1.0
	banner.pivot_offset = banner.size * 0.5
	banner.scale = Vector2.ONE * 1.4
	var tween = banner.create_tween()
	tween.tween_property(banner, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.5)
	tween.tween_property(banner, "modulate:a", 0.0, 0.6)
	tween.tween_callback(banner.hide)

## Where pilot i's block sits: left edge, top, width, and whether it's mirrored
## so the numeral sits nearest the right-hand corner
func block_layout(i: int) -> Dictionary:
	var size = canvas.get_viewport_rect().size
	var slot = SLOTS[i]
	var label_w = Poster.font(600, 4).get_string_size(block_label(i), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var w = NUMERAL_GAP + maxf(label_w, row_width(i))
	var right = slot[0] == 1.0
	var top = MARGIN if slot[1] else size.y - MARGIN - BLOCK_H
	var x0 = MARGIN + 12.0
	if right:
		x0 = size.x - MARGIN - 12.0 - w
	elif slot[0] == 0.5:
		x0 = (size.x - w) * 0.5
		# Pilot 5 shares the top centre with the clock and team totals; step
		# aside to the right of them rather than down into the arena
		if slot[1] and clock.visible:
			var half = clock.get_minimum_size().x * 0.5
			for line in [side_scores, goal]:
				if line.visible:
					half = maxf(half, line.get_minimum_size().x * 0.5)
			x0 = size.x * 0.5 + half + 40.0
	return {"x0": x0, "top": top, "w": w, "right": right}

func block_rect(i: int) -> Rect2:
	var b = block_layout(i)
	return Rect2(b.x0, b.top, b.w, BLOCK_H)

## Width of the pills plus the kill count beside them
func row_width(i: int) -> float:
	var w = PILL_STEP * pill_slots.get(i, 0)
	if i in scores:
		if w > 0:
			w += 8.0
		w += Poster.font(700).get_string_size(str(scores[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
	return w

func _draw_hud():
	var numeral_font = Poster.font(700)
	var label_font = Poster.font(600, 4)
	for i in shown_players():
		var b = block_layout(i)
		var ink = GameConfig.PLAYER_COLORS[i]
		var top = b.top
		var numeral = str(i + 1)
		var label = block_label(i)
		var numeral_w = numeral_font.get_string_size(numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 58).x
		var label_w = label_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var row_w = row_width(i)
		# Mirrored blocks run right to left from the inner edge of the numeral
		var inner = b.x0 + b.w - NUMERAL_GAP if b.right else b.x0 + NUMERAL_GAP
		var num_x = b.x0 + b.w - numeral_w if b.right else b.x0
		canvas.draw_string_outline(numeral_font, Vector2(num_x, top + numeral_font.get_ascent(58) - 8), numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 58, 3, ink)
		var label_x = inner - label_w if b.right else inner
		canvas.draw_string(label_font, Vector2(label_x, top + 8 + label_font.get_ascent(14)), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GameConfig.LIGHT if i == wanted else Color(GameConfig.CREAM, 0.8))
		for n in pill_slots[i]:
			var px = inner - 20.0 - n * PILL_STEP if b.right else inner + n * PILL_STEP
			var colour = ink if n < lives[i] else Color(GameConfig.CREAM, 0.18)
			Poster.bar(canvas, Vector2(px + 4, top + 36), Vector2(px + 16, top + 36), 8, colour)
		if i in scores:
			var score = str(scores[i])
			var score_w = numeral_font.get_string_size(score, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
			var sx = inner - row_w if b.right else inner + row_w - score_w
			canvas.draw_string(numeral_font, Vector2(sx, top + 48), score, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, ink)
