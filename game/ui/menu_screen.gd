## Mirage's pause menu, on the engine's: a column of entries in a frame in
## the top right corner, a cursor at the start of the line. The cursor wraps
## at both ends and starts from the first entry at each opening; it keeps its
## place only while a screen opened from the menu shows. The frame fits the
## entries shown, sixteen pixels each.
extends WgMenuScreen

const PixelShadow := preload("res://game/ui/pixel_shadow.gd")
const MenuKeys := preload("res://game/ui/menu_keys.gd")
## A line's height, and the frame around the lines.
const ROW := 16.0
const MARGINS := 16.0

@export_group("Mirage")
@export var panel: NodePath = ^"Menu"
@export var frame: NodePath = ^"Menu/Frame"
@export var cursor: NodePath = ^"Menu/Cursor"

var _keys: MenuKeys
var _model: Label
var _labels: Array[Label] = []


func _on_open(args: Dictionary) -> void:
	var entries := get_node(list)
	_model = entries.get_child(0) as Label
	for child in entries.get_children():
		entries.remove_child(child)
		if child != _model:
			child.free()
	var menu_service: Variant = args.get("menu", get_node(^"/root/Wildgrass").get(&"menu"))
	# Each opening starts from the first entry.
	if menu_service != null and not menu_service.shown().is_empty():
		menu_service.cursor = menu_service.shown()[0]["id"]
	super(args)
	if dialogue != null:
		_keys = MenuKeys.new(dialogue)


func _on_close() -> void:
	super()
	if is_instance_valid(_model) and _model.get_parent() == null:
		_model.free()


func _on_input(event: InputEvent) -> bool:
	if _keys == null or _busy:
		return super(event)
	var key := _keys.key_of(event)
	match key:
		"up":
			_move(-1)
		"down":
			_move(1)
		"confirm":
			_run()
		"cancel":
			close()
		_:
			return false
	return true


func _process(delta: float) -> void:
	if _keys == null or _busy or is_closed() or not visible or Wildgrass.screens.top() != self:
		return
	for key in _keys.repeats(delta):
		if key == "up" or key == "down":
			_move(-1 if key == "up" else 1)


## The entries whose condition holds now, as Mirage's lines.
func refresh() -> void:
	_shown = menu.shown()
	var entries := get_node(list) as Control
	for label in _labels:
		entries.remove_child(label)
		label.queue_free()
	_labels.clear()
	for entry in _shown:
		var label := _model.duplicate(0) as Label
		label.name = String(entry["id"]).to_pascal_case()
		label.text = tr(entry["text"])
		entries.add_child(label)
		label.add_child(PixelShadow.new())
		_labels.append(label)
	var height := MARGINS + ROW * _shown.size()
	(get_node(panel) as Control).size.y = height
	(get_node(frame) as Control).size.y = height
	entries.size.y = ROW * _shown.size()
	if _cursor() < 0 and not _shown.is_empty():
		menu.cursor = _shown[0]["id"]
	_show_cursor()


func _show_cursor() -> void:
	var arrow := get_node(cursor) as Control
	var entries := get_node(list) as Control
	arrow.position.y = entries.position.y + ROW * maxi(_cursor(), 0) + (ROW - arrow.size.y) / 2.0
