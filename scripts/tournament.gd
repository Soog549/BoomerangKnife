extends RefCounted
class_name Tournament

## Определения еженедельных турниров (события).
##
## Неделя считается по ISO-неделе от системной даты. Это детерминированные
## «сезоны»: каждую неделю — новый турнир с темой и наградами.
## Прогресс идёт от GameState.run_scores (набранные очки за неделю).

const WEEK_MS := 604800

## Тема турнира по номеру недели (детерминированно).
static func theme_for_week(week_number: int) -> String:
	var themes := ["Золотая лихорадка", "Ночной рейд", "Буря клинков", "Ледяной шторм",
		TranslationServer.translate("Вулканический марафон"), TranslationServer.translate("Стальной порядок"),
		TranslationServer.translate("Тень луны"), TranslationServer.translate("Руна удачи")]
	return themes[week_number % themes.size()]

## Награда за участие (осколки шлифовки).
static func participation_shards() -> int:
	return Economy.SHARDS_PER_TOURNAMENT

## Сколько очков вложено в турнир в этот тик (полу-заглушка: живые данные в GameState).
static func current_score() -> int:
	return GameState.tournament_score

## Задать набранные очки за неделю (вызывается из GameState).
static func record_score(score: int) -> void:
	if score > GameState.tournament_score:
		GameState.tournament_score = score
		GameState._schedule_save()

## ISO-неделя текущей даты.
static func current_week() -> int:
	var d := Time.get_date_dict_from_system()
	return _iso_week(d.year, d.month, d.day)

## ISO-неделя: стандартный алгоритм.
static func _iso_week(year: int, month: int, day: int) -> int:
	var date := Time.get_unix_time_from_datetime_dict({"year": year, "month": month, "day": day, "hour": 0, "minute": 0, "second": 0})
	var dt := Time.get_datetime_dict_from_unix_time(date)
	# Смещение: считаем дни от начала года по ISO
	var jan1 := Time.get_unix_time_from_datetime_dict({"year": year, "month": 1, "day": 1, "hour": 0, "minute": 0, "second": 0})
	var days := int((date - jan1) / 86400)
	var week := 1 + (days / 7)
	return week

## Секунд до начала следующей недели (для таймера).
static func seconds_to_next_week() -> int:
	var now := Time.get_unix_time_from_system()
	var secs := int(fmod(now, WEEK_MS))
	return WEEK_MS - secs
