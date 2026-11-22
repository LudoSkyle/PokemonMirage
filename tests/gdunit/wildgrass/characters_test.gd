extends GdUnitTestSuite

# Mirage's characters on the Wildgrass engine (docs/wildgrass.md, step 3):
# its people and Pokémon in place of the Kotlin ones, how they look, speak and
# move, and the guarded passage.

const MAIN := preload("res://game/main.tscn")
const ISLAND := &"res://src/main/kotlin/fr/skyle/pokemonmirage/scenes/levels/start_island.tscn"

var _main: Node
var _locale := ""


func before_test() -> void:
	_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("fr")


func after_test() -> void:
	Wildgrass.dialogue.close()
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(_main):
		_main.free()
	Wildgrass.maps.clear()
	if is_instance_valid(Wildgrass.maps.traveller):
		Wildgrass.maps.traveller.free()
	Wildgrass.maps.traveller = null
	Wildgrass.story.reset()
	TranslationServer.set_locale(_locale)


func _start() -> WgWalker:
	_main = MAIN.instantiate()
	add_child(_main)
	for frame in 600:
		if Wildgrass.maps.current != null and not Wildgrass.maps.is_changing:
			break
		await get_tree().process_frame
	return Wildgrass.maps.traveller as WgWalker


func _to_island(player: WgWalker) -> Node:
	await Wildgrass.maps.go_to(ISLAND, &"MaisonLudo")
	var map := Wildgrass.maps.current
	return map.get_node(map.entities)


func _to_island_player() -> WgWalker:
	var player := await _start()
	await _to_island(player)
	return player


func _open_box() -> WgMessageBox:
	for frame in 60:
		if Wildgrass.dialogue.box != null and Wildgrass.dialogue.is_open():
			break
		await get_tree().process_frame
	var box := Wildgrass.dialogue.box
	box.set_process(false)
	box.advance(10.0)
	return box


func test_the_engine_s_characters_stand_in_for_the_kotlin_ones() -> void:
	var entities := await _to_island(await _start())
	assert_object(Wildgrass.maps.current.get_node_or_null(^"Twins/Characters")).is_null()
	for child: Node in entities.get_children():
		var script: Script = child.get_script()
		assert_bool(script != null and script.resource_path.ends_with("/Npc.kt")).override_failure_message("%s is still the Kotlin one" % child.name).is_false()
	assert_object(entities.get_node_or_null(^"Roland")).is_instanceof(WgWalker)
	# Before the bell, those of the vigil are not there yet.
	assert_object(entities.get_node_or_null(^"RolandAfter")).is_null()
	assert_object(entities.get_node_or_null(^"GuardWest")).is_not_null()


func test_after_the_bell_the_guards_are_gone_and_the_vigil_is_there() -> void:
	var player := await _start()
	Wildgrass.story.set_flag(&"bell_hung")
	var entities := await _to_island(player)
	assert_object(entities.get_node_or_null(^"GuardWest")).is_null()
	assert_object(entities.get_node_or_null(^"Roland")).is_null()
	assert_object(entities.get_node_or_null(^"RolandAfter")).is_instanceof(WgWalker)
	assert_object(Wildgrass.maps.current.get_node_or_null(^"Twins/NorthRoadblock0")).is_null()


func test_a_person_wears_its_sheet_and_a_pokemon_its_species_file() -> void:
	var entities := await _to_island(await _start())
	var person := entities.get_node(^"Roland/Sprite") as AnimatedSprite2D
	assert_bool(person.sprite_frames.has_animation(&"turn_right")).is_true()
	assert_int(person.sprite_frames.get_frame_count(&"walk_down")).is_equal(4)
	assert_vector(person.scale).is_equal(Vector2(0.5, 0.5))
	assert_vector(person.position).is_equal(Vector2(0, -4))
	assert_int((entities.get_node(^"Roland") as WgWalker).facing.x).is_equal(1)
	var pokemon := entities.get_node(^"Corphish/Sprite") as AnimatedSprite2D
	var side := pokemon.sprite_frames.get_frame_texture(&"idle_down", 0).get_height()
	assert_vector(pokemon.scale).is_equal(Vector2(0.9, 0.9))
	# Its feet at the bottom of the cell, whatever its size.
	assert_float(pokemon.position.y + side * 0.9 / 2.0).is_equal_approx(8.0, 0.001)


func test_roland_turns_to_the_player_and_speaks_under_his_name_in_blue() -> void:
	var player := await _start()
	var entities := await _to_island(player)
	var roland := entities.get_node(^"Roland") as WgWalker
	player.place_at(roland.cell + Vector2i.DOWN, 0, Vector2i.UP)
	Wildgrass.walkers.interact(player)
	var box := await _open_box()
	assert_str(box.shown_text()).is_equal("Ces eaux, j'y ai plongé vingt ans.")
	var speaker := box.get_node(^"Speaker/Name") as Label
	assert_str(speaker.text).is_equal("Roland")
	assert_that(speaker.get_theme_color(&"font_color")).is_equal(Color(0.188235, 0.313725, 0.784314, 1))
	assert_that(roland.facing).is_equal(Vector2i.DOWN)


func test_the_grass_watcher_keeps_to_the_tall_grass() -> void:
	var entities := await _to_island(await _start())
	var watcher := entities.get_node(^"GrassWatcher") as WgWalker
	var wander := watcher.get_node(^"Wander") as WgWander
	assert_that(wander.layer).is_equal(^"Background/Grass")
	assert_float(watcher.pace).is_equal(2.0)
	var grass := Wildgrass.maps.current.get_node(^"Background/Grass") as TileMapLayer
	var visited := {}
	wander.pause = Vector2(0.01, 0.01)
	wander.step_chance = 1.0
	for round in 400:
		watcher.advance(0.1)
		visited[watcher.cell] = true
	assert_int(visited.size()).is_greater(1)
	for cell: Vector2i in visited:
		assert_int(grass.get_cell_source_id(cell)).override_failure_message("%s left the grass" % cell).is_not_equal(-1)


