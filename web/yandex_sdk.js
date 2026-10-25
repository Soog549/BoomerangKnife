<style>
/* Запрет выделения/контекстного меню при лонгтапе (требование Яндекс Игр для мобильных). */
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
<script src="/sdk.js"></script>
<script>
/*
 * Yandex Games SDK bridge для BoomerangKnife (Godot 4.7 Web export).
 * Вставляется в <head> экспортируемого index.html (настройка html/head_include).
 *
 * На платформе Яндекс Игр `/sdk.js` подгружается автоматически. Вне платформы
 * (локальный запуск) лоадер отсутствует -> `window.YaGames` нет, и игра работает
 * в демо-режиме через GDScript (YandexSDK), как и реклама AdMob в демо.
 *
 * Контракт с GDScript (scripts/yandex_sdk.gd):
 *   - GDScript регистрирует JS-колбэки через window.__gb.cb.<name>.
 *   - JS-помощники вызывают __gb.fire(name, payload), где payload - объект.
 */
(function () {
  'use strict';
  var gb = (window.__gb = {
    ysdk: null,
    initStarted: false,
    cb: {},
    fire: function (name, payload) {
      try {
        var f = gb.cb[name];
        if (typeof f === 'function') { f(payload); }
      } catch (e) { console.warn('[YSDK] cb ' + name, e); }
    }
  });

  function boot() {
    if (gb.initStarted) { return; }
    gb.initStarted = true;
    if (!window.YaGames) {
      console.warn('[YSDK] лоадер /sdk.js не найден — демо-режим');
      return;
    }
    try {
      window.YaGames.init().then(function (ysdk) {
        gb.ysdk = ysdk;
        try {
          var lang = (ysdk.environment && ysdk.environment.i18n && ysdk.environment.i18n.lang) || 'ru';
          gb.lang = lang;
          window.YSDK_LANG = lang;
          document.documentElement.lang = lang;
          gb.fire('lang', { lang: lang });
          console.log('[YSDK] lang=' + lang);
        } catch (e) { console.warn('[YSDK] lang error', e); }
        console.log('[YSDK] инициализирован');
      }).catch(function (e) {
        console.warn('[YSDK] init error', e);
      });
    } catch (e) {
      console.warn('[YSDK] init error', e);
    }
  }

  gb.ready = function () {
    try {
      if (gb.ysdk && gb.ysdk.features && gb.ysdk.features.LoadingAPI) {
        gb.ysdk.features.LoadingAPI.ready();
      }
    } catch (e) {}
  };
  gb.gameplayStart = function () {
    try {
      if (gb.ysdk && gb.ysdk.features && gb.ysdk.features.GameplayAPI) {
        gb.ysdk.features.GameplayAPI.start();
      }
    } catch (e) {}
  };
  gb.gameplayStop = function () {
    try {
      if (gb.ysdk && gb.ysdk.features && gb.ysdk.features.GameplayAPI) {
        gb.ysdk.features.GameplayAPI.stop();
      }
    } catch (e) {}
  };
  gb.rewarded = function (name) {
    if (!gb.ysdk || !gb.ysdk.adv) { gb.fire(name, { ok: false, error: 'no-sdk' }); return; }
    var done = false;
    var close = function (payload) { if (!done) { done = true; gb.fire(name, payload); } };
    var failTimer = null;
    try {
      gb.ysdk.adv.showRewardedVideo({
        callbacks: {
          onOpen: function () {
            // У некоторых билдов SDK onClose приходит раньше onRewarded — даём
            // награде фору, иначе «реклама посмотрена, а счётчик не засчитался».
            if (failTimer) { clearTimeout(failTimer); }
            failTimer = setTimeout(function () { close({ ok: false }); }, 15000);
          },
          onRewarded: function () {
            if (failTimer) { clearTimeout(failTimer); }
            close({ ok: true });
          },
          onClose: function () {
            // onRewarded, как правило, приходит до onClose. Если прогресс уже
            // отдан — просто завершаем. Если нет (закрыл рано) — ждём паузу,
            // давая шанс запоздавшему onRewarded, и только потом фейлим.
            if (done) { return; }
            if (failTimer) { clearTimeout(failTimer); }
            failTimer = setTimeout(function () { close({ ok: false }); }, 1200);
          },
          onError: function (err) {
            if (failTimer) { clearTimeout(failTimer); }
            close({ ok: false, error: String(err) });
          }
        }
      });
    } catch (e) {
      if (failTimer) { clearTimeout(failTimer); }
      close({ ok: false, error: String(e) });
    }
  };
  gb.interstitial = function (name) {
    if (!gb.ysdk || !gb.ysdk.adv) { gb.fire(name, {}); return; }
    var done = false;
    var close = function (p) { if (!done) { done = true; gb.fire(name, p); } };
    try {
      gb.ysdk.adv.showFullscreenAdv({
        callbacks: {
          onClose: function () { close({ ok: true }); },
          onError: function (err) { close({ ok: false, error: String(err) }); }
        }
      });
    } catch (e) { close({ ok: false, error: String(e) }); }
  };
  gb.bannerShow = function () {
    try {
      if (gb.ysdk && gb.ysdk.adv && gb.ysdk.adv.getBannerAdvStatus) {
        gb.ysdk.adv.getBannerAdvStatus().then(function (s) {
          if (s && s.status === 'ACTIVATED' && gb.ysdk.adv.showBannerAdv) {
            gb.ysdk.adv.showBannerAdv();
          }
        }).catch(function () {});
      }
    } catch (e) {}
  };
  gb.bannerHide = function () {
    try {
      if (gb.ysdk && gb.ysdk.adv && gb.ysdk.adv.hideBannerAdv) { gb.ysdk.adv.hideBannerAdv(); }
    } catch (e) {}
  };
  gb.getCurrent = function () {
    if (!gb.ysdk) { return Promise.resolve(null); }
    try {
      if (gb.ysdk.getPlayer) { return gb.ysdk.getPlayer({ scopes: false }); }
      return Promise.resolve(gb.ysdk.player || null);
    } catch (e) { return Promise.resolve(null); }
  };
  function playerInfo(player) {
    var info = { ok: false, name: '', id: '' };
    if (player) {
      info.ok = true;
      try {
        info.name = player.getName ? player.getName() : (player.name || '');
        info.id = String(player.getUniqueID ? player.getUniqueID() : (player.id || ''));
      } catch (e) {}
    }
    return info;
  }
  gb.auth = function (name) {
    if (!gb.ysdk) { gb.fire(name, { ok: false, error: 'no-sdk' }); return; }
    var finish = function (player) { gb.fire(name, playerInfo(player)); };
    try {
      if (gb.ysdk.auth && gb.ysdk.auth.openAuthDialog) {
        gb.ysdk.auth.openAuthDialog().then(function () {
          gb.getCurrent().then(finish);
        }).catch(function () { gb.getCurrent().then(finish); });
      } else {
        gb.getCurrent().then(finish);
      }
    } catch (e) {
      gb.getCurrent().then(finish);
    }
  };
  gb.playerInfo = function (name) {
    gb.getCurrent().then(function (player) { gb.fire(name, playerInfo(player)); });
  };
  var DATA_KEY = 'settings';
  gb.cloudSave = function (name, text) {
    if (!gb.ysdk) { gb.fire(name, { ok: false, error: 'no-sdk' }); return; }
    gb.getCurrent().then(function (player) {
      if (!player || !player.setData) { gb.fire(name, { ok: false, error: 'guest' }); return; }
      var data = {};
      data[DATA_KEY] = text || '';
      try {
        player.setData(data).then(function () { gb.fire(name, { ok: true }); })
          .catch(function (err) { gb.fire(name, { ok: false, error: String(err) }); });
      } catch (e) { gb.fire(name, { ok: false, error: String(e) }); }
    }).catch(function () { gb.fire(name, { ok: false, error: 'no-player' }); });
  };
  gb.cloudLoad = function (name) {
    if (!gb.ysdk) { gb.fire(name, { ok: false, data: '', error: 'no-sdk' }); return; }
    gb.getCurrent().then(function (player) {
      if (!player || !player.getData) { gb.fire(name, { ok: false, data: '' }); return; }
      try {
        player.getData().then(function (d) {
          gb.fire(name, { ok: true, data: (d && d[DATA_KEY] != null) ? String(d[DATA_KEY]) : '' });
        }).catch(function (e) { gb.fire(name, { ok: false, data: '' }); });
      } catch (e) { gb.fire(name, { ok: false, data: '' }); }
    }).catch(function () { gb.fire(name, { ok: false, data: '' }); });
  };

  window.__gb = gb;
  boot();

  /* Потеря/возврат видимости вкладки -> Godot (обязательно: звук на паузу <= 2с). */
  document.addEventListener('visibilitychange', function () {
    gb.fire('visibility', { visible: !document.hidden });
  });
  window.addEventListener('focus', function () { gb.fire('visibility', { visible: true }); });
  window.addEventListener('blur', function () { gb.fire('visibility', { visible: false }); });
})();



/*FITV5*/
(function(){
  var canvas = null;
  function fit(){
    if (!canvas) { canvas = document.querySelector('#canvas') || document.querySelector('canvas'); }
    if (!canvas) return;
    var vw = document.documentElement.clientWidth || window.innerWidth;
    var vh = document.documentElement.clientHeight || window.innerHeight;
    var k = Math.min(vw / 720, vh / 1280);
    canvas.style.position = 'absolute';
    canvas.style.transformOrigin = 'top left';
    canvas.style.transform = 'scale(' + k + ')';
    canvas.style.left = Math.round((vw - 720 * k) / 2) + 'px';
    canvas.style.top = Math.round((vh - 1280 * k) / 2) + 'px';
    canvas.style.margin = '0';
  }
  function loop(){ fit(); window.requestAnimationFrame(loop); }
  window.addEventListener('resize', fit, {passive:true});
  window.addEventListener('orientationchange', fit, {passive:true});
  document.addEventListener('DOMContentLoaded', fit);
  if (window.ResizeObserver) { try { new ResizeObserver(fit).observe(document.documentElement); } catch(e){} }
  try { loop(); } catch(e) { setInterval(fit, 250); }
})();
/*END-FITV5*/
</script>