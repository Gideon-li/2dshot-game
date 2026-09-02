extends Node2D
## Steam stills from playable clinic Camera2D nodes.
## Does not read secrets.env. On-screen copy never names a model, diagnosis, or formula.

const OUT_DIR := "res://ui/store"
const WORLD := Vector2(2560, 1440)
const SHOT := Vector2i(1920, 1080)
const CAM_NAMES: PackedStringArray = [
	"CAM_HERO", "CAM_ASK", "CAM_PULSE", "CAM_FORMULA", "CAM_NEEDLE", "CAM_RESULT"
]

var _clinic: Node2D
var _hud: CanvasLayer
var _art_layer: CanvasLayer
var _art: TextureRect
var _fx: TextureRect
var _hall: Sprite2D


func _ready() -> void:
	await _boot()
	await _shot_ask()
	print("CAPTURE_DONE dir=", ProjectSettings.globalize_path(OUT_DIR))
	get_tree().quit(0)


func _boot() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(SHOT)
	var win := get_tree().root
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	win.size = SHOT
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	TranslationServer.set_locale("zh")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_clinic = preload("res://scenes/clinic.tscn").instantiate()
	add_child(_clinic)
	await get_tree().process_frame
	await get_tree().process_frame
	_prep_clinic()
	_art_layer = CanvasLayer.new()
	_art_layer.layer = 30
	_art_layer.name = "StoreArt"
	add_child(_art_layer)
	_art = TextureRect.new()
	_art.name = "ShotArt"
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_layer.add_child(_art)
	_fx = TextureRect.new()
	_fx.name = "ShotFx"
	_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.visible = false
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	_fx.material = mat
	_art_layer.add_child(_fx)
	_hud = CanvasLayer.new()
	_hud.layer = 40
	_hud.name = "StoreHud"
	add_child(_hud)


func _prep_clinic() -> void:
	var ui := _clinic.get_node_or_null("UI")
	if ui:
		ui.visible = false
	for n in _clinic.find_children("*", "Label", true, false):
		if n.name in ["DeskTag", "CabTag", "NameTag", "ClinicHint", "ClinicFoot"]:
			(n as CanvasItem).visible = false
	var plaque := _clinic.get_node_or_null("L1_arch/Plaque") as Label
	if plaque:
		plaque.text = tr("GAME_TITLE")
	for cam_name in CAM_NAMES:
		var c := _clinic.get_node_or_null(cam_name) as Camera2D
		if c == null:
			continue
		c.position_smoothing_enabled = false
		c.limit_smoothed = false
		c.limit_left = -4096
		c.limit_top = -4096
		c.limit_right = 4096
		c.limit_bottom = 4096
		c.enabled = false
	# World hall so cameras are looking at the playable room, not empty polygons.
	_hall = Sprite2D.new()
	_hall.name = "HallArt"
	_hall.texture = load("res://ui/layers/CAM_HERO.png") as Texture2D
	_hall.centered = true
	_hall.position = Vector2(1280, 720)
	if _hall.texture:
		_hall.scale = Vector2(WORLD.x / float(_hall.texture.get_width()), WORLD.y / float(_hall.texture.get_height()))
	_hall.z_index = 3
	_clinic.add_child(_hall)
	var chars := _clinic.get_node_or_null("L5_characters")
	if chars:
		for poly in chars.find_children("*", "Polygon2D", true, false):
			(poly as CanvasItem).visible = false


func _set_tray(ids: Array) -> void:
	GameFlow.tray_herbs.clear()
	for id in ids:
		GameFlow.tray_herbs.append(str(id))


func _cam(name: String) -> Camera2D:
	for n in CAM_NAMES:
		var c := _clinic.get_node_or_null(n) as Camera2D
		if c == null:
			continue
		c.enabled = (n == name)
		if n == name:
			c.make_current()
	return _clinic.get_node_or_null(name) as Camera2D


func _show_art(path: String, fx_path: String = "") -> void:
	var tex := load(path) as Texture2D
	_art.texture = tex
	_art.visible = tex != null
	print("ART ", path, " loaded=", tex != null, " size=", tex.get_width() if tex else 0, "x", tex.get_height() if tex else 0)
	if fx_path == "":
		_fx.visible = false
		_fx.texture = null
		return
	var fx := load(fx_path) as Texture2D
	_fx.texture = fx
	_fx.visible = fx != null
	print("FX ", fx_path, " loaded=", fx != null)


