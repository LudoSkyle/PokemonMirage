extends GdUnitTestSuite

# Mirage's saving on the Wildgrass engine (docs/save.md): three slots, the
# save screen and its questions, a game read back where it was left.

const MAIN := preload("res://game/main.tscn")

var _main: Node
var _locale := ""


func before_test() -> void:
	_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("fr")
	for slot in range(1, 4):
		Wildgrass.save.erase(slot)


func after_test() -> void:
	for screen in Wildgrass.screens.stack():
		screen.close()
	Wildgrass.dialogue.close()
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(_main):
		_main.free()
	Wildgrass.maps.clear()
	if is_instance_valid(Wildgrass.maps.traveller):
		Wildgrass.maps.traveller.free()
	Wildgrass.maps.traveller = null
	for slot in range(1, 4):
		Wildgrass.save.erase(slot)
	Wildgrass.save.reset()
	TranslationServer.set_locale(_locale)


func _start() -> WgWalker:
	_main = MAIN.instantiate()
	add_child(_main)
	await _settled()
	return Wildgrass.maps.traveller as WgWalker


func _settled() -> void:
	for frame in 600:
		if Wildgrass.maps.current != null and not Wildgrass.maps.is_changing:
			return
		await get_tree().process_frame


func _tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Wildgrass.screens.handle_input(event)
	await get_tree().process_frame
	await get_tree().process_frame


## The text of the message box once written, and its choices shown.
func _question() -> String:
	for frame in 120:
		var box := Wildgrass.dialogue.box
		if box != null and Wildgrass.dialogue.is_open():
			box.advance(10.0)
			if (box.get_node(^"ChoiceFrame") as Control).visible:
				return box.shown_text()
		await get_tree().process_frame
	return ""


func _choices() -> Array:
	var shown: Array = []
	for button: Button in Wildgrass.dialogue.box.get_node(^"ChoiceFrame/List").get_children():
		if button.visible:
			shown.append((button.get_node(^"Text") as Label).text)
	return shown


func _open_save() -> WgScreen:
	Wildgrass.menu.open()
	await get_tree().process_frame
	await _tap("ui_down")
	await _tap("ui_down")
	await _tap("interact")
	return Wildgrass.screens.stack().filter(func(screen: WgScreen) -> bool: return screen.screen_name == &"save").front()


func test_three_slots_and_the_maps_by_their_name() -> void:
	await _start()
	assert_array(Wildgrass.save.slots()).is_equal([1, 2, 3])
	assert_that(Wildgrass.maps.id_of(Wildgrass.maps.current)).is_equal(&"ludo_bedroom")


func test_saving_asks_shows_where_and_how_long_then_closes_the_menu() -> void:
	await _start()
	var screen := await _open_save()
	assert_str(screen.scene_file_path).is_equal("res://game/ui/save_screen.tscn")
	assert_str((screen.get_node(^"Summary/Location") as Label).text).is_equal("Maison de Ludo")
	assert_str((screen.get_node(^"Summary/Time") as Label).text).is_equal("00:00")
	assert_str(await _question()).is_equal("Voulez-vous sauvegarder la partie ?")
	await get_tree().process_frame
	assert_array(_choices()).is_equal(["Oui", "Non"])
	await _tap("interact")
	assert_bool(Wildgrass.save.has(1)).is_true()
	for frame in 240:
		if not Wildgrass.screens.is_open(&"menu"):
			break
		await get_tree().process_frame
	assert_bool(Wildgrass.screens.is_open(&"menu")).override_failure_message("saved: the menu closes too").is_false()
	assert_str(str(Wildgrass.save.summary(1).get("location"))).is_equal("Maison de Ludo")


func test_no_goes_back_to_the_menu_writing_nothing() -> void:
	await _start()
	await _open_save()
	await _question()
	await _tap("ui_down")
	await _tap("interact")
	await get_tree().process_frame
	assert_bool(Wildgrass.save.has(1)).is_false()
	assert_bool(Wildgrass.screens.is_open(&"save")).is_false()
	assert_bool(Wildgrass.screens.is_open(&"menu")).is_true()


func test_a_saved_game_asks_before_it_is_overwritten() -> void:
	await _start()
	Wildgrass.save.new_game(1)
	assert_bool(Wildgrass.save.write()).is_true()
	await _open_save()
	await _question()
	await _tap("interact")
	assert_str(await _question()).is_equal("Une sauvegarde existe déjà.\nVoulez-vous l'écraser ?")


func test_a_game_is_read_back_where_it_was_left() -> void:
	var player := await _start()
	Wildgrass.save.new_game(2)
	await Wildgrass.maps.go_to(&"start_island", &"MaisonLudo")
	await _settled()
	player.place_at(Vector2i(20, 20), 0, Vector2i.LEFT)
	Wildgrass.story.set_flag(&"bell_told")
	Wildgrass.bag.add(&"potion", 3)
	assert_bool(Wildgrass.save.write()).is_true()
	Wildgrass.save.reset()
	await Wildgrass.maps.go_to(&"ludo_bedroom", &"Spawn")
	await _settled()
	assert_bool(await Wildgrass.save.load_game(2)).is_true()
	await _settled()
	assert_that(Wildgrass.maps.id_of(Wildgrass.maps.current)).is_equal(&"start_island")
	assert_that(player.cell).is_equal(Vector2i(20, 20))
	assert_that(player.facing).is_equal(Vector2i.LEFT)
	assert_bool(Wildgrass.story.has(&"bell_told")).is_true()
	assert_int(Wildgrass.bag.count(&"potion")).is_equal(3)
