extends GdUnitTestSuite

# Mirage's items on the Wildgrass engine (docs/wildgrass.md, step 4): its
# catalog, its pockets, and a key item shown when given.

const MAIN := preload("res://game/main.tscn")

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


func _start() -> void:
	_main = MAIN.instantiate()
	_main.title = false
	add_child(_main)
	for frame in 600:
		if Wildgrass.maps.current != null and not Wildgrass.maps.is_changing:
			break
		await get_tree().process_frame


func test_the_catalog_is_mirage_s_with_its_icons() -> void:
	var ids := Wildgrass.items.ids()
	assert_int(ids.size()).is_equal(17)
	var potion := Wildgrass.items.item(&"potion")
	assert_str(potion.name).is_equal("Potion")
	assert_that(potion.pocket).is_equal(&"items")
	assert_bool(potion.consumed).is_true()
	assert_str(potion.icon.resource_path).ends_with("assets/items/icons/potion.png")
	var ribbon := Wildgrass.items.item(&"vigil_ribbon")
	assert_that(ribbon.pocket).is_equal(&"key_items")
	assert_bool(ribbon.consumed).is_false()
	assert_str(ribbon.icon.resource_path).ends_with("assets/items/icons/other/07_F_2_fan.png")
	assert_str(Wildgrass.items.item(&"tarnished_bell").icon.resource_path).ends_with("icons/custom/tarnished_bell.png")
	assert_that(Wildgrass.items.item(&"poke_ball").pocket).is_equal(&"balls")


func test_the_pockets_are_mirage_s_in_its_order() -> void:
	var pockets: Array = Wildgrass.bag.config().pockets
	assert_array(pockets.map(func(pocket: Dictionary) -> String: return pocket["id"])).is_equal(["items", "key_items", "balls"])
	assert_str(tr(pockets[1]["name"])).is_equal("Objets rares")
	TranslationServer.set_locale("en")
	assert_str(tr(pockets[1]["name"])).is_equal("Key Items")


func test_a_key_item_given_shows_in_mirage_s_frame_and_fades() -> void:
	await _start()
	Wildgrass.dialogue.say("[give=tarnished_bell]Vous repêchez la Cloche ternie !")
	var reveal: WgScreen = null
	for frame in 60:
		reveal = Wildgrass.screens.top() if Wildgrass.screens.is_open(&"item_reveal") else null
		if reveal != null:
			break
		await get_tree().process_frame
	assert_object(reveal).is_not_null()
	assert_str(reveal.scene_file_path).is_equal("res://game/ui/item_reveal.tscn")
	assert_object((reveal.get_node(^"Panel/Icon") as TextureRect).texture).is_same(Wildgrass.items.item(&"tarnished_bell").icon)
	var panel := reveal.get_node(^"Panel") as Control
	assert_float(panel.modulate.a).is_less(1.0)
	await get_tree().create_timer(0.3).timeout
	assert_float(panel.modulate.a).is_equal(1.0)
	assert_int(Wildgrass.bag.count(&"tarnished_bell")).is_equal(1)
	reveal.close()
	assert_bool(reveal.is_closed()).is_true()
	assert_bool(is_instance_valid(reveal)).is_true()
	await get_tree().create_timer(0.3).timeout
	assert_bool(is_instance_valid(reveal)).is_false()


func test_the_bell_s_stand_follows_the_engine_s_story() -> void:
	await _start()
	var island := &"res://src/main/kotlin/fr/skyle/pokemonmirage/scenes/levels/start_island.tscn"
	await Wildgrass.maps.go_to(island, &"MaisonLudo")
	assert_object(Wildgrass.maps.current.get_node_or_null(^"World/BellStandEmpty")).is_not_null()
	assert_object(Wildgrass.maps.current.get_node_or_null(^"World/BellStand")).is_null()
	# Hanging the bell reloads the map ([reload]).
	Wildgrass.story.set_flag(&"bell_hung")
	await Wildgrass.maps.reload()
	assert_object(Wildgrass.maps.current.get_node_or_null(^"World/BellStandEmpty")).is_null()
	assert_object(Wildgrass.maps.current.get_node_or_null(^"World/BellStand")).is_not_null()
