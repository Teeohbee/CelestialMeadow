@abstract
class_name RoundSuite
extends GameSuite
# Base for suites that play rounds: finding ships, firing a test shot at one, and waiting for ships to leave
# the arena or come back.

var real_ticks: int
var real_max_steps: int

# How much faster than real time a suite's rounds run; override to speed one up. Physics ticks go up by the
# same factor, so every physics step is still 1/60s of game time: more steps, not bigger ones.
func speed() -> float:
	return 1.0

func before_test() -> void:
	super()
	real_ticks = Engine.physics_ticks_per_second
	real_max_steps = Engine.max_physics_steps_per_frame
	Engine.time_scale = speed()
	Engine.physics_ticks_per_second = roundi(real_ticks * speed())
	Engine.max_physics_steps_per_frame = roundi(real_max_steps * speed())

func after_test() -> void:
	await super()
	Engine.physics_ticks_per_second = real_ticks
	Engine.max_physics_steps_per_frame = real_max_steps

func ship(number: int) -> Node:
	for flying in ships():
		if flying.player_number == number:
			return flying
	return null

func alive() -> Array:
	var numbers := ships().map(func(flying): return flying.player_number)
	numbers.sort()
	return numbers

# Opens a round in a mode with these seats and teams, past its countdown
func new_round(seats: Array[int], teams: Array[int] = [], mode_index := 0) -> Node:
	GameState.mode_index = mode_index
	if not teams.is_empty():
		GameState.teams = teams
	return await start_round(seats)

# Clears the asteroids and stops more coming. A shot that hits one is used up, so a drifting asteroid would
# otherwise decide whether a test shot lands.
func calm() -> void:
	scene().get_node("AsteroidTimer").stop()
	for asteroid in get_tree().get_nodes_in_group("asteroids"):
		asteroid.queue_free()
	await get_tree().physics_frame

# A bullet from one player fired at another from close range, then waits until it has hit or gone by
func fire(from: int, at: int) -> void:
	await calm()
	var target: Vector2 = ship(at).global_position
	var bullet: Node = load("res://bullet.tscn").instantiate()
	scene().add_child(bullet)
	bullet.start(Transform2D(0.0, target - Vector2(80, 0)), from)
	await wait_until(func(): return not is_instance_valid(bullet) or bullet.global_position.x > target.x + 80)

# Waits for these ships to leave the arena, then for the round's end-of-game check to have run
func eliminated(numbers: Array[int]) -> void:
	await wait_until(func(): return alive().all(func(number): return number not in numbers))
	await seconds(GameConfig.END_GAME_CHECK_DELAY + 0.2)

func respawned(number: int) -> bool:
	return await wait_until(func(): return ship(number) != null and not ship(number).dead)

func results_title() -> String:
	var shown := scene().get_node_or_null("Results")
	return shown.title.text if shown else "none"
