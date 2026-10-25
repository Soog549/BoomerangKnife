<style>
/* Общие запреты (как в yandex_sdk.js), без разницы на какой площадке крутится. */
html, body, #canvas {
	-webkit-user-select: none;
	-moz-user-select: none;
	-ms-user-select: none;
	user-select: none;
	-webkit-touch-callout: none;
}
#canvas {
	touch-action: none;
}
</style>
<script>
/*
 * GamePush SDK bridge для BoomerangKnife (Godot 4.7 Web export) — «GamePush» билд.
 * Вставляется в <head> экспортируемого index.html (настройка html/head_include
 * в пресете Web-GamePush).
 *
 * Перед публикацией добавь ИНСТАЛЛ-КОД GamePush для твоего проекта (скрипт SDK +
 * регистрация onGPInit) — обычно вставляется в <head>. Без него мост работает в
 * демо-режиме (как yandex_sdk.js вне Яндекс Игр).
 *
 * Контракт с GDScript (scripts/gamepush_sdk.gd) — САМ как у Yandex:
 *   window.__gp = { gp, cb, fire, ready, gameplayStart, gameplayStop,
 *                   rewarded, interstitial, bannerShow, bannerHide,
 *                   auth, playerInfo, cloudSave, cloudLoad }
 *
 * GamePush сам определяет площадку (VK/Яндекс/ОК/Telegram/свой сайт и т.д.) и
 * подгружает нужный SDK площадки. Здесь мы лишь унифицируем API.
 */
(function () {
  'use strict';
  var gpObj = null;
  var gb = (window.__gp = {
    gp: null,
    cb: {},
    fire: function (name, payload) {
      try {
        var f = gb.cb[name];
        if (typeof f === 'function') { f(payload); }
      } catch (e) { console.warn('[GP] cb ' + name, e); }
    }
  });

  /* ---- платформо-независимые обёртки (feature-detect, без хард-крэша) ---- */
  function uname(o) {
    /* вернуть латинское имя игрока либо '' */
    while (typeof o === 'function') { o = o(); }
    if (!o) { return ''; }
    try {
      if (typeof o.getName === 'function') { return String(o.getName() || ''); }
      if (typeof o.name === 'string') { return o.name; }
    } catch (e) {}
    return '';
  }

  function call(name, args) {
    /* вызвать gpObj.<name>(...args), если есть; иначе no-op -> undefined */
    if (!gpObj || typeof gpObj[name] !== 'function') { return undefined; }
    try { return gpObj[name].apply(gpObj, args || []); } catch (e) {}
    return undefined;
  }

  function gameplayReadyImpl() { call('gameplayReady') || call('gamePlayReady'); }
  function gameplayStartImpl() { call('gameplayStart') || call('gamePlayStart'); }
  function gameplayStopImpl() { call('gameplayStop') || call('gamePlayStop'); }

  /* ---- публичные методы (контракт с GDScript) ---- */
  gb.ready = function () { gameplayReadyImpl(); };
  gb.gameplayStart = function () { gameplayStartImpl(); };
  gb.gameplayStop = function () { gameplayStopImpl(); };

  gb.rewarded = function (name) {
    if (!gpObj) { gb.fire(name, { ok: false, error: 'no-sdk' }); return; }
    call('showRewardedVideo', [{ callbacks: {
      onOpen: function () {},
      onReward: function () { gb.fire(name, { ok: true }); },
      onClose: function (ok) { if (!ok) { gb.fire(name, { ok: false }); } },
      onError: function (err) { gb.fire(name, { ok: false, error: String(err) }); }
    } }]);
  };

  gb.interstitial = function (name) {
    if (!gpObj) { gb.fire(name, {}); return; }
    call('showFullscreen', [{ callbacks: {
      onClose: function () { gb.fire(name, { ok: true }); },
      onError: function (err) { gb.fire(name, { ok: false, error: String(err) }); }
    } }]);
  };

  gb.bannerShow = function () { call('showSticky'); };
  gb.bannerHide = function () { call('hideSticky'); };

  function fetchPlayer() {
    if (!gpObj) { return Promise.resolve(null); }
    var p = call('fetchPlayer') || call('getPlayer');
    if (p && typeof p.then === 'function') { return p; }
    return Promise.resolve(gpObj.player || p || null);
  }
  gb.getCurrent = fetchPlayer;

  gb.auth = function (name) {
    fetchPlayer().then(function (pl) {
      gb.fire(name, { ok: !!pl, name: uname(pl), id: pl ? String(pl.id || '') : '' });
    }).catch(function () { gb.fire(name, { ok: false }); });
  };
  gb.playerInfo = function (name) {
    fetchPlayer().then(function (pl) {
      gb.fire(name, { ok: !!pl, name: uname(pl), id: pl ? String(pl.id || '') : '' });
    }).catch(function () { gb.fire(name, { ok: false }); });
  };

  var DATA_KEY = 'settings';
  gb.cloudSave = function (name, text) {
    if (!gpObj) { gb.fire(name, { ok: false, error: 'no-sdk' }); return; }
    var data = {};
    data[DATA_KEY] = text || '';
    var s = call('setStorage', [data]);
    if (s && typeof s.then === 'function') {
      s.then(function () { gb.fire(name, { ok: true }); })
       .catch(function (err) { gb.fire(name, { ok: false, error: String(err) }); });
    } else {
      gb.fire(name, { ok: false, error: 'setStorage not-a-promise' });
    }
  };
  gb.cloudLoad = function (name) {
    if (!gpObj) { gb.fire(name, { ok: false, data: '' }); return; }
    var s = call('getStorage', [DATA_KEY]);
    if (s && typeof s.then === 'function') {
      s.then(function (d) {
        gb.fire(name, { ok: true, data: (d && d[DATA_KEY] != null) ? String(d[DATA_KEY]) : '' });
      }).catch(function () { gb.fire(name, { ok: false, data: '' }); });
    } else {
      gb.fire(name, { ok: false, data: '' });
    }
  };

  /* ---- инициализация ---- */
  function boot() {
    if (window.GamePush && typeof window.GamePush.init === 'function') {
      try {
        window.GamePush.init().then(function (gp) {
          gpObj = gp;
          gb.gp = gp;
          console.log('[GP] инициализирован');
        }).catch(function (e) { console.warn('[GP] init error', e); });
        return;
      } catch (e) { console.warn('[GP] init error', e); }
    }
    console.warn('[GP] SDK не найден — демо-режим');
  }

  /* Если инсталл-код GamePush сам вызывает window.onGPInit(gp) — ловим его. */
  var prevOnGPInit = window.onGPInit;
  window.onGPInit = function (gp) {
    gpObj = gp;
    gb.gp = gp;
    if (typeof prevOnGPInit === 'function') { prevOnGPInit(gp); }
  };

  window.__gp = gb;
  boot();

  /* Потеря/возврат видимости вкладки -> Godot (звук на паузу <= 2с). */
  document.addEventListener('visibilitychange', function () {
    gb.fire('visibility', { visible: !document.hidden });
  });
  window.addEventListener('focus', function () { gb.fire('visibility', { visible: true }); });
  window.addEventListener('blur', function () { gb.fire('visibility', { visible: false }); });
})();
</script>