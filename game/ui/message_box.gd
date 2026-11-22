## Mirage's message box: the engine's, its choices two pixels above it, as
## the Kotlin box set them.
extends WgMessageBox

## The gap between the choices and the box.
const CHOICE_GAP := 2.0


func _place_choices() -> void:
	super()
	if _choices != null and str(_options.get("place", "bottom")) != "top":
		_choices.position.y -= CHOICE_GAP
