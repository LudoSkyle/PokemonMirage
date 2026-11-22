## The text of its parent button, as a Label, for Mirage's pixel shadow to
## follow: the button draws its own text transparent. The message box's
## choices are buttons it copies from a model; this Label goes with each copy.
extends Label


func _process(_delta: float) -> void:
	var button := get_parent() as Button
	if button != null and text != button.text:
		text = button.text
