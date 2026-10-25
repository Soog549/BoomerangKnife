extends Node

## Шлюз для онлайн-лидерборда (VK Play / Yandex.Games).
##
## Как работает:
##   1. В демо/оффлайн-режиме (ONLINE_ENDPOINT == "") все операции идут в
##      локальный лидерборд GameState.leaderboard — игра полностью работоспособна.
##   2. Когда появится серверный эндпоинт (твой бэкенд, VK Play API или
##      Yandex.Games Leaderboards), впиши ONLINE_ENDPOINT и включи USE_ONLINE.
##      Пуш:  POST {endpoint}/submit  {name, score, mode}
##      Фетч: GET  {endpoint}/top?limit=10
##   3. Ответы — JSON array вида [{name, score, mode}], порядок — по убыванию.
##
## Это отдельный autoload (OnlineService), чтобы лидерборд мог работать и
## локально, и онлайн, не трогая GameState.

const USE_ONLINE := false          # переключи в true, когда будет сервер
const ONLINE_ENDPOINT := ""        # напр. "https://api.example.com/leaderboard"
const REQUEST_TIMEOUT := 5.0

signal online_leaderboard_ready(entries: Array)   # топ-10 из сети
signal online_ping_failed

var _http: HTTPRequest = null


func _ready() -> void:
	if USE_ONLINE and ONLINE_ENDPOINT != "":
		_http = HTTPRequest.new()
		add_child(_http)


## Есть ли реальный онлайн-лидерборд.
func is_online() -> bool:
	return USE_ONLINE and ONLINE_ENDPOINT != "" and _http != null


## Отправить результат. В оффлайн-режиме просто обновляет локальный топ.
func submit_score(name: String, score: int, mode: String) -> void:
	# Локально всегда пишем — это задел под оффлайн-режим (полёты, рынок РФ).
	GameState.add_leaderboard_entry(name, score, mode)
	if not is_online():
		return
	var payload := JSON.stringify({"name": name, "score": score, "mode": mode})
	_send("POST", "%s/submit" % ONLINE_ENDPOINT, payload)


## Загрузить топ-10. Всегда вызывает callback с массивом словарей
## [{name, score, mode}]. Если онлайн недоступен — вернёт локальный топ.
func fetch_top(callback: Callable) -> void:
	if is_online():
		_fetch_online(callback)
	else:
		callback.call(_local_top())


# ---------- внутреннее ----------
func _local_top() -> Array:
	var top: Array = []
	for i in mini(GameState.leaderboard.size(), 10):
		top.append(GameState.leaderboard[i].duplicate())
	return top


func _send(method: String, url: String, body: String = "") -> void:
	if _http == null:
		return
	var headers := ["Content-Type: application/json"]
	var err: int
	if method == "POST":
		err = _http.request(url, headers, HTTPClient.METHOD_POST, body)
	else:
		err = _http.request(url)
	if err != OK:
		print("[Online] request failed: ", err)


func _fetch_online(callback: Callable) -> void:
	if _http == null:
		callback.call(_local_top())
		return
	var url := "%s/top?limit=10" % ONLINE_ENDPOINT
	var err := _http.request(url)
	if err != OK:
		callback.call(_local_top())
		return
	# Используем сигнал — request_completed сработает после ответа.
	# Нельзя подключаться каждый раз, поэтому используем одноразовый connect.
	_http.request_completed.connect(func(result, code, _headers, body):
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			online_ping_failed.emit()
			callback.call(_local_top())
			return
		var json: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json is Array:
			callback.call(json)
		else:
			callback.call(_local_top())
	, CONNECT_ONE_SHOT)
