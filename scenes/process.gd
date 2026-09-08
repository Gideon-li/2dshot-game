extends Control
## V128 炮制院 — STATION_WASH / STATION_FRY / STATION_DRY + CAM_*.

var _focus: String = ""
var _station: String = "STATION_WASH"
var _status: Label
var _cam_l: Label
var _stock_l: Label
var _teach_l: Label
var _warn_l: Label
var _herb_row: HFlowContainer
var _mini_host: Control
var _yard_art: TextureRect
var _station_btns: Dictionary = {}
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
var _sun_flips: int = 0
var _sun_over: float = 0.0
var _sun_flip_l: Label
var _sun_finish_btn: Button


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
	elif hid == "mudanpi" and not processed:
		alt_path = "res://ui/herbs/mudanpi.png"
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
	match hid:
		"baishao":
			sw.color = Color(0.72, 0.55, 0.32)
		"mudanpi":
			sw.color = Color(0.62, 0.38, 0.42)
		_:
			sw.color = Color(0.55, 0.45, 0.3)
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
		_tick_sun(delta)


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.86, 0.78, 0.62, 1)
	add_child(bg)
	_yard_art = TextureRect.new()
	_yard_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_yard_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_yard_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_yard_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_yard_art.modulate = Color(1, 1, 1, 0.9)
	add_child(_yard_art)
	_apply_yard_bg("STATION_WASH")
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
	_station_btns["STATION_WASH"] = wash_b
	var fry_b := UiKit.make_button("PROCESS_STATION_FRY", true)
	fry_b.name = "STATION_FRY"
	fry_b.pressed.connect(_select_station.bind("STATION_FRY"))
	stations.add_child(fry_b)
	_station_btns["STATION_FRY"] = fry_b
	var sun_b := UiKit.make_button("PROCESS_STATION_SUN", true)
	sun_b.name = "STATION_DRY"
	sun_b.disabled = false
	sun_b.pressed.connect(_select_station.bind("STATION_DRY"))
	stations.add_child(sun_b)
	_station_btns["STATION_DRY"] = sun_b
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


func _apply_yard_bg(st: String) -> void:
	if _yard_art == null:
		return
	var path := ""
	if st == "STATION_DRY":
		if ResourceLoader.exists("res://ui/process/CAM_DRY.png"):
			path = "res://ui/process/CAM_DRY.png"
		elif ResourceLoader.exists("res://ui/process/yard-bg-outdoor.png"):
			path = "res://ui/process/yard-bg-outdoor.png"
	if path == "":
		if ResourceLoader.exists("res://ui/process/PROCESS_HERO.png"):
			path = "res://ui/process/PROCESS_HERO.png"
		elif ResourceLoader.exists("res://ui/process/yard-bg-indoor.png"):
			path = "res://ui/process/yard-bg-indoor.png"
		elif ResourceLoader.exists("res://ui/process/yard-bg-outdoor.png"):
			path = "res://ui/process/yard-bg-outdoor.png"
	if path != "":
		_yard_art.texture = load(path)
		_yard_art.modulate = Color(1, 1, 1, 0.92 if st == "STATION_DRY" else 0.9)
	else:
		_yard_art.texture = null


func _highlight_stations() -> void:
	for sid in _station_btns.keys():
		var b: Button = _station_btns[sid]
		var active := str(sid) == _station
		UiKit.style_button(b, active)
		b.disabled = false
		if active:
			b.modulate = Color(1.05, 1.0, 0.92, 1)
		else:
			b.modulate = Color(1, 1, 1, 1)
		var glow := b.get_node_or_null("StationGlow") as TextureRect
		if active and ResourceLoader.exists("res://ui/process/station-highlight.png"):
			if glow == null:
				glow = TextureRect.new()
				glow.name = "StationGlow"
				glow.texture = load("res://ui/process/station-highlight.png")
				glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				glow.stretch_mode = TextureRect.STRETCH_SCALE
				glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
				glow.modulate = Color(1, 1, 1, 0.55)
				b.add_child(glow)
				b.move_child(glow, 0)
			glow.visible = true
		elif glow:
			glow.visible = false


