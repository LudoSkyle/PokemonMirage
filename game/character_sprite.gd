## A Mirage character's sprite, dressed by its appearance: a sheet of
## `assets/characters` (4 columns x 4 rows: down, left, right, up; the first
## picture of a row is the standing pose) or, prefixed `pkmn_`, a species'
## file in `assets/pokemon/overworld`. The animations bear the names the
## engine's walker plays: `idle_`, `walk_`, `turn_` + direction.
@tool
extends AnimatedSprite2D

const CHARACTERS := "res://src/main/kotlin/fr/skyle/pokemonmirage/assets/characters/"
const POKEMON := "res://src/main/kotlin/fr/skyle/pokemonmirage/assets/pokemon/overworld/"
## What marks a species in an appearance: `pkmn_wingull`.
const POKEMON_PREFIX := "pkmn_"
const ROWS: Array[String] = ["down", "left", "right", "up"]
const COLUMNS := 4
## A cell's side: the feet stand at its bottom.
const GRID := 16.0
## A character sheet is drawn twice over: 32 x 48 for a cell.
const CHARACTER_SCALE := 0.5
## A Pokémon a little smaller than its drawing, not to dwarf the people.
const POKEMON_SCALE := 0.9
## A Pokémon drawing (its two pictures, up then down) lasts a third of a
## second.
const POKEMON_FPS := 6.0

## A sheet is cut once, even if ten characters wear it.
static var _cache := {}

## A sheet of `assets/characters` without its extension, or `pkmn_<species>`.
@export var appearance := "":
	set(value):
		appearance = value
		_dress()


func _dress() -> void:
	if appearance.is_empty():
		return
	var frames := frames_of(appearance)
	if frames == null:
		push_error("Unknown appearance: %s" % appearance)
		return
	sprite_frames = frames
	centered = true
	animation = &"idle_down"
	if appearance.begins_with(POKEMON_PREFIX):
		var side := frames.get_frame_texture(&"idle_down", 0).get_height()
		scale = Vector2.ONE * POKEMON_SCALE
		# The feet stay at the bottom of the cell, whatever the scale.
		position = Vector2(0.0, GRID / 2.0 - side * POKEMON_SCALE / 2.0)
	else:
		scale = Vector2.ONE * CHARACTER_SCALE
		position = Vector2(0.0, -4.0)


## An appearance's animations, or null if its picture is missing.
static func frames_of(name: String) -> SpriteFrames:
	if _cache.has(name):
		return _cache[name]
	var pokemon := name.begins_with(POKEMON_PREFIX)
	var path := POKEMON + name.trim_prefix(POKEMON_PREFIX) + ".png" if pokemon else CHARACTERS + name + ".png"
	if not ResourceLoader.exists(path):
		return null
	var sheet := load(path) as Texture2D
	var size := Vector2(sheet.get_width() / float(COLUMNS), sheet.get_height() / float(ROWS.size()))
	if pokemon:
		size.y = size.x
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for row in ROWS.size():
		var cells: Array[AtlasTexture] = []
		for column in COLUMNS:
			var cell := AtlasTexture.new()
			cell.atlas = sheet
			cell.region = Rect2(Vector2(column, row) * size, size)
			cells.append(cell)
		var direction := ROWS[row]
		_add(frames, "idle_" + direction, 5.0, true, [cells[0]])
		if pokemon:
			# Columns 0 and 2: the two drawings; 1 and 3: the same a pixel lower.
			_add(frames, "walk_" + direction, POKEMON_FPS, true, cells)
			_add(frames, "turn_" + direction, 10.0, false, [cells[2], cells[0]])
		else:
			_add(frames, "walk_" + direction, 8.0, true, [cells[1], cells[2], cells[3], cells[0]])
			_add(frames, "turn_" + direction, 10.0, false, [cells[1], cells[0]])
	_cache[name] = frames
	return frames


static func _add(frames: SpriteFrames, animation_name: String, speed: float, loop: bool, cells: Array) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, speed)
	frames.set_animation_loop(animation_name, loop)
	for cell: Texture2D in cells:
		frames.add_frame(animation_name, cell)
