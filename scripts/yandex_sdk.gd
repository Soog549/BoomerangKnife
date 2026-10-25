extends Node
## Фасад web-платформы («мульти SDK»).
##
## По умолчанию — интеграция с Яндекс Играми (мост window.__gb,
## web/yandex_sdk.js, вставляется в <head> index.html).
##
## Если экспорт собран с фичей "gamepush" (пресет Web-GamePush:
## `custom_features="gamepush"`, head_include gamepush_sdk.js) — фасад
## делегирует всю работу GamePushSDK (мости window.__gp): реклама,
## авторизация, облачные сейвы, gameplay. GamePush сам определяет площадку
## (VK / Яндекс / ОК / Telegram / свой сайт и т.д.).
##
## Публичный API (методы и сигналы) одинаков для обоих бэкендов —
## потребители (main.gd, endless.gd, duel_arena.gd, ads.gd, settings.gd,
## main_menu.gd) НЕ меняются.
##
## Вне платформы (или пока SDK не инициализировался) работает демо-режим.
##
## Требования из дока Яндекс Игр (и аналоги площадок через GamePush):
##   - GameplayAPI.start()/stop() на старте/паузе/over'е/рекламе
##   - LoadingAPI.ready() — когда игра готова к взаимодействию (mark_ready)
##   - звук глушится при потере фокуса вкладки (<= 2 сек) + пауза геймплея
##   - гость по умолчанию, вход только по кнопке
##   - облачный сейв через player data
##   - реклама/баннер только через SDK платформы

signal sdk_ready
signal player_refreshed(name: String, signed_in: bool)
signal rewarded_result(ok: bool)
signal interstitial_closed_result
signal cloud_loaded(data: String)

const SDK_READY_DEMO_TIMEOUT := 10.0

const GAMEPUSH_FEATURE := "gamepush"

var is_web := false
var is_ready := false
var signed_in := false
var player_name := ""
var gameplay_active := false

var _poll_timer: Timer = null
var _gb: Variant = null
var _gbcb: Variant = null
var _focused := true
var _ready_called := false
var _cloud_sync_busy := false
var _cloud_pending := false
var _gameplay_before_ad := false

var _gp_backend: Node = null


func _ready() -> void:
	is_web = OS.get_name() == "Web"
	if not is_web:
		return
	if OS.has_feature(GAMEPUSH_FEATURE):
		_activate_gamepush_backend()
		return
	GameState.settings_changed.connect(_on_game_state_saved)
	_poll_timer = Timer.new()
	_poll_timer.wait_time = 0.25
	_poll_timer.timeout.connect(_poll_sdk)
	add_child(_poll_timer)
	_poll_timer.start()
	get_tree().create_timer(SDK_READY_DEMO_TIMEOUT).timeout.connect(_on_sdk_timeout)


## GamePush-бэкенд (см. scripts/gamepush_sdk.gd). Создаётся как child-адаптер,
## его сигналы прокладываются на сигналы фасада — потребители не знают бэкенд.
func _activate_gamepush_backend() -> void:
	var gp_bridge := preload("res://scripts/gamepush_sdk.gd").new()
	gp_bridge.name = "GamePushBackend"
	add_child(gp_bridge)
	_gp_backend = gp_bridge
	gp_bridge.sdk_ready.connect(func(): is_ready = true; sdk_ready.emit())
	gp_bridge.player_refreshed.connect(func(name: String, ok: bool): player_refreshed.emit(name, ok))
	gp_bridge.rewarded_result.connect(func(ok: bool): rewarded_result.emit(ok))
	gp_bridge.interstitial_closed_result.connect(func(): interstitial_closed_result.emit())
	gp_bridge.cloud_loaded.connect(func(data: String): cloud_loaded.emit(data))


func _use_gp() -> bool:
	return _gp_backend != null


# ---------------------------------------------------------------------------
# Инициализация (поиск окна из JS после загрузки лоадера /sdk.js)
# ---------------------------------------------------------------------------

func _poll_sdk() -> void:
	if is_ready:
		return
	var sdk: Variant = JavaScriptBridge.eval("window.__gb ? window.__gb.ysdk : null")
	if sdk == null:
		return
	if _poll_timer != null:
		_poll_timer.stop()
	_sdk_active()


func _on_sdk_timeout() -> void:
	if not is_ready and _poll_timer != null:
		_poll_timer.stop()


func _sdk_active() -> void:
	is_ready = true
	_gb = JavaScriptBridge.eval("window.__gb")
	_gbcb = JavaScriptBridge.eval("window.__gb.cb")
	_register_callbacks()
	if _ready_called:
		_gb.ready()
	sdk_ready.emit()
	refresh_player()
	request_cloud_load()


func _register_callbacks() -> void:
	_gbcb.rewarded = JavaScriptBridge.create_callback(_js_rewarded)
	_gbcb.interstitial = JavaScriptBridge.create_callback(_js_interstitial)
	_gbcb.auth = JavaScriptBridge.create_callback(_js_auth)
	_gbcb.info = JavaScriptBridge.create_callback(_js_info)
	_gbcb.cloud_saved = JavaScriptBridge.create_callback(_js_cloud_saved)
	_gbcb.cloud_loaded = JavaScriptBridge.create_callback(_js_cloud_loaded)
	_gbcb.visibility = JavaScriptBridge.create_callback(_js_visibility)


func _is_usable() -> bool:
	return is_web and is_ready and _gb != null


# ---------------------------------------------------------------------------
# LoadingAPI / GameplayAPI
# ---------------------------------------------------------------------------

