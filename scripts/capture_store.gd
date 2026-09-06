extends Node2D
## One-shot Steam stills into ui/store/. Uses clinic Camera2Ds. No secrets.env.

const OUT_DIR := "res://ui/store"
const CAMS := ["CAM_HERO", "CAM_ASK", "CAM_PULSE", "CAM_FORMULA", "CAM_NEEDLE", "CAM_RESULT"]
const STORE_W := 1920
const STORE_H := 1080
const DESIGN_W := 1280.0

var _sv: SubViewport
var _clinic: Node2D
var _hud: CanvasLayer
var _extras: Node2D


func _ready() -> void:
	TranslationServer.set_locale("zh")
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	get_window().size = Vector2i(STORE_W, STORE_H)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_sv = SubViewport.new()
	_sv.name = "ShotVP"
	_sv.size = Vector2i(STORE_W, STORE_H)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sv.transparent_bg = false
	_sv.handle_input_locally = false
	add_child(_sv)
	_clinic = (load("res://scenes/clinic.tscn") as PackedScene).instantiate()
	_clinic.set_script(null)
	_sv.add_child(_clinic)
	_hide_play_chrome()
	_scale_cameras()
	_hud = CanvasLayer.new()
	_hud.layer = 20
	_hud.name = "StoreHud"
	_sv.add_child(_hud)
	_extras = Node2D.new()
	_extras.name = "StoreExtras"
	_extras.z_index = 9
	_clinic.add_child(_extras)
	await _warm()
	# Keep existing CAM_ASK.png (赵阿福 matching). Recapture formula/needle/result only.
	await _capture_formula()
	await _capture_needle()
	await _capture_result()
	print("STORE_CAPTURE_DONE")
	get_tree().quit(0)


func _warm() -> void:
	for _i in 16:
		await get_tree().process_frame
		await RenderingServer.frame_post_draw


func _hide_play_chrome() -> void:
	var ui := _clinic.get_node_or_null("UI")
	if ui:
		ui.visible = false
	var ap := _clinic.get_node_or_null("L5_characters/Apprentice")
	if ap:
		ap.visible = false
	for n in CAMS:
		var cam := _clinic.get_node_or_null(n) as Camera2D
		if cam == null:
			continue
		cam.position_smoothing_enabled = false
		cam.limit_smoothed = false


func _scale_cameras() -> void:
	var k := float(STORE_W) / DESIGN_W
	for n in CAMS:
		var cam := _clinic.get_node_or_null(n) as Camera2D
		if cam:
			cam.zoom *= k


func _switch(cam_name: String) -> void:
	for n in CAMS:
		var cam := _clinic.get_node_or_null(n) as Camera2D
		if cam == null:
			continue
		if n == cam_name:
			cam.enabled = true
			cam.make_current()
		else:
			cam.enabled = false


func _patients(on: bool) -> void:
	var p := _clinic.get_node_or_null("L5_characters/Patients")
	if p:
		p.visible = on
	var group := _clinic.get_node_or_null("L5_characters")
	if group == null:
		return
	for c in group.get_children():
		if str(c.name).begins_with("Patient"):
			c.visible = on


func _clear_hud() -> void:
	for c in _hud.get_children():
		c.queue_free()
	for c in _extras.get_children():
		c.queue_free()
	await get_tree().process_frame


