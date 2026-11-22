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
	Wildgrass.maps.traveller = PLAYER.instantiate()
	await Wildgrass.maps.go_to(START_MAP, &"Spawn")


func _exit_tree() -> void:
	Wildgrass.hooks.remove(&"map_built", &"mirage_characters")
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
		character.reparent(entities, false)
	twins.free()