func _refresh() -> void:
	UiKit.refresh_i18n_buttons(self)
	_refresh_stock()
	_highlight_stations()
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
	_apply_yard_bg(st)
	_highlight_stations()
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
			var ready := tr("PROCESS_STATION_SUN_READY")
			_status.text = ready if ready != "PROCESS_STATION_SUN_READY" else tr("PROCESS_SUN_HINT")
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
	_sun_flip_l = null
	_sun_finish_btn = null


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
		_status.text = tr("PROCESS_WASH_RETRY") if tr("PROCESS_WASH_RETRY") != "PROCESS_WASH_RETRY" else tr("PROCESS_RETRY")
		if _cam_l:
			_cam_l.text = "CAM_PROCESS"
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
	var cancel := UiKit.make_button("PROCESS_CANCEL", false)
	cancel.pressed.connect(func() -> void:
		_fry_active = false
		_focus = ""
		_clear_mini()
		_status.text = tr("PROCESS_FRY_RETRY") if tr("PROCESS_FRY_RETRY") != "PROCESS_FRY_RETRY" else tr("PROCESS_RETRY")
		if _cam_l:
			_cam_l.text = "CAM_PROCESS"
	)
	_mini_host.add_child(cancel)


func _tick_fry(delta: float) -> void:
	_fry_time += delta
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
		_status.text = "%s · %s" % [tr("PROCESS_FRY_OKAY"), tr("PROCESS_FRY_RETRY")]
	else:
		_status.text = tr("PROCESS_FRY_OK")
	_finish_process(grade)


