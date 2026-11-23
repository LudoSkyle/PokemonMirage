## Mirage's bag, on the engine's: one pocket at a time, its items then Back,
## and the icon and description of the line under the cursor. Pockets and the
## list stop at their ends; changing pocket goes back to the top. An item asks
## what to do in a small box at the bottom right (Toss and Cancel, Cancel
## alone for a key item); tossing asks how many, the count wrapping, then Yes
## or No, then says what was tossed until a key.
extends WgBagScreen

const PixelShadow := preload("res://game/ui/pixel_shadow.gd")
const MenuKeys := preload("res://game/ui/menu_keys.gd")
const PICTURES := "res://src/main/kotlin/fr/skyle/pokemonmirage/assets/ui/bag/bag_%s.png"
const BACK_ICON := "res://src/main/kotlin/fr/skyle/pokemonmirage/assets/items/icons/other/00_F_F_special.png"
## A line's height.
const ROW := 16.0

enum Mode { LIST, ACTIONS, AMOUNT, CONFIRM, DONE }

@export_group("Mirage")
@export var title: NodePath = ^"Title"
@export var bag_picture: NodePath = ^"Bag"
@export var pocket_left: NodePath = ^"PocketLeft"
@export var pocket_right: NodePath = ^"PocketRight"
@export var scroll_up: NodePath = ^"ScrollUp"
@export var scroll_down: NodePath = ^"ScrollDown"
@export var cursor: NodePath = ^"Cursor"
@export var names: NodePath = ^"Names"
@export var amounts: NodePath = ^"Amounts"
@export var choices: NodePath = ^"Choices"
@export var amount_panel: NodePath = ^"Amount"
@export var amount_value: NodePath = ^"Amount/Value"

var _mode := Mode.LIST
var _line := 0
var _top := 0
var _entries: Array[StringName] = []
var _actions: Array[String] = []
var _amount := 1
var _keys: MenuKeys
var _rows: Array[Label] = []
var _counts: Array[Label] = []


func _on_open(args: Dictionary) -> void:
	for child in get_node(names).get_children():
		_rows.append(child)
	for child in get_node(amounts).get_children():
		_counts.append(child)
	for label: Label in _rows + _counts + [get_node(title), get_node(description), get_node(amount_value)]:
		label.add_child(PixelShadow.new())
	(get_node(amount_panel) as CanvasItem).visible = false
	super(args)
	if dialogue != null:
		_keys = MenuKeys.new(dialogue)


func _on_input(event: InputEvent) -> bool:
	if _keys == null:
		return false
	var key := _keys.key_of(event)
	if key.is_empty():
		return false
	_press(key)
	return true


## The id of the line under the cursor; none on Back.
func selected() -> StringName:
	return _entries[_line] if _line < _entries.size() else &""


## Reads the pocket again, the cursor kept unless its line is gone, and
## shows it.
func refresh() -> void:
	_entries = bag.items(pocket)
	_line = mini(_line, _entries.size())
	_follow()
	var index := pockets.find(pocket)
	(get_node(title) as Label).text = tr(str(bag.config().pocket(pocket).get("name", String(pocket))))
	(get_node(bag_picture) as TextureRect).texture = _load(PICTURES % pocket)
	(get_node(pocket_left) as CanvasItem).visible = index > 0
	(get_node(pocket_right) as CanvasItem).visible = index < pockets.size() - 1
	_draw_list()
	if _mode == Mode.LIST:
		_show_line()


func _press(key: String) -> void:
	var box := get_node(choices)
	match _mode:
		Mode.LIST:
			_browse(key)
		Mode.ACTIONS:
			var picked: int = box.handle(key)
			if picked >= 0:
				if _actions[picked] == "toss":
					_ask_amount()
				else:
					_back_to_list()
		Mode.AMOUNT:
			_pick_amount(key)
		Mode.CONFIRM:
			match box.handle(key):
				0:
					_throw_away()
				1:
					_back_to_list()
		Mode.DONE:
			# The message waits for a key, either.
			if key == "confirm" or key == "cancel":
				_back_to_list()


