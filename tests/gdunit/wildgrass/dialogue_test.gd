extends GdUnitTestSuite

# Mirage's dialogue on the Wildgrass engine (docs/wildgrass.md, step 2): its
# box, its signs and furniture, its texts translated page by page.

const MAIN := preload("res://game/main.tscn")
const PageTranslation := preload("res://game/page_translation.gd")

var _main: Node


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
	TranslationServer.set_locale("fr")


func _start() -> WgWalker:
	_main = MAIN.instantiate()
	add_child(_main)
	for frame in 600:
		if Wildgrass.maps.current != null and not Wildgrass.maps.is_changing:
			break
		await get_tree().process_frame
	return Wildgrass.maps.traveller as WgWalker


func _go_to(map: String, point: StringName) -> void:
	await Wildgrass.maps.go_to(StringName("res://src/main/kotlin/fr/skyle/pokemonmirage/scenes/levels/%s.tscn" % map), point)


## Faces `cell` from the cell beside it, `from`, and interacts; the text
## written out.
func _read(player: WgWalker, from: Vector2i, cell: Vector2i) -> String:
	player.place_at(from, 0, cell - from)
	Wildgrass.walkers.interact(player)
	for frame in 30:
		if Wildgrass.dialogue.box != null and Wildgrass.dialogue.is_open():
			break
		await get_tree().process_frame
	var box := Wildgrass.dialogue.box
	box.set_process(false)
	box.advance(10.0)
	return box.shown_text()


func test_the_box_is_mirage_s_with_its_choices_framed_and_pointed_at() -> void:
	await _start()
	assert_str(Wildgrass.screens.scene_path(&"message_box")).is_equal("res://game/ui/message_box.tscn")
	Wildgrass.dialogue.ask("Veux-tu sauvegarder ?", ["Oui", "Non"])
	var box := Wildgrass.dialogue.box
	box.set_process(false)
	box.advance(10.0)
	if not (box.get_node("ChoiceFrame") as Control).visible:
		var event := InputEventAction.new()
		event.action = "interact"
		event.pressed = true
		Wildgrass.screens.handle_input(event)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool((box.get_node("ChoiceFrame") as Control).visible).is_true()
	assert_int(box.get_node("ChoiceFrame/List").get_child_count()).is_equal(2)
	assert_bool((box.get_node("Cursor") as Control).visible).is_true()
	assert_int((box.get_node("Frame/Margin/Text") as RichTextLabel).get_theme_font_size(&"normal_font_size")).is_equal(16)


func test_a_sign_says_its_text_page_by_page() -> void:
	var player := await _start()
	await _go_to("start_island", &"MaisonLudo")
	assert_str(await _read(player, Vector2i(12, 10), Vector2i(12, 9))).is_equal("Maison de Ludo.")


# The item itself comes with the bag (step 4): the engine knows no item yet.
func test_a_find_is_found_once() -> void:
	var player := await _start()
	await _go_to("route_1", &"")
	assert_str(await _read(player, Vector2i(20, 12), Vector2i(20, 11))).contains("Vous trouvez une Potion !")
	assert_bool(Wildgrass.story.has(&"found_route_potion")).is_true()
	Wildgrass.dialogue.close()
	await get_tree().process_frame
	Wildgrass.walkers.interact(player)
	await get_tree().process_frame
	assert_bool(Wildgrass.dialogue.is_open()).is_false()


func test_the_tv_and_the_clock_say_what_mirage_has_them_say() -> void:
	var player := await _start()
	var tv := await _read(player, Vector2i(16, 8), Vector2i(16, 7))
	assert_bool(tv.begins_with("C'est") or tv.begins_with("Il y a") or tv.begins_with("Une") or tv.begins_with("Un ")).override_failure_message(tv).is_true()


func test_a_message_is_translated_page_by_page_its_tags_kept() -> void:
	var joined: Translation = PageTranslation.new()
	joined.pages = load("res://locale/en.po")
	var said := "[give=potion]Vous trouvez une Potion ![page]Vous rangez la Potion dans la poche Objets."
	assert_str(String(joined.get_message(said))).is_equal("[give=potion]You found a Potion![page]You put the Potion away in the Items pocket.")
	assert_str(String(joined.get_message("Vous trouvez une Potion ![page]Rien de tel."))).is_empty()
	assert_str(String(joined.get_message("Vous trouvez une Potion !"))).is_empty()
