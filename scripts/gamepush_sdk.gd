extends Node
## Бэкенд GamePush (Web). Аналог YandexSDK, но поверх JS-моста window.__gp
## (web/gamepush_sdk.js). Используется как child-адаптер фасада YandexSDK,
## когда включён экспорт-фича "gamepush" (пресет Web-GamePush).
##
## GamePush сам определяет площадку (VK / Яндекс / ОК / Telegram / свой сайт…)
## и подгружает нужный SDK. Здесь мы работаем с унифицированным контрактом
## __gp (методы совпадают с __gb):
##   ready, gameplayStart, gameplayStop, rewarded, interstitial,
##   bannerShow, bannerHide, auth, playerInfo, cloudSave, cloudLoad.
## Вне площадки (или пока SDK не готов) — демо-режим, как у YandexSDK.

signal sdk_ready
signal player_refreshed(name: String, signed_in: bool)
signal rewarded_result(ok: bool)
signal interstitial_closed_result
signal cloud_loaded(data: String)

const SDK_READY_DEMO_TIMEOUT := 10.0

var is_web := false
var is_ready := false
var signed_in := false
var player_name := ""
var gameplay_active := false

var _poll_timer: Timer = null
var _gp: Variant = null
var _gpcb: Variant = null
var _focused := true
var _ready_called := false
var _cloud_sync_busy := false
var _cloud_pending := false
var _gameplay_before_ad := false


func _ready() -> void:
	is_web = OS.get_name() == "Web"
	if not is_web:
		return
	GameState.settings_changed.connect(_on_game_state_saved)
	_poll_timer = Timer.new()
	_poll_timer.wait_time = 0.25
	_poll_timer.timeout.connect(_poll_sdk)
	add_child(_poll_timer)
	_poll_timer.start()
	get_tree().create_timer(SDK_READY_DEMO_TIMEOUT).timeout.connect(_on_sdk_timeout)


# ---------------------------------------------------------------------------
# Инициализация (поиск моста window.__gp)
# ---------------------------------------------------------------------------

func _poll_sdk() -> void:
	if is_ready:
		return
	var sdk: Variant = JavaScriptBridge.eval("window.__gp ? window.__gp.gp : null")
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
	_gp = JavaScriptBridge.eval("window.__gp")
	_gpcb = JavaScriptBridge.eval("window.__gp.cb")
	_register_callbacks()
	if _ready_called:
		_gp.ready()
	sdk_ready.emit()
	refresh_player()
	request_cloud_load()


func _register_callbacks() -> void:
	_gpcb.rewarded = JavaScriptBridge.create_callback(_js_rewarded)
	_gpcb.interstitial = JavaScriptBridge.create_callback(_js_interstitial)
	_gpcb.auth = JavaScriptBridge.create_callback(_js_auth)
	_gpcb.info = JavaScriptBridge.create_callback(_js_info)
	_gpcb.cloud_saved = JavaScriptBridge.create_callback(_js_cloud_saved)
	_gpcb.cloud_loaded = JavaScriptBridge.create_callback(_js_cloud_loaded)
	_gpcb.visibility = JavaScriptBridge.create_callback(_js_visibility)


func _is_usable() -> bool:
	return is_web and is_ready and _gp != null


# ---------------------------------------------------------------------------
# LoadingAPI / GameplayAPI (через GamePush)
# ---------------------------------------------------------------------------

func mark_ready() -> void:
	if _ready_called:
		return
	_ready_called = true
	if _is_usable():
		_gp.ready()


func set_gameplay(active: bool) -> void:
	if gameplay_active == active:
		return
	gameplay_active = active
	if not _is_usable():
		return
	if active:
		_gp.gameplayStart()
	else:
		_gp.gameplayStop()


# ---------------------------------------------------------------------------
# Реклама (GamePush -> SDK площадки)
# ---------------------------------------------------------------------------

func show_rewarded() -> void:
	if _is_usable():
		_set_playing_for_ad(true)
		_gp.rewarded("rewarded")
	else:
		_demo_rewarded()


func show_interstitial() -> void:
	if _is_usable():
		_set_playing_for_ad(true)
		_gp.interstitial("interstitial")
	else:
		_demo_interstitial()


func show_banner() -> void:
	if _is_usable():
		_gp.bannerShow()


func hide_banner() -> void:
	if _is_usable():
		_gp.bannerHide()


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


func _set_playing_for_ad(show: bool) -> void:
	if show:
		_gameplay_before_ad = gameplay_active
		set_gameplay(false)
	else:
		if _gameplay_before_ad:
			set_gameplay(true)
		_gameplay_before_ad = false


# ---------------------------------------------------------------------------
# Авторизация
# ---------------------------------------------------------------------------

func is_signed_in() -> bool:
	return signed_in


func refresh_player() -> void:
	if _is_usable():
		_gp.playerInfo("info")


func request_login() -> void:
	if _is_usable():
		_gp.auth("auth")


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
# Облачные сохранения (GamePush storage)
# ---------------------------------------------------------------------------

func request_cloud_load() -> void:
	if _is_usable():
		_gp.cloudLoad("cloud_loaded")


func push_cloud() -> void:
	if not _is_usable():
		return
	if _cloud_sync_busy:
		_cloud_pending = true
		return
	_cloud_sync_busy = true
	_gp.cloudSave("cloud_saved", GameState.dump_settings_text())


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
# Фокус/видимость
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