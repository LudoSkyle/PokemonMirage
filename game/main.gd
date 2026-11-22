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
	Wildgrass.maps.traveller = PLAYER.instantiate()
	await Wildgrass.maps.go_to(START_MAP, &"Spawn")


func _exit_tree() -> void:
	PageTranslation.uninstall(_translations)
