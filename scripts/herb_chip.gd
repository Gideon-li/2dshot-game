class_name HerbChip
extends Panel
## Draggable herb tile. Drop onto the formula plate.

signal chip_clicked(herb_id: String)

var herb_id: String = ""
var on_plate := false


func setup(id: String, plate: bool = false) -> void:
	herb_id = id
	on_plate = plate
	custom_minimum_size = Vector2(120, 44)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for c in get_children():
		c.queue_free()
	var herb := CaseDB.herb(id)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiKit.PAPER
	sb.border_color = UiKit.nature_ink(str(herb.get("nature", "neutral")))
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 4
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	# V121.1: tray reads ui/herbs/{id}.png (or atlas). No ColorRect swatch for whitelist.
	if Forage and Forage.has_method("make_herb_icon"):
		row.add_child(Forage.make_herb_icon(id, Vector2(32, 32)))
	elif ResourceLoader.exists("res://ui/herbs/%s.png" % id):
		var tr := TextureRect.new()
		tr.texture = load("res://ui/herbs/%s.png" % id)
		tr.custom_minimum_size = Vector2(32, 32)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tr)
	var l := Label.new()
	l.text = CaseDB.named_herb(herb)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", UiKit.INK)
	UiKit.apply_font(l, 15)
	row.add_child(l)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chip_clicked.emit(herb_id)


func _get_drag_data(_at: Vector2) -> Variant:
	var preview := HBoxContainer.new()
	if Forage and Forage.has_method("make_herb_icon"):
		preview.add_child(Forage.make_herb_icon(herb_id, Vector2(28, 28)))
	var lab := Label.new()
	lab.text = CaseDB.named_herb(CaseDB.herb(herb_id))
	lab.add_theme_color_override("font_color", UiKit.INK)
	UiKit.apply_font(lab, 14)
	preview.add_child(lab)
	set_drag_preview(preview)
	return {"herb_id": herb_id, "from_plate": on_plate}


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and (data as Dictionary).has("herb_id")


func _drop_data(_at: Vector2, data: Variant) -> void:
	var n: Node = get_parent()
	while n:
		if n.has_signal("herb_dropped"):
			n.emit_signal("herb_dropped", data)
			return
		n = n.get_parent()
