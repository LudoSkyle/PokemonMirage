## Mirage's item reveal: the icon of a key item, in a menu frame in the middle
## of the screen, fading in, and out once the dialogue goes on.
extends WgItemReveal

## Seconds of each fade.
@export var fade_seconds := 0.2
## What fades.
@export var panel: NodePath = ^"Panel"

var _tween: Tween


func _on_open(args: Dictionary) -> void:
	super(args)
	(get_node(panel) as CanvasItem).modulate.a = 0.0
	_fade(1.0)


## Closes at once, for the dialogue; the picture fades out after.
func close() -> void:
	if not _finish():
		return
	_fade(0.0).finished.connect(queue_free)


func _fade(to: float) -> Tween:
	var shown := get_node(panel) as CanvasItem
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(shown, ^"modulate:a", to, fade_seconds * absf(to - shown.modulate.a))
	return _tween
