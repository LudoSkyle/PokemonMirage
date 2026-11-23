extends GdUnitTestSuite

# Mirage's title and choice of a game on the Wildgrass engine (docs/title.md).

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
	Wildgrass.title.remove_choice(&"play")
	Wildgrass.title.add_choice(&"play", "wg.title.play", Wildgrass.title.play, "", &"options")
	TranslationServer.set_locale(_locale)


## A game kept in `slot`, on `map` at `cell`, played `seconds`, written by
## the game started (its hooks name the place), then the title back.
func _plant(slot: int, map: StringName, cell: Vector2i, seconds: float) -> void:
	var player := Wildgrass.maps.traveller as WgWalker
	await Wildgrass.maps.go_to(map, &"")
	player.place_at(cell, 0, Vector2i.LEFT)
	Wildgrass.save.new_game(slot)
	Wildgrass.clock.restore({"seconds": seconds})
	Wildgrass.story.set_flag(&"bell_told")
	assert_bool(Wildgrass.save.write()).is_true()
	Wildgrass.maps.clear()
	Wildgrass.save.reset()


func _start() -> WgScreen:
	_main = MAIN.instantiate()
	add_child(_main)
	for frame in 30:
		if Wildgrass.screens.is_open(&"title"):
			break
		await get_tree().process_frame
	return Wildgrass.screens.top()


func _tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Wildgrass.screens.handle_input(event)
	await get_tree().process_frame
	await get_tree().process_frame


func _settled() -> void:
	for frame in 600:
		if Wildgrass.maps.current != null and not Wildgrass.maps.is_changing and Wildgrass.screens.stack().is_empty():
			return
		await get_tree().process_frame


## The title past its arrival, the key pressed: the choice of a game.
func _open_slots() -> WgScreen:
	var title: WgScreen = Wildgrass.screens.top() if Wildgrass.screens.is_open(&"title") else await _start()
	title.advance(2.0)
	await _tap("interact")
	return Wildgrass.screens.top()


func _cards(slots: WgScreen) -> Array:
	return slots.get_node(^"Strip").get_children().map(func(card: Node) -> String: return String(card.name))


func _answers(slots: WgScreen) -> Array:
	var shown: Array = []
	for label: Label in slots.get_node(^"Choices/Entries").get_children():
		if label.visible and slots.get_node(^"Choices").visible:
			shown.append(label.text)
	return shown


func test_the_title_is_mirage_s_and_waits_for_the_key() -> void:
	var title := await _start()
	assert_str(title.scene_file_path).is_equal("res://game/ui/title_screen.tscn")
	assert_object(Wildgrass.maps.current).is_null()
	assert_bool((title.get_node(^"Logo") as CanvasItem).visible).is_false()
	title.advance(1.2)
	assert_bool((title.get_node(^"Logo") as CanvasItem).visible).is_true()
	assert_float((title.get_node(^"Veil") as CanvasItem).modulate.a).is_equal(0.0)
	# "Press Enter" blinks: shown 0.7 s, hidden 0.4 s.
	assert_bool((title.get_node(^"Prompt") as CanvasItem).visible).is_true()
	title.advance(0.8)
	assert_bool((title.get_node(^"Prompt") as CanvasItem).visible).is_false()
	assert_int(title.get_node(^"Backdrop/FarFlyers").get_child_count()).is_equal(3)
	assert_int(title.get_node(^"Backdrop/NearFlyers").get_child_count()).is_equal(1)


func test_with_no_game_the_cards_are_new_game_and_options() -> void:
	var slots := await _open_slots()
	assert_str(slots.scene_file_path).is_equal("res://game/ui/save_slots_screen.tscn")
	assert_array(_cards(slots)).is_equal(["New", "Options"])
	assert_bool((slots.get_node(^"Title") as CanvasItem).visible if slots.has_node(^"Title") else true).is_true()
	# Left from the first card wraps to the last.
	await _tap("ui_left")
	assert_int(slots.selected()).is_equal(WgSaveSlotsScreen.OPTIONS_CARD)
	await _tap("ui_right")
	await _tap("menu")
	assert_bool(Wildgrass.screens.is_open(&"save_slots")).is_false()
	assert_bool(Wildgrass.screens.is_open(&"title")).is_true()


