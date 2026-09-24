extends Control
## V137 chrome proof — HUD-only (avoid full clinic 3D hang in headless).

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(1280, 720)
	size = Vector2(1280, 720)
	TranslationServer.set_locale("zh")
	GameFlow.settings_open = false
	if GameFlow.has_method("refresh_waiting_seats"):
		GameFlow.refresh_waiting_seats(true)
	# Soft clinic-like wash so shot reads as 诊室 chrome.
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.82, 0.78, 0.68, 1)
	add_child(bg)
	var wood := ColorRect.new()
	wood.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	wood.offset_right = 420
	wood.color = Color(0.72, 0.62, 0.48, 1)
	add_child(wood)
	_build_chrome(false)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	var img: Image = get_viewport().get_texture().get_image()
	var p1 := "res://ui/chrome/v137_after.png"
	print("v137_after_saved=", img.save_png(p1) == OK, " path=", p1, " wh=", img.get_width(), "x", img.get_height())
	# Rebuild with settings open
	for c in get_children():
		if c != bg and c != wood:
			c.queue_free()
	await get_tree().process_frame
	_build_chrome(true)
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	var img2: Image = get_viewport().get_texture().get_image()
	var p2 := "res://ui/chrome/v137_settings_open.png"
	print("v137_settings_saved=", img2.save_png(p2) == OK, " path=", p2)
	if not FileAccess.file_exists("res://ui/chrome/v137_before.png") and FileAccess.file_exists("res://incoming/ui-overlap-haopeng-20260924.png"):
		var src := FileAccess.get_file_as_bytes("res://incoming/ui-overlap-haopeng-20260924.png")
		var f := FileAccess.open("res://ui/chrome/v137_before.png", FileAccess.WRITE)
		if f:
			f.store_buffer(src)
			print("v137_before_copied=true")
	get_tree().quit(0)


func _build_chrome(settings_open: bool) -> void:
	var bar := Control.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	var top := HBoxContainer.new()
	top.position = Vector2(24, 8)
	top.size = Vector2(1232, 40)
	top.add_theme_constant_override("separation", 12)
	bar.add_child(top)
	top.add_child(UiKit.ink_label(UiKit.store_title_text(), 20, UiKit.INK, false))
	var day_n := GameFlow.play_day() if GameFlow.has_method("play_day") else 1
	top.add_child(UiKit.ink_label(UiKit.tr_or("SAVE_SLOT_DAY", "第 {n} 日").replace("{n}", str(day_n)), 14, UiKit.SEAL, false))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.add_child(UiKit.make_settings_gear_button())
	var row := HBoxContainer.new()
	row.position = Vector2(24, 56)
	row.size = Vector2(900, 64)
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)
	var seats: Array = GameFlow.waiting_patients() if GameFlow.has_method("waiting_patients") else []
	if seats.is_empty():
		seats = [{"id": "a", "name": {"zh": "顾晏余"}, "identity": {"zh": "青衿"}}, {"id": "b", "name": {"zh": "秋炭妇"}, "identity": {"zh": "炭户"}}, {"id": "c", "name": {"zh": "赵阿福"}, "identity": {"zh": "脚夫"}}, {"id": "d", "name": {"zh": "韩担夫"}, "identity": {"zh": "挑夫"}}]
	for i in mini(seats.size(), 4):
		var p: Dictionary = seats[i]
		var card := Panel.new()
		card.custom_minimum_size = Vector2(170, 56)
		card.add_theme_stylebox_override("panel", UiKit.paper_style())
		var inner := VBoxContainer.new()
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 8
		inner.offset_right = -8
		inner.offset_top = 4
		inner.offset_bottom = -4
		card.add_child(inner)
		inner.add_child(UiKit.ink_label(UiKit.loc_text(p.get("name", {}), str(p.get("id", ""))), 15))
		inner.add_child(UiKit.ink_label(UiKit.loc_text(p.get("identity", {}), ""), 12, UiKit.INK_MUTED))
		row.add_child(card)
	var hint := UiKit.ink_label(tr("CLINIC_HINT"), 14, UiKit.INK_MUTED)
	hint.position = Vector2(24, 128)
	hint.size = Vector2(900, 24)
	bar.add_child(hint)
	var nav := HBoxContainer.new()
	nav.position = Vector2(960, 650)
	nav.size = Vector2(296, 40)
	nav.add_theme_constant_override("separation", 8)
	bar.add_child(nav)
	nav.add_child(UiKit.make_button("GARDEN_OPEN", false))
	var pb := UiKit.make_button("PROCESS_ENTER", false)
	if pb.text == "PROCESS_ENTER":
		pb.text = UiKit.tr_or("PROCESS_ENTER", "去炮制院")
	nav.add_child(pb)
	# Bottom-left dialog panel (readable, clear of waiting cards)
	var dock := Panel.new()
	dock.position = Vector2(16, 460)
	dock.size = Vector2(624, 224)
	dock.add_theme_stylebox_override("panel", UiKit.paper_style())
	bar.add_child(dock)
	var dcol := VBoxContainer.new()
	dcol.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dcol.offset_left = 12
	dcol.offset_right = -12
	dcol.offset_top = 8
	dcol.offset_bottom = -8
	dock.add_child(dcol)
	dcol.add_child(UiKit.ink_label("韩担夫 · 望○ 闻○ 问● 切○", 14, UiKit.SEAL))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 90)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dcol.add_child(scroll)
	var chat := VBoxContainer.new()
	chat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat.custom_minimum_size = Vector2(580, 0)
	scroll.add_child(chat)
	for pair in [["夜里睡得怎么样？", "……还行，就是肩沉。"], ["肩是酸还是胀？", "扛货后更沉。"], ["汗出吗？", "不大出。"]]:
		chat.add_child(UiKit.ink_label("▸ " + pair[0], 13, UiKit.SEAL, false))
		chat.add_child(UiKit.ink_label(pair[1], 14, UiKit.INK, false))
	call_deferred("_stick", scroll)
	var foot := UiKit.ink_label(tr("BOOT_DISCLAIMER_FOOTER"), 13, UiKit.INK_MUTED)
	foot.position = Vector2(24, 690)
	foot.size = Vector2(1232, 20)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar.add_child(foot)
	if settings_open:
		GameFlow.settings_open = true
		var dim := ColorRect.new()
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.color = Color(0.12, 0.1, 0.08, 0.35)
		add_child(dim)
		var body := UiKit.build_settings_body(Callable(), Callable(), Callable())
		body.position = Vector2(460, 200)
		body.size = Vector2(360, 320)
		add_child(body)


func _stick(scroll: ScrollContainer) -> void:
	UiKit.force_scroll_bottom(scroll)
