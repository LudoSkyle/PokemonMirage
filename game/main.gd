## Pokémon Mirage on the Wildgrass engine: the player, made once, then the
## first map. The title screen comes with step 4 of docs/wildgrass.md.
extends Node

const PLAYER := preload("res://game/player.tscn")
const PageTranslation := preload("res://game/page_translation.gd")
## Mirage's maps are found by name in their folder (`wildgrass/paths/maps`).
const START_MAP := &"ludo_bedroom"

## The pause menu's entries and the options' names: Mirage's words.
# i18n
const WORDS: Array[String] = [
	"Pokédex",
	"Sac",
	"Sauvegarder",
	"Options",
	"Debug",
	"Quitter",
	"Vitesse du texte",
	"Langue",
	"Musique",
	"Cris des Pokémon",
	"Autres sons",
	"Jouer",
]

## False: no title, straight to the first map (the tests).
@export var title := true

var _translations: Array[Translation] = []


func _ready() -> void:
	# Until the switch, the Kotlin game keeps its own SubViewport: the engine's
	# display config is applied here, not from config/display.json.
	var display := WgDisplayConfig.new()
	display.resolution = Vector2i(320, 240)
	display.window_scale = 4
	Wildgrass.display.apply(display, get_window())
	_translations = PageTranslation.install()
	# Before the story's own, which drops what the story does not show: the
	# Kotlin character goes even when its twin is not there.
	Wildgrass.hooks.add(&"map_built", &"mirage_characters", _swap_characters, -1)
	Wildgrass.hooks.add(&"map_built", &"mirage_story", _follow_the_story, -1)
	Wildgrass.maps.door_used.connect(_leave)
	_dress_menu()
	_dress_options()
	Wildgrass.hooks.add(&"save_summary", &"mirage_place", _summary_place)
	Wildgrass.maps.traveller = PLAYER.instantiate()
	if title:
		# The key on the title always opens the choice of a game: its cards
		# hold "Nouvelle partie" and "Options".
		Wildgrass.title.add_choice(&"play", "Jouer", Wildgrass.title.choose_game)
		Wildgrass.title.start()
	else:
		await Wildgrass.maps.go_to(START_MAP, &"Spawn")


func _exit_tree() -> void:
	Wildgrass.hooks.remove(&"map_built", &"mirage_characters")
	Wildgrass.hooks.remove(&"map_built", &"mirage_story")
	Wildgrass.maps.door_used.disconnect(_leave)
	Wildgrass.hooks.remove(&"save_summary", &"mirage_place")
	PageTranslation.uninstall(_translations)


## The Kotlin characters make way for their engine twins, kept under
## `Twins/Characters` while both games share the maps.
func _swap_characters(map: WgMap, _map_id: StringName) -> void:
	var twins := map.get_node_or_null(^"Twins/Characters")
	var entities := map.get_node_or_null(map.entities)
	if twins == null or entities == null:
		return
	for character: Node in twins.get_children():
		var kotlin := entities.get_node_or_null(NodePath(character.name))
		if kotlin != null:
			entities.remove_child(kotlin)
			kotlin.free()
		character.owner = null
		twins.remove_child(character)
		entities.add_child(character)
		character.owner = map
	twins.free()


## The Kotlin furniture shown at some steps of the story (the bell's stand,
## the library's archives) would follow the Kotlin story, which stays still
## on the engine path: the engine's decides, before they enter the tree.
func _follow_the_story(map: WgMap, _map_id: StringName) -> void:
	var twins := map.get_node_or_null(^"Twins")
	for node: Node in map.find_children("*", "", true, false):
		if not is_instance_valid(node) or not "required_flag" in node or (twins != null and twins.is_ancestor_of(node)):
			continue
		var required := str(node.get(&"required_flag"))
		var forbidden := str(node.get(&"forbidden_flag"))
		if required.is_empty() and forbidden.is_empty():
			continue
		var terms: Array[String] = []
		if not required.is_empty():
			terms.append(required)
		if not forbidden.is_empty():
			terms.append("!" + forbidden)
		if Wildgrass.story.check(", ".join(terms)):
			node.set(&"required_flag", "")
			node.set(&"forbidden_flag", "")
		else:
			node.get_parent().remove_child(node)
			node.free()


## Leaving a map by a door may move the story on: its `on_leave` metadata,
## `flag set > flag to set`, rules split by `|`. On the island,
## `bell_hung > vigil_over`: leaving it after the vigil ends it.
func _leave(_door: WgDoor) -> void:
	var map := Wildgrass.maps.current
	if map == null:
		return
	for rule: String in str(map.get_meta(&"on_leave", "")).split("|", false):
		var parts := rule.split(">")
		if parts.size() == 2 and not parts[0].strip_edges().is_empty() and not parts[1].strip_edges().is_empty() and Wildgrass.story.has(StringName(parts[0].strip_edges())):
			Wildgrass.story.set_flag(StringName(parts[1].strip_edges()))


## The pause menu in Mirage's words and order: Pokédex, Bag, Save, Options,
## Debug, Quit.
func _dress_menu() -> void:
	var menu := Wildgrass.menu
	menu.add_entry(&"bag", "Sac", menu.open_bag)
	menu.add_entry(&"save", "Sauvegarder", menu.open_save, "!save_disabled")
	menu.add_entry(&"exit", "Quitter", menu.exit)
	menu.remove_entry(&"options")
	menu.add_entry(&"options", "Options", menu.open_options, "", &"debug" if &"debug" in menu.entries() else &"exit")


## Mirage's options: the text speed from x0.5 to x4 (x1, 0.02 s a letter,
## by default), under an id of its own so that a speed the engine's option
## kept is not read as Mirage's; the language, three volumes by steps of five.
func _dress_options() -> void:
	var options := Wildgrass.options
	var dialogue := Wildgrass.dialogue
	options.add_option(&"text_speed", {
		"name": "Vitesse du texte",
		"values": [0.5, 1.0, 2.0, 4.0],
		"texts": ["x0.5", "x1", "x2", "x4"],
		"default": 1.0,
		"apply": func(factor: Variant) -> void: dialogue.letters_per_second = dialogue.config().letters_per_second * float(factor),
	})
	for renamed: Array in [[&"language", "Langue"], [&"music_volume", "Musique"], [&"cries_volume", "Cris des Pokémon"], [&"effects_volume", "Autres sons"]]:
		var option: Dictionary = options.option(renamed[0]).duplicate()
		if option.is_empty():
			continue
		option["name"] = renamed[1]
		if option.has("format"):
			option["format"] = "%d %%"
		options.add_option(renamed[0], option)


## A game's card names its place as the map does: its `location` metadata,
## in French, translated where it shows.
func _summary_place(summary: Dictionary, _slot: int) -> Dictionary:
	var map := Wildgrass.maps.current
	if map != null:
		summary["location"] = str(map.get_meta(&"location", ""))
		summary["banner"] = str(map.get_meta(&"banner", ""))
	return summary
