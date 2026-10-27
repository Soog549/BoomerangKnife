extends Node

## Аудио-система: музыка (циклические лупы) и SFX (банк файлов с процедурным
## фолбэком). Отдельные громкости: master (GameState.volume) × music/sfx.
## Глобальный мьют (потеря фокуса вкладки — требование Яндекс Игр): set_muted.

const SFX_FILES := {
	"throw": "res://assets/sfx/throw.ogg",
	"hit": "res://assets/sfx/hit.ogg",
	"hit_crit": "res://assets/sfx/hit_crit.ogg",
	"break": "res://assets/sfx/break.ogg",
	"catch": "res://assets/sfx/catch.ogg",
	"return": "res://assets/sfx/return.ogg",
	"click": "res://assets/sfx/click.ogg",
	"hover": "res://assets/sfx/hover.ogg",
	"buy": "res://assets/sfx/buy.ogg",
	"coin": "res://assets/sfx/coin.ogg",
	"crystal": "res://assets/sfx/crystal.ogg",
	"achievement": "res://assets/sfx/achievement.ogg",
	"level": "res://assets/sfx/levelup.ogg",
	"revive": "res://assets/sfx/revive.ogg",
	"over": "res://assets/sfx/gameover.ogg",
	"win": "res://assets/sfx/win.ogg",
	"defeat": "res://assets/sfx/defeat.ogg",
	"shield": "res://assets/sfx/shield.ogg",
	"magnet": "res://assets/sfx/magnet.ogg",
	"combo": "res://assets/sfx/combo.ogg",
	"deny": "res://assets/sfx/deny.ogg",
	"daily": "res://assets/sfx/daily.ogg",
	"portal": "res://assets/sfx/portal.ogg",
}

const MUSIC_FILES := {
	"menu": "res://assets/music/memu_loop.ogg",
	"menu_v2": "res://assets/music/menu_v2.ogg",
	"gameplay": "res://assets/music/gameplay_loop.ogg",
	"gameplay_v2": "res://assets/music/gameplay_v2.ogg",
	"duel": "res://assets/music/duel_loop.ogg",
	"skin_1": "res://assets/audio/music12/music-01.ogg",
	"skin_2": "res://assets/audio/music12/music-02.ogg",
	"skin_3": "res://assets/audio/music12/music-03.ogg",
	"skin_4": "res://assets/audio/music12/music-04.ogg",
	"skin_5": "res://assets/audio/music12/music-05.ogg",
	"skin_6": "res://assets/audio/music12/music-06.ogg",
	"skin_7": "res://assets/audio/music12/music-07.ogg",
	"skin_8": "res://assets/audio/music12/music-08.ogg",
	"skin_9": "res://assets/audio/music12/music-09.ogg",
	"skin_10": "res://assets/audio/music12/music-10.ogg",
	"skin_11": "res://assets/audio/music12/music-11.ogg",
	"skin_12": "res://assets/audio/music12/music-12.ogg",
	"skin_13": "res://assets/audio/music12/music-13.ogg",
	"skin_14": "res://assets/audio/music12/music-14.ogg",
	"skin_15": "res://assets/audio/music12/music-15.ogg",
	"skin_16": "res://assets/audio/music12/music-16.ogg",
	"skin_17": "res://assets/audio/music12/music-17.ogg",
	"skin_18": "res://assets/audio/music12/music-18.ogg",
	"skin_19": "res://assets/audio/music12/music-19.ogg",
	"skin_20": "res://assets/audio/music12/music-20.ogg",
}

# Ротация вариаций меню/геймплея: каждый новый заход в режим играет другой луп.
var _menu_rotate := false
var _gameplay_rotate := false

var _muted := false
var _music_player: AudioStreamPlayer
var _music := ""
var _active_sfx: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}
var _procedural: Dictionary = {}

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "Music"
	add_child(_music_player)
	_music_player.finished.connect(_on_music_finished)
	_build_procedural_fallback()
	_update_volumes()

func _exit_tree() -> void:
	# Останавливаем всё аудио до демонтажа аудио-сервера (чистый выход, без
	# утечек дескрипторов Ogg при форсированном завершении).
	if _music_player != null:
		_music_player.stop()
	for p in _active_sfx:
		if is_instance_valid(p):
			p.stop()
	_active_sfx.clear()

# ---------- громкость ----------
func _base_db(part: float) -> float:
	if _muted:
		return -80.0
	return linear_to_db(clampf(GameState.volume * part, 0.0001, 1.0))

func _sfx_db() -> float:
	return _base_db(GameState.sfx_volume)