func _browse(key: String) -> void:
	var index := pockets.find(pocket)
	match key:
		"cancel":
			close()
		"right":
			if index < pockets.size() - 1:
				_show_pocket(pockets[index + 1])
		"left":
			if index > 0:
				_show_pocket(pockets[index - 1])
		"down":
			if _line < _entries.size():
				_move_to(_line + 1)
		"up":
			if _line > 0:
				_move_to(_line - 1)
		"confirm":
			if _line == _entries.size():
				close()
			else:
				_ask_action()


func _show_pocket(id: StringName) -> void:
	pocket = id
	_line = 0
	_top = 0
	refresh()


func _move_to(line: int) -> void:
	_line = line
	_follow()
	_draw_list()
	_show_line()


## The window of rows follows the cursor, never empty at the bottom while
## the list could fill it.
func _follow() -> void:
	if _line < _top:
		_top = _line
	if _line >= _top + _rows.size():
		_top = _line - _rows.size() + 1
	_top = clampi(_top, 0, maxi(0, _entries.size() + 1 - _rows.size()))


func _ask_action() -> void:
	var item := bag.item(selected())
	# A key item is never tossed.
	_actions.assign(["cancel"] if not item.consumed else ["toss", "cancel"])
	_mode = Mode.ACTIONS
	_say(tr("Objet choisi : %s.") % tr(item.name))
	get_node(choices).open(_actions.map(func(action: String) -> String: return tr("Jeter") if action == "toss" else tr("Annuler")))


func _ask_amount() -> void:
	get_node(choices).close()
	_amount = 1
	_mode = Mode.AMOUNT
	_say(tr("Combien en jeter ?"))
	(get_node(amount_panel) as CanvasItem).visible = true
	_show_amount()


func _pick_amount(key: String) -> void:
	var most := bag.count(selected())
	match key:
		"cancel":
			_back_to_list()
			return
		# The count wraps: below 1 it jumps to the most, and back.
		"up":
			_amount = 1 if _amount >= most else _amount + 1
		"down":
			_amount = most if _amount <= 1 else _amount - 1
		"confirm":
			(get_node(amount_panel) as CanvasItem).visible = false
			_mode = Mode.CONFIRM
			_say(tr("Jeter %s x%d ?") % [tr(bag.item(selected()).name), _amount])
			get_node(choices).open([tr("Oui"), tr("Non")])
			return
	_show_amount()


func _throw_away() -> void:
	var id := selected()
	var item_name := tr(bag.item(id).name)
	get_node(choices).close()
	_mode = Mode.DONE
	# The list shows what is left at once; the message waits for a key.
	bag.remove(id, _amount)
	_say(tr("Vous jetez %s x%d.") % [item_name, _amount])


func _back_to_list() -> void:
	get_node(choices).close()
	(get_node(amount_panel) as CanvasItem).visible = false
	_mode = Mode.LIST
	refresh()


func _show_amount() -> void:
	(get_node(amount_value) as Label).text = "x%d" % _amount


func _say(text: String) -> void:
	(get_node(description) as Label).text = text


func _show_line() -> void:
	var id := selected()
	var item := bag.item(id) if not id.is_empty() else null
	_say(tr(item.description) if item != null else tr("Refermer le sac."))
	(get_node(icon) as TextureRect).texture = item.icon if item != null else _load(BACK_ICON)


## The rows: the items, then Back, then nothing.
func _draw_list() -> void:
	for row in _rows.size():
		var index := _top + row
		var id: StringName = _entries[index] if index < _entries.size() else &""
		var item := bag.item(id) if not id.is_empty() else null
		_rows[row].text = tr(item.name) if item != null else (tr("Retour") if index == _entries.size() else "")
		if row < _counts.size():
			_counts[row].text = "x%d" % bag.count(id) if item != null and item.consumed else ""
	(get_node(scroll_up) as CanvasItem).visible = _top > 0
	(get_node(scroll_down) as CanvasItem).visible = _top + _rows.size() < _entries.size() + 1
	var arrow := get_node(cursor) as Control
	var list := get_node(names) as Control
	arrow.position.y = list.position.y + ROW * (_line - _top) + (ROW - arrow.size.y) / 2.0


func _load(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