func test_the_runner_goes_round_the_square() -> void:
	var entities := await _to_island(await _start())
	var runner := entities.get_node(^"Runner") as WgWalker
	assert_that(runner.cell).is_equal(Vector2i(23, 19))
	var seen := {}
	for round in 400:
		runner.advance(0.1)
		seen[runner.cell] = true
	for corner: Vector2i in [Vector2i(33, 19), Vector2i(33, 26), Vector2i(23, 26)]:
		assert_bool(seen.has(corner)).override_failure_message("never reached %s" % corner).is_true()


func test_the_guard_turns_the_player_back_from_the_north_passage() -> void:
	var player := await _start()
	var entities := await _to_island(player)
	var guard := entities.get_node(^"GuardWest") as WgWalker
	var passage := Vector2i(4, 3)
	assert_that(guard.cell).is_equal(passage + Vector2i.LEFT)
	player.place_at(passage + Vector2i.DOWN, 0, Vector2i.UP)
	player.step(Vector2i.UP)
	var box := await _open_box()
	assert_str(box.shown_text()).is_equal("Désolé, le passage est fermé.")
	Wildgrass.dialogue.close()
	for frame in 120:
		if not guard.is_moving and guard.cell == passage + Vector2i.LEFT and not player.is_moving:
			break
		await get_tree().process_frame
	assert_that(player.cell).is_equal(passage + Vector2i.DOWN)
	assert_that(guard.cell).is_equal(passage + Vector2i.LEFT)


func test_people_leave_mirage_s_prints_in_the_sand() -> void:
	var player := await _to_island_player()
	var sand := Vector2i(-1, -1)
	# A cell of the beach drawn on top with sand: a shell lying there keeps none.
	for cell in [Vector2i(30, 35), Vector2i(31, 35), Vector2i(30, 36), Vector2i(29, 36)]:
		if _keeps_prints(cell):
			sand = cell
			break
	assert_that(sand).is_not_equal(Vector2i(-1, -1))
	var stepped := false
	for direction: Vector2i in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
		player.place_at(sand, 0, direction)
		if player.step(direction):
			stepped = true
			break
	assert_bool(stepped).is_true()
	for frame in 60:
		if not player.is_moving:
			break
		await get_tree().process_frame
	# The player's pair on the cell it left; the children running on the beach
	# nearby leave theirs too.
	var centre := Wildgrass.walkers.tiles.center_of(sand)
	var mine := Wildgrass.footprints.prints.filter(func(mark: Sprite2D) -> bool: return mark.global_position.distance_to(centre) < 10.0)
	assert_int(mine.size()).is_equal(2)
	if mine.is_empty():
		return
	var mark := mine[0] as Sprite2D
	assert_str(mark.texture.resource_path).ends_with("assets/levels/footprints.png")
	assert_bool(mark.region_enabled).is_true()


func _keeps_prints(cell: Vector2i) -> bool:
	var centre := Wildgrass.walkers.tiles.center_of(cell)
	var top := Wildgrass.footprints.ground_at(centre)
	if top == null:
		return false
	var data := top.get_cell_tile_data(top.local_to_map(top.to_local(centre)))
	return data != null and data.get_custom_data(&"footprints") == true


func test_the_speaker_s_name_sits_inside_its_frame() -> void:
	await _start()
	Wildgrass.dialogue.say("Bonjour.", {"speaker": "Mémé Odile"})
	var box := await _open_box()
	await get_tree().process_frame
	var name_label := box.get_node(^"Speaker/Name") as Label
	var font := name_label.get_theme_font(&"font")
	var width := font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, name_label.get_theme_font_size(&"font_size")).x
	# Seven game pixels each side, as the Kotlin box.
	assert_float((box.get_node(^"Speaker") as Control).size.x).is_greater_equal(width + 14.0)


func test_people_stand_in_the_tall_grass_up_to_the_waist_and_make_it_rustle() -> void:
	var player := await _to_island_player()
	var grass := Wildgrass.maps.current.get_node(^"Background/Grass") as TileMapLayer
	var front := Wildgrass.grass.front_of(grass)
	assert_object(front).is_not_null()
	var watcher := Wildgrass.maps.current.get_node(^"World/Entities/GrassWatcher") as WgWalker
	# The island's tufts are the route's: their front strip is source 13.
	assert_int(grass.get_cell_source_id(watcher.cell)).is_equal(12)
	assert_int(front.get_cell_source_id(watcher.cell)).is_equal(13)
	# The player steps into a tuft beside the watcher: it bends.
	for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var into := watcher.cell + direction
		if grass.get_cell_source_id(into) == -1 or Wildgrass.walkers.at(into) != null:
			continue
		player.place_at(into - direction, 0, direction)
		if player.step(direction):
			for frame in 30:
				if grass.get_cell_atlas_coords(into) != Vector2i(6, 0):
					break
				await get_tree().process_frame
			assert_that(grass.get_cell_atlas_coords(into)).is_not_equal(Vector2i(6, 0))
			return
	fail("no tuft to step into beside the watcher")


func test_people_see_themselves_in_the_sea() -> void:
	var player := await _to_island_player()
	var ground := Wildgrass.maps.current.get_node(^"Background/Ground") as TileMapLayer
	var sea := Vector2i(2, 20)
	assert_bool(ground.get_cell_tile_data(sea).get_custom_data(&"reflects")).is_true()
	assert_bool(Wildgrass.maps.current.get_node(^"World/Entities/Roland").reflects).is_true()
