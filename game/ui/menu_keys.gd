## Mirage's menu keys, with repeat: a press moves the cursor once; held, it
## goes again after a short delay, then at a steady pace, to run down a long
## list. A key already held when the menu opens does not count.
extends RefCounted

## Seconds before the first repeat.
const DELAY := 0.35
## Seconds between two repeats.
const INTERVAL := 0.11
## The keys that repeat, as the dialogue config names them.
const KEYS: Array[String] = ["up", "down", "left", "right"]

## The dialogue service: its config names the input actions.
var dialogue: Object
var _left := {}


func _init(dialogue_service: Object) -> void:
	dialogue = dialogue_service


## The key `event` presses (`confirm`, `cancel`, `up`…), or "". A press
## starts that key's repeat.
func key_of(event: InputEvent) -> String:
	for key: String in ["confirm", "cancel"] + KEYS:
		if dialogue.is_action(event, key):
			if key in KEYS:
				_left[key] = DELAY
			return key
	return ""


## The keys that repeat this frame, `delta` seconds after the last.
func repeats(delta: float) -> Array[String]:
	var fired: Array[String] = []
	for key: String in _left.keys():
		var action: String = dialogue.config().actions[key]
		if not Input.is_action_pressed(action):
			_left.erase(key)
			continue
		_left[key] -= delta
		if _left[key] <= 0.0:
			_left[key] += INTERVAL
			fired.append(key)
	return fired
