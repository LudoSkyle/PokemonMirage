extends GdUnitTestSuite

# Mirage's bag screen on the Wildgrass engine (docs/bag.md): its pockets, its
# list ending with Back and scrolling, and tossing an item.

const MAIN := preload("res://game/main.tscn")

var _main: Node
var _locale := ""
var _bag: WgScreen


func before_test() -> void:
	_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("fr")


func after_test() -> void:
	if is_instance_valid(_bag):
		_bag.close()
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


## The game started, the bag filled as the debug tool does, then opened.
func _open(filled := true) -> void:
	_main = MAIN.instantiate()
	_main.title = false
	add_child(_main)
	for frame in 600:
		if Wildgrass.maps.current != null and not Wildgrass.maps.is_changing:
			break
		await get_tree().process_frame
	if filled:
		var counts := {&"potion": 3, &"super_potion": 4, &"hyper_potion": 5, &"antidote": 6, &"revive": 7, &"fresh_water": 8, &"soda_pop": 9, &"lemonade": 10, &"poke_ball": 11, &"repel": 12, &"super_repel": 13}
		for id: StringName in counts:
			Wildgrass.bag.add(id, counts[id])
		Wildgrass.bag.add(&"old_rod")
		Wildgrass.bag.add(&"town_map")
	_bag = Wildgrass.screens.open(&"bag")
	await get_tree().process_frame


func _tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Wildgrass.screens.handle_input(event)
	await get_tree().process_frame


func _rows() -> Array:
	var rows: Array = []
	var names := _bag.get_node(^"Names").get_children()
	var amounts := _bag.get_node(^"Amounts").get_children()
	for index in names.size():
		var name_text: String = names[index].text
		if name_text.is_empty():
			continue
		var amount: String = amounts[index].text
		rows.append(name_text + (" " + amount if not amount.is_empty() else ""))
	return rows


func _text(path: NodePath) -> String:
	return (_bag.get_node(path) as Label).text


func _shown(path: NodePath) -> bool:
	return (_bag.get_node(path) as CanvasItem).visible


func _answers() -> Array:
	var answers: Array = []
	for label: Label in _bag.get_node(^"Choices/Entries").get_children():
		if label.visible:
			answers.append(label.text)
	return answers


func test_it_is_mirage_s_bag() -> void:
	await _open()
	assert_str(_bag.scene_file_path).is_equal("res://game/ui/bag_screen.tscn")
	assert_object(_bag).is_instanceof(WgBagScreen)


func test_the_three_pockets_their_picture_arrows_and_ends() -> void:
	await _open()
	assert_array(_rows()).is_equal(["Potion x3", "Super Potion x4", "Hyper Potion x5", "Antidote x6", "Rappel x7", "Eau Fraîche x8", "Soda Cool x9", "Limonade x10", "Repousse x12"])
	assert_str((_bag.get_node(^"Bag") as TextureRect).texture.resource_path).ends_with("bag_items.png")
	assert_bool(_shown(^"PocketLeft")).is_false()
	assert_bool(_shown(^"PocketRight")).is_true()
	await _tap("ui_left")
	assert_str(_text(^"Title")).is_equal("Objets")
	await _tap("ui_right")
	assert_str(_text(^"Title")).is_equal("Objets rares")
	assert_array(_rows()).is_equal(["Vieille canne", "Carte du village", "Retour"])
	assert_str((_bag.get_node(^"Bag") as TextureRect).texture.resource_path).ends_with("bag_key_items.png")
	assert_bool(_shown(^"PocketLeft") and _shown(^"PocketRight")).is_true()
	assert_bool(_shown(^"ScrollUp") or _shown(^"ScrollDown")).is_false()
	await _tap("ui_right")
	assert_str(_text(^"Title")).is_equal("Poké Balls")
	assert_array(_rows()).is_equal(["Poké Ball x11", "Retour"])
	assert_bool(_shown(^"PocketLeft") and not _shown(^"PocketRight")).is_true()
	await _tap("ui_right")
	assert_str(_text(^"Title")).is_equal("Poké Balls")


