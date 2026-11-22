## Mirage's small box of answers, one under the other, with the menus'
## cursor: above the message box for a question, or in a corner of a screen
## for what to do with what was chosen. Given answers, it fits their number,
## its bottom edge staying put; past the rows the scene has, it adds some and
## grows down from its top edge. It reads no key itself: `handle()` gets them.
extends Control

const PixelShadow := preload("res://game/ui/pixel_shadow.gd")
## A row's height, and the frame around the rows.
const ROW := 16.0
const MARGINS := 16.0

## The answer under the cursor.
var selected := 0

var _labels: Array[Label] = []
var _count := 0
var _top := 0.0
var _bottom := 0.0

@onready var _cursor := $Cursor as Control
@onready var _frame := $Frame as Control
@onready var _entries := $Entries as Control


func _ready() -> void:
	for child in _entries.get_children():
		if child is Label:
			_labels.append(child)
			child.add_child(PixelShadow.new())
	_count = _labels.size()
	_top = position.y
	_bottom = position.y + size.y
	visible = false


## Opens on `answers`, already translated, the cursor on `start`; without
## answers, on those the scene wrote.
func open(answers: Array = [], start := 0) -> void:
	if not answers.is_empty():
		while _labels.size() < answers.size():
			var model := _labels[_labels.size() - 1]
			var extra := model.duplicate(0) as Label
			for child in extra.get_children():
				child.free()
			extra.name = "Entry%d" % _labels.size()
			_entries.add_child(extra)
			extra.add_child(PixelShadow.new())
			_labels.append(extra)
		_count = mini(answers.size(), _labels.size())
		for index in _labels.size():
			_labels[index].visible = index < _count
			if index < _count:
				_labels[index].text = str(answers[index])
		var height := MARGINS + ROW * _count
		size.y = height
		# While it fits its first height, its bottom edge stays; past it, its top.
		position.y = _bottom - height if height <= _bottom - _top else _top
		_frame.size = Vector2(size.x, height)
	selected = start if start > 0 and start < _count else 0
	visible = true
	_place_cursor()


func close() -> void:
	visible = false


func is_open() -> bool:
	return visible


## The answer `key` picks, or -1: the menu key answers the last, the refusal
## by convention.
func handle(key: String) -> int:
	if not visible or _count == 0:
		return -1
	match key:
		"cancel":
			return _count - 1
		"confirm":
			return selected
		"down":
			_move(1)
		"up":
			_move(-1)
	return -1


func _move(step: int) -> void:
	selected = wrapi(selected + step, 0, _count)
	_place_cursor()


func _place_cursor() -> void:
	_cursor.position.y = _entries.position.y + ROW * selected + (ROW - _cursor.size.y) / 2.0
