extends Node

# =========================================================
# 設定
# =========================================================
const MASTER_BUS := "Master"
const BGM_BUS := "BGM"
const SFX_BUS := "SFX"
const SFX_POOL_SIZE := 8          # 音效池大小,可依專案調整
const DEFAULT_FADE_TIME := 1.0    # BGM 淡入淡出秒數
const SFX_COOLDOWN_TIME := 0.05   # 同一個音效,間隔小於這個秒數就忽略,避免爆音
const SILENT_DB := -80.0

# =========================================================
# 音效名稱查找表(由 SoundBank 節點註冊進來)
# =========================================================
var _bgm_lookup: Dictionary = {}  # key: 名字(String), value: AudioStream
var _sfx_lookup: Dictionary = {}

# =========================================================
# BGM 雙軌交叉淡化
# =========================================================
var _bgm_players: Array[AudioStreamPlayer] = []
var _bgm_fade_factor: Array[float] = [0.0, 0.0]  # 每個 player 各自的淡入淡出係數(0~1)
var _bgm_tweens: Array[Tween] = [null, null]     # 每個 player 各自獨立的 tween,互不干擾
var _active_bgm_index := 0
var _current_bgm_name: String = ""

# =========================================================
# SFX 音效池
# =========================================================
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index := 0
var _sfx_last_played_time: Dictionary = {}  # key: AudioStream, value: 上次播放時間

# =========================================================
# 音量 / 靜音狀態
# =========================================================
var master_volume: float = 1.0 : set = set_master_volume
var bgm_volume: float = 1.0 : set = set_bgm_volume
var sfx_volume: float = 1.0 : set = set_sfx_volume
var muted: bool = false : set = set_muted

# =========================================================
# 音量設定持久化
# =========================================================
## AudioManager 自己讀寫這個檔案,不透過 SaveManager——
## 音量/靜音是「應用程式設定」,跟哪一個遊戲存檔無關(不會因為開新遊戲而被重置),
## 也讓 audio_manager 這個 addon 可以單獨使用,不用依賴 save_system。
const SETTINGS_PATH := "user://audio_settings.json"

var _settings_loaded := false  # 讀檔完成前,setter 觸發的存檔先不處理,避免把預設值寫回去蓋掉設定檔


func _ready() -> void:
	# 音樂/音效不該因為遊戲暫停(get_tree().paused = true)而跟著停掉,
	# 例如按 ESC 開暫停選單時 BGM 應該繼續播放。
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 建立兩個 BGM 播放器,互相交叉淡化用
	for i in range(2):
		var p := AudioStreamPlayer.new()
		p.bus = BGM_BUS
		p.volume_db = SILENT_DB  # 一開始靜音
		add_child(p)
		_bgm_players.append(p)

	# 建立 SFX 播放器池
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_sfx_pool.append(p)

	_load_settings()


func _load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file == null:
			push_error("[AudioManager] 無法開啟音量設定檔讀取 -> %s" % SETTINGS_PATH)
		else:
			var parsed = JSON.parse_string(file.get_as_text())
			file.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				set_master_volume(parsed.get("master_volume", master_volume))
				set_bgm_volume(parsed.get("bgm_volume", bgm_volume))
				set_sfx_volume(parsed.get("sfx_volume", sfx_volume))
				set_muted(parsed.get("muted", muted))
			else:
				push_error("[AudioManager] 音量設定檔內容格式錯誤或已損毀 -> %s" % SETTINGS_PATH)

	_settings_loaded = true


## 音量/靜音一變動就立即寫檔(內容只有四個欄位,寫檔很輕量,不需要額外做去抖動)
func _save_settings() -> void:
	if not _settings_loaded:
		return

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[AudioManager] 無法開啟音量設定檔寫入 -> %s (錯誤碼: %s)" % [SETTINGS_PATH, FileAccess.get_open_error()])
		return

	file.store_string(JSON.stringify({
		"master_volume": master_volume,
		"bgm_volume": bgm_volume,
		"sfx_volume": sfx_volume,
		"muted": muted,
	}))
	file.close()


# =========================================================
# 註冊音效(給 SoundBank 節點呼叫,不需要手動使用)
# =========================================================

## 登記表是全專案共用的全域命名空間,不會因場景卸載而清除,
## 請確保 Sound Name 在整個專案裡是唯一的。
func register_bgm(sound_name: String, stream: AudioStream) -> void:
	if _bgm_lookup.has(sound_name) and _bgm_lookup[sound_name] != stream:
		push_warning("[AudioManager] BGM名稱 '" + sound_name + "' 被重複註冊成不同的音檔,將會覆蓋原本的登記")
	_bgm_lookup[sound_name] = stream


func register_sfx(sound_name: String, stream: AudioStream) -> void:
	if _sfx_lookup.has(sound_name) and _sfx_lookup[sound_name] != stream:
		push_warning("[AudioManager] SFX名稱 '" + sound_name + "' 被重複註冊成不同的音檔,將會覆蓋原本的登記")
	_sfx_lookup[sound_name] = stream


# =========================================================
# 對外 API:BGM
# =========================================================

