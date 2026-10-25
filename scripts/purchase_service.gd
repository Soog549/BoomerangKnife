extends Node

## Платёжный шлюз для покупок (IAP).
##
## Пока BILLING_ENABLED == false работает демо-режим: покупка «проходит» мгновенно,
## чтобы экономику и магазин можно было тестировать без платёжного SDK.
##
## Для релиза: подключи реальный биллинг (RuStore Billing / Google Play Billing /
## VK Play Payments) и вызывай purchase_completed(success, pack_id) по факту оплаты.

const BILLING_ENABLED := false

signal purchase_completed(success: bool, pack_id: String)

## Запрос покупки пака. Результат придёт в сигнал purchase_completed.
func purchase(pack_id: String) -> void:
	if not BILLING_ENABLED:
		await get_tree().create_timer(0.4).timeout
		purchase_completed.emit(true, pack_id)
		return
	# TODO: интеграция реального биллинга.
	# Начни с проверки не-потраченных покупок при старте (restore purchases),
	# затем вызывай платёжный SDK:
	#   RuStore:    RuStorePayments.purchase(pack_id)
	#   Google:    GodotGooglePlayBilling.purchase(pack_id)
	#   VK Play:    VKPayments.purchase(pack_id)
	purchase_completed.emit(false, pack_id)
