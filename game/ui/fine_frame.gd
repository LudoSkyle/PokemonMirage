## A frame drawn from a picture finer than the game's pixels, as nine slices:
## Mirage's message box was drawn for a 1280 x 960 screen, four screen pixels
## a game pixel. It fills its rect; its corners keep their size.
@tool
extends Control

@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
## The corners' size in the picture, in its pixels.
@export var corner := 12
## Game pixels a picture pixel.
@export var texture_scale := 0.25


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if texture == null:
		return
	var source := Vector2(texture.get_size())
	var c := float(corner)
	var drawn := c * texture_scale
	var xs_from: Array[float] = [0.0, c, source.x - c, source.x]
	var ys_from: Array[float] = [0.0, c, source.y - c, source.y]
	var xs_to: Array[float] = [0.0, drawn, size.x - drawn, size.x]
	var ys_to: Array[float] = [0.0, drawn, size.y - drawn, size.y]
	for row in 3:
		for column in 3:
			var from := Rect2(xs_from[column], ys_from[row], xs_from[column + 1] - xs_from[column], ys_from[row + 1] - ys_from[row])
			var to := Rect2(xs_to[column], ys_to[row], xs_to[column + 1] - xs_to[column], ys_to[row + 1] - ys_to[row])
			draw_texture_rect_region(texture, to, from)