func _paper_panel(pos: Vector2, size: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = size
	p.add_theme_stylebox_override("panel", UiKit.paper_style(UiKit.PAPER, UiKit.LINE, 6))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(p)
	return p


func _capture_ask() -> void:
	await _clear_hud()
	_patients(true)
	_switch("CAM_ASK")
	var pid := "char_porter"
	var character := CaseDB.patient_by_id(pid)
	var case_data := CaseDB.case_for_patient(pid)
	var q := tr("SUGGEST_SLEEP") if TranslationServer.get_translation_object("zh") else "夜里睡得怎么样？"
	if q == "SUGGEST_SLEEP" or q.is_empty():
		q = "夜里睡得怎么样？"
	var a := QwenClient.template_reply(q, character, case_data)
	a = QwenClient.strip_never_say(a, case_data)
	var opening := CaseDB.opening_line(pid)
	var card := _paper_panel(Vector2(1180, 36), Vector2(700, 260))
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 16
	col.offset_right = -16
	col.offset_top = 12
	col.offset_bottom = -12
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var who := UiKit.ink_label(CaseDB.hud_line(pid), 13, UiKit.INK_MUTED)
	col.add_child(who)
	if opening != "":
		col.add_child(UiKit.ink_label(opening, 16, UiKit.INK))
	col.add_child(UiKit.ink_label("▸ " + q, 15, UiKit.SEAL))
	col.add_child(UiKit.ink_label(a, 16, UiKit.INK))
	await _snap("CAM_ASK.png")


func _capture_formula() -> void:
	await _clear_hud()
	_patients(false)
	_switch("CAM_FORMULA")
	_spawn_open_drawers()
	_spawn_tray_herbs()
	var tag := _paper_panel(Vector2(24, 24), Vector2(280, 56))
	var lb := UiKit.ink_label(tr("ACTION_PRESCRIBE"), 20)
	lb.position = Vector2(16, 12)
	lb.size = Vector2(248, 32)
	tag.add_child(lb)
	await _snap("CAM_FORMULA.png")


func _capture_needle() -> void:
	await _clear_hud()
	_patients(false)
	_switch("CAM_NEEDLE")
	_spawn_bed_body()
	var tag := _paper_panel(Vector2(24, 24), Vector2(280, 56))
	var lb := UiKit.ink_label(tr("ACTION_NEEDLE"), 20)
	lb.position = Vector2(16, 12)
	lb.size = Vector2(248, 32)
	tag.add_child(lb)
	await _snap("CAM_NEEDLE.png")


func _capture_result() -> void:
	await _clear_hud()
	_patients(false)
	_switch("CAM_RESULT")
	var card := _paper_panel(Vector2(560, 80), Vector2(800, 420))
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 28
	col.offset_right = -28
	col.offset_top = 20
	col.offset_bottom = -20
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	col.add_child(UiKit.ink_label(tr("SCORE_TITLE"), 16, UiKit.INK_MUTED))
	var rank := UiKit.ink_label("显效", 52, UiKit.SEAL)
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(rank)
	var flav := UiKit.ink_label("寒从体表散开，人松下来了。", 18)
	flav.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(flav)
	col.add_child(UiKit.ink_label("%s  82" % tr("SCORE_EFFICACY"), 16))
	col.add_child(UiKit.ink_label("%s  %s" % [tr("SCORE_SPEED"), "稳"], 16))
	var foot := UiKit.ink_label(tr("BOOT_DISCLAIMER_FOOTER"), 13, UiKit.INK_MUTED)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(foot)
	await _snap("CAM_RESULT.png")


func _spawn_open_drawers() -> void:
	var origin := Vector2(1752, 680)
	var cell := Vector2(72, 56)
	var herbs: Array = CaseDB.pack.get("herbs", [])
	for row in [2, 3]:
		for col in 6:
			var row_i: int = int(row)
			var idx: int = row_i * 8 + col
			var pos := origin + Vector2(col * cell.x + cell.x * 0.5, row_i * cell.y + cell.y * 0.5 + 28)
			var face := Polygon2D.new()
			face.position = pos
			var hw := cell.x * 0.5 - 4.0
			var hh := cell.y * 0.5 - 4.0
			face.polygon = PackedVector2Array([Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)])
			face.color = Color(0.22, 0.18, 0.14, 0.72)
			_extras.add_child(face)
			var pile := Polygon2D.new()
			pile.position = pos + Vector2(0, 8)
			pile.polygon = PackedVector2Array([Vector2(-14, -6), Vector2(14, -6), Vector2(10, 8), Vector2(-10, 8)])
			var tint := Color(0.45, 0.32, 0.22, 0.9)
			if idx < herbs.size() and typeof(herbs[idx]) == TYPE_DICTIONARY:
				var nat := str(herbs[idx].get("nature", "neutral"))
				if nat == "warm" or nat == "hot":
					tint = Color(0.55, 0.28, 0.18, 0.9)
				elif nat == "cool" or nat == "cold":
					tint = Color(0.32, 0.42, 0.38, 0.9)
			pile.color = tint
			_extras.add_child(pile)
			if idx < herbs.size() and typeof(herbs[idx]) == TYPE_DICTIONARY:
				var lb := Label.new()
				lb.position = pos + Vector2(-30, -10)
				lb.size = Vector2(60, 18)
				lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lb.add_theme_color_override("font_color", Color(0.93, 0.9, 0.82, 0.95))
				UiKit.apply_font(lb, 11)
				lb.text = CaseDB.named_herb(herbs[idx])
				lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_extras.add_child(lb)


