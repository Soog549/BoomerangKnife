extends Node

## Локальные push-уведомления (напоминания о ежедневных наградах/квестах).
##
## Использует Android local notifications plugin (godot-notifications):
##   https://github.com/DrMoriarty/godot-notifications
## Класс доступа — "Notifications" (singleon).
##
## Пока плагин не установлен — НИЧЕГО не происходит (возвращаем false),
## чтобы игра оставалась работоспособной в редакторе и на тестовой сборке.

const NOTIFICATIONS_ENABLED := false
const DAILY_REMINDER_HOUR := 18   # локальное время напоминания

func _ready() -> void:
	if NOTIFICATIONS_ENABLED and Engine.has_singleton("Notifications"):
		_schedule_daily_reminder()

## Запланировать ежедневное напоминание «забери награду/квест».
func _schedule_daily_reminder() -> void:
	var notif := Engine.get_singleton("Notifications")
	if notif == null:
		return
	# Идентификатор уведомления (перезаписывается при каждом запуске)
	var notification_id := 9001
	var title := tr("Нож Бумеранг")
	var body := tr("Ежедневная награда и квест ждут тебя! Заходи и забери монеты.")

	var week_days := PackedInt32Array([1, 2, 3, 4, 5, 6, 7])  # каждый день
	var minutes := PackedInt32Array([DAILY_REMINDER_HOUR * 60])

	if notif.has_method("scheduleDaily"):
		notif.scheduleDaily(notification_id, title, body, week_days, minutes)
	elif notif.has_method("schedule_notification"):
		# fallback: разовое уведомление через N секунд до вечера
		var delay := _seconds_until(DAILY_REMINDER_HOUR)
		notif.schedule_notification(notification_id, title, body, delay)

func _seconds_until(hour: int) -> int:
	var now := Time.get_datetime_dict_from_system()
	var target := now.duplicate()
	target.hour = hour
	target.minute = 0
	target.second = 0
	var now_unix := Time.get_unix_time_from_datetime_dict(now)
	var target_unix := Time.get_unix_time_from_datetime_dict(target)
	var diff := int(target_unix - now_unix)
	if diff <= 0:
		diff += 86400
	return diff
