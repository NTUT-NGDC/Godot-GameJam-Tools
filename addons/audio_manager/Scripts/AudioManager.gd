extends Node

# ---------- 設定 ----------
const BGM_BUS := "BGM"
const SFX_BUS := "SFX"
const SFX_POOL_SIZE := 8          # 音效池大小,可依專案調整
const DEFAULT_FADE_TIME := 1.0    # BGM 淡入淡出秒數

# ---------- BGM 雙軌交叉淡化 ----------
var _bgm_players: Array[AudioStreamPlayer] = []
var _active_bgm_index := 0
var _current_bgm_stream: AudioStream = null
var _bgm_tween: Tween

# ---------- SFX 音效池 ----------
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index := 0

# ---------- 音量 / 靜音狀態 ----------
var bgm_volume: float = 1.0 : set = set_bgm_volume
var sfx_volume: float = 1.0 : set = set_sfx_volume
var muted: bool = false : set = set_muted


func _ready() -> void:
	# 建立兩個 BGM 播放器,互相交叉淡化用
	for i in range(2):
		var p := AudioStreamPlayer.new()
		p.bus = BGM_BUS
		p.volume_db = -80.0  # 一開始靜音
		add_child(p)
		_bgm_players.append(p)

	# 建立 SFX 播放器池
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_sfx_pool.append(p)


# =========================================================
# 對外 API
# =========================================================

## 播放 BGM,若已有 BGM 在播放,會自動做淡入淡出交叉切換
func play_bgm(track: AudioStream, fade_time: float = DEFAULT_FADE_TIME) -> void:
	if track == _current_bgm_stream:
		return  # 同一首就不重播

	_current_bgm_stream = track

	var old_player := _bgm_players[_active_bgm_index]
	var new_index := 1 - _active_bgm_index
	var new_player := _bgm_players[new_index]

	new_player.stream = track
	new_player.volume_db = -80.0
	new_player.play()

	if _bgm_tween:
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.set_parallel(true)

	# 舊的淡出
	if old_player.playing:
		_bgm_tween.tween_property(old_player, "volume_db", -80.0, fade_time)
	# 新的淡入到目前設定音量
	var target_db := linear_to_db(bgm_volume) if not muted else -80.0
	_bgm_tween.tween_property(new_player, "volume_db", target_db, fade_time)

	_bgm_tween.chain().tween_callback(old_player.stop)

	_active_bgm_index = new_index


## 停止目前 BGM(淡出)
func stop_bgm(fade_time: float = DEFAULT_FADE_TIME) -> void:
	var player := _bgm_players[_active_bgm_index]
	_current_bgm_stream = null
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -80.0, fade_time)
	tween.tween_callback(player.stop)


## 播放音效,自動從音效池取用可用的 player,避免爆音疊加
func play_sfx(sound: AudioStream, volume_offset_db: float = 0.0) -> void:
	if sound == null:
		return

	var player := _get_available_sfx_player()
	player.stream = sound
	player.volume_db = linear_to_db(sfx_volume) + volume_offset_db
	player.play()


# =========================================================
# 音量 / 靜音控制
# =========================================================

func set_bgm_volume(value: float) -> void:
	bgm_volume = clamp(value, 0.0, 1.0)
	if not muted:
		var player := _bgm_players[_active_bgm_index]
		player.volume_db = linear_to_db(bgm_volume)


func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	# SFX 是短音效,不需要即時改變已播放中的音量,下一次 play_sfx 生效即可


func set_muted(value: bool) -> void:
	muted = value
	var bus_idx_bgm := AudioServer.get_bus_index(BGM_BUS)
	var bus_idx_sfx := AudioServer.get_bus_index(SFX_BUS)
	AudioServer.set_bus_mute(bus_idx_bgm, muted)
	AudioServer.set_bus_mute(bus_idx_sfx, muted)


# =========================================================
# 內部工具
# =========================================================

## 從音效池挑一個「沒在播放」的 player;
## 若全部都在播放中,就強制搶用最舊的一個(輪替),避免無限疊加
func _get_available_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_pool:
		if not p.playing:
			return p

	# 全部都在忙 -> 用輪替索引搶用最舊的那個
	var player := _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % _sfx_pool.size()
	return player