func test_the_list_of_nine_rows_scrolls_with_the_cursor_down_to_back() -> void:
	await _open()
	assert_bool(not _shown(^"ScrollUp") and _shown(^"ScrollDown")).is_true()
	for step in 8:
		await _tap("ui_down")
	assert_str(_rows()[0]).is_equal("Potion x3")
	assert_str(_text(^"Description")).starts_with("Un spray dont")
	await _tap("ui_down")
	assert_array(_rows()).is_equal(["Super Potion x4", "Hyper Potion x5", "Antidote x6", "Rappel x7", "Eau Fraîche x8", "Soda Cool x9", "Limonade x10", "Repousse x12", "Super Repousse x13"])
	assert_bool(_shown(^"ScrollUp") and _shown(^"ScrollDown")).is_true()
	await _tap("ui_down")
	assert_str(_rows()[8]).is_equal("Retour")
	assert_bool(_shown(^"ScrollUp") and not _shown(^"ScrollDown")).is_true()
	assert_str(_text(^"Description")).is_equal("Refermer le sac.")
	await _tap("ui_down")
	assert_str(_rows()[8]).is_equal("Retour")
	for step in 9:
		await _tap("ui_up")
	assert_str(_rows()[0]).is_equal("Super Potion x4")
	await _tap("ui_up")
	assert_str(_rows()[0]).is_equal("Potion x3")
	assert_bool(_shown(^"ScrollUp")).is_false()


func test_an_empty_bag_offers_back_alone_which_closes_it() -> void:
	await _open(false)
	assert_array(_rows()).is_equal(["Retour"])
	assert_str(_text(^"Description")).is_equal("Refermer le sac.")
	assert_object((_bag.get_node(^"Icon") as TextureRect).texture).is_not_null()
	await _tap("interact")
	assert_bool(Wildgrass.screens.is_open(&"bag")).is_false()


func test_a_key_item_offers_cancel_alone() -> void:
	await _open()
	await _tap("ui_right")
	await _tap("interact")
	assert_bool(_shown(^"Choices")).is_true()
	assert_array(_answers()).is_equal(["Annuler"])
	await _tap("interact")
	assert_bool(_shown(^"Choices")).is_false()
	assert_int(Wildgrass.bag.count(&"old_rod")).is_equal(1)


func test_tossing_asks_how_many_wrapping_then_yes_or_no() -> void:
	await _open()
	await _tap("interact")
	assert_array(_answers()).is_equal(["Jeter", "Annuler"])
	assert_str(_text(^"Description")).is_equal("Objet choisi : Potion.")
	await _tap("interact")
	assert_bool(_shown(^"Amount")).is_true()
	assert_str(_text(^"Amount/Value")).is_equal("x1")
	assert_str(_text(^"Description")).is_equal("Combien en jeter ?")
	assert_bool(_shown(^"Choices")).is_false()
	for expected: String in ["x2", "x3", "x1"]:
		await _tap("ui_up")
		assert_str(_text(^"Amount/Value")).is_equal(expected)
	for expected: String in ["x3", "x2"]:
		await _tap("ui_down")
		assert_str(_text(^"Amount/Value")).is_equal(expected)
	await _tap("interact")
	assert_str(_text(^"Description")).is_equal("Jeter Potion x2 ?")
	assert_array(_answers()).is_equal(["Oui", "Non"])
	assert_bool(_shown(^"Amount")).is_false()
	# No: nothing is tossed.
	await _tap("ui_down")
	await _tap("interact")
	assert_str(_rows()[0]).is_equal("Potion x3")
	assert_bool(_shown(^"Choices")).is_false()
	# Again, yes this time.
	await _tap("interact")
	await _tap("interact")
	await _tap("ui_up")
	await _tap("interact")
	await _tap("interact")
	assert_str(_text(^"Description")).is_equal("Vous jetez Potion x2.")
	assert_str(_rows()[0]).is_equal("Potion x1")
	assert_int(Wildgrass.bag.count(&"potion")).is_equal(1)
	await _tap("interact")
	assert_str(_text(^"Description")).starts_with("Un spray qui soigne")


func test_held_keys_repeat_after_a_delay() -> void:
	await _open()
	# Held: the action stays pressed after its press.
	Input.action_press("ui_down")
	await _tap("ui_down")
	Wildgrass.dialogue.repeat_keys(0.3)
	assert_str(_text(^"Description")).starts_with("Un spray plus concentré")
	Wildgrass.dialogue.repeat_keys(0.06)
	assert_str(_text(^"Description")).starts_with("Le spray des grands jours")
	Wildgrass.dialogue.repeat_keys(0.11)
	assert_str(_text(^"Description")).starts_with("Un spray qui chasse")
	Input.action_release("ui_down")
	Wildgrass.dialogue.repeat_keys(0.5)
	assert_str(_text(^"Description")).starts_with("Un spray qui chasse")


func test_a_held_left_or_right_turns_one_pocket_only() -> void:
	await _open()
	Input.action_press("ui_right")
	await _tap("ui_right")
	Wildgrass.dialogue.repeat_keys(1.0)
	Wildgrass.dialogue.repeat_keys(1.0)
	Input.action_release("ui_right")
	assert_str(_text(^"Title")).is_equal("Objets rares")
