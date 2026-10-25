extends Node

## Локализация: выбор языка, применение локали и перезагрузка сцены для
## мгновенного пере-перевода всего UI. Стек: Godot TranslationServer + CSV
## в res://locale/translations.csv (10 языков). Исходный язык — русский (ключи).

const LANGS := [
	["ru", "Русский"],
	["en", "English"],
	["uk", "Українська"],
	["es", "Español"],
	["de", "Deutsch"],
	["fr", "Français"],
	["pt", "Português"],
	["it", "Italiano"],
	["pl", "Polski"],
	["tr", "Türkçe"],
]

func _ready() -> void:
	for pair in LANGS:
		var path := "res://locale/translations.%s.translation" % pair[0]
		if ResourceLoader.exists(path):
			var tl: Translation = load(path) as Translation
			if tl != null:
				TranslationServer.add_translation(tl)
	var loc := GameState.locale
	if loc.is_empty():
		loc = "ru"
		GameState.locale = loc
	TranslationServer.set_locale(loc)

func index_of(loc: String) -> int:
	for i in LANGS.size():
		if LANGS[i][0] == loc:
			return i
	return 0

## Смена языка: применяем локали и перезагружаем текущую сцену.
func apply_locale(loc: String) -> void:
	GameState.locale = loc
	TranslationServer.set_locale(loc)
	GameState.save_settings()
	var scene := get_tree().current_scene
	if scene != null and not scene.scene_file_path.is_empty():
		get_tree().change_scene_to_file(scene.scene_file_path)