func test_a_new_game_starts_in_ludo_s_bedroom_on_the_rug_facing_down() -> void:
	await _open_slots()
	await _tap("interact")
	await _settled()
	assert_that(Wildgrass.maps.id_of(Wildgrass.maps.current)).is_equal(&"ludo_bedroom")
	var player := Wildgrass.maps.traveller as WgWalker
	assert_that(player.cell).is_equal(Vector2i(15, 11))
	assert_that(player.facing).is_equal(Vector2i.DOWN)
	assert_int(Wildgrass.save.slot).is_equal(1)


func test_a_saved_game_s_card_and_continuing_it() -> void:
	await _start()
	await _plant(1, &"start_island", Vector2i(20, 20), 3754.0)
	var slots := await _open_slots()
	assert_array(_cards(slots)).is_equal(["Save1", "New", "Options"])
	var card := slots.get_node(^"Strip/Save1")
	assert_str((card.get_node(^"Save/Title") as Label).text).is_equal("Partie 1")
	assert_str((card.get_node(^"Save/Location") as Label).text).is_equal("Bourg-Ludo")
	assert_str((card.get_node(^"Save/Time/Value") as Label).text).is_equal("01:02")
	assert_int(card.get_node(^"Save/Team").get_child_count()).is_equal(6)
	assert_float((slots.get_node(^"Strip/New") as CanvasItem).modulate.a).is_equal_approx(0.55, 0.001)
	await _tap("interact")
	assert_array(_answers(slots)).is_equal(["Continuer", "Effacer", "Retour"])
	assert_bool((slots.get_node(^"Left") as CanvasItem).visible).is_false()
	await _tap("interact")
	await _settled()
	assert_that(Wildgrass.maps.id_of(Wildgrass.maps.current)).is_equal(&"start_island")
	assert_that((Wildgrass.maps.traveller as WgWalker).cell).is_equal(Vector2i(20, 20))
	assert_bool(Wildgrass.story.has(&"bell_told")).is_true()


func test_erasing_asks_with_no_first_then_the_card_goes() -> void:
	await _start()
	await _plant(1, &"start_island", Vector2i(20, 20), 60.0)
	var slots := await _open_slots()
	await _tap("interact")
	await _tap("ui_down")
	await _tap("interact")
	assert_str((slots.get_node(^"Footer/Hint") as Label).text).is_equal("Effacer la partie 1 ?")
	assert_array(_answers(slots)).is_equal(["Oui", "Non"])
	# The cursor waits on No.
	await _tap("interact")
	assert_bool(Wildgrass.save.has(1)).is_true()
	assert_str((slots.get_node(^"Footer/Hint") as Label).text).is_equal("")
	await _tap("interact")
	await _tap("ui_down")
	await _tap("interact")
	await _tap("ui_up")
	await _tap("interact")
	assert_bool(Wildgrass.save.has(1)).is_false()
	await get_tree().process_frame
	assert_array(_cards(slots)).is_equal(["New", "Options"])


func test_three_games_leave_no_new_game_card() -> void:
	await _start()
	for slot in range(1, 4):
		await _plant(slot, &"ludo_house", Vector2i(10, 10), 0.0)
	var slots := await _open_slots()
	assert_array(_cards(slots)).is_equal(["Save1", "Save2", "Save3", "Options"])


func test_the_options_card_opens_the_options_and_comes_back_to_it() -> void:
	var slots := await _open_slots()
	await _tap("ui_right")
	await _tap("interact")
	assert_bool(Wildgrass.screens.is_open(&"options")).is_true()
	await _tap("menu")
	assert_bool(Wildgrass.screens.is_open(&"options")).is_false()
	assert_int(slots.selected()).is_equal(WgSaveSlotsScreen.OPTIONS_CARD)
