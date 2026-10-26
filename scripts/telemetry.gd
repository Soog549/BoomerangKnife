extends Node
## ТЕЛЕМЕТРИЯ: сбор событий/ошибок/метрик → user://telemetry/*.jsonl
## Автозагрузка: Telemetry. Вызов: Telemetry.event("arena_end", {"wave": 5})

var _events: Array = []
var _max := 600
var _errors: int = 0
var _started := 0


func _ready() -> void:
	_started = int(Time.get_unix_time_from_system())
	process_mode = Node.PROCESS_MODE_ALWAYS


func event(name: String, data: Dictionary = {}) -> void:
	_events.append({
		"ts": int(Time.get_unix_time_from_system()),
		"e": name,
		"d": data,
		"v": str(ProjectSettings.get_setting("application/config/version", "dev")),
	})
	if _events.size() > _max:
		_events = _events.slice(_events.size() - _max)


func error(msg: String, ctx: Dictionary = {}) -> void:
	_errors += 1
	event("error", {"msg": msg, "ctx": ctx})
	push_warning("[Telemetry] " + msg)


func metric(name: String, value: float) -> void:
	event("metric", {"name": name, "value": value})


func summary() -> Dictionary:
	var counts := {}
	for e: Dictionary in _events:
		var k: String = str(e["e"])
		counts[k] = int(counts.get(k, 0)) + 1
	return {
		"events": _events.size(),
		"errors": _errors,
		"session_sec": int(Time.get_unix_time_from_system()) - _started,
		"counts": counts,
	}


func flush_to_disk() -> String:
	if _events.is_empty():
		return ""
	var dir := "user://telemetry"
	DirAccess.make_dir_recursive_absolute(dir)
	var d := Time.get_datetime_dict_from_system()
	var path := "%s/events-%04d%02d%02d.jsonl" % [dir, d.year, d.month, d.day]
	var f := FileAccess.open(path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.seek_end()
	for e: Dictionary in _events:
		f.store_line(JSON.stringify(e))
	f.close()
	return path


func export_report() -> String:
	var s := summary()
	var text := "# ОТЧЁТ ДИАГНОСТИКИ\n\n"
	text += "Версия: %s\n" % str(ProjectSettings.get_setting("application/config/version", "dev"))
	text += "Сессия: %d c\nСобытий: %d\nОшибок: %d\n\n" % [s.session_sec, s.events, s.errors]
	text += "## Счётчики событий\n"
	for k: String in s.counts:
		text += "- %s: %d\n" % [k, int(s.counts[k])]
	DirAccess.make_dir_recursive_absolute("user://telemetry")
	var p := "user://telemetry/report.md"
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()
	return p


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_PREDELETE:
		flush_to_disk()
