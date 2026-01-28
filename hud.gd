extends CanvasLayer

var player_containers = []
var life_icon_size = 20
var player_colors = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW]
var corner_positions = [
	{"anchor": Control.PRESET_TOP_LEFT, "margin": Vector2(20, 20)},
	{"anchor": Control.PRESET_TOP_RIGHT, "margin": Vector2(-20, 20)},
	{"anchor": Control.PRESET_BOTTOM_LEFT, "margin": Vector2(20, -20)},
	{"anchor": Control.PRESET_BOTTOM_RIGHT, "margin": Vector2(-20, 20)}
]

func _ready():
	for i in range(4):
		var container = HBoxContainer.new()
		container.set_anchors_preset(corner_positions[i].anchor)
		
		# Position container in corner
		if i == 0:  # Top left
			container.position = corner_positions[i].margin
		elif i == 1:  # Top right
			container.position = Vector2(corner_positions[i].margin.x - 100, corner_positions[i].margin.y)
			container.alignment = BoxContainer.ALIGNMENT_END
		elif i == 2:  # Bottom left
			container.position = Vector2(corner_positions[i].margin.x, corner_positions[i].margin.y - 30)
		else:  # Bottom right
			container.position = Vector2(corner_positions[i].margin.x - 100, corner_positions[i].margin.y - 30)
			container.alignment = BoxContainer.ALIGNMENT_END
		
		container.add_theme_constant_override("separation", 5)
		add_child(container)
		player_containers.append(container)
		
		# Hide containers for inactive players
		if i >= GameState.num_players:
			container.hide()
		else:
			# Create initial life icons
			update_lives(i, GameState.lives_per_player)

func update_lives(player_number: int, lives: int):
	if player_number >= player_containers.size():
		return
	
	var container = player_containers[player_number]
	
	# Clear existing icons
	for child in container.get_children():
		child.queue_free()
	
	# Add life icons
	for i in lives:
		var icon = ColorRect.new()
		icon.custom_minimum_size = Vector2(life_icon_size, life_icon_size)
		icon.color = player_colors[player_number]
		container.add_child(icon)
