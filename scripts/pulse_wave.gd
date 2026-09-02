class_name PulseWave
extends Control
## Screenshot-worthy pulse: animated wave + 浮沉迟数 gauges. Not a text dump.

var depth := 0.15
var amplitude := 0.85
var tension := 0.9
var width := 0.45
var smoothness := 0.2
var rate_bpm := 68.0
var _t := 0.0
var draw_stage := true


func apply_pulse(pulse: Dictionary) -> void:
	rate_bpm = float(pulse.get("rate_bpm", 72))
	var vis: Dictionary = pulse.get("visual", {})
	depth = float(vis.get("depth", 0.4))
	amplitude = float(vis.get("amplitude", 0.6))
	tension = float(vis.get("tension", 0.5))
	width = float(vis.get("width", 0.4))
	smoothness = float(vis.get("smoothness", 0.3))
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(640, 220)


func _process(delta: float) -> void:
	_t += delta * (rate_bpm / 60.0) * TAU
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 8.0 or h < 8.0:
		return
	if draw_stage:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.93, 0.9, 0.82, 0.0))
		var wrist := Rect2(w * 0.06, h * 0.42, w * 0.88, h * 0.46)
		draw_rect(wrist, Color(0.78, 0.7, 0.62, 0.15), true)
		for i in 3:
			var fx := w * (0.28 + i * 0.16)
			draw_circle(Vector2(fx, h * 0.40), 16.0, Color(0.72, 0.62, 0.54, 0.55))
	var n := 160
	var pts := PackedVector2Array()
	var baseline := h * (0.38 + depth * 0.28)
	var amp := amplitude * h * 0.28
	var line_w := 1.5 + width * 5.0
	var cycles := 1.6 + (1.0 - width) * 2.2
	for i in n:
		var u := float(i) / float(n - 1)
		var x := w * 0.08 + u * w * 0.84
		var phase := u * TAU * cycles - _t
		var sharp := 1.0 + tension * 4.0
		var beat := pow(abs(sin(phase)), sharp)
		if smoothness > 0.0:
			beat = lerp(beat, (sin(phase) + 1.0) * 0.5, smoothness)
		# Tight pulse: triangular; wiry: long plateau via tension
		if tension > 0.75:
			beat = pow(beat, 0.65)
		var y := baseline - beat * amp
		pts.append(Vector2(x, y))
	if pts.size() >= 2:
		draw_polyline(pts, Color(0.28, 0.12, 0.12, 0.92), line_w, true)
		draw_polyline(pts, Color(0.16, 0.1, 0.1, 0.35), maxf(1.0, line_w - 1.2), true)
	# Paper grain ticks
	draw_line(Vector2(w * 0.08, h * 0.18), Vector2(w * 0.92, h * 0.18), Color(0.2, 0.18, 0.15, 0.25), 1.0)