func _spawn_tray_herbs() -> void:
	var ids: Array = ["mahuang", "guizhi", "xingren", "gancao"]
	var base := Vector2(1860, 900)
	for i in ids.size():
		var id := str(ids[i])
		var p := base + Vector2((i % 2) * 70.0, floor(i / 2.0) * 48.0)
		var chip := Polygon2D.new()
		chip.position = p
		chip.polygon = PackedVector2Array([Vector2(-28, -16), Vector2(28, -16), Vector2(28, 16), Vector2(-28, 16)])
		chip.color = Color(0.78, 0.72, 0.58, 0.92)
		_extras.add_child(chip)
		var lb := Label.new()
		lb.position = p + Vector2(-28, -12)
		lb.size = Vector2(56, 24)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.add_theme_color_override("font_color", UiKit.INK)
		UiKit.apply_font(lb, 13)
		lb.text = CaseDB.herb_name(id)
		lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_extras.add_child(lb)
	var drag := Polygon2D.new()
	drag.position = Vector2(1780, 860)
	drag.polygon = PackedVector2Array([Vector2(-16, -10), Vector2(16, -10), Vector2(16, 10), Vector2(-16, 10)])
	drag.color = Color(0.45, 0.28, 0.18, 0.9)
	_extras.add_child(drag)


func _spawn_bed_body() -> void:
	var bed := Rect2(320, 820, 420, 160)
	var sil := Polygon2D.new()
	sil.color = Color(0.28, 0.24, 0.2, 0.72)
	sil.polygon = PackedVector2Array([
		Vector2(bed.position.x + 40, bed.position.y + 90),
		Vector2(bed.position.x + 90, bed.position.y + 40),
		Vector2(bed.position.x + 200, bed.position.y + 28),
		Vector2(bed.position.x + 340, bed.position.y + 50),
		Vector2(bed.position.x + 390, bed.position.y + 100),
		Vector2(bed.position.x + 300, bed.position.y + 140),
		Vector2(bed.position.x + 80, bed.position.y + 140),
	])
	_extras.add_child(sil)
	var selected: Array = ["fengchi", "hegu", "lieque"]
	var norm := {
		"fengchi": Vector2(0.50, 0.10),
		"dazhui": Vector2(0.50, 0.18),
		"qimen": Vector2(0.28, 0.32),
		"neiguan": Vector2(0.16, 0.38),
		"lieque": Vector2(0.14, 0.42),
		"hegu": Vector2(0.08, 0.46),
		"quchi": Vector2(0.20, 0.34),
		"shenshu": Vector2(0.50, 0.44),
		"mingmen": Vector2(0.50, 0.50),
		"zusanli": Vector2(0.38, 0.72),
		"yanglingquan": Vector2(0.62, 0.70),
		"sanyinjiao": Vector2(0.38, 0.82),
		"taixi": Vector2(0.36, 0.90),
		"zhaohai": Vector2(0.64, 0.90),
		"taichong": Vector2(0.38, 0.97),
		"yongquan": Vector2(0.62, 0.97),
	}
	for raw in CaseDB.pack.get("acupoints", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var id := str(raw.get("id", ""))
		var uv: Vector2 = norm.get(id, Vector2(0.5, 0.5))
		var pos := bed.position + Vector2(uv.x * bed.size.x, uv.y * bed.size.y)
		var dot := Polygon2D.new()
		dot.position = pos
		dot.polygon = PackedVector2Array([Vector2(-7, 0), Vector2(0, -7), Vector2(7, 0), Vector2(0, 7)])
		if id in selected:
			dot.color = Color(0.55, 0.18, 0.16, 0.95)
		else:
			dot.color = Color(0.93, 0.9, 0.82, 0.92)
		_extras.add_child(dot)


func _snap(filename: String) -> void:
	for _i in 6:
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
	var img := _sv.get_texture().get_image()
	var path := OUT_DIR.path_join(filename)
	var err := img.save_png(path)
	var abs_path := ProjectSettings.globalize_path(path)
	print("SNAP %s %dx%d err=%d -> %s" % [filename, img.get_width(), img.get_height(), err, abs_path])
