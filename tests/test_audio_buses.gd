extends GdUnitTestSuite
# The bus layout: Music and Sounds both send to Master, and every player that ships in a scene is on
# the bus its volume setting drives, so the options screen turns down what it says it does.

## Every player that ships in a scene, and the bus it belongs on.
const EXPECTED = {
	"res://main.tscn": {"AudioStreamPlayer": "Sounds"},
	"res://player.tscn": {"LaserSound": "Sounds", "ExplosionSound": "Sounds"},
	"res://asteroid.tscn": {"ExplosionSound": "Sounds"},
	"res://countdown.tscn": {"AudioStreamPlayer": "Sounds"},
}

func _players_in(node: Node, found: Array[Node] = []) -> Array[Node]:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
		found.append(node)
	for child in node.get_children():
		_players_in(child, found)
	return found

func test_music_and_sounds_send_to_master() -> void:
	for bus_name in ["Music", "Sounds"]:
		var index := AudioServer.get_bus_index(bus_name)
		assert_int(index).override_failure_message("%s bus is missing" % bus_name).is_not_equal(-1)
		assert_str(AudioServer.get_bus_send(index)).is_equal("Master")

func test_every_player_is_on_its_bus() -> void:
	for path in EXPECTED:
		var players := _players_in(auto_free(load(path).instantiate()))
		assert_int(players.size()).override_failure_message("%s should have %d players, found %d" %
			[path, EXPECTED[path].size(), players.size()]).is_equal(EXPECTED[path].size())
		for player in players:
			var want: String = EXPECTED[path].get(String(player.name), "?")
			assert_str(player.bus).override_failure_message("%s %s should be on %s, is on %s" %
				[path, player.name, want, player.bus]).is_equal(want)
