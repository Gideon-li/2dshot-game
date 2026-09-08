extends Control
## V124 炮制院 — STATION_WASH / STATION_FRY / DOOR_PHARMACY.

var _focus: String = ""
var _station: String = "STATION_WASH"
var _status: Label
var _cam_l: Label
var _stock_l: Label
var _teach_l: Label
var _warn_l: Label
var _herb_row: HFlowContainer
var _mini_host: Control
var _wash_hits: int = 0
var _wash_needed: int = 5
var _fry_heat: float = 0.45
var _fry_time: float = 0.0
var _fry_in_green: float = 0.0
var _fry_out: float = 0.0
var _fry_active: bool = false
var _fry_bar: ProgressBar
var _sun_prog: ProgressBar
var _sun_active: bool = false


func _herb_tex(hid: String, processed: bool = false) -> Texture2D:
	var tag := "processed" if processed else "raw"
	var path := "res://ui/herbs/process/%s_%s.png" % [hid, tag]
	if ResourceLoader.exists(path):
		return load(path)
	var alt_path := ""
	if hid == "fuzi":
		alt_path = "res://ui/herbs/process/zhifuzi.png" if processed else "res://ui/herbs/process/fuzi_raw.png"
	elif hid == "gancao":
		alt_path = "res://ui/herbs/process/zhigancao.png" if processed else "res://ui/herbs/process/gancao_raw.png"
	if alt_path != "" and ResourceLoader.exists(alt_path):
		return load(alt_path)
	if Forage and Forage.has_method("herb_texture"):
		return Forage.herb_texture(hid)
	var cab := "res://ui/herbs/%s.png" % hid
	if ResourceLoader.exists(cab):
		return load(cab)
	return null


func _herb_icon(hid: String, size: Vector2 = Vector2(40, 40)) -> Control:
	var processed := Process.processed_count(hid) > 0 and Process.raw_count(hid) <= 0
	# Prefer dedicated process sheet when present (xingren/baishao raw|processed).
	var tex := _herb_tex(hid, processed)
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = size
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return tr
	var sw := ColorRect.new()
	sw.custom_minimum_size = size
	sw.color = Color(0.72, 0.55, 0.32) if hid == "baishao" else Color(0.55, 0.45, 0.3)
	sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sw



func _ready() -> void:
	if AudioHub:
		AudioHub.enter_clinic()
	Process.ensure_teaching_raw()
	_build()
	GameFlow.locale_changed.connect(_refresh)
	_refresh()


