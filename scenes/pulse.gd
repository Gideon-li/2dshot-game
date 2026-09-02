extends Control
## Steam-screenshot pulse. Lines come ONLY from pulse-overlay.png atlas
## (left 浮紧 / center 弦 / right 细数). Background is CAM_PULSE-empty.

signal finished

const OVERLAY := preload("res://ui/layers/pulse-overlay.png")
const PULSE_ATLAS := {
	"fu_jin": Rect2(0, 180, 512, 660),
	"xian": Rect2(512, 180, 512, 660),
	"xi_shu": Rect2(1024, 180, 512, 660),
}

var _wave: PulseWave
var _applied := false


func _ready() -> void:
	$Caption.text = tr("EXAM_PULSE")
	if has_node("Wave"):
		$Wave.color = Color(0.45, 0.18, 0.16, 0.0)
		$Wave.visible = false
	if has_node("Wrist"):
		$Wrist.visible = false
	_wave = PulseWave.new()
	_wave.name = "Waveform"
	_wave.draw_stage = false
	_wave.visible = false
	_wave.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wave.offset_left = 0
	_wave.offset_top = 0
	_wave.offset_right = 0
	_wave.offset_bottom = 0
	$Wrist.add_child(_wave)
	_add_fingers()
	_add_gauges()
	_add_close()
	if not _applied:
		var p: Dictionary = {}
		if Engine.has_singleton("GameFlow") or true:
			if GameFlow.current_patient_id != "":
				p = GameFlow.pulse_for_current()
			elif GameFlow.cases_by_id.has("fenghan_biao"):
				p = GameFlow.cases_by_id["fenghan_biao"].get("pulse", {})
		if not p.is_empty():
			apply_pulse(p)


func apply_pulse(pulse: Dictionary) -> void:
	AudioHub.play_pulse_id(str(pulse.get("id", "fu_jin")))
	_applied = true
	if _wave == null:
		await ready
	_wave.apply_pulse(pulse)
	_wave.visible = false
	$Caption.text = tr("EXAM_PULSE")
	_show_overlay(str(pulse.get("id", "fu_jin")))
	var felt := UiKit.loc_text(pulse, "")
	if has_node("Quality"):
		$Quality.text = felt
	elif felt != "":
		var q := Label.new()
		q.name = "Quality"
		q.text = felt
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.add_theme_color_override("font_color", Color(0.45, 0.18, 0.16, 1))
		q.add_theme_font_size_override("font_size", 22)
		q.set_anchors_preset(Control.PRESET_CENTER_TOP)
		q.offset_left = -200
		q.offset_right = 200
		q.offset_top = 78
		q.offset_bottom = 114
		add_child(q)
	if has_node("RateHint"):
		var bpm := int(pulse.get("rate_bpm", 0))
		$RateHint.text = "" if bpm <= 0 else "·"


func apply_from_case(pulse: Dictionary) -> void:
	apply_pulse(pulse)


func _show_overlay(pulse_id: String) -> void:
	if not has_node("PulseLine"):
		return
	var tr := $PulseLine as TextureRect
	var at := AtlasTexture.new()
	at.atlas = OVERLAY
	at.region = PULSE_ATLAS.get(pulse_id, PULSE_ATLAS["fu_jin"])
	tr.texture = at
	tr.visible = true


func _add_fingers() -> void:
	var labels := ["寸", "关", "尺"]
	for i in 3:
		var pad := ColorRect.new()
		pad.color = Color(0.72, 0.62, 0.54, 0.85)
		pad.size = Vector2(52, 36)
		pad.position = Vector2(140 + i * 120, -18)
		pad.visible = false
		$Wrist.add_child(pad)
		var lb := Label.new()
		lb.text = labels[i]
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.add_theme_color_override("font_color", Color(0.16, 0.14, 0.12, 0.8))
		lb.add_theme_font_size_override("font_size", 14)
		pad.add_child(lb)
		lb.set_anchors_preset(Control.PRESET_FULL_RECT)


func _add_close() -> void:
	if has_node("CloseBtn"):
		$CloseBtn.pressed.connect(_on_close)
		$CloseBtn.text = tr("UI_PULSE_CLOSE")
		return
	var b := Button.new()
	b.name = "CloseBtn"
	b.text = tr("UI_PULSE_CLOSE")
	b.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	b.offset_left = -90
	b.offset_right = 90
	b.offset_top = -88
	b.offset_bottom = -44
	add_child(b)
	b.pressed.connect(_on_close)


func _on_close() -> void:
	AudioHub.stop_pulse()
	finished.emit()
	if get_parent() == get_tree().root:
		get_tree().change_scene_to_file("res://scenes/clinic.tscn")
	else:
		visible = false


func _add_gauges() -> void:
	var row := HBoxContainer.new()
	row.name = "Gauges"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_left = -420
	row.offset_right = 420
	row.offset_top = -140
	row.offset_bottom = -100
	row.add_theme_constant_override("separation", 28)
	add_child(row)
	for pair in [["PULSE_FLOAT", "PULSE_SINK"], ["PULSE_SLOW", "PULSE_RAPID"], ["PULSE_VACUOUS", "PULSE_TENSE"]]:
		var l := Label.new()
		l.text = "%s · %s" % [tr(pair[0]), tr(pair[1])]
		l.add_theme_color_override("font_color", Color(0.16, 0.14, 0.12, 1))
		l.add_theme_font_size_override("font_size", 16)
		l.set_meta("gauge_pair", pair)
		row.add_child(l)
