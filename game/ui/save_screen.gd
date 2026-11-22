## Mirage's save screen, on the engine's: where the game is and how long it
## was played in a frame in the top left corner, the questions in the message
## box, the saved message held a second; then everything closes, the menu
## too. No, or the menu key, goes back to the menu writing nothing.
extends WgSaveScreen

const PixelShadow := preload("res://game/ui/pixel_shadow.gd")

## Mirage's questions, translated by the message box.
# i18n
const TEXTS: Array[String] = [
	"Voulez-vous sauvegarder la partie ?",
	"Une sauvegarde existe déjà.\nVoulez-vous l'écraser ?",
	"La partie est sauvegardée.",
	"La partie n'a pas pu être sauvegardée.",
]


func _on_open(args: Dictionary) -> void:
	save_text = TEXTS[0]
	overwrite_text = TEXTS[1]
	saved_text = TEXTS[2]
	failed_text = TEXTS[3]
	for label: Label in find_children("*", "Label", true, false):
		label.add_child(PixelShadow.new())
	super(args)


## The place, as the map names it, and the play time as `hh:mm`.
func _show_summary(summary: Dictionary) -> void:
	(get_node(place) as Label).text = tr(str(summary.get("location", "")))
	var minutes := int(float(summary.get("seconds", 0.0)) / 60.0)
	(get_node(time) as Label).text = "%02d:%02d" % [minutes / 60, minutes % 60]
