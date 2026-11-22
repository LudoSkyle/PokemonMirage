extends GdUnitTestSuite

# The bell's quest, from start to end, on the Wildgrass engine: every flag,
# every item given and taken, the map reloaded and the vigil ended on leaving
# the island (docs/quests.md).

const MAIN := preload("res://game/main.tscn")
const LEVELS := "res://src/main/kotlin/fr/skyle/pokemonmirage/scenes/levels/%s.tscn"

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
	Wildgrass.bag.reset()
	TranslationServer.set_locale(_locale)


func _start() -> WgWalker:
	_main = MAIN.instantiate()
	_main.title = false
	add_child(_main)
	await _settled()
	return Wildgrass.maps.traveller as WgWalker


func _settled() -> void:
	for frame in 600:
		if Wildgrass.maps.current != null and not Wildgrass.maps.is_changing:
			return
		await get_tree().process_frame


func _go_to(map: String, point: StringName) -> void:
	await Wildgrass.maps.go_to(StringName(LEVELS % map), point)
	await _settled()


## Faces `cell` from `from`, interacts, and plays the dialogue out, saying
## yes to what it asks; the pages read, joined.
func _talk(player: WgWalker, from: Vector2i, cell: Vector2i) -> String:
	player.place_at(from, 0, cell - from)
	Wildgrass.walkers.interact(player)
	var read := PackedStringArray()
	var quiet := 0
	for frame in 1200:
		if not Wildgrass.dialogue.is_open():
			quiet += 1
			if quiet > 10:
				break
			await get_tree().process_frame
			continue
		quiet = 0
		var box := Wildgrass.dialogue.box
		box.advance(10.0)
		var page := box.shown_text()
		if read.is_empty() or read[read.size() - 1] != page:
			read.append(page)
		var event := InputEventAction.new()
		event.action = "interact"
		event.pressed = true
		Wildgrass.screens.handle_input(event)
		await get_tree().process_frame
	await _settled()
	return " | ".join(read)


func test_the_bell_s_quest_plays_through_on_the_engine() -> void:
	var player := await _start()
	var story := Wildgrass.story
	var bag := Wildgrass.bag

	await _go_to("ludo_house", &"")
	await _talk(player, Vector2i(16, 11), Vector2i(17, 11))
	assert_bool(story.has(&"bell_told")).override_failure_message("Granny Odile tells of the bell").is_true()

	await _go_to("library", &"")
	await _talk(player, Vector2i(11, 9), Vector2i(11, 8))
	assert_bool(story.has(&"bell_register")).override_failure_message("the register is found").is_true()
	assert_int(bag.count(&"dusty_register")).is_equal(1)

	await _go_to("start_island", &"MaisonLudo")
	await _talk(player, Vector2i(7, 37), Vector2i(7, 36))
	assert_bool(story.has(&"bell_spotted")).override_failure_message("Roland saw something shine").is_true()
	# The glint is there once the island is entered again, as in the Kotlin game.
	await _go_to("library", &"")
	await _go_to("start_island", &"Bibliotheque")
	await _talk(player, Vector2i(35, 46), Vector2i(35, 47))
	assert_bool(story.has(&"bell_tarnished")).override_failure_message("the bell is fished out").is_true()
	assert_int(bag.count(&"tarnished_bell")).is_equal(1)

	await _go_to("lab_house", &"")
	await _talk(player, Vector2i(16, 8), Vector2i(16, 7))
	assert_bool(story.has(&"bell_clean")).override_failure_message("the machine cleans the bell").is_true()
	assert_int(bag.count(&"tarnished_bell")).is_equal(0)
	assert_int(bag.count(&"clear_bell")).is_equal(1)

	await _go_to("ludo_house", &"")
	await _talk(player, Vector2i(16, 11), Vector2i(17, 11))
	assert_bool(story.has(&"bell_ribbon")).override_failure_message("Granny Odile gives her ribbon").is_true()
	assert_int(bag.count(&"vigil_ribbon")).is_equal(1)

	await _go_to("start_island", &"MaisonLudo")
	await _talk(player, Vector2i(28, 20), Vector2i(28, 21))
	assert_bool(story.has(&"bell_hung")).override_failure_message("the bell is hung").is_true()
	assert_int(bag.count(&"clear_bell")).is_equal(0)
	# Hanging it reloads the map: the stand bears the bell, the vigil is there.
	assert_object(Wildgrass.maps.current.get_node_or_null(^"World/BellStand")).is_not_null()
	assert_object(Wildgrass.maps.current.get_node_or_null(^"World/Entities/RolandAfter")).is_not_null()
	assert_bool(story.has(&"vigil_over")).is_false()

	Wildgrass.maps.use(Wildgrass.maps.current.get_node(^"Exits/MaisonLudo") as WgDoor)
	await get_tree().process_frame
	await _settled()
	assert_bool(story.has(&"vigil_over")).override_failure_message("leaving the island ends the vigil").is_true()
	assert_object(Wildgrass.maps.current.get_node_or_null(^"World/Entities/OdileBack")).is_not_null()
