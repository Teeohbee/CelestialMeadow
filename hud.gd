extends CanvasLayer

var player_containers: Array = []
var lives_boxes: Array = []
var score_labels: Array = []
var clock: Label
var side_scores: Label
var banner: Label
var life_icon_size: int = 20
var corner_positions: Array = [
	{"anchor": Control.PRESET_TOP_LEFT, "margin": Vector2(20, 20)},       # Player 0
	{"anchor": Control.PRESET_BOTTOM_RIGHT, "margin": Vector2(-20, -20)}, # Player 1
	{"anchor": Control.PRESET_BOTTOM_LEFT, "margin": Vector2(20, -20)},   # Player 2
	{"anchor": Control.PRESET_TOP_RIGHT, "margin": Vector2(-20, 20)},     # Player 3
	{"anchor": Control.PRESET_CENTER_TOP, "margin": Vector2(0, 20)},      # Player 4
	{"anchor": Control.PRESET_CENTER_BOTTOM, "margin": Vector2(0, -20)}   # Player 5
]

func _ready():
	for i in range(6):
		var container = HBoxContainer.new()
		container.set_anchors_preset(corner_positions[i].anchor)
		
		# Position container based on player position
		if i == 0:  # Top left
			container.position = corner_positions[i].margin
		elif i == 1:  # Bottom right
			container.position = Vector2(corner_positions[i].margin.x - 100, corner_positions[i].margin.y - 30)
			container.alignment = BoxContainer.ALIGNMENT_END
		elif i == 2:  # Bottom left
			container.position = Vector2(corner_positions[i].margin.x, corner_positions[i].margin.y - 30)
		elif i == 3:  # Top right
			container.position = Vector2(corner_positions[i].margin.x - 100, corner_positions[i].margin.y)
			container.alignment = BoxContainer.ALIGNMENT_END
		elif i == 4:  # Top center
			container.position = Vector2(corner_positions[i].margin.x - 50, corner_positions[i].margin.y)
		else:  # Bottom center (Player 5)
			container.position = Vector2(corner_positions[i].margin.x - 50, corner_positions[i].margin.y - 30)
		
		container.add_theme_constant_override("separation", 12)
		add_child(container)
		player_containers.append(container)

		var lives_box = HBoxContainer.new()
		lives_box.add_theme_constant_override("separation", 5)
		container.add_child(lives_box)
		lives_boxes.append(lives_box)

		var score_label = Label.new()
		score_label.add_theme_font_size_override("font_size", 32)
		score_label.add_theme_color_override("font_color", GameConfig.PLAYER_COLORS[i].lightened(0.35))
		score_label.add_theme_constant_override("outline_size", 6)
		score_label.add_theme_color_override("font_outline_color", Color.BLACK)
		score_label.hide()
		container.add_child(score_label)
		score_labels.append(score_label)
		
		# Hide containers for inactive players
		if i not in GameState.players:
			container.hide()

	clock = Label.new()
	clock.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	clock.position.y = 12
	clock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock.add_theme_font_size_override("font_size", 44)
	clock.add_theme_constant_override("outline_size", 8)
	clock.add_theme_color_override("font_outline_color", Color.BLACK)
	clock.hide()
	add_child(clock)

	side_scores = Label.new()
	side_scores.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	side_scores.position.y = 64
	side_scores.grow_horizontal = Control.GROW_DIRECTION_BOTH
	side_scores.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	side_scores.add_theme_font_size_override("font_size", 28)
	side_scores.add_theme_constant_override("outline_size", 6)
	side_scores.add_theme_color_override("font_outline_color", Color.BLACK)
	side_scores.hide()
	add_child(side_scores)

	banner = Label.new()
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 96)
	banner.add_theme_color_override("font_color", Color(1, 0.35, 0.25))
	banner.add_theme_constant_override("outline_size", 12)
	banner.add_theme_color_override("font_outline_color", Color.BLACK)
	banner.hide()
	# Finish fading even if the round ends and pauses mid-announcement
	banner.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(banner)

func update_lives(player_number: int, lives: int):
	if player_number >= player_containers.size():
		return
	
	var container = lives_boxes[player_number]
	
	# Clear existing icons
	for child in container.get_children():
		child.queue_free()
	
	# Add life icons; none when lives are unlimited
	for i in maxi(lives, 0):
		var icon = ColorRect.new()
		icon.custom_minimum_size = Vector2(life_icon_size, life_icon_size)
		icon.color = GameConfig.PLAYER_COLORS[player_number]
		container.add_child(icon)

func hide_player(player_number: int):
	player_containers[player_number].hide()

func update_score(player_number: int, score: int):
	score_labels[player_number].text = str(score)
	score_labels[player_number].show()

## Team totals under the clock, e.g. "Alpha 3  -  Beta 2"
func set_team_scores(totals: Dictionary):
	var parts: Array[String] = []
	for team in GameConfig.TEAM_NAMES.size():
		if team in totals:
			parts.append("%s %d" % [GameConfig.TEAM_NAMES[team], totals[team]])
	side_scores.text = "  -  ".join(parts)
	side_scores.visible = not parts.is_empty()
	place_top_centre_player()

## Shows the time left as m:ss, top centre
func set_clock(seconds: float):
	if not clock.visible:
		clock.show()
		place_top_centre_player()
	var whole = ceili(seconds)
	clock.text = "%d:%02d" % [whole / 60, whole % 60]
	clock.modulate = Color(1, 0.4, 0.3) if seconds <= 10 else Color.WHITE

## Player 5's corner is top centre, shared with the clock and team totals;
## keep it below whichever of those are showing
func place_top_centre_player():
	var y = corner_positions[4].margin.y
	if clock.visible:
		y += 56
	if side_scores.visible:
		y += 40
	player_containers[4].position.y = y

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