func _process(delta: float) -> void:
	if _fry_active:
		_tick_fry(delta)
	if _sun_active and _sun_prog:
		_sun_prog.value = minf(100.0, _sun_prog.value + delta * 35.0)
		if _sun_prog.value >= 100.0:
			_sun_active = false
			_finish_process("ok")


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.86, 0.78, 0.62, 1)
	add_child(bg)
	var bg_path := ""
	if ResourceLoader.exists("res://ui/process/PROCESS_HERO.png"):
		bg_path = "res://ui/process/PROCESS_HERO.png"
	elif ResourceLoader.exists("res://ui/process/yard-bg-indoor.png"):
		bg_path = "res://ui/process/yard-bg-indoor.png"
	elif ResourceLoader.exists("res://ui/process/yard-bg.png"):
		bg_path = "res://ui/process/yard-bg.png"
	if bg_path != "":
		var art := TextureRect.new()
		art.texture = load(bg_path)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.modulate = Color(1, 1, 1, 0.9)
		add_child(art)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 28
	root.offset_right = -28
	root.offset_top = 16
	root.offset_bottom = -16
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var top := HBoxContainer.new()
	top.add_child(UiKit.ink_label(tr("PROCESS_TITLE"), 22))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.add_child(UiKit.locale_bar())
	_cam_l = UiKit.ink_label("CAM_PROCESS", 12, UiKit.INK_MUTED)
	top.add_child(_cam_l)
	var back := UiKit.make_button("PROCESS_EXIT", false)
	back.name = "DOOR_PHARMACY"
	back.pressed.connect(func() -> void: Process.leave_process())
	top.add_child(back)
	root.add_child(top)
	var who: String = CaseDB.mentor_name() if CaseDB else "苏问舟"
	if who == "":
		who = "苏问舟"
	root.add_child(UiKit.ink_label("%s：%s" % [who, Process.mentor_line(0)], 14, UiKit.SEAL))
	var xname := tr("XIAOHE_NAME")
	if xname == "" or xname == "XIAOHE_NAME":
		xname = "小荷"
	root.add_child(UiKit.ink_label("%s：%s" % [xname, Process.xiaohe_line(0)], 13, UiKit.INK_MUTED))
	root.add_child(UiKit.ink_label(tr("PROCESS_TIME_COST"), 12, UiKit.INK_MUTED))
	_stock_l = UiKit.ink_label("", 14)
	root.add_child(_stock_l)
	var stations := HBoxContainer.new()
	stations.add_theme_constant_override("separation", 10)
	root.add_child(stations)
	var wash_b := UiKit.make_button("PROCESS_STATION_WASH", true)
	wash_b.name = "STATION_WASH"
	wash_b.pressed.connect(_select_station.bind("STATION_WASH"))
	stations.add_child(wash_b)
	var fry_b := UiKit.make_button("PROCESS_STATION_FRY", true)
	fry_b.name = "STATION_FRY"
	fry_b.pressed.connect(_select_station.bind("STATION_FRY"))
	stations.add_child(fry_b)
	var sun_b := UiKit.make_button("PROCESS_STATION_SUN", false)
	sun_b.name = "STATION_DRY"
	sun_b.pressed.connect(_select_station.bind("STATION_DRY"))
	stations.add_child(sun_b)
	root.add_child(UiKit.ink_label(tr("PROCESS_PICK_HERB"), 13, UiKit.INK_MUTED))
	_herb_row = HFlowContainer.new()
	_herb_row.add_theme_constant_override("h_separation", 8)
	_herb_row.add_theme_constant_override("v_separation", 8)
	root.add_child(_herb_row)
	_teach_l = UiKit.ink_label("", 13, UiKit.SEAL)
	_teach_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_teach_l)
	_warn_l = UiKit.ink_label("", 12, Color(0.55, 0.2, 0.15))
	_warn_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_warn_l)
	_status = UiKit.ink_label("", 14, UiKit.SEAL)
	root.add_child(_status)
	if ResourceLoader.exists("res://ui/process/process-ui.png"):
		var chrome := TextureRect.new()
		chrome.texture = load("res://ui/process/process-ui.png")
		chrome.custom_minimum_size = Vector2(0, 120)
		chrome.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chrome.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chrome.modulate = Color(1, 1, 1, 0.85)
		root.add_child(chrome)
	_mini_host = VBoxContainer.new()
	_mini_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mini_host.add_theme_constant_override("separation", 8)
	root.add_child(_mini_host)
	var foot := UiKit.ink_label(tr("STORE_NOT_MEDICAL"), 12, UiKit.INK_MUTED)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(foot)
	_rebuild_herbs()
	_select_station("STATION_WASH")


func _refresh() -> void:
	UiKit.refresh_i18n_buttons(self)
	_refresh_stock()
	if _focus != "":
		_focus_herb(_focus)


func _refresh_stock() -> void:
	var bits: PackedStringArray = []
	for hid in Process.processable_ids():
		var raw := Process.raw_count(str(hid))
		var proc := Process.processed_count(str(hid))
		var name := CaseDB.herb_name(str(hid)) if CaseDB else str(hid)
		bits.append("%s 生%d/炮%d" % [name, raw, proc])
	_stock_l.text = " · ".join(bits) if bits.size() > 0 else "—"


