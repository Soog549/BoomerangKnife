extends Node

## Единый шлюз рекламы.
##
## Платформы:
##   - Web (Яндекс Игры): реклама через YandexSDK (YSDK). Без SDK — демо-режим.
##   - Android: плагин AdMob (Poing-Studios). Без плагина — демо-режим.
##   - Прочие: демо-режим.
##
## Публичный API (сигналы) тот же для всех платформ — потребители
## (main.gd, shop.gd, endless.gd, duel_arena.gd) не меняются.

signal rewarded_completed(success: bool)
signal interstitial_closed

const ADMOB_INITIALIZED := false

# Тестовые ID объявлений (Google официально публикует их для разработчиков).
# Замени на реальные из консоли AdMob перед релизом (Android-сборка).
const TEST_REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"
const TEST_INTERSTITIAL_ID := "ca-app-pub-3940256099942544/1033173712"
const TEST_BANNER_ID := "ca-app-pub-3940256099942544/6300978111"

## Баннер (стики) — на web через YSDK, на Android через плагин (если включён).
const BANNER_ENABLED := true

var _admob: Object = null

func _ready() -> void:
	if YandexSDK.is_web:
		YandexSDK.rewarded_result.connect(func(ok: bool): rewarded_completed.emit(ok))
		YandexSDK.interstitial_closed_result.connect(func(): interstitial_closed.emit())
		return
	if Engine.has_singleton("AdMob"):
		_admob = Engine.get_singleton("AdMob")
	if not ADMOB_INITIALIZED:
		print(tr("[Ads] Демо-режим: плагин AdMob не активирован, реклама не показывается."))
	else:
		_setup_plugin()

# ---------------------------------------------------------------------------
# Публичный API
# ---------------------------------------------------------------------------

## Включён ли демо-режим (нет живого SDK на текущей платформе).
func is_demo_mode() -> bool:
	if YandexSDK.is_web:
		return not YandexSDK.is_ready
	return not ADMOB_INITIALIZED

func show_rewarded() -> void:
	if YandexSDK.is_web:
		YandexSDK.show_rewarded()
		return
	if not _admob_available():
		await get_tree().create_timer(0.4).timeout
		rewarded_completed.emit(true)
		return
	if _admob.has_method("is_rewarded_ad_loaded") and _admob.is_rewarded_ad_loaded():
		_admob.show_rewarded_ad()
	elif _admob.has_method("show_rewarded_ad"):
		_admob.show_rewarded_ad()
	else:
		rewarded_completed.emit(false)

func show_interstitial() -> void:
	if YandexSDK.is_web:
		YandexSDK.show_interstitial()
		return
	if not _admob_available():
		interstitial_closed.emit()
		return
	if _admob.has_method("is_interstitial_ad_loaded") and _admob.is_interstitial_ad_loaded():
		_admob.show_interstitial_ad()
	elif _admob.has_method("show_interstitial_ad"):
		_admob.show_interstitial_ad()
	else:
		interstitial_closed.emit()

## Показать баннерную (стики) рекламу. На web — через YSDK, уважая настройку
## платформы (показывается только если рекламодатель активирован платформой).
func show_banner() -> void:
	if YandexSDK.is_web:
		if BANNER_ENABLED:
			YandexSDK.show_banner()
		return
	if not BANNER_ENABLED or not _admob_available():
		return
	if _admob.has_method("show_banner_ad"):
		_admob.show_banner_ad()
	elif _admob.has_method("show_banner"):
		_admob.show_banner()

func hide_banner() -> void:
	if YandexSDK.is_web:
		YandexSDK.hide_banner()
		return
	if not BANNER_ENABLED or not _admob_available():
		return
	if _admob.has_method("hide_banner_ad"):
		_admob.hide_banner_ad()
	elif _admob.has_method("hide_banner"):
		_admob.hide_banner()

# ---------------------------------------------------------------------------
# Установка плагина AdMob (вызывается только когда объявлен реальный плагин)
# ---------------------------------------------------------------------------

func _setup_plugin() -> void:
	if _admob.has_method("set_is_testing"):
		_admob.set_is_testing(true)

	if _admob.has_method("set_banner_unit_id"):
		_admob.set_banner_unit_id(TEST_BANNER_ID)
	if _admob.has_method("set_interstitial_unit_id"):
		_admob.set_interstitial_unit_id(TEST_INTERSTITIAL_ID)
	if _admob.has_method("set_rewarded_ad_unit_id"):
		_admob.set_rewarded_ad_unit_id(TEST_REWARDED_ID)

	if _admob.has_method("initialize"):
		_admob.initialize()
	elif _admob.has_method("load_rewarded_ad"):
		_admob.load_rewarded_ad()
		_admob.load_interstitial_ad()

	if not _admob.rewarded_ad_earning_reward.is_connected(_on_reward):
		_admob.rewarded_ad_earning_reward.connect(_on_reward)
	if not _admob.interstitial_ad_closed.is_connected(_on_interstitial_closed):
		_admob.interstitial_ad_closed.connect(_on_interstitial_closed)

func _on_reward() -> void:
	rewarded_completed.emit(true)

func _on_interstitial_closed() -> void:
	interstitial_closed.emit()

func _admob_available() -> bool:
	return ADMOB_INITIALIZED and _admob != null