func _music_db() -> float:
	return _base_db(GameState.music_volume)

func _update_volumes() -> void:
	if _music_player != null:
		_music_player.volume_db = _music_db()
	for p in _active_sfx:
		p.volume_db = _sfx_db()

## Вызывается из настроек при изменении громкости напрямую.
func update_volumes() -> void:
	_update_volumes()

## Глобальный мьют (потеря фокуса/видимости вкладки).
func set_muted(muted: bool) -> void:
	_muted = muted
	_update_volumes()

# ---------- музыка ----------
## Запускает циклический луп. track: "menu"/"gameplay"/"duel" (menu_v2/gameplay_v2 — ротация).
func play_music(track: String) -> void:
	# Ротация: если уже играет вариация того же семейства — не перезапускаем,
	# иначе выбираем следующую вариацию (чередование между забегами).
	if track == "menu":
		if _music in ["menu", "menu_v2"] and _music_player.playing:
			return
		_menu_rotate = not _menu_rotate
		track = "menu_v2" if _menu_rotate else "menu"
	elif track == "gameplay":
		if _music in ["gameplay", "gameplay_v2"] and _music_player.playing:
			return
		_gameplay_rotate = not _gameplay_rotate
		track = "gameplay_v2" if _gameplay_rotate else "gameplay"
	if not MUSIC_FILES.has(track):
		return
	var path: String = MUSIC_FILES[track]
	if not ResourceLoader.exists(path):
		if _music != "" and _music_player.playing:
			_music_player.stop()
		_music = ""
		return
	if _music == track and _music_player.playing:
		return
	_music = track
	_music_player.stream = load(path) as AudioStream
	_music_player.volume_db = _music_db()
	_music_player.play()

func _on_music_finished() -> void:
	if _music != "":
		_music_player.play()

# ---------- SFX ----------
## Воспроизводит короткий звук (банк файлов  фолбэк на процедурный).
func play(sfx_name: String) -> void:
	var transient := AudioStreamPlayer.new()
	transient.volume_db = _sfx_db()
	if _sfx_cache.has(sfx_name):
		transient.stream = _sfx_cache[sfx_name]
	elif _procedural.has(sfx_name):
		transient.stream = _procedural[sfx_name]
	else:
		transient.queue_free()
		return
	add_child(transient)
	_active_sfx.append(transient)
	transient.play()
	transient.finished.connect(func()->void: _release(transient))

func _release(player: AudioStreamPlayer) -> void:
	_active_sfx.erase(player)
	player.queue_free()

# ---------- фолбэк ----------
func _build_procedural_fallback() -> void:
	var bank := {
		"hit": _tone([440.0, 660.0], 0.09, 0.5),
		"clank": _noise(0.08, 0.5),
		"regen": _tone([880.0, 720.0], 0.18, 0.3),
		"break": _noise(0.18, 0.7),
		"return": _tone([660.0, 440.0], 0.14, 0.4),
		"click": _tone([880.0], 0.04, 0.3),
		"level": _tone([523.0, 659.0, 784.0], 0.22, 0.4),
		"over": _tone([220.0, 180.0], 0.5, 0.5),
	}
	for key in bank:
		if not ResourceLoader.exists(SFX_FILES.get(key, "")):
			_procedural[key] = bank[key]
	for event in SFX_FILES:
		if ResourceLoader.exists(SFX_FILES[event]):
			_sfx_cache[event] = load(SFX_FILES[event])

func _tone(freqs: Array, duration: float, gain: float) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(rate * duration)
	var data := PackedByteArray()
	for f in frames:
		var t := f / float(rate)
		var envelope := 1.0 - float(f) / frames
		var value := 0.0
		for i in freqs.size():
			value += sin(TAU * float(freqs[i]) * t) / freqs.size()
		var sample := int(clampf(value * envelope * gain * 32767.0, -32767, 32767))
		data.append(sample & 0xFF)
		data.append((sample >> 8) & 0xFF)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav

func _noise(duration: float, gain: float) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(rate * duration)
	var data := PackedByteArray()
	for f in frames:
		var t := float(f) / frames
		var envelope := 1.0 - t
		var value := randf_range(-1.0, 1.0) * envelope * gain
		var sample := int(clampf(value * 32767.0, -32767, 32767))
		data.append(sample & 0xFF)
		data.append((sample >> 8) & 0xFF)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav

func play_skin_music() -> void:
	var t := int(GameState.music_track)
	if t >= 1 and t <= 20:
		play_music("skin_%d" % t)
		return
	var i: int = clampi(GameState.selected_skin, 0, 11)
	play_music("skin_%d" % (i + 1))