func _rebuild_herbs() -> void:
	for c in _herb_row.get_children():
		c.queue_free()
	for hid in Process.processable_ids():
		var b := Button.new()
		b.custom_minimum_size = Vector2(170, 56)
		UiKit.style_button(b, false)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 6
		row.offset_right = -6
		b.add_child(row)
		var done := Process.processed_count(str(hid)) > 0
		row.add_child(_herb_icon(str(hid), Vector2(36, 36)))
		var name := CaseDB.herb_name(str(hid)) if CaseDB else str(hid)
		var tag := tr("PROCESS_DONE_TAG") if done else tr("PROCESS_RAW_TAG")
		var lab := UiKit.ink_label("%s · %s" % [name, tag], 13)
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lab)
		b.pressed.connect(_focus_herb.bind(str(hid)))
		_herb_row.add_child(b)


func _select_station(st: String) -> void:
	_station = st
	_fry_active = false
	_sun_active = false
	_clear_mini()
	match st:
		"STATION_WASH":
			_status.text = tr("PROCESS_WASH_HINT")
			if _cam_l:
				_cam_l.text = "CAM_WASH"
		"STATION_FRY":
			_status.text = tr("PROCESS_FRY_HINT")
			if _cam_l:
				_cam_l.text = "CAM_FRY"
		"STATION_DRY":
			_status.text = tr("PROCESS_SUN_HINT")
			if _cam_l:
				_cam_l.text = "CAM_DRY"
	if _focus != "":
		_start_minigame()


func _focus_herb(hid: String) -> void:
	_focus = hid
	_teach_l.text = Process.herb_teach_line(hid)
	_warn_l.text = Process.herb_warn_line(hid)
	var method := Process.process_method(hid)
	if method == "wash":
		_select_station("STATION_WASH")
	elif method == "stir_fry":
		_select_station("STATION_FRY")
	elif method == "sun_dry":
		_select_station("STATION_DRY")
	else:
		_start_minigame()


func _clear_mini() -> void:
	for c in _mini_host.get_children():
		c.queue_free()
	_fry_bar = null
	_sun_prog = null


func _start_minigame() -> void:
	if _focus == "":
		return
	_clear_mini()
	_fry_active = false
	_sun_active = false
	match _station:
		"STATION_WASH":
			_build_wash()
		"STATION_FRY":
			_build_fry()
		"STATION_DRY":
			_build_sun()


