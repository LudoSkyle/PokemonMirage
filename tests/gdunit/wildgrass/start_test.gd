extends GdUnitTestSuite

# A new game on the Wildgrass engine: Ludo's bedroom, down the stairs into the
# house, out of the door onto the island (docs/wildgrass.md, step 1).

const MAIN := preload("res://game/main.tscn")

var _main: Node


func after_test() -> void:
	if is_instance_valid(_main):
		_main.free()
	Wildgrass.maps.clear()
	if is_instance_valid(Wildgrass.maps.traveller):
		Wildgrass.maps.traveller.free()
	Wildgrass.maps.traveller = null


func _settled() -> void:
	for frame in 600:
		if Wildgrass.maps.current != null and not Wildgrass.maps.is_changing:
			return
		await get_tree().process_frame


func _map_name() -> String:
	return String(Wildgrass.maps.current_id).get_file().get_basename()


func test_down_the_stairs_and_out_of_the_house() -> void:
	_main = MAIN.instantiate()
	_main.title = false
	add_child(_main)
	await _settled()
	var player := Wildgrass.maps.traveller as WgWalker
	assert_str(_map_name()).is_equal("ludo_bedroom")
	assert_that(player.cell).is_equal(Vector2i(15, 11))
	assert_that(player.facing).is_equal(Vector2i.DOWN)
	assert_bool(await Wildgrass.walkers.walk_to(player, Vector2i(11, 8))).is_true()
	player.step(Vector2i.LEFT)
	await get_tree().process_frame
	await _settled()
	assert_str(_map_name()).is_equal("ludo_house")
	assert_that(player.cell).is_equal(Vector2i(11, 8))
	assert_that(player.facing).is_equal(Vector2i.RIGHT)
	assert_bool(await Wildgrass.walkers.walk_to(player, Vector2i(15, 14))).is_true()
	player.step(Vector2i.DOWN)
	await get_tree().process_frame
	await _settled()
	assert_str(_map_name()).is_equal("start_island")
	assert_that(player.facing).is_equal(Vector2i.DOWN)