## 播放 BGM(用名字呼叫,例如 "battle_theme"),若已有 BGM 在播放,會自動交叉淡化切換
func play_bgm(track_name: String, fade_time: float = DEFAULT_FADE_TIME) -> void:
	if not _bgm_lookup.has(track_name):
		push_warning("[AudioManager] 找不到名叫 '" + track_name + "' 的BGM,請檢查 SoundBank 設定")
		return

	if track_name == _current_bgm_name:
		return  # 同一首就不重播

	var track: AudioStream = _bgm_lookup[track_name]
	_current_bgm_name = track_name

	var old_index := _active_bgm_index
	var new_index := 1 - _active_bgm_index
	var new_player := _bgm_players[new_index]

	new_player.stream = track
	_set_bgm_fade_factor(new_index, 0.0)
	new_player.play()

	_fade_bgm_player(old_index, 0.0, fade_time, true)   # 舊的淡出,淡完就停止
	_fade_bgm_player(new_index, 1.0, fade_time, false)  # 新的淡入到目前音量

	_active_bgm_index = new_index


## 停止目前 BGM(淡出)
func stop_bgm(fade_time: float = DEFAULT_FADE_TIME) -> void:
	_current_bgm_name = ""
	_fade_bgm_player(_active_bgm_index, 0.0, fade_time, true)


# =========================================================
# 對外 API:SFX
# =========================================================

## 播放音效(用名字呼叫,例如 "click"),自動從音效池取用可用的 player,
## 並自動避免同一個音效短時間內大量疊加造成爆音
func play_sfx(sound_name: String, volume_offset_db: float = 0.0) -> void:
	if not _sfx_lookup.has(sound_name):
		push_warning("[AudioManager] 找不到名叫 '" + sound_name + "' 的音效,請檢查 SoundBank 設定")
		return

	var sound: AudioStream = _sfx_lookup[sound_name]
	if sound == null:
		return

	# ---- 冷卻檢查:避免同一個音效短時間內被大量重複播放 ----
	var current_time := Time.get_ticks_msec() / 1000.0
	if _sfx_last_played_time.has(sound):
		var last_time: float = _sfx_last_played_time[sound]
		if current_time - last_time < SFX_COOLDOWN_TIME:
			return  # 太近了,直接忽略這次播放請求

	_sfx_last_played_time[sound] = current_time

	var player := _get_available_sfx_player()
	player.stream = sound
	player.volume_db = linear_to_db(sfx_volume) + volume_offset_db
	player.play()


# =========================================================
# 音量 / 靜音控制
# =========================================================

## 總音量直接控制 Master bus,BGM/SFX 都會送進 Master,不需要額外跟其他音量相乘
func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	var bus_idx := AudioServer.get_bus_index(MASTER_BUS)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(master_volume) if master_volume > 0.0 else SILENT_DB)
	_save_settings()


func set_bgm_volume(value: float) -> void:
	bgm_volume = clamp(value, 0.0, 1.0)
	for i in range(_bgm_players.size()):
		_apply_bgm_volume(i)
	_save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	_save_settings()


## 靜音只透過 bus mute 處理,跟 volume_db 的數值運算完全脫鉤,
## 這樣取消靜音時不需要額外還原任何音量數值
func set_muted(value: bool) -> void:
	muted = value
	var bus_idx_bgm := AudioServer.get_bus_index(BGM_BUS)
	var bus_idx_sfx := AudioServer.get_bus_index(SFX_BUS)
	AudioServer.set_bus_mute(bus_idx_bgm, muted)
	AudioServer.set_bus_mute(bus_idx_sfx, muted)
	_save_settings()


# =========================================================
# 內部工具:BGM 淡化
# =========================================================

## 讓某個 BGM player 的淡化係數(0~1)從目前值動畫到 target_factor。
## 每個 player 有自己獨立的 tween,kill 舊的不會影響另一個 player。
func _fade_bgm_player(player_index: int, target_factor: float, fade_time: float, stop_when_done: bool) -> void:
	if _bgm_tweens[player_index]:
		_bgm_tweens[player_index].kill()

	var tween := create_tween()
	_bgm_tweens[player_index] = tween
	tween.tween_method(
		_set_bgm_fade_factor.bind(player_index),
		_bgm_fade_factor[player_index],
		target_factor,
		fade_time
	)
	if stop_when_done:
		tween.tween_callback(_bgm_players[player_index].stop)


func _set_bgm_fade_factor(player_index: int, factor: float) -> void:
	_bgm_fade_factor[player_index] = factor
	_apply_bgm_volume(player_index)


## 唯一負責寫入 volume_db 的地方:使用者音量 * 淡化係數
func _apply_bgm_volume(player_index: int) -> void:
	var linear := bgm_volume * _bgm_fade_factor[player_index]
	_bgm_players[player_index].volume_db = linear_to_db(linear) if linear > 0.0 else SILENT_DB


# =========================================================
# 內部工具:SFX
# =========================================================

## 從音效池挑一個「沒在播放」的 player;
## 若全部都在播放中,就強制搶用最舊的一個(輪替),避免無限疊加
func _get_available_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_pool:
		if not p.playing:
			return p

	var player := _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % _sfx_pool.size()
	return player