func _build_sun() -> void:
	_sun_flips = 0
	_sun_over = 0.0
	_sun_active = true
	if ResourceLoader.exists("res://ui/process/sun-flip-ui.png"):
		var flip_art := TextureRect.new()
		flip_art.texture = load("res://ui/process/sun-flip-ui.png")
		flip_art.custom_minimum_size = Vector2(0, 96)
		flip_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flip_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flip_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mini_host.add_child(flip_art)
	_mini_host.add_child(UiKit.ink_label(tr("PROCESS_SUN_HINT"), 13, UiKit.INK_MUTED))
	var mentor_sun := tr("MENTOR_PROCESS_SUN")
	if mentor_sun != "MENTOR_PROCESS_SUN":
		_mini_host.add_child(UiKit.ink_label(mentor_sun, 12, UiKit.SEAL))
	var xh_sun := tr("XIAOHE_PROCESS_SUN")
	if xh_sun != "XIAOHE_PROCESS_SUN":
		_mini_host.add_child(UiKit.ink_label(xh_sun, 12, UiKit.INK_MUTED))
	var prog_lab := tr("PROCESS_SUN_PROGRESS")
	if prog_lab == "PROCESS_SUN_PROGRESS":
		prog_lab = "日照"
	_mini_host.add_child(UiKit.ink_label(prog_lab, 12, UiKit.INK_MUTED))
	_sun_prog = ProgressBar.new()
	_sun_prog.min_value = 0
	_sun_prog.max_value = 100
	_sun_prog.value = 0
	_sun_prog.custom_minimum_size = Vector2(0, 26)
	_sun_prog.show_percentage = true
	_mini_host.add_child(_sun_prog)
	_sun_flip_l = UiKit.ink_label("%s · 0" % tr("PROCESS_SUN_FLIP"), 13)
	_mini_host.add_child(_sun_flip_l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_mini_host.add_child(row)
	var flip := Button.new()
	flip.custom_minimum_size = Vector2(140, 52)
	UiKit.style_button(flip, true)
	flip.text = tr("PROCESS_SUN_FLIP")
	if flip.text == "PROCESS_SUN_FLIP":
		flip.text = "翻晒"
	flip.pressed.connect(_on_sun_flip)
	row.add_child(flip)
	_sun_finish_btn = Button.new()
	_sun_finish_btn.custom_minimum_size = Vector2(140, 52)
	UiKit.style_button(_sun_finish_btn, false)
	_sun_finish_btn.text = tr("PROCESS_SUN_DONE")
	if _sun_finish_btn.text == "PROCESS_SUN_DONE":
		_sun_finish_btn.text = "收药"
	_sun_finish_btn.disabled = true
	_sun_finish_btn.pressed.connect(_finish_sun)
	row.add_child(_sun_finish_btn)
	var cancel := UiKit.make_button("PROCESS_CANCEL", false)
	cancel.pressed.connect(func() -> void:
		_sun_active = false
		_focus = ""
		_clear_mini()
		_status.text = tr("PROCESS_SUN_RETRY") if tr("PROCESS_SUN_RETRY") != "PROCESS_SUN_RETRY" else tr("PROCESS_RETRY")
		if _cam_l:
			_cam_l.text = "CAM_PROCESS"
		_apply_yard_bg("STATION_WASH")
	)
	_mini_host.add_child(cancel)
	_status.text = tr("PROCESS_SUN_FLIP_HINT") if tr("PROCESS_SUN_FLIP_HINT") != "PROCESS_SUN_FLIP_HINT" else tr("PROCESS_SUN_HINT")


func _on_sun_flip() -> void:
	_sun_flips += 1
	if AudioHub:
		AudioHub.play_one("sun-dry")
	if _sun_prog:
		_sun_prog.value = minf(100.0, _sun_prog.value + 8.0)
	if _sun_flip_l:
		_sun_flip_l.text = "%s · %d" % [tr("PROCESS_SUN_FLIP"), _sun_flips]
	_status.text = tr("PROCESS_SUN_FLIP_HINT") if _sun_flips < 2 else tr("PROCESS_SUN_HINT")
	_update_sun_finish_enabled()


func _tick_sun(delta: float) -> void:
	if not _sun_active or _sun_prog == null:
		return
	# Slow sun fill — player must flip at least once, not pure AFK.
	_sun_prog.value = minf(100.0, _sun_prog.value + delta * 22.0)
	if _sun_prog.value >= 100.0:
		_sun_over += delta
		_sun_prog.modulate = Color(1.0, 0.85, 0.55) if _sun_over > 1.2 else Color(0.85, 1.0, 0.75)
		if _sun_flips >= 1 and _sun_over >= 2.2:
			# Left too long on the rack → collect as overexposed.
			_finish_sun()
	else:
		_sun_prog.modulate = Color(1, 1, 1, 1)
	_update_sun_finish_enabled()


func _update_sun_finish_enabled() -> void:
	if _sun_finish_btn == null or _sun_prog == null:
		return
	_sun_finish_btn.disabled = not (_sun_flips >= 1 and _sun_prog.value >= 100.0)


func _finish_sun() -> void:
	if not _sun_active:
		return
	if _sun_flips < 1:
		_status.text = tr("PROCESS_SUN_FLIP_NEED")
		return
	if _sun_prog and _sun_prog.value < 100.0:
		_status.text = tr("PROCESS_SUN_WEAK")
		return
	_sun_active = false
	var grade := "ok"
	# 翻少（仅 1 次）或过曝 → ok_ish
	if _sun_flips < 2 or _sun_over > 1.8:
		grade = "ok_ish"
		if _sun_over > 1.8:
			_status.text = tr("PROCESS_SUN_OVER")
		else:
			_status.text = tr("PROCESS_SUN_OKAY")
	else:
		_status.text = tr("PROCESS_SUN_OK")
	_finish_process(grade)


func _finish_process(grade: String) -> void:
	if _focus == "":
		return
	var hid := _focus
	var res: Dictionary = Process.consume_raw_to_processed(hid, grade)
	_fry_active = false
	_sun_active = false
	if not bool(res.get("ok", false)):
		var weak := tr("PROCESS_WASH_WEAK")
		if _station == "STATION_DRY":
			weak = tr("PROCESS_SUN_WEAK")
		elif _station == "STATION_FRY":
			weak = tr("PROCESS_FRY_RETRY")
		_status.text = weak
		return
	if AudioHub:
		AudioHub.play_one("stamp-ok")
	var qlabel := tr("PROCESS_QUALITY_GOOD") if grade == "ok" else tr("PROCESS_QUALITY_OK")
	var done_line := Process.herb_done_line(hid)
	var retry_hint := ""
	if grade == "ok_ish":
		match _station:
			"STATION_WASH":
				retry_hint = " · " + tr("PROCESS_WASH_RETRY")
			"STATION_FRY":
				retry_hint = " · " + tr("PROCESS_FRY_RETRY")
			"STATION_DRY":
				retry_hint = " · " + tr("PROCESS_SUN_RETRY")
		if retry_hint.find("PROCESS_") >= 0:
			retry_hint = " · " + tr("PROCESS_RETRY")
	_status.text = "%s · %s — %s%s" % [done_line, qlabel, tr("PROCESS_DONE_HINT"), retry_hint]
	_refresh_stock()
	_rebuild_herbs()
	_clear_mini()
	_focus = ""
	if _cam_l:
		_cam_l.text = "CAM_PROCESS"