func _clear_hud() -> void:
	for c in _hud.get_children():
		c.queue_free()
	_fx.visible = false
	await get_tree().process_frame


func _paper(pos: Vector2, size: Vector2, color: Color = Color(0.93, 0.9, 0.82, 0.94)) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", UiKit.paper_style(color, UiKit.LINE, 6))
	_hud.add_child(p)
	return p


func _label(text: String, size: int, color: Color, pos: Vector2, sz: Vector2, center: bool = false) -> Label:
	var l := UiKit.ink_label(text, size, color)
	l.position = pos
	l.size = sz
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.add_child(l)
	return l


func _patient_atlas(index: int) -> AtlasTexture:
	var sheet := load("res://ui/patients-three.png") as Texture2D
	var at := AtlasTexture.new()
	at.atlas = sheet
	if sheet:
		var w := sheet.get_width() / 3
		var h := sheet.get_height()
		at.region = Rect2(w * index, 0, w, h)
	return at

func _shot_ask() -> void:
	await _clear_hud()
	# One case only: 赵阿福 / 码头脚夫 / 江风扛货. Do not mix with 沈清荷.
	var pid := "char_porter"
	GameFlow.current_patient_id = pid
	GameFlow.fsm_state = "examining"
	GameFlow.mark_exam("wen_ask")
	var opening := CaseDB.opening_line(pid)
	if opening.strip_edges() == "":
		opening = GameFlow.wrap_inquiry_fallback(GameFlow.consume_inquiry_anchor())
	var card := CaseDB.hud_card(pid)
	var cam := _cam("CAM_ASK")
	_art.texture = _patient_atlas(0)
	_art.visible = _art.texture != null
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fx.visible = false
	var x := 48.0
	for pair in [["望", false], ["闻", false], ["问", true], ["切", false]]:
		_paper(Vector2(x, 36), Vector2(76, 76), Color(0.55, 0.18, 0.16, 0.18) if pair[1] else Color(0.93, 0.9, 0.82, 0.9))
		_label(str(pair[0]), 28, UiKit.SEAL if pair[1] else UiKit.INK, Vector2(x + 18, 52), Vector2(48, 48), true)
		x += 88.0
	_paper(Vector2(1120, 36), Vector2(760, 210))
	_label("问", 22, UiKit.SEAL, Vector2(1140, 50), Vector2(64, 36))
	_label("%s · %s" % [str(card.get("name", "")), str(card.get("identity", ""))], 18, UiKit.INK_MUTED, Vector2(1210, 52), Vector2(640, 32))
	_label(opening, 22, UiKit.INK, Vector2(1140, 96), Vector2(720, 130))
	await _dump("CAM_ASK.png", cam)


func _shot_formula() -> void:
	await _clear_hud()
	GameFlow.current_patient_id = "char_porter"
	GameFlow.fsm_state = "formula_crafting"
	_set_tray(["mahuang", "guizhi", "xingren", "gancao"])
	var cam := _cam("CAM_FORMULA")
	_show_art("res://ui/formula-tray.png")
	# Cover baked formula title on the mockup. Herb names on the plate are OK.
	_paper(Vector2(0, 0), Vector2(1920, 132), Color(0.93, 0.9, 0.82, 0.97))
	_label("药柜 · 方盘", 28, UiKit.INK, Vector2(48, 20), Vector2(520, 44))
	_label(tr("TREAT_FORMULA_HINT"), 16, UiKit.INK_MUTED, Vector2(48, 72), Vector2(1400, 44))
	_paper(Vector2(1660, 24), Vector2(220, 64), Color(0.55, 0.18, 0.16, 0.14))
	_label("下手", 24, UiKit.SEAL, Vector2(1710, 36), Vector2(140, 40), true)
	# Cover bottom-right decoct/formula-name control if the mockup drew one.
	_paper(Vector2(1540, 900), Vector2(360, 160), Color(0.93, 0.9, 0.82, 0.0))
	var ids: PackedStringArray = ["mahuang", "guizhi", "xingren", "gancao"]
	var origin := Vector2(700, 390)
	for i in ids.size():
		var id := ids[i]
		var pos := origin + Vector2((i % 2) * 260, int(i / 2) * 100)
		_paper(pos, Vector2(230, 80), UiKit.nature_ink(str(CaseDB.herb(id).get("nature", "neutral"))).lerp(UiKit.PAPER, 0.78))
		_label(CaseDB.herb_name(id), 24, UiKit.INK, pos + Vector2(16, 22), Vector2(198, 40), true)
	_label(tr("FORMULA_COUNT").format({"n": 4}), 18, UiKit.INK, Vector2(820, 990), Vector2(280, 36), true)
	await _dump("04-CAM_FORMULA.png", cam)