## Вызывается, когда игра готова к взаимодействию (первый экран отрисован).
func mark_ready() -> void:
	if _use_gp():
		_gp_backend.mark_ready()
		return
	if _ready_called:
		return
	_ready_called = true
	if _is_usable():
		_gb.ready()


func set_gameplay(active: bool) -> void:
	if _use_gp():
		_gp_backend.set_gameplay(active)
		return
	if gameplay_active == active:
		return
	gameplay_active = active
	if not _is_usable():
		return
	if active:
		_gb.gameplayStart()
	else:
		_gb.gameplayStop()


# ---------------------------------------------------------------------------
# Реклама
# ---------------------------------------------------------------------------

func show_rewarded() -> void:
	if _use_gp():
		_gp_backend.show_rewarded()
		return
	if _is_usable():
		_set_playing_for_ad(true)
		_gb.rewarded("rewarded")
	else:
		_demo_rewarded()


func show_interstitial() -> void:
	if _use_gp():
		_gp_backend.show_interstitial()
		return
	if _is_usable():
		_set_playing_for_ad(true)
		_gb.interstitial("interstitial")
	else:
		_demo_interstitial()


func show_banner() -> void:
	if _use_gp():
		_gp_backend.show_banner()
		return
	if _is_usable():
		_gb.bannerShow()


func hide_banner() -> void:
	if _use_gp():
		_gp_backend.hide_banner()
		return
	if _is_usable():
		_gb.bannerHide()


func _demo_rewarded() -> void:
	set_gameplay(false)
	await get_tree().create_timer(0.4).timeout
	rewarded_result.emit(true)
	set_gameplay(true)


func _demo_interstitial() -> void:
	await get_tree().create_timer(0.1).timeout
	interstitial_closed_result.emit()


func _js_rewarded(payload: Dictionary) -> void:
	rewarded_result.emit(bool(payload.get("ok", false)))
	_set_playing_for_ad(false)


func _js_interstitial(payload: Dictionary) -> void:
	interstitial_closed_result.emit()
	_set_playing_for_ad(false)


## Перед показом рекламы — GameplayAPI.stop(), после закрытия — start() обратно.
func _set_playing_for_ad(show: bool) -> void:
	if show:
		_gameplay_before_ad = gameplay_active
		set_gameplay(false)
	else:
		if _gameplay_before_ad:
			set_gameplay(true)
		_gameplay_before_ad = false


# ---------------------------------------------------------------------------
# Авторизация (только по кнопке; гость — по умолчанию)
# ---------------------------------------------------------------------------

func is_signed_in() -> bool:
	if _use_gp():
		return bool(_gp_backend.is_signed_in())
	return signed_in


func refresh_player() -> void:
	if _use_gp():
		_gp_backend.refresh_player()
		return
	if _is_usable():
		_gb.playerInfo("info")


func request_login() -> void:
	if _use_gp():
		_gp_backend.request_login()
		return
	if _is_usable():
		_gb.auth("auth")


func _js_auth(payload: Dictionary) -> void:
	_apply_player(payload)
	request_cloud_load()


func _js_info(payload: Dictionary) -> void:
	_apply_player(payload)


func _apply_player(info: Dictionary) -> void:
	var ok: bool = bool(info.get("ok", false))
	signed_in = ok
	if ok:
		var name := str(info.get("name", ""))
		if not name.is_empty() and (GameState.player_name == tr("Игрок") or GameState.player_name.is_empty()):
			GameState.player_name = name
			GameState.save_settings()
	player_name = GameState.player_name
	player_refreshed.emit(player_name, signed_in)


# ---------------------------------------------------------------------------
# Облачные сохранения (Yandex playerData)
# ---------------------------------------------------------------------------

func request_cloud_load() -> void:
	if _use_gp():
		_gp_backend.request_cloud_load()
		return
	if _is_usable():
		_gb.cloudLoad("cloud_loaded")


func push_cloud() -> void:
	if _use_gp():
		_gp_backend.push_cloud()
		return
	if not _is_usable():
		return
	if _cloud_sync_busy:
		_cloud_pending = true
		return
	_cloud_sync_busy = true
	_gb.cloudSave("cloud_saved", GameState.dump_settings_text())


func _js_cloud_loaded(payload: Dictionary) -> void:
	if not bool(payload.get("ok", false)):
		return
	var data := str(payload.get("data", ""))
	if data.is_empty():
		return
	GameState.merge_from_text(data)
	cloud_loaded.emit(data)


func _js_cloud_saved(payload: Dictionary) -> void:
	_cloud_sync_busy = false
	if _cloud_pending:
		_cloud_pending = false
		push_cloud()


func _on_game_state_saved() -> void:
	push_cloud()


# ---------------------------------------------------------------------------
# Фокус/видимость (звук обязан замолчать в течение 2 сек)
# ---------------------------------------------------------------------------

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_set_visible(false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_set_visible(true)


func _js_visibility(payload: Dictionary) -> void:
	_set_visible(bool(payload.get("visible", true)))


func _set_visible(visible: bool) -> void:
	if visible == _focused:
		return
	_focused = visible
	if visible:
		AudioManager.set_muted(false)
	else:
		AudioManager.set_muted(true)
		set_gameplay(false)
		if is_web:
			_autopause_gameplay()


func _autopause_gameplay() -> void:
	if get_tree().paused:
		return
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("_toggle_pause") and not bool("game_over" in scene and scene.game_over):
		scene.call("_toggle_pause")