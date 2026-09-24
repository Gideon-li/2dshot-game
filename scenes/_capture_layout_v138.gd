extends Node
## V138 proof: boot zones + clinic idle CAM_HERO (药柜中景) full HUD.
## Idle MUST use real clinic.tscn + CAM_HERO home — never lightweight paper L5.

func _ready() -> void:
	TranslationServer.set_locale("zh")
	GameFlow.settings_open = false
	# --- Boot ---
	var boot_ps: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var boot: Node = boot_ps.instantiate()
	add_child(boot)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	var img_boot: Image = get_viewport().get_texture().get_image()
	var p_boot := "res://ui/boot/v138_boot.png"
	# A-side may already have landed v138_boot.png — keep it if present and non-trivial.
	var skip_boot_if_present := FileAccess.file_exists(p_boot)
	if skip_boot_if_present:
		print("boot_kept_existing=true path=", p_boot)
	else:
		print("boot_saved=", img_boot.save_png(p_boot) == OK, " path=", p_boot, " wh=", img_boot.get_width(), "x", img_boot.get_height())
	boot.queue_free()
	await get_tree().process_frame
	# --- Clinic idle (CAM_HERO home, full HUD) ---
	GameFlow.fsm_state = "clinic_idle"
	if GameFlow.has_method("refresh_waiting_seats"):
		GameFlow.refresh_waiting_seats(true)
	var clinic_ps: PackedScene = load("res://scenes/clinic.tscn") as PackedScene
	var clinic: Node = clinic_ps.instantiate()
	add_child(clinic)
	await get_tree().process_frame
	await get_tree().process_frame
	if clinic.has_method("_label_patients"):
		clinic.call("_label_patients")
	if clinic.has_method("_pin_cam_hero_home"):
		clinic.call("_pin_cam_hero_home")
	elif clinic.has_method("_switch_camera"):
		clinic.call("_switch_camera", "CAM_HERO")
	var cam := clinic.get_node_or_null("CAM_HERO") as Camera2D
	if cam:
		cam.position = Vector2(1280, 740)
		cam.zoom = Vector2(0.50, 0.50)
		cam.position_smoothing_enabled = false
		cam.make_current()
		cam.enabled = true
	# Disable follow drift during capture
	if clinic.get("_cam_name") != null:
		clinic.set("_cam_name", "CAM_HERO")
	await get_tree().process_frame
	await get_tree().create_timer(0.55).timeout
	# Re-pin in case _process follow nudged
	if cam:
		cam.position = Vector2(1280, 740)
		cam.zoom = Vector2(0.50, 0.50)
		cam.make_current()
	if clinic.has_method("_apply_portraits"):
		clinic.call("_apply_portraits")
	# Hold idle midshot (disable follow drift for the shot).
	if cam:
		cam.position = Vector2(1280, 740)
		cam.zoom = Vector2(0.50, 0.50)
		cam.position_smoothing_enabled = false
		cam.drag_horizontal_enabled = false
		cam.drag_vertical_enabled = false
		cam.make_current()
	if clinic.has_method("set_process"):
		clinic.set_process(false)
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	if cam:
		cam.position = Vector2(1280, 740)
		cam.make_current()
	var img_idle: Image = get_viewport().get_texture().get_image()
	var p_idle := "res://ui/waiting/v138_idle.png"
	print("idle_saved=", img_idle.save_png(p_idle) == OK, " path=", p_idle, " wh=", img_idle.get_width(), "x", img_idle.get_height())
	# Log seat / apprentice for smoke-adjacent proof
	var chars := clinic.get_node_or_null("L5_characters")
	var vis := 0
	var xs: Array = []
	if chars:
		for i in 4:
			var pn := chars.get_node_or_null("Patient%d" % i) as Node2D
			if pn == null:
				continue
			var spr := pn.get_node_or_null("Portrait") as Sprite2D
			if spr and spr.visible and spr.texture != null:
				vis += 1
				xs.append(pn.position.x)
				print("seat", i, " pid=", pn.get_meta("pid", ""), " pos=", pn.position)
		var ap := chars.get_node_or_null("Apprentice") as Node2D
		if ap:
			print("apprentice_pos=", ap.position)
	print("portrait_visible_count=", vis, " xs=", xs)
	# Screen-space footprint under current camera (for Haopeng readability check).
	var cam2 := clinic.get_node_or_null("CAM_HERO") as Camera2D
	if cam2 and chars:
		for i2 in 4:
			var pn2 := chars.get_node_or_null("Patient%d" % i2) as Node2D
			if pn2 == null:
				continue
			var spr2 := pn2.get_node_or_null("Portrait") as Sprite2D
			if spr2 == null or spr2.texture == null:
				continue
			var th2 := float(spr2.texture.get_height()) * absf(spr2.scale.y)
			var tw2 := float(spr2.texture.get_width()) * absf(spr2.scale.x)
			var foot := pn2.position
			var head := foot + Vector2(0, -th2)
			print("portrait_screen seat", i2, " foot=", foot, " head=", head, " display_h=", th2, " display_w=", tw2, " tex=", spr2.texture)

	print("cam_pos=", cam.position if cam else Vector2.ZERO, " zoom=", cam.zoom if cam else Vector2.ZERO)
	# Furniture layer present?
	var furn := clinic.get_node_or_null("L3_furniture/Art") as Sprite2D
	print("l3_furniture_tex=", furn.texture.resource_path if furn and furn.texture else "MISSING")
	get_tree().quit(0 if vis >= 3 else 1)
