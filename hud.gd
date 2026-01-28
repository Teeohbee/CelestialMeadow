extends CanvasLayer

var player_labels = []

func _ready():
	for i in GameState.num_players:
		var label = get_node("MarginContainer/VBoxContainer/Player%dLabel" % (i + 1))
		player_labels.append(label)

func update_lives(player_number: int, lives: int):
	if player_number < player_labels.size():
		player_labels[player_number].text = "P%d Lives: %d" % (player_number + 1, lives)
