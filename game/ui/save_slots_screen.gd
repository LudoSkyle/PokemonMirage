## Mirage's choice of a game, on the engine's: a row of cards gliding left
## and right, the one in the middle chosen and the others dimmed; a card per
## saved game, "Nouvelle partie" while a slot is free, "Options". A game asks
## Continue, Erase or Back in the small box; erasing asks in the footer, the
## cursor on No. The row goes round, held keys repeat; the menu key goes back
## to "Press Enter".
extends WgSaveSlotsScreen

const PixelShadow := preload("res://game/ui/pixel_shadow.gd")
const MenuKeys := preload("res://game/ui/menu_keys.gd")
const CARD := preload("res://game/ui/save_card.tscn")
## Where the arrows rest, in game pixels.
const LEFT_X := 6.0
const RIGHT_X := 298.0

@export_group("Mirage")
## The gap between two cards: the next one shows past the edge.
@export var pitch := 248.0
## The share of the way the row glides each second.
@export var slide := 14.0
## How opaque the cards not chosen are.
@export var dimmed := 0.55

## Mirage's words on the cards and in the boxes.
# i18n
const WORDS: Array[String] = [
	"Nouvelle partie",
	"Options",
	"Continuer",
	"Effacer",
	"Retour",
	"Effacer la partie %d ?",
	"Oui",
	"Non",
]

var _keys: MenuKeys
var _answering := false
var _clock := 0.0
var _arrow_home := 0.0


func _on_open(args: Dictionary) -> void:
	horizontal = true
	wrap = true
	new_game_card = "first_free"
	options_card = true
	list = ^"Strip"
	scroll = ^""
	for label: Label in [$Header/Title, $Footer/Hint, $Footer/Back]:
		label.add_child(PixelShadow.new())
	_arrow_home = ($Left as Control).position.y
	($Footer/Hint as Label).text = ""
	super(args)
	# The first card under the cursor, already in the middle: no glide.
	cursor = 0
	_show_cursor()
	($Strip as Control).position.x = _target()
	if dialogue != null:
		_keys = MenuKeys.new(dialogue)


func _on_input(event: InputEvent) -> bool:
	if _keys == null:
		return false
	var key := _keys.key_of(event)
	if key.is_empty():
		return false
	if _busy:
		if _answering:
			_answer(key)
		return true
	return super(event)


func _process(delta: float) -> void:
	if is_closed():
		return
	_clock += delta
	if _keys != null and not _busy and Wildgrass.screens.top() == self:
		for key in _keys.repeats(delta):
			if key == "left" or key == "right":
				_move(-1 if key == "left" else 1)
	# The row glides to the card chosen, slower and slower.
	var strip := $Strip as Control
	var goal := _target()
	strip.position.x = goal if absf(goal - strip.position.x) < 0.25 else strip.position.x + (goal - strip.position.x) * minf(delta * slide, 1.0)
	# The arrows beat, a game pixel at a time.
	var beat := 0.0 if sin(_clock * 5.0) > 0.0 else 1.0
	($Left as Control).position = Vector2(LEFT_X - beat, _arrow_home)
	($Right as Control).position = Vector2(RIGHT_X + beat, _arrow_home)


## True once the row has stopped gliding.
func is_settled() -> bool:
	return absf(($Strip as Control).position.x - _target()) < 0.25


func refresh() -> void:
	super()
	var strip := $Strip as Control
	for index in _cards.size():
		var card := _cards[index]
		card.position = Vector2((strip.size.x - card.size.x) / 2.0 + index * pitch, 0.0)
	_show_cursor()


func _make_card(number: int, summary: Dictionary) -> Control:
	var card := CARD.instantiate()
	card.name = "Options" if number == OPTIONS_CARD else ("Save%d" % number if not summary.is_empty() else "New")
	if number == OPTIONS_CARD:
		card.show_action(tr("Options"))
	elif summary.is_empty():
		card.show_action(tr("Nouvelle partie"))
	else:
		card.show_save(number, summary)
	return card


func _show_selected(card: Control, is_selected: bool) -> void:
	card.modulate.a = 1.0 if is_selected else dimmed


func _show_cursor() -> void:
	super()
	var several := _cards.size() > 1 and not _busy
	($Left as CanvasItem).visible = several
	($Right as CanvasItem).visible = several


## A new game starts at once.
func _ask_new_game(_number: int) -> bool:
	return true


func _ask_action(_number: int) -> StringName:
	var picked := await _ask([tr("Continuer"), tr("Effacer"), tr("Retour")])
	return [&"continue", &"erase", &"cancel"][picked]


## Erasing waits on No: a key too many erases nothing.
func _ask_erase(number: int) -> bool:
	($Footer/Hint as Label).text = tr("Effacer la partie %d ?") % number
	var picked := await _ask([tr("Oui"), tr("Non")], 1)
	($Footer/Hint as Label).text = ""
	return picked == 0


signal _answered(index: int)


## Opens the small box on `answers`, and waits for one.
func _ask(answers: Array, start := 0) -> int:
	_show_cursor()
	$Choices.open(answers, start)
	_answering = true
	var picked: int = await _answered
	_answering = false
	$Choices.close()
	_show_cursor()
	return picked


func _answer(key: String) -> void:
	var picked: int = $Choices.handle(key)
	if picked >= 0:
		_answered.emit(picked)


func _target() -> float:
	return -cursor * pitch
