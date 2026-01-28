extends CanvasLayer

var player_labels = []

func _ready():
	# Get all 4 labels
	for i in range(4):
		var label = get_node("MarginContainer/VBoxContainer/Player%dLabel" % (i + 1))
		player_labels.append(label)
		# Hide labels for inactive players
		if i >= GameState.num_players:
			label.hide()

func update_lives(player_number: int, lives: int):
	if player_number < player_labels.size():
		player_labels[player_number].text = "P%d Lives: %d" % (player_number + 1, lives)
