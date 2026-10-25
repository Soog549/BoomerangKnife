extends Node

## Управление ассетами. Ищет файлы в res://assets/images/<категория>/<имя>.png
## и возвращает текстуру. Если файла нет — возвращает null, и игра использует
## процедурную графику (fallback). Это позволяет подключать арты из ComfyUI
## БЕЗ правки кода: просто положи .png в правильную папку с правильным именем.

func load_tex(category: String, file_name: String) -> Texture2D:
	var path := "res://assets/images/%s/%s.png" % [category, file_name]
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

## Проверка на существование файла
func has_asset(category: String, file_name: String) -> bool:
	return ResourceLoader.exists("res://assets/images/%s/%s.png" % [category, file_name])
