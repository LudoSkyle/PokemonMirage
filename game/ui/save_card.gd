## A card of Mirage's choice of a game. Two faces in one scene: `Save`, a
## saved game (its number, the player's portrait, the place, the badges, the
## Pokédex, the play time and the party's six cells), and `Action`, a bar
## with a text ("Nouvelle partie", "Options"). Badges, the Pokédex and the
## party are not counted yet: the card shows what the game holds.
extends Control

const PixelShadow := preload("res://game/ui/pixel_shadow.gd")


func _ready() -> void:
	for label: Label in find_children("*", "Label", true, false):
		label.add_child(PixelShadow.new())


## Shows the game of `slot`, from its summary.
func show_save(slot: int, summary: Dictionary) -> void:
	($Save as CanvasItem).visible = true
	($Action as CanvasItem).visible = false
	_write(^"Save/Title", tr("Partie %d") % slot)
	_write(^"Save/Location", tr(str(summary.get("location", ""))))
	_write(^"Save/Badges/Value", str(int(summary.get("badges", 0))))
	_write(^"Save/Pokedex/Value", str(int(summary.get("pokedex", 0))))
	var minutes := int(float(summary.get("seconds", 0.0)) / 60.0)
	_write(^"Save/Time/Value", "%02d:%02d" % [minutes / 60, minutes % 60])


## Shows a bar with a text alone, already translated.
func show_action(text: String) -> void:
	($Save as CanvasItem).visible = false
	($Action as CanvasItem).visible = true
	_write(^"Action/Text", text)


func _write(path: NodePath, text: String) -> void:
	(get_node(path) as Label).text = text
