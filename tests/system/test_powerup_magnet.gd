extends RoundSuite
# Power-ups are a little magnetic: one near a ship drifts in to it, faster the closer it gets, so a near
# miss still picks it up. One out of reach stays put, it goes to the nearest ship, and a dead ship doesn't
# pull.

func speed() -> float:
	return 4.0

func drop(at: Vector2) -> Node:
	var powerup: Node = load("res://powerup.tscn").instantiate()
	powerup.position = at
	scene().add_child(powerup)
	return powerup

# Towards the middle of the arena from a ship, so it's clear of the other ships
func beside(number: int, distance: float) -> Vector2:
	var from: Vector2 = ship(number).global_position
	return from + (get_viewport().get_visible_rect().get_center() - from).normalized() * distance

func test_a_near_miss_drifts_in_and_is_picked_up() -> void:
	await new_round([0, 1])
	await calm()
	var picked: WeakRef = weakref(drop(beside(1, GameConfig.POWERUP_MAGNET_RADIUS * 0.8)))
	assert_bool(await wait_until(func(): return picked.get_ref() == null, 3.0)).is_true()
	assert_bool(ship(1).shield_active).is_true()

func test_out_of_reach_it_stays_put() -> void:
	await new_round([0, 1])
	await calm()
	var at := beside(1, GameConfig.POWERUP_MAGNET_RADIUS * 1.5)
	var powerup := drop(at)
	await seconds(1.0)
	assert_vector(powerup.position).is_equal_approx(at, Vector2.ONE * 0.01)

func test_it_goes_to_the_nearer_ship() -> void:
	await new_round([0, 1])
	await calm()
	var near := beside(1, GameConfig.POWERUP_MAGNET_RADIUS * 0.6)
	var powerup := drop(near)
	await seconds(0.1)
	assert_float(powerup.position.distance_to(ship(1).global_position)).is_less(near.distance_to(ship(1).global_position))

func test_a_dead_ship_doesnt_pull() -> void:
	await new_round([0, 1, 2])
	await calm()
	var at := beside(1, GameConfig.POWERUP_MAGNET_RADIUS * 0.8)
	ship(1).destroy()
	var powerup := drop(at)
	await seconds(0.5)
	assert_vector(powerup.position).is_equal_approx(at, Vector2.ONE * 0.01)
