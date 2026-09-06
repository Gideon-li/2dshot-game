class_name HerbChip
extends Panel
## Draggable herb tile. Drop onto the formula plate.

signal chip_clicked(herb_id: String)

var herb_id: String = ""
var on_plate := false


func setup(id: String, plate: bool = false) -> void:
	herb_id = id
	on_plate = plate
	custom_minimum_size = Vector2(108, 44)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var herb := CaseDB.herb(id)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiKit.nature_ink(str(herb.get("nature", "neutral"))).lerp(UiKit.PAPER, 0.72)
	sb.border_color = UiKit.nature_ink(str(herb.get("nature", "neutral")))
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = CaseDB.named_herb(herb)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", UiKit.INK)
	UiKit.apply_font(l, 15)
	add_child(l)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chip_clicked.emit(herb_id)


func _get_drag_data(_at: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = CaseDB.named_herb(CaseDB.herb(herb_id))
	preview.add_theme_color_override("font_color", UiKit.INK)
	UiKit.apply_font(preview, 14)
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
