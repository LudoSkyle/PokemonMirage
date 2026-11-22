## Mirage's text shadow: a copy of its parent text one game pixel to the
## right, another one below, under the text's own shadow on the diagonal,
## kept in step with it every frame: its text, the letters shown and, for
## the message box that turns pages by scrolling, the line at the top.
extends Node

const OFFSETS: Array[Vector2] = [Vector2(1, 0), Vector2(0, 1)]

var _source: Control
var _copies: Array[Control] = []


func _ready() -> void:
	_source = get_parent() as Control
	if not (_source is Label or _source is RichTextLabel):
		push_error("%s: a pixel shadow goes in a Label or a RichTextLabel" % name)
		return
	var colour_name := &"default_color" if _source is RichTextLabel else &"font_color"
	var shade := _source.get_theme_color(&"font_shadow_color")
	for offset in OFFSETS:
		var copy := _source.duplicate(0) as Control
		for child in copy.get_children():
			child.free()
		copy.name = "Shadow%d" % _copies.size()
		copy.add_theme_color_override(colour_name, shade)
		copy.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0))
		copy.show_behind_parent = true
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.set_anchors_preset(Control.PRESET_FULL_RECT)
		copy.offset_left = offset.x
		copy.offset_right = offset.x
		copy.offset_top = offset.y
		copy.offset_bottom = offset.y
		_source.add_child.call_deferred(copy)
		_copies.append(copy)


func _process(_delta: float) -> void:
	if _source == null:
		return
	for copy in _copies:
		if copy.get(&"text") != _source.get(&"text"):
			copy.set(&"text", _source.get(&"text"))
		if _source is RichTextLabel:
			var rich := _source as RichTextLabel
			var shade := copy as RichTextLabel
			shade.visible_characters_behavior = rich.visible_characters_behavior
			shade.visible_characters = rich.visible_characters
			shade.get_v_scroll_bar().value = rich.get_v_scroll_bar().value
		else:
			copy.set(&"visible_characters", _source.get(&"visible_characters"))
