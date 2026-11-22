extends GdUnitTestSuite

# Mirage's maps on the Wildgrass engine (docs/wildgrass.md, step 1): each is a
# WgMap, and each door leads to a door of its target map.

const LEVELS := "res://src/main/kotlin/fr/skyle/pokemonmirage/scenes/levels/"
const MAPS := ["ludo_bedroom", "ludo_house", "lab_house", "library", "orange_house_north", "orange_house_south", "route_1", "start_island"]


func _map(id: String) -> WgMap:
	return auto_free((load(LEVELS + id + ".tscn") as PackedScene).instantiate()) as WgMap


func test_every_map_is_a_wg_map_of_its_size_the_player_going_in_world_entities() -> void:
	for id: String in MAPS:
		var map := _map(id)
		assert_object(map).override_failure_message(id).is_not_null()
		assert_object(map.entities_node()).override_failure_message(id).is_same(map.get_node("World/Entities"))
		var ground := map.get_node("Background/Ground") as TileMapLayer
		assert_that(map.size).override_failure_message(id).is_equal(ground.get_used_rect().end)
	assert_bool(_map("start_island").outside).is_true()
	assert_bool(_map("route_1").outside).is_true()
	assert_bool(_map("ludo_house").outside).is_false()


func test_every_door_leads_to_a_door_of_its_target_map_where_its_twin_stands() -> void:
	var count := 0
	for id: String in MAPS:
		var map := _map(id)
		for door: Node in map.get_node("Exits").get_children():
			assert_bool(door is WgDoor).override_failure_message("%s/%s" % [id, door.name]).is_true()
			var twin := map.get_node("Doors/" + str(door.name)) as Node2D
			assert_that((door as Node2D).position).override_failure_message("%s/%s" % [id, door.name]).is_equal(twin.position)
			assert_that((door as WgDoor).direction).override_failure_message("%s/%s" % [id, door.name]).is_not_equal(Vector2i.ZERO)
			var target := auto_free((load(String((door as WgDoor).target_map)) as PackedScene).instantiate()) as WgMap
			assert_object(target.find_point((door as WgDoor).target_door)).override_failure_message("%s/%s" % [id, door.name]).is_not_null()
			count += 1
	assert_int(count).is_equal(23)


func test_a_new_game_starts_in_ludo_s_bedroom() -> void:
	var spawn := _map("ludo_bedroom").find_point(&"Spawn") as WgSpawnPoint
	assert_object(spawn).is_not_null()
	assert_that(Vector2i(spawn.position / 16.0)).is_equal(Vector2i(15, 11))
	assert_that(spawn.direction).is_equal(Vector2i.DOWN)
