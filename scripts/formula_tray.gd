extends Panel
## Drop target for the 方剂盘.

signal herb_dropped(herb_id: String)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var id := str(data.get("herb_id", data.get("id", "")))
	return id != ""


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var id := str(data.get("herb_id", data.get("id", "")))
	if id != "":
		herb_dropped.emit(id)
