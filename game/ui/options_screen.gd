## Mirage's options, on the engine's: one row per option, its values side by
## side with the chosen one in red, or its volume; Back at the end. Up and
## down change row, wrapping; left and right change the value, stopping at
## both ends, applied and kept at once. Back, or the menu key, closes.
extends WgOptionsScreen

const PixelShadow := preload("res://game/ui/pixel_shadow.gd")
const MenuKeys := preload("res://game/ui/menu_keys.gd")
const INK := Color(0.345098, 0.345098, 0.313725, 1.0)
const CHOSEN := Color(0.878431, 0.188235, 0.12549, 1.0)

@export_group("Mirage")
@export var rows_box: NodePath = ^"Screen/Rows"
@export var cursor_node: NodePath = ^"Screen/Cursor"
## The option of each row of the scene, by the row's name; a row of none
## closes the screen.
@export var row_options: Dictionary[String, StringName] = {
	"TextSpeed": &"text_speed",
	"Language": &"language",
	"MusicVolume": &"music_volume",
	"CriesVolume": &"cries_volume",
	"SoundsVolume": &"effects_volume",
}

var _keys: MenuKeys
var _rows: Array[Control] = []
var _row := 0


func _on_open(args: Dictionary) -> void:
	for row in get_node(rows_box).get_children():
		_rows.append(row)
	for label: Label in find_children("*", "Label", true, false):
		label.add_child(PixelShadow.new())
	super(args)
	if dialogue != null:
		_keys = MenuKeys.new(dialogue)
	# The rows are laid out at the next frame: the cursor follows them then.
	refresh.call_deferred()


func _on_input(event: InputEvent) -> bool:
	if _keys == null:
		return false
	var key := _keys.key_of(event)
	if key.is_empty():
		return false
	_press(key)
	return true


func _process(delta: float) -> void:
	if _keys == null or is_closed() or Wildgrass.screens.top() != self:
		return
	for key in _keys.repeats(delta):
		# Left and right change a setting, not a place in a list: no repeat.
		if key == "up" or key == "down":
			_press(key)


## The option of the row under the cursor; none on Back.
func selected() -> StringName:
	return row_options.get(String(_rows[_row].name), &"") if not _rows.is_empty() else &""


func refresh() -> void:
	for row in _rows:
		var id: StringName = row_options.get(String(row.name), &"")
		if id.is_empty() or not options.has_option(id):
			continue
		var choices := row.get_node_or_null(^"Choices")
		if choices != null:
			var at := options.values_of(id).find(options.value(id))
			for index in choices.get_child_count():
				(choices.get_child(index) as Label).add_theme_color_override(&"font_color", CHOSEN if index == at else INK)
		var shown := row.get_node_or_null(^"Value") as Label
		if shown != null:
			shown.text = options.text_of(id)
	if _rows.is_empty():
		return
	var current := _rows[_row]
	var arrow := get_node(cursor_node) as Control
	var box := get_node(rows_box) as Control
	arrow.position.y = box.position.y + current.position.y + (current.size.y - arrow.size.y) / 2.0


func _press(key: String) -> void:
	match key:
		"cancel":
			close()
			return
		"down":
			_row = wrapi(_row + 1, 0, _rows.size())
		"up":
			_row = wrapi(_row - 1, 0, _rows.size())
		"left", "right":
			var id := selected()
			if not id.is_empty():
				var values := options.values_of(id)
				var at := values.find(options.value(id)) + (1 if key == "right" else -1)
				# No wrap: both ends stop.
				if at >= 0 and at < values.size():
					options.set_value(id, values[at])
		"confirm":
			if selected().is_empty():
				close()
				return
	refresh()
