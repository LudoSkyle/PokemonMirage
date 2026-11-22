## Furniture one examines, on the engine: its text (which may follow the
## story and ask first), the real clock, a programme on the TV picked at
## random, or a find that gives an item once and sets its flag.
extends WgInteractable

const _StoryLines := preload("res://addons/wildgrass/story/story_lines.gd")

## The programmes of the TV, one picked each time.
# i18n
const TV_PROGRAMS: Array[String] = [
	"C'est la météo.[page]Grand soleil sur tout le village aujourd'hui !",
	"C'est la météo.[page]Quelques nuages ce soir, mais pas une goutte de pluie.",
	"C'est la météo.[page]Un petit vent frais soufflera sur la côte demain matin.",
	"Il y a un film à la télé.[page]Quatre garçons marchent le long d'une voie ferrée.[page]Je ferais mieux d'y aller aussi.",
	"Il y a un film à la télé.[page]Deux hommes dansent sur un piano géant.[page]Bon, il est temps de bouger !",
	"Une émission de cuisine.[page]Le chef rate sa crêpe, le public applaudit quand même.",
	"Un documentaire sur les grottes de la région.[page]Il paraît qu'on s'y perd facilement.",
	"Un jeu télévisé.[page]Le candidat hésite... Ah, mauvaise réponse !",
	"C'est le journal.[page]Rien à signaler au village, et c'est très bien comme ça.",
	"Une publicité pour des chaussures de course.[page]Avec elles on irait deux fois plus vite, paraît-il.",
]

@export_enum("text", "clock", "tv", "item") var kind := "text"
## What it says; `[page]` starts a page.
@export_multiline var text := ""
## `condition => text`: the last whose condition holds is said instead.
@export var states: Array[String] = []
## A question before: `Question?`, or `condition => Question?` for one state.
@export var ask := ""
## A find's flag, set once it gave its item: it says nothing more.
@export var flag := ""


func _interact(walker: WgWalker) -> void:
	var dialogue: Object = walker.walkers.dialogue
	match kind:
		"clock":
			var now := Time.get_time_dict_from_system()
			await dialogue.say(tr("L'horloge indique %d h %02d.") % [now["hour"], now["minute"]])
		"tv":
			await dialogue.say(TV_PROGRAMS.pick_random())
		"item":
			var story: Object = walker.walkers.story
			if flag.is_empty() or story.has(StringName(flag)):
				return
			await _say(walker, "[flag=%s]%s" % [flag, text])
		_:
			await _say(walker, text)


func _say(walker: WgWalker, said: String) -> void:
	var dialogue: Object = walker.walkers.dialogue
	var chosen := _StoryLines.choose(walker.walkers.story, self, said, states, ask)
	if not chosen["question"].is_empty() and not await dialogue.confirm(chosen["question"]):
		return
	await dialogue.say(chosen["text"])