func _build_wash() -> void:
	_wash_hits = 0
	_wash_needed = 5
	_mini_host.add_child(UiKit.ink_label(tr("PROCESS_WASH_HINT"), 13, UiKit.INK_MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_mini_host.add_child(row)
	for i in _wash_needed:
		var b := Button.new()
		b.custom_minimum_size = Vector2(72, 72)
		UiKit.style_button(b, true)
		b.text = "洗"
		b.pressed.connect(_on_wash_hit.bind(b))
		row.add_child(b)
	var cancel := UiKit.make_button("PROCESS_CANCEL", false)
	cancel.pressed.connect(func() -> void:
		_focus = ""
		_clear_mini()
		_status.text = ""
	)
	_mini_host.add_child(cancel)


func _on_wash_hit(b: Button) -> void:
	b.disabled = true
	b.text = "✓"
	_wash_hits += 1
	if AudioHub:
		AudioHub.play_one("ui-ink")
	if _wash_hits >= _wash_needed:
		_finish_process("ok")
	else:
		_status.text = "%s (%d/%d)" % [tr("PROCESS_WASH_HINT"), _wash_hits, _wash_needed]


func _build_fry() -> void:
	_fry_heat = 0.42
	_fry_time = 0.0
	_fry_in_green = 0.0
	_fry_out = 0.0
	_fry_active = true
	_mini_host.add_child(UiKit.ink_label(tr("PROCESS_FRY_HINT"), 13, UiKit.INK_MUTED))
	_fry_bar = ProgressBar.new()
	_fry_bar.min_value = 0
	_fry_bar.max_value = 100
	_fry_bar.value = _fry_heat * 100.0
	_fry_bar.custom_minimum_size = Vector2(0, 28)
	_fry_bar.show_percentage = false
	_mini_host.add_child(_fry_bar)
	var zone := UiKit.ink_label("▓▓ 绿区 35–65 ▓▓", 12, Color(0.2, 0.45, 0.25))
	_mini_host.add_child(zone)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_mini_host.add_child(row)
	var cool := Button.new()
	cool.text = "← 弱火"
	cool.custom_minimum_size = Vector2(120, 44)
	UiKit.style_button(cool, false)
	cool.button_down.connect(func() -> void: _fry_heat = maxf(0.0, _fry_heat - 0.08))
	row.add_child(cool)
	var hot := Button.new()
	hot.text = "旺火 →"
	hot.custom_minimum_size = Vector2(120, 44)
	UiKit.style_button(hot, true)
	hot.button_down.connect(func() -> void: _fry_heat = minf(1.0, _fry_heat + 0.08))
	row.add_child(hot)
	var done := UiKit.make_button("PROCESS_START", true)
	done.text = tr("PROCESS_STATION_FRY") + " · 出锅"
	done.pressed.connect(_finish_fry)
	_mini_host.add_child(done)


func _tick_fry(delta: float) -> void:
	_fry_time += delta
	# Drift toward edges so player must correct.
	_fry_heat += sin(_fry_time * 1.7) * 0.012 + 0.004
	_fry_heat = clampf(_fry_heat, 0.0, 1.0)
	if _fry_bar:
		_fry_bar.value = _fry_heat * 100.0
		if _fry_heat >= 0.35 and _fry_heat <= 0.65:
			_fry_in_green += delta
			_fry_bar.modulate = Color(0.75, 1.0, 0.75)
		else:
			_fry_out += delta
			_fry_bar.modulate = Color(1.0, 0.75, 0.65)
			if _fry_heat > 0.65:
				_status.text = tr("PROCESS_FRY_HOT")
			else:
				_status.text = tr("PROCESS_FRY_COLD")
	if _fry_time >= 6.0:
		_finish_fry()


func _finish_fry() -> void:
	if not _fry_active and _fry_time <= 0.0:
		return
	_fry_active = false
	var grade := "ok"
	if _fry_out > _fry_in_green * 0.55 or _fry_heat < 0.3 or _fry_heat > 0.7:
		grade = "ok_ish"
		_status.text = tr("PROCESS_FRY_OKAY")
	else:
		_status.text = tr("PROCESS_FRY_OK")
	_finish_process(grade)


func _build_sun() -> void:
	_mini_host.add_child(UiKit.ink_label(tr("PROCESS_SUN_HINT"), 13, UiKit.INK_MUTED))
	_sun_prog = ProgressBar.new()
	_sun_prog.min_value = 0
	_sun_prog.max_value = 100
	_sun_prog.value = 0
	_sun_prog.custom_minimum_size = Vector2(0, 24)
	_mini_host.add_child(_sun_prog)
	var start := UiKit.make_button("PROCESS_START", true)
	start.pressed.connect(func() -> void:
		_sun_active = true
		_status.text = tr("PROCESS_SUN_HINT")
	)
	_mini_host.add_child(start)


func _finish_process(grade: String) -> void:
	if _focus == "":
		return
	var hid := _focus
	var res: Dictionary = Process.consume_raw_to_processed(hid, grade)
	_fry_active = false
	_sun_active = false
	if not bool(res.get("ok", false)):
		_status.text = tr("PROCESS_WASH_WEAK")
		return
	if AudioHub:
		AudioHub.play_one("stamp-ok")
	var qlabel := tr("PROCESS_QUALITY_GOOD") if grade == "ok" else tr("PROCESS_QUALITY_OK")
	_status.text = "%s · %s — %s" % [Process.herb_done_line(hid), qlabel, tr("PROCESS_DONE_HINT")]
	_refresh_stock()
	_rebuild_herbs()
	_clear_mini()
	_focus = ""
