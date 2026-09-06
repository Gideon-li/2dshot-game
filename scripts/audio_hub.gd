extends Node
## Ambient rain + Music bed + SFX. Rain stays ≤ 0.32. Duck Music on pulse.

const DIR := "res://other-systems/audio/"
const PULSE_FILE := {
	"fu_jin": "pulse-fu.ogg",
	"xian": "pulse-xian.ogg",
	"xi_shu": "pulse-xi.ogg",
}
const SETTLE_FILE := {
	"none": "settle-0.ogg",
	"slight": "settle-1.ogg",
	"work": "settle-2.ogg",
	"clear": "settle-3.ogg",
	"toward_heal": "settle-4.ogg",
}

var rain: AudioStreamPlayer
var bed: AudioStreamPlayer
var pulse_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var rain_linear := 0.32
var music_linear := 0.15
var sfx_linear := 0.8
var _ducked := false

func _ready() -> void:
	_read_volumes()
	rain = _make_loop("rain-clinic.ogg", "Ambient", rain_linear)
	bed = _make_loop("clinic-bed.ogg", "Music", music_linear)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)

func _read_volumes() -> void:
	if not Save or typeof(Save.data.get("audio")) != TYPE_DICTIONARY:
		return
	var a: Dictionary = Save.data["audio"]
	rain_linear = clampf(float(a.get("ambient", 0.32)), 0.0, 0.32)
	music_linear = clampf(float(a.get("music", 0.15)), 0.0, 0.18)
	sfx_linear = clampf(float(a.get("sfx", 0.8)), 0.0, 1.0)

func enter_clinic() -> void:
	_read_volumes()
	_set_linear(rain, rain_linear)
	if not _ducked:
		_set_linear(bed, music_linear)
	if rain and not rain.playing:
		rain.play()
	if bed and not bed.playing:
		bed.play()

func mute_boot() -> void:
	if rain:
		rain.stop()
	if bed:
		bed.stop()
	stop_pulse()

func duck_music() -> void:
	_ducked = true
	if bed:
		bed.volume_db = linear_to_db(0.02)

func unduck_music() -> void:
	_ducked = false
	_set_linear(bed, music_linear)

func play_one(stem: String) -> void:
	var stream: AudioStream = load(DIR + stem + ".ogg")
	if stream == null or sfx_player == null:
		return
	sfx_player.stream = stream
	_set_linear(sfx_player, sfx_linear)
	sfx_player.play()

func play_pulse_from_case() -> void:
	var pid := "fu_jin"
	if GameFlow and GameFlow.current_patient_id != "":
		pid = str(GameFlow.pulse_for_current().get("id", pid))
	play_pulse_id(pid)

func play_pulse_id(pulse_id: String) -> void:
	duck_music()
	var fname: String = PULSE_FILE.get(pulse_id, "pulse-fu.ogg")
	var stream: AudioStream = load(DIR + fname)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	if pulse_player == null:
		pulse_player = AudioStreamPlayer.new()
		pulse_player.bus = "SFX"
		add_child(pulse_player)
	pulse_player.stream = stream
	_set_linear(pulse_player, clampf(sfx_linear * 0.7, 0.0, 1.0))
	pulse_player.play()

func stop_pulse() -> void:
	if pulse_player:
		pulse_player.stop()
	unduck_music()

func play_settle(rank_id: String) -> void:
	stop_pulse()
	var fname: String = SETTLE_FILE.get(rank_id, "settle-0.ogg")
	var stem := fname.replace(".ogg", "")
	play_one(stem)
	# v1.19 slice SFX from music pack
	if rank_id in ["clear", "toward_heal", "work"]:
		play_one("stamp-ok")
	elif rank_id in ["none", "slight"]:
		play_one("ink-bleed")


func play_ui_ink() -> void:
	play_one("ui-ink")


func play_chime() -> void:
	play_one("chime")


func play_herb_wrong() -> void:
	play_one("herb-wrong")

func _make_loop(file_name: String, bus: String, linear: float) -> AudioStreamPlayer:
	var stream: AudioStream = load(DIR + file_name)
	var p := AudioStreamPlayer.new()
	p.bus = bus
	if stream != null:
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		p.stream = stream
	_set_linear(p, linear)
	add_child(p)
	return p

func _set_linear(p: AudioStreamPlayer, linear: float) -> void:
	if p == null:
		return
	var v := clampf(linear, 0.0001, 1.0)
	p.volume_db = linear_to_db(v)