func _shot_result() -> void:
	await _clear_hud()
	GameFlow.current_patient_id = "char_porter"
	GameFlow.exams = {"wang": true, "wen_listen": true, "wen_ask": true, "qie": true}
	GameFlow.completed_exams.clear()
	for e in ["wang", "wen_listen", "wen_ask", "qie"]:
		GameFlow.completed_exams.append(e)
	GameFlow.fsm_state = "formula_crafting"
	_set_tray(["mahuang", "guizhi", "xingren", "gancao"])
	var raw: Dictionary = GameFlow.confirm_formula()
	var cam := _cam("CAM_RESULT")
	_show_art("res://ui/layers/L4-props.png")
	var rank := ""
	var rank_v: Variant = raw.get("rank", {})
	if typeof(rank_v) == TYPE_DICTIONARY:
		rank = GameFlow.loc_text(rank_v)
	if rank.strip_edges() == "":
		rank = tr("SCORE_WORK")
	_paper(Vector2(660, 48), Vector2(600, 168), Color(0.93, 0.9, 0.82, 0.92))
	_label(tr("SCORE_TITLE"), 18, UiKit.INK_MUTED, Vector2(760, 64), Vector2(400, 32), true)
	_label(rank, 52, UiKit.SEAL, Vector2(760, 100), Vector2(400, 72), true)
	_label(tr("BOOT_DISCLAIMER_FOOTER"), 14, UiKit.INK_MUTED, Vector2(660, 1010), Vector2(600, 28), true)
	await _dump("05-CAM_RESULT.png", cam)


func _shot_pulse() -> void:
	await _clear_hud()
	GameFlow.current_patient_id = "char_porter"
	GameFlow.mark_exam("qie")
	var cam := _cam("CAM_PULSE")
	_show_art("res://ui/layers/CAM_PULSE-empty.png", "res://ui/layers/pulse-overlay.png")
	_label(tr("EXAM_PULSE"), 28, UiKit.SEAL, Vector2(760, 24), Vector2(400, 44), true)
	_label("%s · %s · %s" % [tr("PULSE_CUN"), tr("PULSE_GUAN"), tr("PULSE_CHI")], 16, UiKit.INK_MUTED, Vector2(760, 1016), Vector2(400, 28), true)
	await _dump("03-CAM_PULSE.png", cam)


func _dump(filename: String, cam: Camera2D) -> void:
	if cam:
		cam.reset_smoothing()
		cam.force_update_scroll()
	for _i in 6:
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
	var tex := get_viewport().get_texture()
	if tex == null:
		push_error("no viewport texture for " + filename)
		return
	var img := tex.get_image()
	if img == null:
		push_error("no image for " + filename)
		return
	if img.get_width() != SHOT.x or img.get_height() != SHOT.y:
		img.resize(SHOT.x, SHOT.y, Image.INTERPOLATE_LANCZOS)
	var abs_path := ProjectSettings.globalize_path("%s/%s" % [OUT_DIR, filename])
	var err := img.save_png(abs_path)
	print("CAPTURE %s cam=%s size=%dx%d luma=%.3f err=%s path=%s" % [
		filename,
		cam.name if cam else "none",
		img.get_width(),
		img.get_height(),
		_mean_luma(img),
		str(err),
		abs_path
	])


func _mean_luma(img: Image) -> float:
	var acc := 0.0
	var n := 0
	var step := maxi(1, img.get_width() / 64)
	for y in range(0, img.get_height(), step):
		for x in range(0, img.get_width(), step):
			var c := img.get_pixel(x, y)
			acc += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			n += 1
	return acc / float(maxi(n, 1))
