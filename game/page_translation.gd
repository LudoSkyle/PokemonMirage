## Mirage's texts are translated page by page in locale/*.po (one entry a
## page, the tags left out, docs/i18n.md); the engine translates a whole
## message at once. This translation puts the pages' translations back
## together, each page's tags kept in front of it. A page with no
## translation leaves the message untranslated.
extends Translation

## The page by page translation it reads.
var pages: Translation

static var _tags := RegEx.create_from_string("^((?:\\[[a-z]+(?:=[^\\]]*)?\\])*)(.*)$")


## Adds one for each translation of the project; returns them, to be taken
## back with `uninstall()` before the game quits: a scripted translation
## left in Godot's translation server outlives the scripts and crashes the
## quit.
static func install() -> Array[Translation]:
	var added: Array[Translation] = []
	for path: String in ProjectSettings.get_setting("internationalization/locale/translations", PackedStringArray()):
		var loaded := load(path) as Translation
		if loaded == null:
			continue
		var joined: Translation = load("res://game/page_translation.gd").new()
		joined.pages = loaded
		joined.locale = loaded.locale
		TranslationServer.add_translation(joined)
		added.append(joined)
	return added


static func uninstall(added: Array[Translation]) -> void:
	for joined in added:
		TranslationServer.remove_translation(joined)
	added.clear()


func _get_message(src_message: StringName, _context: StringName) -> StringName:
	var text := String(src_message)
	if pages == null or not ("[page]" in text or text.begins_with("[")):
		return &""
	var out := PackedStringArray()
	for page in text.split("[page]"):
		var found := _tags.search(page.strip_edges())
		var said := found.get_string(2)
		var translated := String(pages.get_message(said)) if not said.is_empty() else ""
		if not said.is_empty() and translated.is_empty():
			return &""
		out.append(found.get_string(1) + translated)
	return StringName("[page]".join(out))
