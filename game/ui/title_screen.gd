## Mirage's title, on the engine's: the top of a tower above the clouds, the
## clouds drifting and Wingull flying by, far behind the tower or near before
## it; the logo growing in, overshooting, then floating; "Press Enter"
## blinking. The key opens the choice of a game.
extends WgTitleScreen

const FLYERS := "res://src/main/kotlin/fr/skyle/pokemonmirage/assets/pokemon/overworld/%s.png"
const FLYER_FRAME := 32.0
const FLYER_BEATS := 5.0
## How far a bird goes past the edge before turning back, in game pixels.
const FLYER_MARGIN := 22.5

@export_group("Mirage")
## The frame the logo fits in, in game pixels, keeping its shape.
@export var logo_size := Vector2(250.0, 87.5)
## How far the logo floats up and down, in game pixels, and in how long.
@export var float_pixels := 1.5
@export var float_seconds := 3.6
## The species flying by: a file of `assets/pokemon/overworld`; empty: none.
@export var flyer_species := "wingull"
@export var far_flyers := 3
@export var near_flyers := 1
## The far ones are drawn smaller, paled by the distance.
@export var far_flyer_scale := 0.5

var _logo_scale := 1.0
var _logo_home := Vector2.ZERO
var _clock := 0.0
var _birds: Array[Dictionary] = []
var _random := RandomNumberGenerator.new()


func _on_open(args: Dictionary) -> void:
	background = ^"Backdrop"
	hidden_under_choice = [^"Logo", ^"Prompt"]
	var shown_logo := get_node(logo) as Sprite2D
	var size := shown_logo.texture.get_size()
	_logo_scale = minf(logo_size.x / size.x, logo_size.y / size.y)
	_logo_home = shown_logo.position
	_release_flyers()
	super(args)


func advance(delta: float) -> void:
	_clock += delta
	super(delta)
	var shown_logo := get_node(logo) as Sprite2D
	shown_logo.position = _logo_home + Vector2(0.0, sin(_clock * TAU / float_seconds) * float_pixels if float_seconds > 0.0 else 0.0)
	_fly(delta)


## The logo grows in, past its size and back, fading in faster.
func _arrival(progress: float) -> void:
	var shown_logo := get_node(logo) as Sprite2D
	shown_logo.visible = _clock >= fade_in_seconds or progress > 0.0
	shown_logo.modulate.a = minf(progress * 2.5, 1.0)
	shown_logo.scale = Vector2.ONE * _logo_scale * (0.7 + 0.3 * _overshoot(progress))


## From 0 to 1, going past 1 before coming back: the swing of an arrival.
static func _overshoot(progress: float) -> float:
	var back := 1.70158
	var rest := progress - 1.0
	return 1.0 + (back + 1.0) * pow(rest, 3) + back * pow(rest, 2)


func _release_flyers() -> void:
	if flyer_species.is_empty() or not ResourceLoader.exists(FLYERS % flyer_species):
		return
	var sheet := load(FLYERS % flyer_species) as Texture2D
	for spec: Array in [[^"Backdrop/FarFlyers", far_flyers, true], [^"Backdrop/NearFlyers", near_flyers, false]]:
		var host := get_node_or_null(spec[0])
		if host == null:
			continue
		for index in int(spec[1]):
			var sprite := Sprite2D.new()
			sprite.texture = sheet
			sprite.region_enabled = true
			var far: bool = spec[2]
			sprite.scale = Vector2.ONE * (far_flyer_scale if far else 1.0)
			# The distance pales and blues.
			if far:
				sprite.modulate = Color(0.8, 0.9, 1.0, 1.0)
			host.add_child(sprite)
			var bird := {"sprite": sprite, "far": far}
			_route(bird)
			# At launch they are already up, somewhere over the clouds.
			bird["wait"] = 0.0
			sprite.position = Vector2(_random.randf() * size.x, bird["height"])
			_birds.append(bird)


## The next crossing of a bird: its way, height, pace, and the wait before.
func _route(bird: Dictionary) -> void:
	var far: bool = bird["far"]
	bird["heading"] = 1.0 if _random.randf() < 0.5 else -1.0
	bird["speed"] = (34.0 + _random.randf() * 22.0 if far else 70.0 + _random.randf() * 40.0) / 4.0
	# The far ones fly higher in the picture; none crosses the logo.
	var band := Vector2(0.44, 0.66) if far else Vector2(0.5, 0.8)
	bird["height"] = size.y * (band.x + _random.randf() * (band.y - band.x))
	bird["sway"] = (6.0 + _random.randf() * 6.0 if far else 10.0 + _random.randf() * 14.0) / 4.0
	bird["phase"] = _random.randf() * TAU
	bird["wait"] = 1.0 + _random.randf() * 5.0
	(bird["sprite"] as Sprite2D).position = Vector2(-FLYER_MARGIN if bird["heading"] > 0.0 else size.x + FLYER_MARGIN, bird["height"])


func _fly(delta: float) -> void:
	for bird in _birds:
		var sprite := bird["sprite"] as Sprite2D
		# The wings beat even while waiting, out of the screen.
		var beat := int((_clock + bird["phase"]) * FLYER_BEATS) % 2
		# Rows down, left, right, up; the two drawings in columns 0 and 2.
		var row := 1 if bird["heading"] < 0.0 else 2
		sprite.region_rect = Rect2(beat * 2 * FLYER_FRAME, row * FLYER_FRAME, FLYER_FRAME, FLYER_FRAME)
		if bird["wait"] > 0.0:
			bird["wait"] -= delta
			continue
		var x: float = sprite.position.x + bird["heading"] * bird["speed"] * delta
		sprite.position = Vector2(x, bird["height"] + sin(_clock * 0.9 + bird["phase"]) * bird["sway"])
		if x < -FLYER_MARGIN or x > size.x + FLYER_MARGIN:
			_route(bird)
