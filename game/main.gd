## Pokémon Mirage on the Wildgrass engine: the player, made once, then the
## first map. The title screen comes with step 4 of docs/wildgrass.md.
extends Node

const PLAYER := preload("res://game/player.tscn")
const PageTranslation := preload("res://game/page_translation.gd")
const START_MAP := &"res://src/main/kotlin/fr/skyle/pokemonmirage/scenes/levels/ludo_bedroom.tscn"

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
	Wildgrass.maps.traveller = PLAYER.instantiate()
	await Wildgrass.maps.go_to(START_MAP, &"Spawn")


func _exit_tree() -> void:
	Wildgrass.hooks.remove(&"map_built", &"mirage_characters")
	Wildgrass.hooks.remove(&"map_built", &"mirage_story")
	Wildgrass.maps.door_used.disconnect(_leave)
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
