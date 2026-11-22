extends GdUnitTestSuite

# Mirage's pause menu and options on the Wildgrass engine (docs/menu.md).

const MAIN := preload("res://game/main.tscn")

var _main: Node
var _locale := ""


func before_test() -> void:
	_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("fr")


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
	Wildgrass.story.reset()
	Wildgrass.bag.reset()
	Wildgrass.options.set_value(&"text_speed", 1.0)
	Wildgrass.options.set_value(&"language", "fr")
	Wildgrass.options.set_value(&"music_volume", 100)
	TranslationServer.set_locale(_locale)


func _start() -> void:
	_main = MAIN.instantiate()
	_main.title = false
	add_child(_main)
	for frame in 600:
		if Wildgrass.maps.current != null and not Wildgrass.maps.is_changing:
			break
		await get_tree().process_frame


func _tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Wildgrass.screens.handle_input(event)
	await get_tree().process_frame
	await get_tree().process_frame


func _lines(menu: WgScreen) -> Array:
	return menu.get_node(^"Menu/Entries").get_children().map(func(label: Label) -> String: return label.text)


func _cursor_row(menu: WgScreen) -> int:
	var cursor := menu.get_node(^"Menu/Cursor") as Control
	var entries := menu.get_node(^"Menu/Entries") as Control
	return roundi((cursor.position.y + cursor.size.y / 2.0 - entries.position.y - 8.0) / 16.0)


func test_the_menu_is_mirage_s_in_its_words_and_order() -> void:
	await _start()
	var menu := Wildgrass.menu.open()
	await get_tree().process_frame
	assert_str(menu.scene_file_path).is_equal("res://game/ui/menu_screen.tscn")
	assert_array(_lines(menu)).is_equal(["Pokédex", "Sac", "Sauvegarder", "Options", "Debug", "Quitter"])
	# The frame fits the six lines.
	assert_float((menu.get_node(^"Menu/Frame") as Control).size.y).is_equal(112.0)
	TranslationServer.set_locale("en")
	menu.refresh()
	assert_array(_lines(menu)).is_equal(["Pokédex", "Bag", "Save", "Options", "Debug", "Exit"])


func test_the_cursor_wraps_and_starts_from_the_top_at_each_opening() -> void:
	await _start()
	var menu := Wildgrass.menu.open()
	await get_tree().process_frame
	assert_int(_cursor_row(menu)).is_equal(0)
	await _tap("ui_up")
	assert_that(menu.selected()).is_equal(&"exit")
	assert_int(_cursor_row(menu)).is_equal(5)
	await _tap("ui_down")
	assert_that(menu.selected()).is_equal(&"pokedex")
	await _tap("ui_down")
	await _tap("menu")
	assert_bool(Wildgrass.screens.is_open(&"menu")).is_false()
	menu = Wildgrass.menu.open()
	await get_tree().process_frame
	assert_that(menu.selected()).is_equal(&"pokedex")


func test_quit_closes_the_menu() -> void:
	await _start()
	var menu := Wildgrass.menu.open()
	await get_tree().process_frame
	await _tap("ui_up")
	await _tap("interact")
	assert_bool(Wildgrass.screens.is_open(&"menu")).is_false()


func test_options_open_over_the_menu_and_back_brings_it_back_on_options() -> void:
	await _start()
	var menu := Wildgrass.menu.open()
	await get_tree().process_frame
	for step in 3:
		await _tap("ui_down")
	assert_that(menu.selected()).is_equal(&"options")
	await _tap("interact")
	var options := Wildgrass.screens.top()
	assert_str(options.scene_file_path).is_equal("res://game/ui/options_screen.tscn")
	await _tap("menu")
	assert_bool(Wildgrass.screens.is_open(&"options")).is_false()
	assert_bool(Wildgrass.screens.is_open(&"menu")).is_true()
	assert_that(menu.selected()).is_equal(&"options")
	await _tap("interact")
	# Up from the first row wraps to Back, which closes.
	await _tap("ui_up")
	assert_that(Wildgrass.screens.top().selected()).is_equal(&"")
	await _tap("interact")
	assert_bool(Wildgrass.screens.is_open(&"options")).is_false()
	assert_bool(Wildgrass.screens.is_open(&"menu")).is_true()


func test_the_options_rows_their_values_and_their_ends() -> void:
	await _start()
	var options := Wildgrass.screens.open(&"options")
	await get_tree().process_frame
	var names: Array = options.get_node(^"Screen/Rows").get_children().map(func(row: Control) -> String: return (row.get_node(^"Name") as Label).text if row.has_node(^"Name") else (row as Label).text)
	assert_array(names).is_equal(["Vitesse du texte", "Langue", "Musique", "Cris des Pokémon", "Autres sons", "Retour"])
	var speeds := options.get_node(^"Screen/Rows/TextSpeed/Choices")
	assert_that((speeds.get_child(1) as Label).get_theme_color(&"font_color")).is_equal(Color(0.878431, 0.188235, 0.12549, 1.0))
	var base: float = Wildgrass.dialogue.config().letters_per_second
	assert_float(Wildgrass.dialogue.letters_per_second).is_equal(base)
	await _tap("ui_right")
	await _tap("ui_right")
	await _tap("ui_right")
	assert_float(Wildgrass.options.value(&"text_speed")).is_equal(4.0)
	assert_float(Wildgrass.dialogue.letters_per_second).is_equal(base * 4.0)
	assert_that((speeds.get_child(3) as Label).get_theme_color(&"font_color")).is_equal(Color(0.878431, 0.188235, 0.12549, 1.0))
	await _tap("ui_down")
	await _tap("ui_right")
	assert_str(Wildgrass.texts.language).is_equal("en")
	assert_str((options.get_node(^"Screen/Rows/Language/Name") as Label).text).is_equal("Langue")
	assert_str(tr("Langue")).is_equal("Language")
	await _tap("ui_right")
	assert_str(Wildgrass.texts.language).is_equal("en")
	await _tap("ui_left")
	assert_str(Wildgrass.texts.language).is_equal("fr")
	await _tap("ui_down")
	assert_str((options.get_node(^"Screen/Rows/MusicVolume/Value") as Label).text).is_equal("100 %")
	await _tap("ui_right")
	assert_int(Wildgrass.options.value(&"music_volume")).is_equal(100)
	await _tap("ui_left")
	assert_str((options.get_node(^"Screen/Rows/MusicVolume/Value") as Label).text).is_equal("95 %")
