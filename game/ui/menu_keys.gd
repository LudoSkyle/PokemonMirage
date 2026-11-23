## Mirage's menu keys: the key an event presses, as the dialogue config names
## it. A key held goes again through the engine (the dialogue config's
## `repeating`, each screen's `_repeats()`).
extends RefCounted

## The keys a menu reads, as the dialogue config names them.
const KEYS: Array[String] = ["confirm", "cancel", "up", "down", "left", "right"]

## The dialogue service: its config names the input actions.
var dialogue: Object


func _init(dialogue_service: Object) -> void:
	dialogue = dialogue_service


## The key `event` presses (`confirm`, `cancel`, `up`…), or "".
func key_of(event: InputEvent) -> String:
	for key: String in KEYS:
		if dialogue.is_action(event, key):
			return key
	return ""
