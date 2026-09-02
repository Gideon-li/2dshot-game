extends Node
## 3 local slots. Schema: res://other-systems/save/schema.json

const SCHEMA := "res://other-systems/save/schema.json"
const SLOT_PATH := "user://saves/slot_%d.json"
const SLOT_COUNT := 3

var active_slot: int = 0
var data: Dictionary = {}

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://saves")
	data = load_slot(0)

func schema_default() -> Dictionary:
	var txt := FileAccess.get_file_as_string(SCHEMA)
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		return (parsed as Dictionary).duplicate(true)
	return {}

func load_slot(n: int) -> Dictionary:
	n = clampi(n, 0, SLOT_COUNT - 1)
	var path := SLOT_PATH % n
	if not FileAccess.file_exists(path):
		var fresh := schema_default()
		fresh["slot"] = n
		return fresh
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return schema_default()
	var merged := schema_default()
	_merge(merged, parsed)
	merged["slot"] = n
	return merged

func write_slot(n: int = -1) -> void:
	if n < 0:
		n = active_slot
	n = clampi(n, 0, SLOT_COUNT - 1)
	data["slot"] = n
	var path := SLOT_PATH % n
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))

func disclaimer_accepted() -> bool:
	return bool(data.get("disclaimer_accepted", false))

func accept_disclaimer() -> void:
	data["disclaimer_accepted"] = true
	write_slot()

func set_locale(code: String) -> void:
	data["locale"] = code
	TranslationServer.set_locale(code)
	write_slot()

func _merge(dst: Dictionary, src: Dictionary) -> void:
	for k in src.keys():
		if dst.has(k) and typeof(dst[k]) == TYPE_DICTIONARY and typeof(src[k]) == TYPE_DICTIONARY:
			_merge(dst[k], src[k])
		else:
			dst[k] = src[k]
